import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/buyer_persona.dart';

const _prefsKey = 'ibuild.quiz.persona';

/// Locally-persisted buyer-persona quiz result. Mirrors the lightweight
/// controller pattern used by [CurrencyController]: restores from
/// [SharedPreferences] on build and writes back on every mutation. No server.
class QuizController extends Notifier<QuizResult?> {
  @override
  QuizResult? build() {
    _restore();
    return null;
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null) return;
    try {
      state = QuizResult.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      // Corrupt/legacy payload — ignore and treat as "not taken yet".
    }
  }

  /// Computes the persona for [answers], stores it locally, and updates state.
  Future<QuizResult> save(QuizAnswers answers) async {
    final result = QuizResult(
      answers: answers,
      persona: personaFor(answers),
      completedAt: DateTime.now(),
    );
    state = result;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(result.toJson()));
    return result;
  }

  Future<void> clear() async {
    state = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }
}

final quizControllerProvider = NotifierProvider<QuizController, QuizResult?>(
  QuizController.new,
);
