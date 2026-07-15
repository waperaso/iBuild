import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';

part 'lead.freezed.dart';
part 'lead.g.dart';

/// A client enquiry (lead-gen model — no online payment, plan section 3.6).
@freezed
abstract class Lead with _$Lead {
  const factory Lead({
    required String id,
    required String number,
    required String projectId,
    required String projectName,
    String? unitId,
    String? unitLabel,
    required LeadIntent intent,
    required LeadStatus status,
    required String contactPhone,
    String? message,
    DateTime? preferredAt,
    required DateTime createdAt,
  }) = _Lead;

  factory Lead.fromJson(Map<String, dynamic> json) => _$LeadFromJson(json);
}
