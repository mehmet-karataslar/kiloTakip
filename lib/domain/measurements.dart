import '../l10n/app_localizations.dart';

enum Slot {
  morning('Sabah', 9, 0),
  evening('Akşam', 22, 30);

  const Slot(this._rawLabel, this.hour, this.minute);
  final String _rawLabel;
  final int hour;
  final int minute;

  String get label => trText(_rawLabel);
  int get defaultMinutes => hour * 60 + minute;
}

DateTime dayOf(DateTime date) => DateTime(date.year, date.month, date.day);
DateTime shiftDay(DateTime date, int days) =>
    DateTime(date.year, date.month, date.day + days);
DateTime weekOf(DateTime date) => shiftDay(date, 1 - date.weekday);
DateTime monthOf(DateTime date) => DateTime(date.year, date.month);
String dateKey(DateTime day) =>
    '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';

const minWeight = 2.0;
const maxWeight = 500.0;

const quickTags = <String>[
  '🏋️ Spor Günü',
  '🧂 Tuzlu Öğün',
  '💧 Ödem',
  '🍕 Kaçamak',
  '😴 Az Uyku',
  '🤒 Hastalık',
];

List<String> extractTagsFromNote(String? note) {
  if (note == null || note.trim().isEmpty) return const [];
  return [
    for (final tag in quickTags)
      if (note.contains(tag)) tag,
  ];
}

String toggleTagInNote(String currentNote, String tag) {
  if (currentNote.contains(tag)) {
    final cleaned = currentNote
        .replaceAll(tag, '')
        .replaceAll(RegExp(r'\s*•\s*•\s*'), ' • ')
        .replaceAll(RegExp(r'^\s*•\s*|\s*•\s*$'), '')
        .replaceAll(RegExp(r'\s{2,}'), ' ')
        .trim();
    return cleaned;
  } else {
    final trimmed = currentNote.trim();
    if (trimmed.isEmpty) return tag;
    return '$trimmed • $tag';
  }
}

double? parseWeight(String input) {
  final value = input.trim();
  if (!RegExp(r'^\d+(?:[.,]\d{1,2})?$').hasMatch(value)) return null;
  final kg = double.tryParse(value.replaceAll(',', '.'));
  return kg != null && kg >= minWeight && kg <= maxWeight ? rounded(kg) : null;
}

double rounded(double kg) => (kg * 100).round() / 100;

String clockLabel(int minutes) =>
    '${(minutes ~/ 60).toString().padLeft(2, '0')}:${(minutes % 60).toString().padLeft(2, '0')}';

int? parseClockMinutes(String? time) {
  if (time == null || time.trim().isEmpty) return null;
  final parts = time.trim().split(':');
  if (parts.length != 2) return null;
  final h = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  if (h == null || m == null || h < 0 || h > 23 || m < 0 || m > 59) return null;
  return h * 60 + m;
}

class Measurement {
  const Measurement(
    this.day,
    this.slot,
    this.kg, {
    this.minutes,
    this.note,
    this.waistCm,
  });

  final DateTime day;
  final Slot slot;
  final double kg;
  final int? minutes;
  final String? note;
  final double? waistCm;

  int get effectiveMinutes => minutes ?? slot.defaultMinutes;
  String get timeLabel => clockLabel(effectiveMinutes);
  String? get cleanNote {
    final trimmed = note?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }

  Measurement copyWith({
    DateTime? day,
    Slot? slot,
    double? kg,
    int? minutes,
    String? note,
    double? waistCm,
  }) => Measurement(
    day ?? this.day,
    slot ?? this.slot,
    kg ?? this.kg,
    minutes: minutes ?? this.minutes,
    note: note ?? this.note,
    waistCm: waistCm ?? this.waistCm,
  );
}

class DayMeasurements {
  DayMeasurements(this.day);
  final DateTime day;
  final values = <Slot, Measurement>{};

  Measurement? get morning => values[Slot.morning];
  Measurement? get evening => values[Slot.evening];

  /// Günün bel ölçüsü (varsa sabah veya akşam girilmiş olanı alır).
  double? get waistCm => morning?.waistCm ?? evening?.waistCm;

  /// Günlük fark: Akşam Kilosu - Sabah Kilosu.
  /// Yalnızca iki kayıt da mevcutsa hesaplanır.
  double? get difference {
    final m = morning;
    final e = evening;
    return m == null || e == null ? null : rounded(e.kg - m.kg);
  }

  /// Takvim hücresi gibi tek değer gereken yerlerde temsilî kilo.
  double? get representativeWeight => evening?.kg ?? morning?.kg;

  String? get combinedNote {
    final notes = [
      if (morning?.cleanNote case final n?) '${Slot.morning.label}: ${trText(n)}',
      if (evening?.cleanNote case final n?) '${Slot.evening.label}: ${trText(n)}',
    ];
    return notes.isEmpty ? null : notes.join(' • ');
  }
}

class SeriesSummary {
  SeriesSummary(this.entries);
  final List<Measurement> entries;
  Measurement? get first => entries.firstOrNull;
  Measurement? get last => entries.lastOrNull;
  double? get change =>
      entries.length < 2 ? null : rounded(last!.kg - first!.kg);
  double? get average => entries.isEmpty
      ? null
      : rounded(entries.fold(0.0, (sum, m) => sum + m.kg) / entries.length);
  double? get min => entries.isEmpty
      ? null
      : entries.map((m) => m.kg).reduce((a, b) => a < b ? a : b);
  double? get max => entries.isEmpty
      ? null
      : entries.map((m) => m.kg).reduce((a, b) => a > b ? a : b);
}

class PeriodSummary {
  PeriodSummary(this.start, List<Measurement> entries)
    : countDays = entries.map((m) => m.day).toSet().length,
      series = {
        for (final slot in Slot.values)
          slot: SeriesSummary(entries.where((m) => m.slot == slot).toList()),
      };

  final DateTime start;
  final int countDays;
  final Map<Slot, SeriesSummary> series;
}

class BmiInfo {
  const BmiInfo({
    required this.bmi,
    required this.category,
    required this.idealMinKg,
    required this.idealMaxKg,
    required this.heightCm,
  });

  final double bmi;
  final String category;
  final double idealMinKg;
  final double idealMaxKg;
  final double heightCm;
}

class MilestoneBadge {
  const MilestoneBadge({
    required this.label,
    required this.targetKg,
    required this.reached,
  });

  final String label;
  final double targetKg;
  final bool reached;
}

class TargetProgressInfo {
  const TargetProgressInfo({
    required this.startWeight,
    required this.currentWeight,
    required this.targetWeight,
    required this.remainingKg,
    required this.progressFraction,
    this.estimatedTargetDate,
    this.dailyRateKg,
    this.milestones = const [],
    this.nextMilestoneKg,
    this.maintenanceMinKg,
    this.maintenanceMaxKg,
    this.isInMaintenanceBand = false,
  });

  final double startWeight;
  final double currentWeight;
  final double targetWeight;
  final double remainingKg;
  final double progressFraction;
  final DateTime? estimatedTargetDate;
  final double? dailyRateKg;
  final List<MilestoneBadge> milestones;
  final double? nextMilestoneKg;
  final double? maintenanceMinKg;
  final double? maintenanceMaxKg;
  final bool isInMaintenanceBand;

  int get progressPercent => (progressFraction * 100).round().clamp(0, 100);
}

class Statistics {
  Statistics(Iterable<Measurement> entries)
    : all = List.of(entries)
        ..sort((a, b) {
          final order = a.day.compareTo(b.day);
          return order == 0 ? a.slot.index.compareTo(b.slot.index) : order;
        }) {
    for (final m in all) {
      days.putIfAbsent(m.day, () => DayMeasurements(m.day)).values[m.slot] = m;
    }
  }

  final List<Measurement> all;
  final days = <DateTime, DayMeasurements>{};

  List<Measurement> range(DateTime start, DateTime end) =>
      all.where((m) => !m.day.isBefore(start) && m.day.isBefore(end)).toList();

  List<Measurement> forMonth(int year, int month) {
    final start = DateTime(year, month);
    final end = DateTime(year, month + 1);
    return range(start, end);
  }

  List<Measurement> lastDays(DateTime today, int count) =>
      range(shiftDay(today, 1 - count), shiftDay(today, 1));

  Measurement? previous(DateTime day, Slot slot) => all.reversed
      .where((m) => m.slot == slot && m.day.isBefore(day))
      .firstOrNull;

  double? previousChange(DateTime day, Slot slot) {
    final current = days[day]?.values[slot];
    final last = previous(day, slot);
    return current == null || last == null
        ? null
        : rounded(current.kg - last.kg);
  }

  PeriodSummary period(DateTime start, DateTime end) =>
      PeriodSummary(start, range(start, end));

  List<PeriodSummary> grouped(DateTime Function(DateTime) group) {
    final groups = <DateTime, List<Measurement>>{};
    for (final m in all) {
      groups.putIfAbsent(group(m.day), () => []).add(m);
    }
    return [
      for (final entry in groups.entries) PeriodSummary(entry.key, entry.value),
    ];
  }

  /// Tutarlı karşılaştırma değişimi:
  /// Yalnızca tek tür seçiliyse o türün ilk ve son kaydını karşılaştırır.
  /// Her iki tür seçiliyse önce sabah ölçümlerini (en az 2 kayıt varsa),
  /// yoksa akşam ölçümlerini (en az 2 kayıt varsa), o da yoksa tüm kayıtları kullanır.
  ({double? change, Slot? usedSlot}) comparableChange(
    List<Measurement> entries, {
    Set<Slot>? slots,
  }) {
    final activeSlots = slots ?? Slot.values.toSet();
    final filtered = entries.where((m) => activeSlots.contains(m.slot)).toList();
    if (filtered.length < 2) return (change: null, usedSlot: null);

    if (activeSlots.length == 1) {
      final slot = activeSlots.first;
      final summary = SeriesSummary(filtered);
      return (change: summary.change, usedSlot: slot);
    }

    final morning = SeriesSummary(
      filtered.where((m) => m.slot == Slot.morning).toList(),
    );
    if (morning.change != null) {
      return (change: morning.change, usedSlot: Slot.morning);
    }

    final evening = SeriesSummary(
      filtered.where((m) => m.slot == Slot.evening).toList(),
    );
    if (evening.change != null) {
      return (change: evening.change, usedSlot: Slot.evening);
    }

    final overall = SeriesSummary(filtered);
    return (change: overall.change, usedSlot: null);
  }

  double? averageOf(List<Measurement> entries) =>
      SeriesSummary(entries).average;

  double? minOf(List<Measurement> entries) => SeriesSummary(entries).min;

  double? maxOf(List<Measurement> entries) => SeriesSummary(entries).max;

  Measurement? get firstMeasurement => all.firstOrNull;
  Measurement? get latestMeasurement => all.lastOrNull;

  /// En güncel kaydedilmiş bel ölçüsü (cm)
  double? get latestWaistCm {
    for (final day in days.values.toList().reversed) {
      if (day.waistCm != null) return day.waistCm;
    }
    return null;
  }

  /// Son 7 gündeki tutarlı seri (varsayılan sabah, yoksa akşam)
  List<Measurement> miniChartSeries(DateTime today) {
    final recent = lastDays(today, 7);
    final mornings = recent.where((m) => m.slot == Slot.morning).toList();
    if (mornings.length >= 2) return mornings;
    final evenings = recent.where((m) => m.slot == Slot.evening).toList();
    if (evenings.length >= 2) return evenings;
    return mornings.isNotEmpty ? mornings : evenings;
  }

  /// 1. 7 Günlük Hareketli Ortalama (Gerçek Trend Çizgisi)
  List<(DateTime day, double kg)> movingAverageSeries(
    List<Measurement> entries, {
    int windowDays = 7,
  }) {
    if (entries.isEmpty) return const [];
    final byDay = <DateTime, double>{};
    for (final m in entries) {
      final d = m.day;
      final dayObj = days[d];
      byDay[d] = dayObj?.morning?.kg ?? dayObj?.representativeWeight ?? m.kg;
    }
    final sortedDays = byDay.keys.toList()..sort();
    final result = <(DateTime, double)>[];
    for (final d in sortedDays) {
      final windowStart = shiftDay(d, -(windowDays - 1));
      final inWindow = [
        for (final other in sortedDays)
          if (!other.isBefore(windowStart) && !other.isAfter(d)) byDay[other]!,
      ];
      if (inWindow.isNotEmpty) {
        final avg =
            inWindow.fold(0.0, (a, b) => a + b) / inWindow.length;
        result.add((d, rounded(avg)));
      }
    }
    return result;
  }

  /// 10. Seri (Streak) Sayacı: Kesintisiz ölçüm günleri ve en uzun rekor
  ({int current, int best, bool loggedToday}) streakInfo(DateTime today) {
    if (days.isEmpty) return (current: 0, best: 0, loggedToday: false);
    final sorted = days.keys.toList()..sort();
    var best = 1;
    var run = 1;
    for (var i = 1; i < sorted.length; i++) {
      final prev = sorted[i - 1];
      final curr = sorted[i];
      if (shiftDay(prev, 1) == curr) {
        run++;
        if (run > best) best = run;
      } else if (curr != prev) {
        run = 1;
      }
    }

    final loggedToday = days.containsKey(today);
    var current = 0;
    var cursor = loggedToday ? today : shiftDay(today, -1);
    while (days.containsKey(cursor)) {
      current++;
      cursor = shiftDay(cursor, -1);
    }
    if (current > best) best = current;
    return (current: current, best: best, loggedToday: loggedToday);
  }

  /// 3. VKİ (BMI) ve İdeal Kilo Aralığı
  BmiInfo? bmiInfo({required double? heightCm, double? currentWeight}) {
    final w = currentWeight ?? latestMeasurement?.kg;
    if (heightCm == null || heightCm < 80 || heightCm > 250 || w == null) {
      return null;
    }
    final hMeters = heightCm / 100.0;
    final bmi = rounded(w / (hMeters * hMeters));
    final idealMin = rounded(18.5 * hMeters * hMeters);
    final idealMax = rounded(24.9 * hMeters * hMeters);
    final String category;
    if (bmi < 18.5) {
      category = 'Düşük Kilolu';
    } else if (bmi < 25.0) {
      category = 'İdeal (Normal)';
    } else if (bmi < 30.0) {
      category = 'Fazla Kilolu';
    } else {
      category = 'Obezite Sınırı Üstü';
    }
    return BmiInfo(
      bmi: bmi,
      category: trText(category),
      idealMinKg: idealMin,
      idealMaxKg: idealMax,
      heightCm: heightCm,
    );
  }

  /// 4. Sabah – Akşam Metabolik Fark Analizi (Gün İçi vs Gece Boyu Değişim)
  ({
    double? avgIntradayDiff,
    double? avgOvernightDrop,
    int intradayCount,
    int overnightCount,
  }) metabolicAnalysis([List<Measurement>? subset]) {
    final activeDays = subset == null
        ? (days.keys.toList()..sort())
        : (subset.map((e) => e.day).toSet().toList()..sort());
    final intradayDiffs = <double>[];
    final overnightDrops = <double>[];

    for (final d in activeDays) {
      final dayObj = days[d];
      if (dayObj?.difference case final diff?) {
        intradayDiffs.add(diff);
      }
      final prevEvening = days[shiftDay(d, -1)]?.evening;
      final thisMorning = dayObj?.morning;
      if (prevEvening != null && thisMorning != null) {
        overnightDrops.add(rounded(thisMorning.kg - prevEvening.kg));
      }
    }

    final avgIntra = intradayDiffs.isEmpty
        ? null
        : rounded(
            intradayDiffs.fold(0.0, (a, b) => a + b) / intradayDiffs.length,
          );
    final avgOvernight = overnightDrops.isEmpty
        ? null
        : rounded(
            overnightDrops.fold(0.0, (a, b) => a + b) / overnightDrops.length,
          );

    return (
      avgIntradayDiff: avgIntra,
      avgOvernightDrop: avgOvernight,
      intradayCount: intradayDiffs.length,
      overnightCount: overnightDrops.length,
    );
  }

  /// 5. Hafta İçi vs. Hafta Sonu Kıyaslaması
  ({
    double? weekdayAvg,
    double? weekendAvg,
    double? weekendVsWeekdayDiff,
  }) weekdayWeekendComparison([List<Measurement>? subset]) {
    final source = subset ?? all;
    final weekdayWeights = <double>[];
    final weekendWeights = <double>[];
    for (final m in source) {
      if (m.day.weekday <= 5) {
        weekdayWeights.add(m.kg);
      } else {
        weekendWeights.add(m.kg);
      }
    }
    final wdAvg = weekdayWeights.isEmpty
        ? null
        : rounded(
            weekdayWeights.fold(0.0, (a, b) => a + b) / weekdayWeights.length,
          );
    final weAvg = weekendWeights.isEmpty
        ? null
        : rounded(
            weekendWeights.fold(0.0, (a, b) => a + b) / weekendWeights.length,
          );
    final diff = (wdAvg != null && weAvg != null)
        ? rounded(weAvg - wdAvg)
        : null;
    return (
      weekdayAvg: wdAvg,
      weekendAvg: weAvg,
      weekendVsWeekdayDiff: diff,
    );
  }

  /// 15. Etiket Bazlı Etki Raporu
  List<({String tag, int count, double? avgNextMorningChange})>
  tagImpactAnalysis() {
    final results = <({String tag, int count, double? avgNextMorningChange})>[];
    final sortedDays = days.keys.toList()..sort();

    for (final tag in quickTags) {
      var count = 0;
      final nextDayChanges = <double>[];

      for (final d in sortedDays) {
        final dayObj = days[d]!;
        final hasTag =
            (dayObj.morning?.cleanNote?.contains(tag) ?? false) ||
            (dayObj.evening?.cleanNote?.contains(tag) ?? false);
        if (!hasTag) continue;
        count++;

        final baseMorning = dayObj.morning?.kg ?? dayObj.evening?.kg;
        final nextMorning = days[shiftDay(d, 1)]?.morning?.kg;
        if (baseMorning != null && nextMorning != null) {
          nextDayChanges.add(rounded(nextMorning - baseMorning));
        }
      }

      if (count > 0) {
        final avgChange = nextDayChanges.isEmpty
            ? null
            : rounded(
                nextDayChanges.fold(0.0, (a, b) => a + b) /
                    nextDayChanges.length,
              );
        results.add((
          tag: tag,
          count: count,
          avgNextMorningChange: avgChange,
        ));
      }
    }
    return results;
  }

  TargetProgressInfo? targetProgress({
    required double? configuredStartWeight,
    required double? targetWeight,
    double maintenanceToleranceKg = 1.0,
    DateTime? referenceToday,
  }) {
    if (targetWeight == null) return null;
    final start = configuredStartWeight ?? firstMeasurement?.kg;
    final current = latestMeasurement?.kg ?? configuredStartWeight;
    if (start == null || current == null) return null;

    final totalSpan = (start - targetWeight).abs();
    final isLossGoal = targetWeight <= start;
    final double remaining;
    if (isLossGoal) {
      remaining = current <= targetWeight ? 0.0 : rounded(current - targetWeight);
    } else {
      remaining = current >= targetWeight ? 0.0 : rounded(targetWeight - current);
    }

    double progress = 0.0;
    if (totalSpan < 0.01) {
      progress = remaining < 0.05 ? 1.0 : 0.0;
    } else if (isLossGoal) {
      progress = ((start - current) / (start - targetWeight)).clamp(0.0, 1.0);
    } else {
      progress = ((current - start) / (targetWeight - start)).clamp(0.0, 1.0);
    }

    // 2. Tahmini Hedefe Ulaşma Tarihi (Son 30 gün veya tüm seri hızına göre)
    DateTime? estimatedDate;
    double? dailyRate;
    final today = referenceToday ?? latestMeasurement?.day ?? dayOf(DateTime.now());
    final recent30 = lastDays(today, 30);
    final seriesSource = recent30.length >= 2 ? recent30 : all;
    if (seriesSource.length >= 2 && remaining > 0.05) {
      final firstM = seriesSource.first;
      final lastM = seriesSource.last;
      final spanDays = lastM.day.difference(firstM.day).inDays;
      final weightDelta = lastM.kg - firstM.kg;
      final effectiveDays = spanDays > 0 ? spanDays : 1;
      final ratePerDay = weightDelta / effectiveDays;
      dailyRate = rounded(ratePerDay);

      if (isLossGoal && ratePerDay < -0.005) {
        final daysLeft = (remaining / (-ratePerDay)).ceil().clamp(1, 730);
        estimatedDate = shiftDay(today, daysLeft);
      } else if (!isLossGoal && ratePerDay > 0.005) {
        final daysLeft = (remaining / ratePerDay).ceil().clamp(1, 730);
        estimatedDate = shiftDay(today, daysLeft);
      }
    }

    // 11. Ara Hedefler (Milestone Rozetleri)
    final milestones = <MilestoneBadge>[];
    double? nextMilestone;
    if (totalSpan >= 1.0) {
      for (final pct in [0.25, 0.50, 0.75, 1.0]) {
        final mWeight = rounded(
          isLossGoal
              ? start - totalSpan * pct
              : start + totalSpan * pct,
        );
        final reached = isLossGoal ? current <= mWeight : current >= mWeight;
        if (!reached && nextMilestone == null) {
          nextMilestone = mWeight;
        }
        milestones.add(
          MilestoneBadge(
            label: '%${(pct * 100).round()} (${mWeight.toStringAsFixed(1)} kg)',
            targetKg: mWeight,
            reached: reached,
          ),
        );
      }
    }

    // 12. Kilo Koruma (Maintenance) Bandı
    final maintMin = rounded(targetWeight - maintenanceToleranceKg);
    final maintMax = rounded(targetWeight + maintenanceToleranceKg);
    final inBand = current >= maintMin && current <= maintMax;

    return TargetProgressInfo(
      startWeight: rounded(start),
      currentWeight: rounded(current),
      targetWeight: rounded(targetWeight),
      remainingKg: remaining,
      progressFraction: progress,
      estimatedTargetDate: estimatedDate,
      dailyRateKg: dailyRate,
      milestones: milestones,
      nextMilestoneKg: nextMilestone,
      maintenanceMinKg: maintMin,
      maintenanceMaxKg: maintMax,
      isInMaintenanceBand: inBand,
    );
  }
}
