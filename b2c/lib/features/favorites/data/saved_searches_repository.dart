import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../models/saved_search.dart';

const _prefsKey = 'ibuild.saved_searches';

/// Local SharedPreferences store for [SavedSearch] (JSON-encoded).
class SavedSearchesRepository {
  Future<List<SavedSearch>> restore() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null) return const [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((e) => SavedSearch.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> persist(List<SavedSearch> searches) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsKey,
      jsonEncode(searches.map((s) => s.toJson()).toList()),
    );
  }
}
