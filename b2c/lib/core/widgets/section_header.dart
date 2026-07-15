import 'package:flutter/material.dart';

import '../theme/app_theme_ext.dart';

/// Section title + optional trailing "See all" action, used to break the
/// home screen (and similar list-heavy screens) into named sections instead
/// of one continuous, undifferentiated feed.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Expanded(child: Text(title, style: textTheme.titleLarge)),
        if (actionLabel != null && onAction != null)
          TextButton(
            onPressed: onAction,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(actionLabel!),
                const SizedBox(width: 2),
                Icon(Icons.arrow_forward, size: 16, color: colors.ink),
              ],
            ),
          ),
      ],
    );
  }
}
