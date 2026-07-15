import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/provider_retry.dart';
import 'core/widgets/error_screen.dart';
import 'core/widgets/restart_widget.dart';

/// Session restore (secure storage read + `/users/me`) happens inside
/// [AuthController] once the app is already on screen, behind the animated
/// splash — `main` no longer blocks the first frame on it, which is what
/// made cold starts feel laggy.
///
/// Everything below `runZonedGuarded` exists so a first-build failure (the
/// "white screen after refresh, no logs" symptom) is at minimum *visible*
/// and *recoverable*: uncaught errors are logged instead of silently
/// swallowed, and any widget that throws during build renders a real
/// "Something went wrong" screen with a Reload action instead of a blank
/// grey box.
void main() {
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    developer.log(
      'FlutterError.onError',
      error: details.exception,
      stackTrace: details.stack,
      name: 'b2b.error',
    );
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    developer.log(
      'PlatformDispatcher.onError',
      error: error,
      stackTrace: stack,
      name: 'b2b.error',
    );
    return true;
  };
  ErrorWidget.builder = (details) => ErrorScreen(message: '${details.exception}');

  runZonedGuarded(
    () {
      WidgetsFlutterBinding.ensureInitialized();
      runApp(
        RestartWidget(
          child: const ProviderScope(retry: providerRetry, child: B2bApp()),
        ),
      );
    },
    (error, stack) {
      developer.log(
        'Uncaught zone error',
        error: error,
        stackTrace: stack,
        name: 'b2b.error',
      );
    },
  );
}
