import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether the FAB (`ai_fab.dart`) should be in its compact, icon-only puck
/// state. Driven by a [NotificationListener] wrapped around the active tab's
/// content in `adaptive_scaffold.dart` — kept as shared state (rather than
/// local widget state) so it survives the FAB's own rebuilds.
class AiFabVisibilityController extends Notifier<bool> {
  double _lastOffset = 0;

  @override
  bool build() => false;

  /// Collapses on a meaningful downward scroll, expands again near the top
  /// or on any upward scroll — mirrors common app-bar collapse heuristics.
  void handleScroll(ScrollNotification notification) {
    final metrics = notification.metrics;
    if (metrics.axis != Axis.vertical) return;
    final offset = metrics.pixels;
    final delta = offset - _lastOffset;
    _lastOffset = offset;

    if (offset <= 24) {
      if (state) state = false;
      return;
    }
    if (delta > 6 && !state) {
      state = true;
    } else if (delta < -6 && state) {
      state = false;
    }
  }
}

final aiFabCollapsedProvider = NotifierProvider<AiFabVisibilityController, bool>(
  AiFabVisibilityController.new,
);
