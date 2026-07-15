/// Non-web fallback — there's no OS-level "reload this app" primitive, so
/// the error screen's Reload button falls back to popping back to the root
/// route instead (handled by the caller when this returns `false`).
bool reloadPage() => false;
