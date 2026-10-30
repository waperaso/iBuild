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

  Future<void> restore() async {
    try {
      user = await api.me();
      projects = user == null ? const [] : await api.projects();
      error = null;
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
