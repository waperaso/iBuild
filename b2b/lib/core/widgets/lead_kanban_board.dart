import 'package:flutter/material.dart';

import '../theme/app_dimens.dart';
import '../theme/app_theme_ext.dart';

/// Drag-and-drop status columns for lead-like records.
class LeadKanbanBoard extends StatelessWidget {
  const LeadKanbanBoard({
    super.key,
    required this.leads,
    required this.statuses,
    required this.statusLabel,
    required this.cardBuilder,
    required this.onStatusChanged,
  });

  final List<Map<String, dynamic>> leads;
  final List<String> statuses;
  final String Function(String status) statusLabel;
  final Widget Function(BuildContext context, Map<String, dynamic> lead)
  cardBuilder;
  final void Function(Map<String, dynamic> lead, String newStatus)
  onStatusChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < statuses.length; i++)
          Padding(
            padding: EdgeInsets.only(
              bottom: i == statuses.length - 1 ? 0 : AppSpacing.md,
            ),
            child: _KanbanColumn(
              label: statusLabel(statuses[i]),
              leads: leads
                  .where(
                    (l) => (l['status']?.toString() ?? '') == statuses[i],
                  )
                  .toList(),
              cardBuilder: cardBuilder,
              onDropped: (lead) {
                if (lead['status']?.toString() != statuses[i]) {
                  onStatusChanged(lead, statuses[i]);
                }
              },
            ),
          ),
      ],
    );
  }
}

class _KanbanColumn extends StatelessWidget {
  const _KanbanColumn({
    required this.label,
    required this.leads,
    required this.cardBuilder,
    required this.onDropped,
  });

  final String label;
  final List<Map<String, dynamic>> leads;
  final Widget Function(BuildContext, Map<String, dynamic>) cardBuilder;
  final void Function(Map<String, dynamic>) onDropped;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth - AppSpacing.sm * 2;

        return DragTarget<Map<String, dynamic>>(
          onAcceptWithDetails: (details) => onDropped(details.data),
          builder: (context, candidateData, rejectedData) {
            final highlighted = candidateData.isNotEmpty;
            return Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: highlighted
                    ? colors.accent.withValues(alpha: 0.1)
                    : colors.surfaceAlt.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(AppRadii.md),
                border: Border.all(
                  color: highlighted ? colors.accent : colors.outline,
                  width: highlighted ? 1.5 : 1,
                ),
              ),
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                      vertical: AppSpacing.xs,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.titleSmall,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: colors.surface,
                            borderRadius: BorderRadius.circular(AppRadii.pill),
                          ),
                          child: Text(
                            '${leads.length}',
                            style: textTheme.labelSmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  if (leads.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.lg,
                      ),
                      child: Center(
                        child: Text(
                          '—',
                          style: textTheme.bodySmall?.copyWith(
                            color: colors.inkMuted,
                          ),
                        ),
                      ),
                    )
                  else
                    for (final lead in leads)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: Draggable<Map<String, dynamic>>(
                          data: lead,
                          maxSimultaneousDrags:
                              lead['isDemoPlaceholder'] == true ? 0 : 1,
                          feedback: Material(
                            color: Colors.transparent,
                            child: SizedBox(
                              width: cardWidth,
                              child: cardBuilder(context, lead),
                            ),
                          ),
                          childWhenDragging: Opacity(
                            opacity: 0.3,
                            child: cardBuilder(context, lead),
                          ),
                          child: cardBuilder(context, lead),
                        ),
                      ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
