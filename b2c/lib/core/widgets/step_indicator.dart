import 'package:flutter/material.dart';

import '../theme/app_dimens.dart';
import '../theme/app_theme_ext.dart';

/// Tiny "step X of N" progress indicator — a row of pill segments, filled up
/// to the current step. Used by the phone-OTP sign-in flow so it's clear
/// there's a second step coming (and how far along you are).
class StepIndicator extends StatelessWidget {
  const StepIndicator({
    super.key,
    required this.step,
    required this.totalSteps,
  });

  /// 1-indexed current step.
  final int step;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < totalSteps; i++)
          Padding(
            padding: EdgeInsets.only(
              right: i == totalSteps - 1 ? 0 : AppSpacing.xs,
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: i == step - 1 ? 26 : 16,
              height: 5,
              decoration: BoxDecoration(
                color: i <= step - 1 ? colors.accent : colors.outline,
                borderRadius: BorderRadius.circular(AppRadii.pill),
              ),
            ),
          ),
      ],
    );
  }
}
