import 'package:flutter/material.dart';

/// Detects a rapid tap sequence on [child] and calls [onUnlocked] once.
///
/// Used on login screens to reveal phone/OTP auth behind a hidden gesture.
class AuthUnlockTap extends StatefulWidget {
  const AuthUnlockTap({
    super.key,
    required this.child,
    required this.onUnlocked,
    this.tapCount = 5,
    this.window = const Duration(seconds: 2),
  });

  final Widget child;
  final VoidCallback onUnlocked;
  final int tapCount;
  final Duration window;

  @override
  State<AuthUnlockTap> createState() => _AuthUnlockTapState();
}

class _AuthUnlockTapState extends State<AuthUnlockTap> {
  int _taps = 0;
  DateTime? _firstTap;
  bool _unlocked = false;

  void _registerTap() {
    if (_unlocked) return;
    final now = DateTime.now();
    if (_firstTap == null || now.difference(_firstTap!) > widget.window) {
      _firstTap = now;
      _taps = 1;
    } else {
      _taps++;
    }
    if (_taps >= widget.tapCount) {
      _unlocked = true;
      widget.onUnlocked();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _registerTap,
      behavior: HitTestBehavior.opaque,
      child: widget.child,
    );
  }
}
