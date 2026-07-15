import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/otp_screen.dart';
import '../../features/developer/presentation/developer_screen.dart';
import '../../features/discovery/presentation/discovery_screen.dart';
import '../../features/favorites/presentation/favorites_screen.dart';
import '../../features/leads/presentation/lead_form_screen.dart';
import '../../features/leads/presentation/leads_screen.dart';
import '../../features/map/presentation/map_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/onboarding/presentation/quiz_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/project/presentation/project_screen.dart';
import '../../features/units/presentation/compare_screen.dart';
import '../../features/units/presentation/unit_card_screen.dart';
import '../../features/units/presentation/unit_grid_screen.dart';
import '../network/auth_token_cache.dart';
import '../theme/app_dimens.dart';
import '../widgets/adaptive_scaffold.dart';
import '../widgets/splash_screen.dart';

final _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final _shellKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

/// Cross-fade + subtle slide-up page transition, tuned to stay light on both
/// desktop/web and mobile.
///
/// The incoming page fades/slides in on its own [animation] while the
/// outgoing page fades out on [secondaryAnimation] — both driven by the same
/// underlying route animation, so they always resolve in lockstep. That
/// synchronization is the actual fix for the old bug here: previously this
/// used `Duration.zero`, which let the new page's frame land before the
/// outgoing page's route was actually popped from the Overlay, so for a
/// frame or two both pages were stacked and the old one lingered behind the
/// new one instead of disappearing together with it. A short, explicit,
/// symmetric fade keeps exactly one page visible at a time and still feels
/// snappy (~260ms, [AppDurations.medium]) rather than the sluggish combos
/// that made navigation feel laggy before.
CustomTransitionPage<void> _fadeSlidePage({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
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
        // Fades this page out once a page pushed on top of it starts
        // entering (no-op while this page is simply entering itself, since
        // secondaryAnimation sits at 0 until something covers it).
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

/// App route table. A [StatefulShellRoute] gives each primary tab its own
/// navigation stack, wrapped by [AdaptiveScaffold] which renders the mobile
/// pill bar or the desktop sidebar.
final routerProvider = Provider<GoRouter>((ref) {
  final bootstrap = ref.watch(bootstrapProvider);

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/splash',
    refreshListenable: _BootstrapRefresh(ref),
    redirect: (context, state) {
      final onSplash = state.matchedLocation == '/splash';
      // One animated loading state for the whole cold-start bootstrap (the
      // cached-session token read) — nothing renders until it resolves, so
      // there's no blank/frozen frame before the app ever paints anything.
      if (bootstrap.isLoading) return onSplash ? null : '/splash';
      if (onSplash) return '/onboarding';
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        pageBuilder: (context, state) =>
            _fadeSlidePage(state: state, child: const SplashScreen()),
      ),
      GoRoute(
        path: '/onboarding',
        pageBuilder: (context, state) =>
            _fadeSlidePage(state: state, child: const OnboardingScreen()),
      ),
      // Phone-OTP sign-in (plan §5) — top-level, outside the shell, so guest
      // browsing to `/home` never gets gated behind it.
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) =>
            _fadeSlidePage(state: state, child: const LoginScreen()),
      ),
      GoRoute(
        path: '/otp',
        pageBuilder: (context, state) => _fadeSlidePage(
          state: state,
          child: OtpScreen(
            requestId: state.uri.queryParameters['requestId'] ?? '',
            phone: state.uri.queryParameters['phone'] ?? '',
          ),
        ),
      ),
      // Engagement features (plan Phase 3) — top-level, like /login and
      // /otp above, so they're reachable from any tab without nesting under
      // the discovery shell branch.
      GoRoute(
        path: '/notifications',
        pageBuilder: (context, state) =>
            _fadeSlidePage(state: state, child: const NotificationsScreen()),
      ),
      GoRoute(
        path: '/compare',
        pageBuilder: (context, state) =>
            _fadeSlidePage(state: state, child: const CompareScreen()),
      ),
      // Gamified buyer-persona quiz (Phase 2, frontend-only) — top-level so it's
      // reachable from onboarding and the profile without nesting under a tab.
      GoRoute(
        path: '/quiz',
        pageBuilder: (context, state) =>
            _fadeSlidePage(state: state, child: const QuizScreen()),
      ),
      StatefulShellRoute.indexedStack(
        parentNavigatorKey: _rootKey,
        // Without this, the shell (bottom nav / sidebar + active tab) falls
        // back to a plain [MaterialPage], which animates with the platform's
        // default page-transitions theme instead of [_fadeSlidePage]. That
        // mismatch was the real cause of the "old page lingers behind the
        // new one" glitch: pushing a detail route (e.g. `project/:id`) on
        // top of the shell showed the new page settle on our ~260ms fade
        // while the shell underneath animated out on its own, longer,
        // platform-default timeline. Giving the shell the same transition
        // keeps entrance/exit perfectly in sync in both directions.
        pageBuilder: (context, state, navigationShell) => _fadeSlidePage(
          state: state,
          child: AdaptiveScaffold(navigationShell: navigationShell),
        ),
        branches: [
          StatefulShellBranch(
            navigatorKey: _shellKey,
            routes: [
              GoRoute(
                path: '/home',
                pageBuilder: (context, state) => _fadeSlidePage(
                  state: state,
                  child: const DiscoveryScreen(),
                ),
                routes: [
                  GoRoute(
                    path: 'developer/:id',
                    parentNavigatorKey: _rootKey,
                    pageBuilder: (context, state) => _fadeSlidePage(
                      state: state,
                      child: DeveloperScreen(
                        developerId: state.pathParameters['id']!,
                      ),
                    ),
                  ),
                  GoRoute(
                    path: 'project/:id',
                    parentNavigatorKey: _rootKey,
                    pageBuilder: (context, state) => _fadeSlidePage(
                      state: state,
                      child: ProjectScreen(
                        projectId: state.pathParameters['id']!,
                      ),
                    ),
                  ),
                  GoRoute(
                    path: 'project/:id/grid',
                    parentNavigatorKey: _rootKey,
                    pageBuilder: (context, state) => _fadeSlidePage(
                      state: state,
                      child: UnitGridScreen(
                        projectId: state.pathParameters['id']!,
                      ),
                    ),
                  ),
                  GoRoute(
                    path: 'unit/:uid',
                    parentNavigatorKey: _rootKey,
                    pageBuilder: (context, state) => _fadeSlidePage(
                      state: state,
                      child: UnitCardScreen(
                        unitId: state.pathParameters['uid']!,
                        projectId: state.uri.queryParameters['project'],
                      ),
                    ),
                  ),
                  GoRoute(
                    path: 'lead/new',
                    parentNavigatorKey: _rootKey,
                    pageBuilder: (context, state) => _fadeSlidePage(
                      state: state,
                      child: LeadFormScreen(
                        projectId: state.uri.queryParameters['project'],
                        unitId: state.uri.queryParameters['unit'],
                        initialIntent: state.uri.queryParameters['intent'],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/map',
                pageBuilder: (context, state) =>
                    _fadeSlidePage(state: state, child: const MapScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/favorites',
                pageBuilder: (context, state) => _fadeSlidePage(
                  state: state,
                  child: const FavoritesScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/inquiries',
                pageBuilder: (context, state) =>
                    _fadeSlidePage(state: state, child: const LeadsScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                pageBuilder: (context, state) =>
                    _fadeSlidePage(state: state, child: const ProfileScreen()),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

class _BootstrapRefresh extends ChangeNotifier {
  _BootstrapRefresh(this._ref) {
    _ref.listen(bootstrapProvider, (_, _) => notifyListeners());
  }
  final Ref _ref;
}
