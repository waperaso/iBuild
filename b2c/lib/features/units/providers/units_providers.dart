import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ibuild_core/ibuild_core.dart';

import '../data/units_repository.dart';

/// Looks up a single unit by id via [UnitsRepository] (live API or mock).
final unitByIdProvider = FutureProvider.family<Unit?, String>(
  (ref, id) => ref.watch(unitsRepositoryProvider).fetchUnit(id),
);
