import 'package:web/web.dart' as web;

/// Full browser reload — the most reliable recovery from a corrupted first
/// build on web, since it re-runs `main()` from scratch rather than trying
/// to repair whatever state caused the crash.
bool reloadPage() {
  web.window.location.reload();
  return true;
}
