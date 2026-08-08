import 'package:flutter/material.dart';
import 'package:ibuild_core/ibuild_core.dart';

/// `/splash` while bootstrap (token warm-up, etc.) completes.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) => const IBuildBootSplash();
}
