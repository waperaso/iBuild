import 'package:web/web.dart';

const _key = 'ibuild_theme';

String? readStoredTheme() => window.localStorage.getItem(_key);

void writeStoredTheme(String code) {
  window.localStorage.setItem(_key, code);
}
