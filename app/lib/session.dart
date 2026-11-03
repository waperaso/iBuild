import 'dart:async';

import 'package:flutter/foundation.dart';

import 'api.dart';
import 'models.dart';

class SessionController extends ChangeNotifier {
  SessionController(this.api);

  final Api api;

  UserProfile? user;
  List<ProjectSummary> projects = const [];
  String? currentProjectId;
  bool ready = false;
  bool busy = false;
  String? error;

  /// Unread letters of the signed-in person, shown on the mail button.
  int mailUnread = 0;
  DateTime? _mailAsked;

  /// Asks the server for the number of unread letters. Quiet when it fails and
  /// not more often than every few seconds unless [force] is set.
  Future<void> refreshMail({bool force = false}) async {
    if (user == null) {
      if (mailUnread != 0) {
        mailUnread = 0;
        notifyListeners();
      }
      return;
    }
    final now = DateTime.now();
    final last = _mailAsked;
    if (!force && last != null && now.difference(last) < const Duration(seconds: 5)) return;
    _mailAsked = now;
    try {
      final answer = await api.getJson('/api/mail/unread');
      final count = (answer['count'] as num?)?.toInt() ?? 0;
      if (count != mailUnread) {
        mailUnread = count;
        notifyListeners();
      }
    } catch (_) {
      // The badge is a convenience; a failure must not disturb the screen.
    }
  }

  Future<void> restore() async {
    try {
      user = await api.me();
      projects = user == null ? const [] : await api.projects();
      error = null;
      if (user != null) unawaited(refreshMail(force: true));
    } on ApiException catch (failure) {
      user = null;
      projects = const [];
      error = failure.message;
    } finally {
      ready = true;
      notifyListeners();
    }
  }

  Future<bool> login(String login, String password) async {
    busy = true;
    error = null;
    notifyListeners();
    try {
      user = await api.login(login, password);
      projects = await api.projects();
      error = null;
      unawaited(refreshMail(force: true));
      return true;
    } on ApiException catch (failure) {
      user = null;
      projects = const [];
      error = failure.message;
      return false;
    } finally {
      busy = false;
      ready = true;
      notifyListeners();
    }
  }

  /// Opens the read-only demo as one of the roles.
  Future<bool> demoLogin(String role) async {
    busy = true;
    error = null;
    notifyListeners();
    try {
      user = await api.demoLogin(role);
      projects = await api.projects();
      error = null;
      return true;
    } on ApiException catch (failure) {
      user = null;
      projects = const [];
      error = failure.message;
      return false;
    } finally {
      busy = false;
      ready = true;
      notifyListeners();
    }
  }

  Future<void> changePassword(String current, String next) async {
    await api.changePassword(current, next);
    user = await api.me() ?? user;
    notifyListeners();
  }

  Future<void> logout() async {
    try {
      await api.logout();
    } on ApiException {
      // The screen still returns to the login form.
    }
    user = null;
    mailUnread = 0;
    projects = const [];
    currentProjectId = null;
    error = null;
    notifyListeners();
  }

  Future<String?> createProject({
    required String name,
    required String address,
  }) async {
    try {
      await api.createProject(name: name, address: address);
      projects = await api.projects();
      notifyListeners();
      return null;
    } on ApiException catch (failure) {
      return failure.message;
    }
  }

  ProjectSummary? findProject(String id) {
    for (final project in projects) {
      if (project.id == id) return project;
    }
    return null;
  }

  ProjectSummary? get focusedProject {
    if (currentProjectId == null) return null;
    return findProject(currentProjectId!);
  }

  void rememberProject(ProjectSummary project) {
    currentProjectId = project.id;
    projects = [
      for (final item in projects)
        if (item.id == project.id) project else item,
    ];
    notifyListeners();
  }
}
