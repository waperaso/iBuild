import 'package:web/web.dart';

const _key = 'ibuild_lang';
const _themeKey = 'ibuild_theme';

String? readStoredLanguage() => window.localStorage.getItem(_key);

void writeStoredLanguage(String code) {
  window.localStorage.setItem(_key, code);
}

String? readStoredTheme() => window.localStorage.getItem(_themeKey);

void writeStoredTheme(String code) {
  window.localStorage.setItem(_themeKey, code);
}
