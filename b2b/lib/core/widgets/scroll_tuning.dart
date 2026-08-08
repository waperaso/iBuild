import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../theme/app_dimens.dart';

/// Smaller off-screen build window on mobile web — cuts jank from decoding
/// images and laying out cards the user has not scrolled to yet.
ScrollCacheExtent scrollCacheExtentFor(BuildContext context) {
  if (kIsWeb && context.isMobile) {
    return const ScrollCacheExtent.pixels(80);
  }
  if (context.isMobile) {
    return const ScrollCacheExtent.pixels(120);
  }
  return const ScrollCacheExtent.pixels(250);
}
