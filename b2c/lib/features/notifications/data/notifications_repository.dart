import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_notification.dart';

const _prefsKey = 'ibuild.notifications';

/// Most recent notifications kept in local storage; older ones are dropped
/// on persist so the list can't grow unbounded.
const kNotificationsCap = 50;

class NotificationsRepository {
  Future<List<AppNotification>> restore() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null) return const [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> persist(List<AppNotification> notifications) async {
    final prefs = await SharedPreferences.getInstance();
    final capped = notifications.take(kNotificationsCap).toList();
    await prefs.setString(
      _prefsKey,
      jsonEncode(capped.map((n) => n.toJson()).toList()),
    );
  }
}
