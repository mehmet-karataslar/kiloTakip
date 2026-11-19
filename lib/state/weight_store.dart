import 'package:flutter/foundation.dart';

import '../data/weight_repository.dart';
import '../domain/measurements.dart';

class WeightStore extends ChangeNotifier {
  WeightStore(this.repository);
  final WeightRepository repository;
  Statistics stats = Statistics([]);
  bool loading = true;
  bool failed = false;

  Future<void> load() async {
    loading = true;
    failed = false;
    notifyListeners();
    try {
      stats = Statistics(await repository.readAll());
    } catch (_) {
      failed = true;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> save(Measurement value, {Measurement? original}) async {
    await repository.save(value, original: original);
    stats = Statistics([
      ...stats.all.where(
        (m) => m.day != original?.day || m.slot != original?.slot,
      ),
      value,
    ]);
    notifyListeners();
  }

  Future<void> delete(Measurement value) async {
    await repository.delete(value);
    stats = Statistics(
      stats.all.where((m) => m.day != value.day || m.slot != value.slot),
    );
    notifyListeners();
  }

  Future<void> deleteMany(Iterable<Measurement> values) async {
    final list = values.toList();
    for (final v in list) {
      await repository.delete(v);
    }
    stats = Statistics(
      stats.all.where(
        (m) => !list.any((del) => del.day == m.day && del.slot == m.slot),
      ),
    );
    notifyListeners();
  }
}
