import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ibuild_core/ibuild_core.dart';

import '../../../core/config/env.dart';
import '../../../core/network/api_client.dart';
import '../../../models/mock_data.dart';

String _intentWire(LeadIntent intent) => switch (intent) {
  LeadIntent.buy => 'buy',
  LeadIntent.buyOffplan => 'buy_offplan',
  LeadIntent.rent => 'rent',
  LeadIntent.viewing => 'viewing',
  LeadIntent.callback => 'callback',
};

/// Leads ("My inquiries") — list + submit, live API or mock fallback.
class LeadsRepository {
  LeadsRepository(this._dio);

  final Dio _dio;
  final _rand = Random();

  Future<List<Lead>> fetchLeads() async {
    if (Env.useMockData) return List.of(MockData.leads);
    final response = await _dio.get<List<dynamic>>('/users/me/leads');
    return (response.data ?? const [])
        .map((e) => Lead.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Lead> submitLead({
    required String projectId,
    required String projectName,
    String? unitId,
    String? unitLabel,
    required LeadIntent intent,
    required String contactPhone,
    String? message,
    DateTime? preferredAt,

    /// PII-processing consent — the server rejects `POST /v1/leads` with
    /// `422 VALIDATION_ERROR` unless this is `true` (plan section 11 /
    /// Track A.2). The lead form only enables submit once the user has
    /// checked the consent checkbox, so this is always `true` by the time it
    /// gets here, but the parameter stays required so a future call site
    /// can't accidentally skip it.
    required bool consent,
  }) async {
    if (Env.useMockData) {
      return Lead(
        id: 'lead-${DateTime.now().millisecondsSinceEpoch}',
        number: 'LD-${100000 + _rand.nextInt(9000)}',
        projectId: projectId,
        projectName: projectName,
        unitId: unitId,
        unitLabel: unitLabel,
        intent: intent,
        status: LeadStatus.newLead,
        contactPhone: contactPhone,
        message: message,
        preferredAt: preferredAt,
        createdAt: DateTime.now(),
      );
    }
    final response = await _dio.post<Map<String, dynamic>>(
      '/leads',
      data: {
        'projectId': projectId,
        'unitId': unitId,
        'intent': _intentWire(intent),
        'contactPhone': contactPhone,
        'message': message,
        'preferredAt': preferredAt?.toIso8601String(),
        'consent': consent,
      },
    );
    return Lead.fromJson(response.data!);
  }
}

final leadsRepositoryProvider = Provider<LeadsRepository>((ref) {
  return LeadsRepository(ref.watch(apiClientProvider));
});
