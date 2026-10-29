import 'package:flutter/material.dart';

import 'session.dart';

class SessionScope extends InheritedNotifier<SessionController> {
  const SessionScope({
    super.key,
    required SessionController session,
    required super.child,
  }) : super(notifier: session);

  static SessionController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<SessionScope>();
    assert(scope != null, 'SessionScope is missing');
    return scope!.notifier!;
  }
}
