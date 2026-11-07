import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import 'api.dart';
import 'fx.dart';
import 'l10n.dart';
import 'router.dart';
import 'session.dart';
import 'session_scope.dart';
import 'theme.dart';

const _materialLocales = <Locale>[Locale('ru'), Locale('en'), Locale('uz')];

const _materialDelegates = <LocalizationsDelegate<dynamic>>[
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

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
    locale.addListener(_onSession);
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
    locale.removeListener(_onSession);
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
                locale: Locale(locale.language.name),
                supportedLocales: _materialLocales,
                localizationsDelegates: _materialDelegates,
                routerConfig: _router!,
                builder: (context, child) => Column(
                  children: [
                    if (session.user?.isDemo ?? false) _DemoStrip(session: session),
                    Expanded(child: child ?? const SizedBox.shrink()),
                  ],
                ),
                debugShowCheckedModeBanner: false,
              )
            : MaterialApp(
                title: 'iBuild',
                theme: buildIBuildTheme(IBuildColors.light),
                darkTheme: buildIBuildTheme(IBuildColors.dark),
                themeMode: theme.mode,
                themeAnimationDuration: Duration.zero,
                locale: Locale(locale.language.name),
                supportedLocales: _materialLocales,
                localizationsDelegates: _materialDelegates,
                debugShowCheckedModeBanner: false,
                home: const BootScreen(),
              ),
        ),
      ),
      ),
    );
  }
}

/// Says on every screen that this is the read-only demo, and lets the visitor leave it.
class _DemoStrip extends StatelessWidget {
  const _DemoStrip({required this.session});

  final SessionController session;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final copy = LocaleScope.copy(context);
    final status = Text(
      copy.demoBanner,
      key: const Key('demo-banner'),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(color: colors.ink),
    );
    final exit = TextButton(
      key: const Key('demo-exit'),
      style: TextButton.styleFrom(
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        foregroundColor: colors.ink,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      ),
      onPressed: session.logout,
      child: Text(copy.demoExit, maxLines: 1, overflow: TextOverflow.ellipsis),
    );
    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: Material(
        key: const Key('demo-strip'),
        color: Color.alphaBlend(colors.warning.withValues(alpha: 0.28), colors.surface),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final icon = Icon(Icons.visibility_outlined, size: 18, color: colors.warning);
                // A bank bar beside a narrow side rail used to squeeze this row
                // until only the icon stayed on screen. Below 720 the exit drops
                // to its own line so both the status and the way out stay visible.
                if (constraints.maxWidth < 720) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          icon,
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(child: status),
                        ],
                      ),
                      Align(alignment: Alignment.centerLeft, child: exit),
                    ],
                  );
                }
                return Row(
                  children: [
                    icon,
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: status),
                    exit,
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
