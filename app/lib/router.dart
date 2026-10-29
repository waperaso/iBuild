import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'brand.dart';
import 'screens/admin/admin_screens.dart';
import 'screens/bank/approval_screen.dart';
import 'screens/bank/bank_sections.dart';
import 'screens/bank/queue_screen.dart';
import 'screens/bank/tranche_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/inspections_screen.dart';
import 'screens/draw_wizard_screen.dart';
import 'screens/login_screen.dart';
import 'screens/moderation_screen.dart';
import 'screens/password_screen.dart';
import 'screens/applications_screen.dart';
import 'screens/project_screen.dart';
import 'screens/register_screen.dart';
import 'screens/register_status_screen.dart';
import 'screens/projects_screen.dart';
import 'screens/request_form_screen.dart';
import 'screens/request_screen.dart';
import 'screens/requests_screen.dart';
import 'screens/section_screens.dart';
import 'session.dart';
import 'shell.dart';
import 'theme.dart';

Page<void> _instant(GoRouterState state, Widget child, {LocalKey? key}) {
  return CustomTransitionPage<void>(
    key: key ?? state.pageKey,
    child: child,
    transitionDuration: Duration.zero,
    reverseTransitionDuration: Duration.zero,
    transitionsBuilder: (context, animation, secondaryAnimation, child) =>
        child,
  );
}

bool _developerPath(String path) {
  const roots = [
    '/home',
    '/projects',
    '/requests',
    '/budget',
    '/inspections',
    '/documents',
    '/people',
    '/queue',
    '/moderation',
    '/applications',
  ];
  for (final root in roots) {
    if (path == root || path.startsWith('$root/')) return true;
  }
  return false;
}

bool _adminPath(String path) {
  const roots = ['/admin', '/applications', '/moderation'];
  for (final root in roots) {
    if (path == root || path.startsWith('$root/')) return true;
  }
  return false;
}

GoRouter buildRouter(SessionController session) {
  return GoRouter(
    initialLocation: '/login',
    refreshListenable: session,
    redirect: (context, state) {
      final path = state.uri.path;
      // Sign-up pages are open to everyone and must survive a page reload,
      // because the status link in the applicant's hands points straight at one.
      final signUp = path == '/register' || path.startsWith('/register/');
      if (!session.ready) return path == '/boot' || signUp ? null : '/boot';
      final signedIn = session.user != null;
      if (!signedIn) {
        return path == '/login' || signUp ? null : '/login';
      }
      final bank = session.user!.isBank;
      final admin = session.user!.platformAdmin && !bank;
      if (session.user!.mustChangePassword) return path == '/password' ? null : '/password';
      if (path == '/login' || path == '/boot') {
        return bank ? '/bank/queue' : (admin ? '/admin' : '/home');
      }
      if (path == '/password') return null;
      if (bank && _developerPath(path)) return '/bank/queue';
      if (!bank && path.startsWith('/bank')) return admin ? '/admin' : '/home';
      // The administrator of the platform has a workspace of its own.
      if (admin && !_adminPath(path)) return '/admin';
      if (!admin && (path == '/admin' || path.startsWith('/admin/'))) return bank ? '/bank/queue' : '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/boot',
        pageBuilder: (context, state) => _instant(state, const BootScreen()),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => _instant(state, const LoginScreen()),
      ),
      GoRoute(
        path: '/password',
        pageBuilder: (context, state) => _instant(state, const PasswordScreen()),
      ),
      GoRoute(
        path: '/register',
        pageBuilder: (context, state) => _instant(
          state,
          RegisterScreen(kind: state.uri.queryParameters['kind']),
        ),
        routes: [
          GoRoute(
            path: 'status',
            pageBuilder: (context, state) => _instant(
              state,
              RegisterStatusScreen(token: state.uri.queryParameters['t'] ?? ''),
            ),
          ),
        ],
      ),
      ShellRoute(
        pageBuilder: (context, state, child) => _instant(
          state,
          AdaptiveShell(child: child),
          key: const ValueKey('shell'),
        ),
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) =>
                _instant(state, const DashboardScreen()),
          ),
          GoRoute(
            path: '/inspections',
            pageBuilder: (context, state) =>
                _instant(state, const InspectionsScreen()),
          ),
          GoRoute(
            path: '/queue',
            pageBuilder: (context, state) =>
                _instant(state, const QueueScreen()),
          ),
          GoRoute(
            path: '/moderation',
            pageBuilder: (context, state) =>
                _instant(state, const ModerationScreen()),
          ),
          GoRoute(
            path: '/applications',
            pageBuilder: (context, state) => _instant(state, const ApplicationsScreen()),
          ),
          GoRoute(
            path: '/applications/:id',
            pageBuilder: (context, state) => _instant(
              state,
              ApplicationScreen(id: state.pathParameters['id']!),
            ),
          ),
          GoRoute(
            path: '/budget',
            pageBuilder: (context, state) => _instant(state, const BudgetPage()),
          ),
          GoRoute(
            path: '/documents',
            pageBuilder: (context, state) => _instant(state, const DocumentsPage()),
          ),
          GoRoute(
            path: '/people',
            pageBuilder: (context, state) => _instant(state, const PeoplePage()),
          ),
          GoRoute(
            path: '/projects',
            pageBuilder: (context, state) =>
                _instant(state, const ProjectsScreen()),
          ),
          GoRoute(
            path: '/projects/:id',
            pageBuilder: (context, state) {
              final extra = state.extra;
              return _instant(
                state,
                ProjectScreen(
                  id: state.pathParameters['id']!,
                  initial: extra is ProjectReady ? extra : null,
                ),
              );
            },
          ),
          GoRoute(
            path: '/projects/:id/draw',
            pageBuilder: (context, state) => _instant(
              state,
              DrawWizardScreen(
                projectId: state.pathParameters['id']!,
                drawId: state.uri.queryParameters['id'],
              ),
            ),
          ),
          GoRoute(
            path: '/requests',
            pageBuilder: (context, state) => _instant(
              state,
              RequestsScreen(projectId: state.uri.queryParameters['project']),
            ),
          ),
          GoRoute(
            path: '/requests/new',
            pageBuilder: (context, state) {
              final extra = state.extra;
              return _instant(
                state,
                RequestFormScreen(
                  initial: extra is RequestFormData ? extra : null,
                ),
              );
            },
          ),
          GoRoute(
            path: '/requests/:id',
            pageBuilder: (context, state) => _instant(
              state,
              RequestScreen(
                id: state.pathParameters['id']!,
                initial: state.extra,
              ),
            ),
          ),
          GoRoute(
            path: '/admin',
            pageBuilder: (context, state) => _instant(state, const AdminOverviewScreen()),
          ),
          GoRoute(
            path: '/admin/companies',
            pageBuilder: (context, state) => _instant(state, const AdminCompaniesScreen()),
          ),
          GoRoute(
            path: '/admin/users',
            pageBuilder: (context, state) => _instant(
              state,
              AdminUsersScreen(
                key: ValueKey('users-${state.uri.queryParameters['company'] ?? ''}'),
                company: state.uri.queryParameters['company'] ?? '',
              ),
            ),
          ),
          GoRoute(
            path: '/admin/events',
            pageBuilder: (context, state) => _instant(state, const AdminEventsScreen()),
          ),
          GoRoute(
            path: '/admin/mail',
            pageBuilder: (context, state) => _instant(state, const AdminMailScreen()),
          ),
          GoRoute(
            path: '/admin/system',
            pageBuilder: (context, state) => _instant(state, const AdminSystemScreen()),
          ),
          GoRoute(
            path: '/bank/journal',
            pageBuilder: (context, state) => _instant(state, const BankAuditScreen()),
          ),
          GoRoute(
            path: '/bank/queue',
            pageBuilder: (context, state) => _instant(state, const BankQueueScreen()),
          ),
          GoRoute(
            path: '/bank/portfolio',
            pageBuilder: (context, state) => _instant(state, const BankPortfolioScreen()),
          ),
          GoRoute(
            path: '/bank/objects',
            pageBuilder: (context, state) => _instant(state, const BankObjectsScreen()),
          ),
          GoRoute(
            path: '/bank/objects/:id',
            pageBuilder: (context, state) => _instant(
              state,
              BankObjectScreen(id: state.pathParameters['id']!),
            ),
          ),
          GoRoute(
            path: '/bank/inspections',
            pageBuilder: (context, state) => _instant(state, const BankInspectionsScreen()),
          ),
          GoRoute(
            path: '/bank/developers',
            pageBuilder: (context, state) => _instant(state, const BankDevelopersScreen()),
          ),
          GoRoute(
            path: '/bank/developers/:id',
            pageBuilder: (context, state) => _instant(
              state,
              BankDeveloperScreen(id: state.pathParameters['id']!),
            ),
          ),
          GoRoute(
            path: '/bank/reports',
            pageBuilder: (context, state) => _instant(state, const BankReportsScreen()),
          ),
          GoRoute(
            path: '/bank/reports/:code',
            pageBuilder: (context, state) => _instant(
              state,
              BankReportScreen(code: state.pathParameters['code']!),
            ),
          ),
          GoRoute(
            path: '/bank/rules',
            pageBuilder: (context, state) => _instant(state, const BankRulesScreen()),
          ),
          GoRoute(
            path: '/bank/tranches/:id',
            pageBuilder: (context, state) => _instant(
              state,
              BankTrancheScreen(id: state.pathParameters['id']!),
            ),
          ),
          GoRoute(
            path: '/bank/tranches/:id/approval',
            pageBuilder: (context, state) => _instant(
              state,
              BankApprovalScreen(id: state.pathParameters['id']!),
            ),
          ),
        ],
      ),
    ],
  );
}

class BootScreen extends StatelessWidget {
  const BootScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [const BrandLockup(size: 72)],
        ),
      ),
      backgroundColor: colors.background,
    );
  }
}
