import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ibuild_core/ibuild_core.dart';

import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_theme_ext.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/shell_tab_scope.dart';
import '../../../l10n/enum_labels.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../providers/leads_providers.dart';

/// "My inquiries": Active / Completed / Cancelled tabs over the client's leads.
class LeadsScreen extends ConsumerWidget {
  const LeadsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    final tabIndex = ShellTabScope.maybeOf(context);
    // Indexed stack keeps this tab mounted — don't hit /leads until opened.
    if (tabIndex != null && tabIndex != ShellTabScope.inquiriesTabIndex) {
      return ColoredBox(color: colors.background);
    }

    final leadsAsync = ref.watch(leadsProvider);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(
          title: Text(l10n.myInquiriesTitle),
          bottom: TabBar(
            tabs: [
              Tab(text: l10n.tabActive),
              Tab(text: l10n.tabCompleted),
              Tab(text: l10n.tabCancelled),
            ],
          ),
        ),
        body: AsyncValueView(
          value: leadsAsync,
          minHeight: 400,
          onRetry: () => ref.invalidate(leadsProvider),
          builder: (context, leads) {
            final active = leads.where((l) => l.status.isActive).toList();
            final completed = leads
                .where(
                  (l) =>
                      l.status == LeadStatus.won ||
                      l.status == LeadStatus.visited,
                )
                .toList();
            final cancelled = leads
                .where((l) => l.status == LeadStatus.lost)
                .toList();
            Future<void> refresh() async => ref.invalidate(leadsProvider);
            return TabBarView(
              children: [
                RefreshIndicator(
                  onRefresh: refresh,
                  child: _LeadList(leads: active),
                ),
                RefreshIndicator(
                  onRefresh: refresh,
                  child: _LeadList(leads: completed),
                ),
                RefreshIndicator(
                  onRefresh: refresh,
                  child: _LeadList(leads: cancelled),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _LeadList extends StatelessWidget {
  const _LeadList({required this.leads});

  final List<Lead> leads;

  @override
  Widget build(BuildContext context) {
    if (leads.isEmpty) {
      final l10n = AppLocalizations.of(context);
      // Always scrollable (even though there's nothing to scroll) so
      // RefreshIndicator's drag gesture is recognized in the empty state too.
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: 400,
            child: Center(
              child: EmptyState(
                icon: Icons.assignment_outlined,
                title: l10n.nothingHereYet,
                subtitle: l10n.inquiriesEmptySubtitle,
                actionLabel: l10n.browseListingsAction,
                onAction: () => context.go('/home'),
              ),
            ),
          ),
        ],
      );
    }
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: leads.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) => _LeadCard(lead: leads[index]),
    );
  }
}

class _LeadCard extends StatelessWidget {
  const _LeadCard({required this.lead});

  final Lead lead;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(lead.projectName, style: textTheme.titleMedium),
              ),
              Text(
                lead.number,
                style: textTheme.labelMedium?.copyWith(color: colors.inkMuted),
              ),
            ],
          ),
          if (lead.unitLabel != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              lead.unitLabel!,
              style: textTheme.bodyMedium?.copyWith(color: colors.inkMuted),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              _Pill(text: lead.intent.label(context)),
              const SizedBox(width: AppSpacing.sm),
              _Pill(text: lead.status.label(context), accent: true),
              const Spacer(),
              Text(
                Formatters.date(lead.createdAt),
                style: textTheme.labelMedium?.copyWith(color: colors.inkMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, this.accent = false});

  final String text;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs + 1,
      ),
      decoration: BoxDecoration(
        color: accent ? colors.accent : colors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: accent ? colors.onAccent : colors.ink,
        ),
      ),
    );
  }
}
