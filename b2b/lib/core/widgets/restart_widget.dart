import 'package:flutter/widgets.dart';

/// Standard "restart the whole Flutter app" trick: changing this widget's
/// [Key] tears down and rebuilds the entire tree below it, including every
/// [ProviderScope]/router/controller — the closest thing to a fresh
/// `main()` run without an actual process restart. Used by the error
/// screen's Reload action on platforms where a real page reload (web)
/// isn't available.
class RestartWidget extends StatefulWidget {
  const RestartWidget({super.key, required this.child});

  final Widget child;

  static void restartApp(BuildContext context) {
    context.findAncestorStateOfType<_RestartWidgetState>()?.restart();
  }

  @override
  State<RestartWidget> createState() => _RestartWidgetState();
}

class _RestartWidgetState extends State<RestartWidget> {
  Key _key = UniqueKey();

  void restart() {
    setState(() => _key = UniqueKey());
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(key: _key, child: widget.child);
  }
}
