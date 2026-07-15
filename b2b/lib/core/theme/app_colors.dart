// Semantic color tokens now live in the shared `ibuild_core` package so the
// B2B and B2C apps share one contract. This file re-exports [AppColors] so
// existing `import '../app_colors.dart'` (and `color_schemes/*`) call sites
// keep working unchanged.
export 'package:ibuild_core/ibuild_core.dart' show AppColors;
