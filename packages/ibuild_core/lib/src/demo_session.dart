/// Runtime flag for awards / reviewer demo sessions (read-only, no DB writes).
class DemoSession {
  DemoSession._();

  static bool _active = false;

  static bool get isActive => _active;

  static void activate() => _active = true;

  static void deactivate() => _active = false;
}
