import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'api.dart';
import 'fx.dart';
import 'l10n.dart';
import 'router.dart';
import 'session.dart';
import 'session_scope.dart';
import 'theme.dart';

class IBuildApp extends StatefulWidget {
  const IBuildApp({
    super.key,
    required this.api,
    this.session,
    this.restoreOnStart = true,
  });

  final Api api;
  final SessionController? session;
  final bool restoreOnStart;

  @override
  State<IBuildApp> createState() => _IBuildAppState();
}

class _IBuildAppState extends State<IBuildApp> {
  late final SessionController session;
  late final LocaleController locale;
  late final FxController fx;
  GoRouter? _router;

  late final ThemeController theme;

  @override
  void initState() {
    super.initState();
    locale = LocaleController();
    theme = ThemeController();
    fx = FxController();
    session = widget.session ?? SessionController(widget.api);
    session.addListener(_onSession);
    theme.addListener(_onSession);
    if (widget.restoreOnStart && !session.ready) {
      session.restore();
    }
  }

  void _onSession() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    session.removeListener(_onSession);
    theme.removeListener(_onSession);
    locale.dispose();
    theme.dispose();
    fx.dispose();
    _router?.dispose();
    if (widget.session == null) session.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // GoRouter runs the top-level redirect once per navigation. Create it
    // only after the session is known, so the first redirect already sees
    // the signed-in user and does not stay on the boot screen.
    if (session.ready) {
      _router ??= buildRouter(session);
    }
    return LocaleScope(
      controller: locale,
      child: ThemeScope(
        controller: theme,
        child: FxScope(
        controller: fx,
        child: SessionScope(
        session: session,
        child: session.ready
              ? MaterialApp.router(
                title: 'iBuild',
                theme: buildIBuildTheme(IBuildColors.light),
                darkTheme: buildIBuildTheme(IBuildColors.dark),
                themeMode: theme.mode,
                themeAnimationDuration: Duration.zero,
                routerConfig: _router!,
                debugShowCheckedModeBanner: false,
              )
            : MaterialApp(
                title: 'iBuild',
                theme: buildIBuildTheme(IBuildColors.light),
                darkTheme: buildIBuildTheme(IBuildColors.dark),
                themeMode: theme.mode,
                themeAnimationDuration: Duration.zero,
                debugShowCheckedModeBanner: false,
                home: const BootScreen(),
              ),
        ),
      ),
      ),
    );
  }
}
