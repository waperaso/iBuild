import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'app.dart';
import 'core/config/env.dart';
import 'core/provider_retry.dart';

/// Token warm-up runs on `/splash` ([bootstrapProvider]), not here.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Fail closed: a release artifact must never ship the mock-data seam (which
  // includes the `123456` OTP auth bypass). Pass
  // `--dart-define=USE_MOCK_DATA=false` for production builds.
  if (kReleaseMode && Env.useMockData) {
    throw StateError(
      'Refusing to start a release build with USE_MOCK_DATA=true — pass '
      '--dart-define=USE_MOCK_DATA=false for production.',
    );
  }

  const sentryDsn = String.fromEnvironment('SENTRY_DSN');
  if (sentryDsn.isNotEmpty) {
    await SentryFlutter.init((options) {
      options.dsn = sentryDsn;
      options.environment = kReleaseMode ? 'production' : 'development';
      options.tracesSampleRate = 0.2;
    }, appRunner: () => runApp(
          const ProviderScope(retry: providerRetry, child: IBuildApp()),
        ));
  } else {
    runApp(const ProviderScope(retry: providerRetry, child: IBuildApp()));
  }
}
