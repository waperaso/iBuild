import 'package:flutter/material.dart';

import '../theme/app_dimens.dart';
import '../theme/app_theme_ext.dart';
import 'app_loading_indicator.dart';
import 'brand_mark.dart';

/// Shown at `/splash` — the app's single initial-load state — while the
/// startup bootstrap (cached session token, etc.) resolves, so cold start
/// shows one deliberate animated screen instead of blocking the very first
/// frame on it.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final t = Curves.easeInOut.transform(_controller.value);
                return Opacity(
                  opacity: 0.7 + (0.3 * t),
                  child: Transform.scale(scale: 0.92 + (0.08 * t), child: child),
                );
              },
              child: const BrandMark(size: 64),
            ),
            const SizedBox(height: AppSpacing.xxl),
            const AppLoadingBar(),
          ],
        ),
      ),
    );
  }
}
