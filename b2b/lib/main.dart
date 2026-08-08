import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/provider_retry.dart';
import 'core/session_storage.dart';
import 'core/widgets/error_screen.dart';
import 'core/widgets/restart_widget.dart';

/// Session restore runs in [AuthController] behind splash; errors are logged
/// and surfaced via [ErrorScreen] instead of a blank page.
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
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      globalSessionStorage = await SessionStorage.open();
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
