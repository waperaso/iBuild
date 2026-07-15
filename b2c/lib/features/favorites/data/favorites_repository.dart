import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/config/env.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/auth_token_cache.dart';

const _prefsKey = 'ibuild.favorites';

/// Persists favorited project IDs locally and syncs to `/users/me/favorites`
/// when the user is signed in.
class FavoritesRepository {
  FavoritesRepository(this._dio);

  final Dio _dio;

  Future<Set<String>> restore() async {
    final prefs = await SharedPreferences.getInstance();
    final local = prefs.getStringList(_prefsKey)?.toSet() ?? <String>{};

    if (Env.useMockData || AuthTokenCache.accessToken == null) {
      return local;
    }
    try {
      final response = await _dio.get<List<dynamic>>('/users/me/favorites');
      final remote = (response.data ?? const [])
          .map((e) => e.toString())
          .toSet();
      final merged = {...local, ...remote};
      await prefs.setStringList(_prefsKey, merged.toList());
      // Push any local-only IDs to the server.
      for (final id in local.difference(remote)) {
        await _dio.post('/users/me/favorites', data: {'projectId': id});
      }
      return merged;
    } catch (_) {
      return local;
    }
  }

  Future<void> persist(Set<String> projectIds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, projectIds.toList());
  }

  Future<void> addRemote(String projectId) async {
    if (Env.useMockData || AuthTokenCache.accessToken == null) return;
    try {
      await _dio.post('/users/me/favorites', data: {'projectId': projectId});
    } catch (_) {}
  }

  Future<void> removeRemote(String projectId) async {
    if (Env.useMockData || AuthTokenCache.accessToken == null) return;
    try {
      await _dio.delete('/users/me/favorites/$projectId');
    } catch (_) {}
  }
}

final favoritesRepositoryProvider = Provider<FavoritesRepository>(
  (ref) => FavoritesRepository(ref.watch(apiClientProvider)),
);
