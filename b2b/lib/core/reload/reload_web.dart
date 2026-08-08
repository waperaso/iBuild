import 'package:web/web.dart' as web;

/// Hard browser reload; re-runs `main()` after a bad first web build.
bool reloadPage() {
  web.window.location.reload();
  return true;
}
