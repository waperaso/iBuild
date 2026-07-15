import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/formatters.dart';

const kCurrencyLabels = {
  DisplayCurrency.usd: 'USD',
  DisplayCurrency.uzs: 'UZS',
};

const _prefsKey = 'ibuild.currency';

/// Active display currency. Persisted locally and mirrored into [Formatters] so
/// every `Formatters.price` call stays in sync without threading context.
class CurrencyController extends Notifier<DisplayCurrency> {
  @override
  DisplayCurrency build() {
    const restored = DisplayCurrency.uzs;
    Formatters.displayCurrency = restored;
    _restore();
    return restored;
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_prefsKey);
    if (code == null) return;
    for (final currency in DisplayCurrency.values) {
      if (currency.name == code) {
        Formatters.displayCurrency = currency;
        state = currency;
        break;
      }
    }
  }

  Future<void> setCurrency(DisplayCurrency currency) async {
    Formatters.displayCurrency = currency;
    state = currency;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, currency.name);
  }
}

final currencyControllerProvider =
    NotifierProvider<CurrencyController, DisplayCurrency>(
      CurrencyController.new,
    );
