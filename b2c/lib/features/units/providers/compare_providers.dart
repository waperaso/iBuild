import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Unit ids selected for side-by-side comparison, capped at 3. Adding a 4th
/// drops the oldest selection rather than no-op'ing, so the list always
/// reflects the most recently picked units.
class CompareController extends Notifier<List<String>> {
  static const int _cap = 3;

  @override
  List<String> build() => const [];

  bool contains(String unitId) => state.contains(unitId);

  void toggle(String unitId) {
    if (state.contains(unitId)) {
      state = state.where((id) => id != unitId).toList();
      return;
    }
    final next = [...state, unitId];
    state = next.length > _cap ? next.sublist(next.length - _cap) : next;
  }

  void clear() => state = const [];
}

final compareProvider = NotifierProvider<CompareController, List<String>>(
  CompareController.new,
);
