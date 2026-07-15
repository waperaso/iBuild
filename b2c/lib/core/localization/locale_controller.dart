import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Locales the app ships translations for (see `lib/l10n/*.arb`).
const List<Locale> kSupportedLocales = [
  Locale('uz'),
  Locale('en'),
  Locale('ru'),
];

const kLanguageNames = {'en': 'English', 'ru': 'Русский', 'uz': 'Oʻzbekcha'};

const kLanguageShort = {'en': 'EN', 'ru': 'RU', 'uz': 'UZ'};

const _prefsKey = 'ibuild.locale';

/// Active app language. Defaults to Uzbek, persisted to local storage so
/// the choice survives a restart, and mirrored into [Intl.defaultLocale] so
/// number/date formatting (see `Formatters`) follows the same language.
class LocaleController extends Notifier<Locale> {
  @override
  Locale build() {
    const restored = Locale('uz');
    Intl.defaultLocale = restored.languageCode;
    _restore();
    return restored;
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_prefsKey);
    if (code == null) return;
    for (final locale in kSupportedLocales) {
      if (locale.languageCode == code) {
        Intl.defaultLocale = locale.languageCode;
        state = locale;
        break;
      }
    }
  }

  Future<void> setLocale(Locale locale) async {
    Intl.defaultLocale = locale.languageCode;
    state = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, locale.languageCode);
  }
}

final localeControllerProvider = NotifierProvider<LocaleController, Locale>(
  LocaleController.new,
);
