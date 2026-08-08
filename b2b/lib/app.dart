import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/auth/auth.dart';
import 'features/shell/b2b_adaptive_shell.dart';
import 'features/auth/apply_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/otp_screen.dart';
import 'features/platform/platform_active_projects.dart';
import 'features/platform/platform_crm.dart';
import 'features/platform/platform_home.dart';
import 'features/platform/platform_moderation.dart';
import 'features/platform/platform_notifications.dart';
import 'features/platform/platform_projects.dart';
import 'features/platform/platform_tickets.dart';
import 'features/residence/residence_home.dart';
import 'features/residence/org_profile_screen.dart';
import 'features/residence/project_detail_admin.dart';
import 'features/settings/settings_screen.dart';
import 'features/support/support_tickets.dart';
import 'core/localization/locale_controller.dart';
import 'core/theme/app_dimens.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'core/widgets/app_scroll_behavior.dart';
import 'core/widgets/splash_screen.dart';
import 'l10n/gen/app_localizations.dart';

/// Fade + slight slide for pushed auth/shell entry routes (not shell siblings).
CustomTransitionPage<void> _fadeSlidePage({
  required LocalKey key,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: key,
    child: child,
    transitionDuration: AppDurations.medium,
    reverseTransitionDuration: AppDurations.medium,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final enter = CurvedAnimation(
        parent: animation,
        curve: AppDurations.enter,
        reverseCurve: AppDurations.exit,
      );
      final exit = CurvedAnimation(
        parent: secondaryAnimation,
        curve: AppDurations.exit,
        reverseCurve: AppDurations.enter,
      );

      return FadeTransition(
        opacity: Tween<double>(begin: 1, end: 0).animate(exit),
        child: FadeTransition(
          opacity: enter,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.03),
              end: Offset.zero,
            ).animate(enter),
            child: child,
          ),
        ),
      );
    },
  );
}

/// No transition for sibling shell panels (instant cut).
Page<void> _instantPage({required LocalKey key, required Widget child}) {
  return NoTransitionPage<void>(key: key, child: child);
}

final _routerProvider = Provider<GoRouter>((ref) {
  // Do not `watch` auth here — that recreates GoRouter on every auth update
  // and remounts the shell (re-firing child fetches). Redirect reads live
  // state via [ref.read]; [refreshListenable] triggers redirect re-runs.
  final refresh = _AuthRefresh(ref);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final user = auth.value;
      final onSplash = state.matchedLocation == '/splash';
      // Single animated loading state for the whole session restore — no
      // route renders until auth has actually resolved, so there's no
      // flash of the login screen before an authenticated user is bounced
      // into their dashboard.
      if (auth.isLoading) return onSplash ? null : '/splash';
      if (onSplash) {
        if (user == null) return '/login';
        if (!user.isSystemAdmin && !user.isResidenceAdmin) return '/apply';
        return user.isSystemAdmin ? '/platform' : '/residence';
      }
      final loggingIn =
          state.matchedLocation.startsWith('/login') ||
          state.matchedLocation.startsWith('/otp');
      if (user == null) return loggingIn ? null : '/login';
      if (!user.isSystemAdmin && !user.isResidenceAdmin) {
        if (state.matchedLocation == '/apply') return null;
        return '/apply';
      }
      // A system admin never owns a ЖК — the "residence" (own projects) and
      // "organization" screens are a residence admin's own dashboard, so
      // bounce a system admin to the platform-wide "ЖК" roster instead.
      if (user.isSystemAdmin &&
          (state.matchedLocation == '/residence' ||
              state.matchedLocation.startsWith('/residence/org'))) {
        return '/platform/projects';
      }
      // Conversely, the platform governance surface (/platform/*) is
      // system-admin only — a residence admin typing the URL lands on
      // their own workspace instead.
      if (!user.isSystemAdmin && state.matchedLocation.startsWith('/platform')) {
        return '/residence';
      }
      if (loggingIn || state.matchedLocation == '/apply') {
        return user.isSystemAdmin ? '/platform' : '/residence';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        pageBuilder: (_, state) =>
            _fadeSlidePage(key: state.pageKey, child: const SplashScreen()),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (_, state) =>
            _fadeSlidePage(key: state.pageKey, child: const LoginScreen()),
      ),
      GoRoute(
        path: '/otp',
        pageBuilder: (_, state) {
          final extra = state.extra as Map<String, String>? ?? {};
          return _fadeSlidePage(
            key: state.pageKey,
            child: OtpScreen(
              phone: extra['phone'] ?? '',
              requestId: extra['requestId'] ?? '',
            ),
          );
        },
      ),
      GoRoute(
        path: '/apply',
        pageBuilder: (_, state) => _fadeSlidePage(
          key: state.pageKey,
          child: const DeveloperApplyScreen(),
        ),
      ),
      ShellRoute(
        pageBuilder: (_, state, child) => _fadeSlidePage(
          key: state.pageKey,
          child: B2bAdaptiveShell(child: child),
        ),
        routes: [
          GoRoute(
            path: '/platform',
            pageBuilder: (_, state) =>
                _instantPage(key: state.pageKey, child: const PlatformHome()),
          ),
          GoRoute(
            path: '/platform/moderation',
            pageBuilder: (_, state) => _instantPage(
              key: state.pageKey,
              child: const PlatformModeration(),
            ),
          ),
          GoRoute(
            path: '/platform/active',
            pageBuilder: (_, state) => _instantPage(
              key: state.pageKey,
              child: const PlatformActiveProjects(),
            ),
          ),
          GoRoute(
            path: '/platform/projects',
            pageBuilder: (_, state) => _instantPage(
              key: state.pageKey,
              child: const PlatformProjects(),
            ),
          ),
          GoRoute(
            path: '/platform/crm',
            pageBuilder: (_, state) =>
                _instantPage(key: state.pageKey, child: const PlatformCrm()),
          ),
          GoRoute(
            path: '/platform/tickets',
            pageBuilder: (_, state) => _instantPage(
              key: state.pageKey,
              child: const PlatformTickets(),
            ),
          ),
          GoRoute(
            path: '/platform/notifications',
            pageBuilder: (_, state) => _instantPage(
              key: state.pageKey,
              child: const PlatformNotifications(),
            ),
          ),
          GoRoute(
            path: '/residence',
            pageBuilder: (_, state) => _instantPage(
              key: state.pageKey,
              child: const ResidenceHome(),
            ),
          ),
          GoRoute(
            path: '/residence/org',
            pageBuilder: (_, state) => _instantPage(
              key: state.pageKey,
              child: const OrgProfileScreen(),
            ),
          ),
          GoRoute(
            path: '/residence/project/:id',
            pageBuilder: (_, state) => _instantPage(
              key: state.pageKey,
              child: ProjectDetailAdmin(
                projectId: state.pathParameters['id']!,
              ),
            ),
          ),
          GoRoute(
            path: '/support',
            pageBuilder: (_, state) =>
                _instantPage(key: state.pageKey, child: const SupportTickets()),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (_, state) =>
                _instantPage(key: state.pageKey, child: const SettingsScreen()),
          ),
        ],
      ),
    ],
  );
});

class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(this._ref) {
    _subscription = _ref.listen(authControllerProvider, (_, _) {
      notifyListeners();
    });
  }

  final Ref _ref;
  late final ProviderSubscription<AsyncValue<AdminUser?>> _subscription;

  @override
  void dispose() {
    _subscription.close();
    super.dispose();
  }
}

class B2bApp extends ConsumerWidget {
  const B2bApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(_routerProvider);
    final locale = ref.watch(localeControllerProvider);
    final theme = ref.watch(themeControllerProvider);
    return MaterialApp.router(
      title: 'iBuild B2B',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(theme.light),
      darkTheme: buildAppTheme(theme.dark),
      themeMode: theme.themeMode,
      scrollBehavior: const AppScrollBehavior(),
      routerConfig: router,
      locale: locale,
      supportedLocales: kSupportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
