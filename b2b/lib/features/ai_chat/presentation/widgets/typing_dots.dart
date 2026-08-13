import 'package:flutter/material.dart';

import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_theme_ext.dart';

/// Three dots animating opacity in sequence — the assistant's "typing"
/// indicator. Deliberately plain (no shimmer/gradient), matching the rest of
/// the B2B AI surface (`ai_crm_widgets.dart`, `ai_crm_bot_sheet.dart`).
class TypingDots extends StatefulWidget {
  const TypingDots({super.key});

  @override
  State<TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppDurations.medium * 3,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Dot [index] (0..2) peaks roughly one third of the cycle after the
  /// previous one, so the three fade in sequence rather than in unison.
  double _opacityFor(int index) {
    const minOpacity = 0.25;
    final phase = (_controller.value + (2 - index) / 3) % 1.0;
    final wave = (1 - (2 * phase - 1).abs()).clamp(0.0, 1.0);
    return minOpacity + (1 - minOpacity) * wave;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      label: 'iBuild AI is typing',
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < 3; i++)
                Padding(
                  padding: EdgeInsets.only(right: i == 2 ? 0 : AppSpacing.xs),
                  child: Opacity(
                    opacity: _opacityFor(i),
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: colors.inkMuted,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
