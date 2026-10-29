import 'package:flutter/material.dart';

import 'api.dart';

class FxController extends ChangeNotifier {
  bool usd = false;
  String? rate;
  String? date;
  String? error;

  Future<void> refresh(Api api) async {
    try {
      final quote = await api.usdRate();
      rate = quote.rate;
      date = quote.date;
      error = null;
    } on ApiException catch (failure) {
      error = failure.message;
    }
    notifyListeners();
  }

  Future<void> useUsd(Api api, bool value) async {
    usd = value;
    if (usd && (rate == null || rate!.isEmpty)) {
      await refresh(api);
      return;
    }
    notifyListeners();
  }
}

class FxScope extends InheritedNotifier<FxController> {
  const FxScope({super.key, required FxController controller, required super.child})
      : super(notifier: controller);

  static FxController? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<FxScope>()?.notifier;
  }
}

class UsdQuote {
  const UsdQuote({required this.rate, required this.date});
  final String rate;
  final String date;
}
