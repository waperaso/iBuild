import 'package:flutter/material.dart';

import 'l10n.dart';
import 'models.dart';
import 'object_map.dart';
import 'theme.dart';

class ObjectPassport extends StatelessWidget {
  const ObjectPassport({
    super.key,
    required this.project,
    this.documents = const [],
    this.compact = false,
  });

  final ProjectSummary project;
  final List<ProjectDocument> documents;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final copy = LocaleScope.copy(context);
    final muted = Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.colors.inkMuted);
    final facts = <Widget>[
      if (project.companyName.isNotEmpty) Text(copy.developerIs(copy.place(project.companyName))),
      if (project.bankName.isNotEmpty) Text(copy.bankIs(project.bankName)),
      if (project.description.isNotEmpty && !compact)
        Text(project.description, style: muted),
      if (project.latitude != null && project.longitude != null && !compact) ...[
        const SizedBox(height: AppSpacing.md),
        ObjectMap(latitude: project.latitude!, longitude: project.longitude!),
        const SizedBox(height: AppSpacing.sm),
        Text('${project.latitude}, ${project.longitude}', style: muted),
      ],
    ];
    if (facts.isEmpty && (compact || documents.isEmpty)) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...facts,
        if (!compact && documents.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          Text(copy.documents, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          for (final document in documents) ...[
            Text(document.title),
            Text(
              [
                if (document.number.isNotEmpty) document.number,
                if (document.issuedOn.isNotEmpty) document.issuedOn,
                if (document.note.isNotEmpty) document.note,
              ].join(' · '),
              style: muted,
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ],
    );
  }
}
