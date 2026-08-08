import 'package:flutter/material.dart';

import '../theme/ibuild_scheme.dart';
import 'brand_mark.dart';

/// Branded boot / splash — always uses official iBuild colors and logo,
/// independent of the user's chosen accent palette.
class IBuildBootSplash extends StatefulWidget {
  const IBuildBootSplash({super.key, this.logoSize = 64});

  final double logoSize;

  @override
  State<IBuildBootSplash> createState() => _IBuildBootSplashState();
}

class _IBuildBootSplashState extends State<IBuildBootSplash>
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
    final brand = Theme.of(context).brightness == Brightness.dark
        ? ibuildSchemeDark
        : ibuildScheme;

    return Scaffold(
      backgroundColor: brand.background,
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
                  child: Transform.scale(
                    scale: 0.92 + (0.08 * t),
                    child: child,
                  ),
                );
              },
              child: BrandMark(size: widget.logoSize),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: 120,
              height: 3,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  backgroundColor: brand.surfaceAlt,
                  color: brand.accent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
