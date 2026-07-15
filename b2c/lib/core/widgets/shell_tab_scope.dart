import 'package:flutter/material.dart';

/// Exposes the active shell tab index so heavy branches can skip network
/// work while another tab is selected in the indexed stack.
class ShellTabScope extends InheritedWidget {
  const ShellTabScope({
    super.key,
    required this.currentIndex,
    required super.child,
  });

  final int currentIndex;

  /// Indices matching [kNavDestinations].
  static const homeTabIndex = 0;
  static const mapTabIndex = 1;
  static const favoritesTabIndex = 2;
  static const inquiriesTabIndex = 3;
  static const profileTabIndex = 4;

  static int of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ShellTabScope>();
    assert(scope != null, 'ShellTabScope not found');
    return scope!.currentIndex;
  }

  static int? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ShellTabScope>()?.currentIndex;

  @override
  bool updateShouldNotify(ShellTabScope oldWidget) =>
      currentIndex != oldWidget.currentIndex;
}
