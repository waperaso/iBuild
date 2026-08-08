import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme/app_dimens.dart';

/// Smaller off-screen build window on mobile web — cuts jank from decoding
/// images and laying out cards the user has not scrolled to yet.
double scrollCacheExtentFor(BuildContext context) {
  if (kIsWeb && context.isMobile) return 80;
  if (context.isMobile) return 120;
  return 250;
}
