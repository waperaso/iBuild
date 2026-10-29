import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'api.dart';
import 'brand.dart';
import 'file_pick.dart';
import 'fx.dart';
import 'l10n.dart';
import 'models.dart';
import 'money.dart';
import 'screens/bank/bank_sections.dart';
import 'screens/bank/bank_ui.dart';
import 'object_passport.dart';
import 'screens/kit.dart' show Tx;
import 'session_scope.dart';
import 'theme.dart';
import 'widgets.dart';

class AdaptiveShell extends StatelessWidget {
  const AdaptiveShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < kPhoneBreakpoint) {
      return _PhoneShell(child: child);
    }
    return _DeskShell(tablet: width < kTabletBreakpoint, child: child);
  }
}

class _DeskShell extends StatefulWidget {
  const _DeskShell({required this.tablet, required this.child});

  final bool tablet;
  final Widget child;

  @override
  State<_DeskShell> createState() => _DeskShellState();
}

class _DeskShellState extends State<_DeskShell> {
  var _collapsed = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tablet = widget.tablet;
    final collapsed = tablet || _collapsed;
    return Scaffold(
      body: Row(
        children: [
          SizedBox(
            key: const Key('side-nav'),
            width: collapsed ? 84 : 300,
            child: ColoredBox(
              color: colors.heroSurface,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _BrandBlock(
                    onDark: true,
                    markOnly: collapsed,
                    trailing: tablet
                        ? null
                        : IconButton(
                            key: const Key('collapse-nav'),
                            tooltip: collapsed
                                ? LocaleScope.copy(context).expandMenu
                                : LocaleScope.copy(context).collapseMenu,
                            onPressed: () => setState(() => _collapsed = !_collapsed),
                            icon: Icon(
                              collapsed ? Icons.chevron_right : Icons.chevron_left,
                              color: colors.onHeroSurface,
                            ),
                          ),
                  ),
                  _NavList(compact: false, onDark: true, iconsOnly: collapsed),
                  const Spacer(),
                  if (!collapsed) const _SecurityNote(onDark: true),
                  if (!collapsed)
                    const Padding(
                      padding: EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        0,
                        AppSpacing.lg,
                        AppSpacing.sm,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _ThemeButton(onDark: true),
                          LanguageSwitch(onDark: true),
                        ],
                      ),
                    )
                  else
                    const _ThemeButton(onDark: true),
                  _AccountBlock(onDark: true, iconsOnly: collapsed),
                ],
              ),
            ),
          ),
          VerticalDivider(width: 1, color: colors.outline),
          Expanded(
            child: Column(
              children: [
                if (tablet) const _IdentityStrip(),
                _TopBar(showLanguage: collapsed && !tablet),
                Expanded(
                  child: ClipRect(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth > 1100
                            ? 1100.0
                            : constraints.maxWidth;
                        return Align(
                          alignment: Alignment.topCenter,
                          child: SizedBox(
                            width: width,
                            height: constraints.maxHeight,
                            child: widget.child,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (!tablet &&
              SessionScope.of(context).user?.isBank != true &&
              SessionScope.of(context).user?.platformAdmin != true &&
              MediaQuery.sizeOf(context).width >= kTabletBreakpoint) ...[
            VerticalDivider(width: 1, color: colors.outline),
            const SizedBox(width: 300, child: _ProjectRail()),
          ],
        ],
      ),
    );
  }
}

class _PhoneShell extends StatelessWidget {
  const _PhoneShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const _PhoneBar(),
            const _TopBar(compact: true),
            Expanded(child: child),
            const _NavList(compact: true),
          ],
        ),
      ),
    );
  }
}

class _BrandBlock extends StatelessWidget {
  const _BrandBlock({this.onDark = false, this.markOnly = false, this.trailing});

  final bool onDark;
  final bool markOnly;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final bank = SessionScope.of(context).user?.isBank == true;
    final admin = !bank && SessionScope.of(context).user?.platformAdmin == true;
    final mark = markOnly
        ? const BrandMark(size: 36, onDark: true)
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BrandLockup(onDark: onDark),
              if (bank || admin)
                Padding(
                  padding: const EdgeInsets.only(left: 52),
                  child: Text(
                    admin ? Tx.of(context)('Панель администратора', 'Admin panel', 'Administrator paneli') : LocaleScope.copy(context).bankCabinet,
                    key: const Key('bank-cabinet-label'),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.colors.onHeroSurface,
                    ),
                  ),
                ),
            ],
          );
    return Padding(
      padding: EdgeInsets.fromLTRB(
        markOnly ? AppSpacing.sm : AppSpacing.lg,
        AppSpacing.lg,
        markOnly ? 0 : AppSpacing.sm,
        AppSpacing.md,
      ),
      child: markOnly
          ? Column(
              children: [
                mark,
                ?trailing,
              ],
            )
          : Row(
              children: [
                Expanded(child: mark),
                ?trailing,
              ],
            ),
    );
  }
}

class _PhoneBar extends StatelessWidget {
  const _PhoneBar();

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);
    final user = session.user;
    final copy = LocaleScope.copy(context);
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          const BrandMark(size: 36),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.name ?? 'iBuild',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  user == null
                      ? copy.tagline
                      : '${copy.rolesOf(user)} · ${user.companyName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: colors.inkMuted),
                ),
              ],
            ),
          ),
          const _ThemeButton(),
          const LanguageSwitch(),
          IconButton(
            key: const Key('password-button'),
            tooltip: copy.pick('Сменить пароль', 'Change password', 'Parolni almashtirish'),
            onPressed: () => context.go('/password'),
            icon: const Icon(Icons.key_outlined),
          ),
          IconButton(
            key: const Key('logout-button'),
            tooltip: copy.signOut,
            onPressed: session.logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
    );
  }
}

class _NavList extends StatelessWidget {
  const _NavList({required this.compact, this.onDark = false, this.iconsOnly = false});

  final bool compact;
  final bool onDark;
  final bool iconsOnly;

  @override
  Widget build(BuildContext context) {
    final uri = GoRouterState.of(context).uri;
    final copy = LocaleScope.copy(context);
    final bank = SessionScope.of(context).user?.bank;
    if (bank != null) {
      final items = _bankNav(context, uri, copy, bank.queueCount, bank.role);
      return _navBody(context, items, compact: compact, onDark: onDark, iconsOnly: iconsOnly);
    }
    if (SessionScope.of(context).user?.platformAdmin == true) {
      return _navBody(context, _adminNav(context, uri, copy), compact: compact, onDark: onDark, iconsOnly: iconsOnly);
    }
    final items = [
      _NavSpec(
        key: const Key('nav-home'),
        label: copy.home,
        icon: Icons.space_dashboard_outlined,
        location: '/home',
        selected: uri.path == '/home',
      ),
      _NavSpec(
        key: const Key('nav-projects'),
        label: copy.projects,
        icon: Icons.apartment_outlined,
        location: '/projects',
        selected: uri.path == '/projects',
      ),
      _NavSpec(
        key: const Key('nav-requests'),
        label: copy.requests,
        icon: Icons.receipt_long_outlined,
        location: '/requests',
        selected: uri.path.startsWith('/requests'),
      ),
      _NavSpec(
        key: const Key('nav-budget'),
        label: copy.budget,
        icon: Icons.account_balance_outlined,
        location: '/budget',
        selected: uri.path == '/budget',
      ),
      _NavSpec(
        key: const Key('nav-inspections'),
        label: copy.inspections,
        icon: Icons.fact_check_outlined,
        location: '/inspections',
        selected: uri.path == '/inspections',
      ),
      _NavSpec(
        key: const Key('nav-documents'),
        label: copy.documents,
        icon: Icons.folder_outlined,
        location: '/documents',
        selected: uri.path == '/documents',
      ),
      _NavSpec(
        key: const Key('nav-people'),
        label: copy.people,
        icon: Icons.groups_outlined,
        location: '/people',
        selected: uri.path == '/people',
      ),
      _NavSpec(
        key: const Key('nav-queue'),
        label: copy.queue,
        icon: Icons.inbox_outlined,
        location: '/queue',
        selected: uri.path == '/queue',
      ),
    ];
    return _navBody(context, items, compact: compact, onDark: onDark, iconsOnly: iconsOnly);
  }

  List<_NavSpec> _adminNav(BuildContext context, Uri uri, AppCopy copy) {
    final t = Tx.of(context);
    final path = uri.path;
    return [
      _NavSpec(
        key: const Key('nav-admin-overview'),
        label: t('Обзор', 'Overview', 'Sharh'),
        icon: Icons.space_dashboard_outlined,
        location: '/admin',
        selected: path == '/admin',
      ),
      _NavSpec(
        key: const Key('nav-applications'),
        label: copy.applications,
        icon: Icons.how_to_reg_outlined,
        location: '/applications',
        selected: path == '/applications' || path.startsWith('/applications/'),
      ),
      _NavSpec(
        key: const Key('nav-moderation'),
        label: copy.moderation,
        icon: Icons.verified_user_outlined,
        location: '/moderation',
        selected: path == '/moderation',
      ),
      _NavSpec(
        key: const Key('nav-admin-companies'),
        label: t('Компании и банки', 'Companies and banks', 'Kompaniyalar va banklar'),
        icon: Icons.apartment_outlined,
        location: '/admin/companies',
        selected: path == '/admin/companies',
      ),
      _NavSpec(
        key: const Key('nav-admin-users'),
        label: t('Пользователи', 'Users', 'Foydalanuvchilar'),
        icon: Icons.groups_outlined,
        location: '/admin/users',
        selected: path == '/admin/users',
      ),
      _NavSpec(
        key: const Key('nav-admin-events'),
        label: t('Журнал', 'Journal', 'Jurnal'),
        icon: Icons.history,
        location: '/admin/events',
        selected: path == '/admin/events',
      ),
      _NavSpec(
        key: const Key('nav-admin-mail'),
        label: t('Почта', 'Mail', 'Pochta'),
        icon: Icons.mail_outline,
        location: '/admin/mail',
        selected: path == '/admin/mail',
      ),
      _NavSpec(
        key: const Key('nav-admin-system'),
        label: t('Система', 'System', 'Tizim'),
        icon: Icons.monitor_heart_outlined,
        location: '/admin/system',
        selected: path == '/admin/system',
      ),
    ];
  }

  List<_NavSpec> _bankNav(BuildContext context, Uri uri, AppCopy copy, int queueCount, String role) {
    final path = uri.path;
    return [
      _NavSpec(
        key: const Key('nav-bank-queue'),
        label: copy.queue,
        icon: Icons.inbox_outlined,
        location: '/bank/queue',
        selected: path.startsWith('/bank/queue') || path.startsWith('/bank/tranches'),
        badge: queueCount > 0 ? '$queueCount' : null,
      ),
      _NavSpec(
        key: const Key('nav-bank-portfolio'),
        label: copy.bankPortfolio,
        icon: Icons.pie_chart_outline,
        location: '/bank/portfolio',
        selected: path == '/bank/portfolio',
      ),
      _NavSpec(
        key: const Key('nav-bank-objects'),
        label: copy.projects,
        icon: Icons.apartment_outlined,
        location: '/bank/objects',
        selected: path.startsWith('/bank/objects'),
      ),
      _NavSpec(
        key: const Key('nav-bank-inspections'),
        label: copy.bankInspections,
        icon: Icons.fact_check_outlined,
        location: '/bank/inspections',
        selected: path == '/bank/inspections',
      ),
      _NavSpec(
        key: const Key('nav-bank-developers'),
        label: copy.bankDevelopers,
        icon: Icons.domain_outlined,
        location: '/bank/developers',
        selected: path.startsWith('/bank/developers'),
      ),
      _NavSpec(
        key: const Key('nav-bank-reports'),
        label: copy.bankReports,
        icon: Icons.assessment_outlined,
        location: '/bank/reports',
        selected: path.startsWith('/bank/reports'),
      ),
      if (role == 'admin')
        _NavSpec(
          key: const Key('nav-bank-rules'),
          label: copy.bankRules,
          icon: Icons.account_tree_outlined,
          location: '/bank/rules',
          selected: path == '/bank/rules',
        ),
      if (const {'admin', 'audit', 'risk', 'head'}.contains(role))
        _NavSpec(
          key: const Key('nav-bank-journal'),
          label: Tx.of(context)('Журнал', 'Journal', 'Jurnal'),
          icon: Icons.history,
          location: '/bank/journal',
          selected: path == '/bank/journal',
        ),
    ];
  }

  Widget _navBody(
    BuildContext context,
    List<_NavSpec> items, {
    required bool compact,
    required bool onDark,
    required bool iconsOnly,
  }) {
    if (!compact) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
        child: Column(
          children: [
            for (final item in items) ...[
              _NavButton(spec: item, onDark: onDark, iconsOnly: iconsOnly),
              const SizedBox(height: AppSpacing.xs),
            ],
          ],
        ),
      );
    }
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: DecoratedBox(
        key: const Key('bottom-nav'),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppRadii.pill),
          border: Border.all(color: colors.outline.withValues(alpha: 0.7)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Row(
            children: [
              for (final item in items)
                Expanded(child: _NavButton(spec: item, pill: true)),
            ],
          ),
        ),
      ),
    );
  }
}

String _shown(BuildContext context, Object? value) {
  final fx = FxScope.maybeOf(context);
  return moneyPreview(value, usdPerSom: fx != null && fx.usd ? fx.rate : null);
}

class _TopBar extends StatelessWidget {
  const _TopBar({this.compact = false, this.showLanguage = false});

  final bool compact;
  final bool showLanguage;

  @override
  Widget build(BuildContext context) {
    final bank = SessionScope.of(context).user?.bank;
    if (bank != null) return _bankBar(context, bank);
    // The platform administrator has no project: no currency or object strip.
    if (SessionScope.of(context).user?.platformAdmin == true) {
      if (!showLanguage) return const SizedBox.shrink();
      return Material(
        key: const Key('admin-topbar'),
        color: context.colors.surface,
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          child: Align(alignment: Alignment.centerRight, child: LanguageSwitch()),
        ),
      );
    }
    final project = SessionScope.of(context).focusedProject;
    final copy = LocaleScope.copy(context);
    final colors = context.colors;
    return Material(
      key: const Key('project-topbar'),
      color: colors.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        child: Row(
          children: [
            const _CurrencySwitch(),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: project == null
            ? Text(
                LocaleScope.copy(context).pickProject,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.inkMuted),
              )
            : LayoutBuilder(
                builder: (context, constraints) {
                  final showAll = !compact && constraints.maxWidth >= 860;
                  return Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              copy.place(project.name),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              project.address,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: colors.inkMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (showAll) ...[
                        _BarMoney(label: copy.plan, value: project.plan),
                        _BarMoney(label: copy.reserved, value: project.reserved),
                        _BarMoney(label: copy.paid, value: project.paid),
                      ],
                      _BarMoney(label: copy.available, value: project.available),
                    ],
                  );
                },
              ),
            ),
            if (showLanguage) ...[
              const SizedBox(width: AppSpacing.sm),
              const LanguageSwitch(),
            ],
          ],
        ),
      ),
    );
  }
}

class _IdentityStrip extends StatelessWidget {
  const _IdentityStrip();

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);
    final user = session.user;
    final copy = LocaleScope.copy(context);
    final colors = context.colors;
    final bank = user?.bank;
    return Material(
      color: colors.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.sm,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?.name ?? 'iBuild',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    user == null
                        ? copy.tagline
                        : bank == null
                            ? '${copy.rolesOf(user)} · ${user.companyName}'
                            : '${bank.title} · ${bank.name}',
                    key: bank == null ? null : const Key('bank-account-role'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.inkMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            const LanguageSwitch(),
          ],
        ),
      ),
    );
  }
}

Widget _bankBar(BuildContext context, BankProfile bank) {
  final copy = LocaleScope.copy(context);
  final colors = context.colors;
  final path = GoRouterState.of(context).uri.path;
  final onQueue = path == '/bank/queue';
  final title = switch (path) {
    '/bank/portfolio' => copy.bankPortfolio,
    '/bank/inspections' => copy.bankInspections,
    '/bank/rules' => copy.bankRules,
    _ when path.startsWith('/bank/objects') => copy.projects,
    _ when path.startsWith('/bank/developers') => copy.bankDevelopers,
    _ when path.startsWith('/bank/reports') => copy.bankReports,
    _ => copy.queue,
  };
  final summary = bankQueueSummary(
    copy,
    bank.trancheCount,
    bankAmount(context, bank.waitingAmount),
    bankUnit(context),
  );
  final narrow = MediaQuery.sizeOf(context).width < kPhoneBreakpoint;
  final heading = Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: Theme.of(context).textTheme.titleMedium),
      Text(
        '${bank.name} · ${bank.department}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.inkMuted),
      ),
    ],
  );
  final waiting = Column(
    crossAxisAlignment: narrow ? CrossAxisAlignment.start : CrossAxisAlignment.end,
    children: [
      Text(
        copy.bankWaiting,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.inkMuted),
      ),
      Text(summary, key: const Key('bank-queue-summary')),
    ],
  );
  return Material(
    key: const Key('bank-topbar'),
    color: colors.surface,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: narrow
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const _CurrencySwitch(),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(child: heading),
                  ],
                ),
                if (onQueue) ...[
                  const SizedBox(height: AppSpacing.md),
                  waiting,
                ],
              ],
            )
          : Row(
              children: [
                const _CurrencySwitch(),
                const SizedBox(width: AppSpacing.lg),
                Expanded(child: heading),
                if (onQueue) waiting,
              ],
            ),
    ),
  );
}

class _CurrencySwitch extends StatelessWidget {
  const _CurrencySwitch();

  @override
  Widget build(BuildContext context) {
    final fx = FxScope.maybeOf(context);
    final usd = fx?.usd ?? false;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SegmentedButton<bool>(
          key: const Key('currency-switch'),
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: false, label: Text('UZS')),
            ButtonSegment(value: true, label: Text('USD')),
          ],
          selected: {usd},
          onSelectionChanged: fx == null
              ? null
              : (value) {
                  fx.useUsd(SessionScope.of(context).api, value.first);
                },
        ),
        if (usd && (fx?.date ?? '').isNotEmpty)
          Text(
            LocaleScope.copy(context).fxDate(fx?.date ?? ''),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.colors.inkMuted),
          ),
      ],
    );
  }
}

class _BarMoney extends StatelessWidget {
  const _BarMoney({required this.label, required this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.colors.inkMuted),
          ),
          Text(_shown(context, value), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _ProjectRail extends StatelessWidget {
  const _ProjectRail();

  @override
  Widget build(BuildContext context) {
    final project = SessionScope.of(context).focusedProject;
    final colors = context.colors;
    return ColoredBox(
      key: const Key('project-rail'),
      color: colors.background,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Text(LocaleScope.copy(context).project, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.lg),
          if (project == null)
            Text(
              LocaleScope.copy(context).pickProject,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.inkMuted),
            )
          else
            _PinnedObject(key: ValueKey(project.id), project: project),
          ],
        ),
      ),
    );
  }
}

class _PinnedObject extends StatefulWidget {
  const _PinnedObject({super.key, required this.project});

  final ProjectSummary project;

  @override
  State<_PinnedObject> createState() => _PinnedObjectState();
}

class _PinnedObjectState extends State<_PinnedObject> {
  late ProjectSummary _project = widget.project;
  ProjectChange? _pending;
  ProjectChange? _rejected;
  Uint8List? _photo;
  String? _error;
  var _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _load();
  }

  @override
  void didUpdateWidget(covariant _PinnedObject oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.project.id != widget.project.id) {
      _project = widget.project;
      _pending = null;
      _rejected = null;
      _photo = null;
      _started = true;
      _load();
    }
  }

  Future<void> _load() async {
    final api = SessionScope.of(context).api;
    try {
      final fresh = await api.project(_project.id);
      final changes = await api.projectChanges(_project.id);
      final photo = fresh.hasPhoto ? await api.projectPhoto(fresh.id) : null;
      if (!mounted) return;
      SessionScope.of(context).rememberProject(fresh);
      ProjectChange? pending;
      ProjectChange? rejected;
      for (final item in changes) {
        if (item.pending) {
          pending = item;
          break;
        }
        if (rejected == null && item.status == 'rejected') rejected = item;
      }
      setState(() {
        _project = fresh;
        _pending = pending;
        _rejected = pending == null ? rejected : null;
        _photo = photo;
        _error = null;
      });
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    }
  }

  Future<void> _edit() async {
    final result = await showPlainDialog<_ObjectDraft>(
      context: context,
      builder: (context) => _EditObjectDialog(project: _project),
    );
    if (result == null || !mounted) return;
    try {
      await SessionScope.of(context).api.proposeProjectChange(
        projectId: _project.id,
        name: result.name,
        address: result.address,
        photo: result.photo,
      );
      await _load();
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final copy = LocaleScope.copy(context);
    final director = _project.myRole == AppRole.director;
    return IBuildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_photo != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadii.input),
              child: Image.memory(_photo!, height: 96, width: double.infinity, fit: BoxFit.cover),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          Text(copy.place(_project.name), style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          Text(_project.address),
          ObjectPassport(project: _project, compact: true),
          const SizedBox(height: AppSpacing.md),
          Text(copy.roleName(_project.myRole)),
          const SizedBox(height: AppSpacing.sm),
          StatusText(
            label: copy.projectStatus(_project.active),
            tone: _project.active ? StatusTone.good : StatusTone.neutral,
          ),
          if (_pending != null) ...[
            const SizedBox(height: AppSpacing.md),
            StatusText(label: copy.changesOnReview, tone: StatusTone.wait),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _pending!.name,
              key: const Key('pending-object'),
            ),
            Text(_pending!.address),
          ],
          if (_rejected != null) ...[
            const SizedBox(height: AppSpacing.md),
            StatusText(label: copy.changesRejected, tone: StatusTone.bad),
            if (_rejected!.reviewNote.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(_rejected!.reviewNote),
            ],
          ],
          const SizedBox(height: AppSpacing.lg),
          _RailMoney(label: copy.plan, value: _project.plan),
          _RailMoney(label: copy.reserved, value: _project.reserved),
          _RailMoney(label: copy.paid, value: _project.paid),
          _RailMoney(label: copy.available, value: _project.available),
          if (director) ...[
            const SizedBox(height: AppSpacing.md),
            TextButton(
              key: const Key('edit-object'),
              onPressed: _edit,
              child: Text(copy.edit),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(copy.known(_error!)),
          ],
        ],
      ),
    );
  }
}

class _ObjectDraft {
  const _ObjectDraft(this.name, this.address, this.photo);

  final String name;
  final String address;
  final Uint8List? photo;
}

class _EditObjectDialog extends StatefulWidget {
  const _EditObjectDialog({required this.project});

  final ProjectSummary project;

  @override
  State<_EditObjectDialog> createState() => _EditObjectDialogState();
}

class _EditObjectDialogState extends State<_EditObjectDialog> {
  late final TextEditingController _name = TextEditingController(text: widget.project.name);
  late final TextEditingController _address = TextEditingController(text: widget.project.address);
  Uint8List? _photo;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final copy = LocaleScope.copy(context);
    return AlertDialog(
      title: Text(copy.projectCard),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            key: const Key('object-name'),
            controller: _name,
            decoration: InputDecoration(labelText: copy.name),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            key: const Key('object-address'),
            controller: _address,
            decoration: InputDecoration(labelText: copy.address),
          ),
          const SizedBox(height: AppSpacing.md),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              key: const Key('object-photo'),
              onPressed: () async {
                final file = await pickRequestFile();
                if (file == null || !mounted) return;
                final lower = file.name.toLowerCase();
                if (lower.endsWith('.pdf') || file.bytes.length > 5 * 1024 * 1024) {
                  setState(() => _error = copy.projectPhotoRule);
                  return;
                }
                setState(() {
                  _photo = file.bytes;
                  _error = null;
                });
              },
              child: Text(_photo == null ? copy.projectPhoto : copy.photoPicked),
            ),
          ),
          if (_error != null) Text(_error!),
          const SizedBox(height: AppSpacing.md),
          Text(
            copy.projectCardNote,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.colors.inkMuted),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(copy.cancel)),
        PrimaryButton(
          label: copy.sendForReview,
          onPressed: () {
            final name = _name.text.trim();
            final address = _address.text.trim();
            if (name.isEmpty || address.isEmpty) {
              setState(() => _error = copy.needNameAddress);
              return;
            }
            Navigator.pop(context, _ObjectDraft(name, address, _photo));
          },
        ),
      ],
    );
  }
}

class _RailMoney extends StatelessWidget {
  const _RailMoney({required this.label, required this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.colors.inkMuted),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(_shown(context, value)),
        ],
      ),
    );
  }
}

class _NavSpec {
  const _NavSpec({
    required this.key,
    required this.label,
    required this.icon,
    required this.location,
    required this.selected,
    this.badge,
  });

  final Key key;
  final String label;
  final IconData icon;
  final String location;
  final bool selected;
  final String? badge;
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.spec,
    this.pill = false,
    this.onDark = false,
    this.iconsOnly = false,
  });

  final _NavSpec spec;
  final bool pill;
  final bool onDark;
  final bool iconsOnly;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final selected = spec.selected;
    final background = selected
        ? (onDark ? colors.onHeroSurface : colors.accent)
        : Colors.transparent;
    final foreground = selected
        ? (onDark ? colors.accent : colors.onAccent)
        : (onDark ? colors.onHeroSurface : colors.ink);
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(pill ? AppRadii.pill : 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: spec.key,
        onTap: () => context.go(spec.location),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: pill || iconsOnly ? AppSpacing.sm : AppSpacing.lg,
            vertical: pill ? AppSpacing.sm : 12,
          ),
          child: pill || iconsOnly
              ? Tooltip(
                  message: spec.label,
                  child: spec.badge == null
                      ? Icon(spec.icon, size: 22, color: foreground)
                      : Badge(
                          key: const Key('bank-queue-badge'),
                          label: Text(spec.badge!),
                          child: Icon(spec.icon, size: 22, color: foreground),
                        ),
                )
              : Row(
                  children: [
                    Icon(spec.icon, size: 22, color: foreground),
                    const SizedBox(width: AppSpacing.md),
                    Flexible(
                      child: Text(
                        spec.label,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: foreground,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    if (spec.badge != null) ...[
                      const SizedBox(width: AppSpacing.sm),
                      DecoratedBox(
                        key: const Key('bank-queue-badge'),
                        decoration: BoxDecoration(
                          color: colors.accent,
                          borderRadius: BorderRadius.circular(AppRadii.pill),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          child: Text(
                            spec.badge!,
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: colors.onAccent,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}

class _AccountBlock extends StatelessWidget {
  const _AccountBlock({this.onDark = false, this.iconsOnly = false});

  final bool onDark;
  final bool iconsOnly;

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);
    final user = session.user;
    final copy = LocaleScope.copy(context);
    final colors = context.colors;
    if (user == null) return const SizedBox.shrink();
    if (iconsOnly) {
      return IconButton(
        key: const Key('logout-button'),
        tooltip: copy.signOut,
        onPressed: session.logout,
        icon: Icon(Icons.logout, color: onDark ? colors.onHeroSurface : colors.ink),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: onDark ? colors.onAccent : colors.ink,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  user.bank == null
                      ? '${copy.rolesOf(user)} · ${user.companyName}'
                      : '${user.bank!.title} · ${user.bank!.name}',
                  key: user.bank == null ? null : const Key('bank-account-role'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: onDark ? colors.onHeroSurface : colors.inkMuted,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            key: const Key('password-button'),
            tooltip: copy.pick('Сменить пароль', 'Change password', 'Parolni almashtirish'),
            onPressed: () => context.go('/password'),
            icon: Icon(Icons.key_outlined, color: onDark ? colors.onHeroSurface : colors.ink),
          ),
          IconButton(
            key: const Key('logout-button'),
            tooltip: copy.signOut,
            onPressed: session.logout,
            icon: Icon(
              Icons.logout,
              color: onDark ? colors.onHeroSurface : colors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _SecurityNote extends StatelessWidget {
  const _SecurityNote({this.onDark = false});

  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      key: const Key('security-note'),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Text(
        LocaleScope.copy(context).tagline,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: onDark ? colors.onHeroSurface : colors.inkMuted,
        ),
      ),
    );
  }
}

class _ThemeButton extends StatelessWidget {
  const _ThemeButton({this.onDark = false});

  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    final colors = context.colors;
    return IconButton(
      key: const Key('theme-switch'),
      tooltip: theme.dark ? LocaleScope.copy(context).lightTheme : LocaleScope.copy(context).darkTheme,
      onPressed: theme.toggle,
      icon: Icon(
        theme.dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
        color: onDark ? colors.onHeroSurface : colors.ink,
      ),
    );
  }
}
