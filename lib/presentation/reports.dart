import 'package:flutter/material.dart' hide Text;

import '../app/app_theme.dart';
import '../domain/measurements.dart';
import '../services/reminders.dart';
import 'common.dart';

enum ReportPeriod { daily, weekly, monthly, overall }

class ReportsPage extends StatefulWidget {
  const ReportsPage(
    this.stats,
    this.today,
    this.export, {
    this.settings,
    this.onOpenSettings,
    super.key,
  });

  final Statistics stats;
  final DateTime today;
  final VoidCallback export;
  final AppSettings? settings;
  final VoidCallback? onOpenSettings;

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  ReportPeriod period = ReportPeriod.weekly;

  List<Measurement> _entriesForPeriod() => switch (period) {
    ReportPeriod.daily => [
      ...?widget.stats.days[widget.today]?.values.values,
    ],
    ReportPeriod.weekly => widget.stats.lastDays(widget.today, 7),
    ReportPeriod.monthly => widget.stats.lastDays(widget.today, 30),
    ReportPeriod.overall => widget.stats.all,
  };

  String get _periodTitle => switch (period) {
    ReportPeriod.daily => 'Bugün',
    ReportPeriod.weekly => 'Son 7 günde',
    ReportPeriod.monthly => 'Son 30 günde',
    ReportPeriod.overall => 'Tüm zamanlarda',
  };

  List<(IconData, Color, Color, String)> _buildSummaryMessages(
    BuildContext context,
    List<Measurement> entries,
  ) {
    final c = context.colors;
    if (entries.isEmpty) return [];

    final items = <(IconData, Color, Color, String)>[];
    final changeRes = widget.stats.comparableChange(entries);
    if (changeRes.change != null) {
      final ch = changeRes.change!;
      final periodStr = trText(_periodTitle);
      final slotStr = changeRes.usedSlot != null
          ? ' (${changeRes.usedSlot!.label})'
          : '';
      items.add((
        ch <= 0 ? Icons.trending_down_rounded : Icons.trending_up_rounded,
        ch <= 0 ? c.greenSurface : c.orangeSurface,
        ch <= 0 ? c.greenText : c.orangeText,
        '$periodStr$slotStr: ${delta(ch)} ${trText('değişim kaydedildi.')}',
      ));
    }

    final avg = widget.stats.averageOf(entries);
    if (avg != null) {
      final periodStr = trText(_periodTitle);
      items.add((
        Icons.bar_chart_rounded,
        c.morningSurface,
        c.morningAccent,
        '$periodStr: ${trText('ortalama kilon')} ${kg(avg)}',
      ));
    }

    final minW = widget.stats.minOf(entries);
    final maxW = widget.stats.maxOf(entries);
    if (minW != null && maxW != null && entries.length >= 2) {
      items.add((
        Icons.emoji_events_outlined,
        c.eveningSurface,
        c.eveningAccent,
        '${trText('En düşük ölçüm')}: ${kg(minW)} • ${trText('en yüksek ölçüm')}: ${kg(maxW)}',
      ));
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final stats = widget.stats;
    final periodEntries = _entriesForPeriod();

    // Üst satır değişim kartları
    final dailyDiff =
        stats.days[widget.today]?.difference ??
        (stats.days.values.isNotEmpty
            ? stats.days.values.last.difference
            : null);
    final weeklyChange = stats
        .comparableChange(stats.lastDays(widget.today, 7))
        .change;
    final monthlyChange = stats
        .comparableChange(stats.lastDays(widget.today, 30))
        .change;

    // Seçili aralığa ait istatistikler
    final avgWeight = stats.averageOf(periodEntries);
    final count = periodEntries.length;
    final minWeightVal = stats.minOf(periodEntries);
    final maxWeightVal = stats.maxOf(periodEntries);

    // Hedef ilerleme bilgisi
    final targetInfo = stats.targetProgress(
      configuredStartWeight: widget.settings?.startWeight,
      targetWeight: widget.settings?.targetWeight,
      maintenanceToleranceKg: widget.settings?.maintenanceToleranceKg ?? 1.0,
      referenceToday: widget.today,
    );

    final bmi = stats.bmiInfo(
      heightCm: widget.settings?.heightCm,
      currentWeight: stats.latestMeasurement?.kg,
    );
    final metabolic = stats.metabolicAnalysis(periodEntries);
    final weekdayWeekend = stats.weekdayWeekendComparison(periodEntries);
    final tagImpacts = stats.tagImpactAnalysis();
    final waistRatio = widget.settings?.waistToHeightRatio;

    final summaryMessages = _buildSummaryMessages(context, periodEntries);

    return PageBody([
      // 1. Rapor Aralığı Seçimi (Günlük, Haftalık, Aylık, Genel)
      PillSelector<ReportPeriod>(
        items: const [
          (ReportPeriod.daily, 'Günlük'),
          (ReportPeriod.weekly, 'Haftalık'),
          (ReportPeriod.monthly, 'Aylık'),
          (ReportPeriod.overall, 'Genel'),
        ],
        selected: period,
        onSelected: (v) => setState(() => period = v),
      ),
      const SizedBox(height: 14),

      // 2. İlk İstatistik Bölümü (3x2 Grid)
      Row(
        children: [
          Expanded(
            child: _ReportMetricCard(
              title: 'Günlük\nDeğişim',
              value: delta(dailyDiff, empty: '—'),
              icon: Icons.arrow_downward_rounded,
              surfaceColor: dailyDiff == null
                  ? c.cardSurface
                  : (dailyDiff <= 0 ? c.greenSurface : c.orangeSurface),
              borderColor: dailyDiff == null
                  ? c.cardBorder
                  : (dailyDiff <= 0 ? c.greenBorder : c.orangeBorder),
              iconColor: dailyDiff == null
                  ? c.primaryBlue
                  : (dailyDiff <= 0 ? c.greenText : c.orangeText),
              valueColor: dailyDiff == null
                  ? c.heading
                  : (dailyDiff < 0
                        ? c.greenText
                        : dailyDiff > 0
                        ? c.orangeText
                        : c.heading),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _ReportMetricCard(
              title: 'Haftalık\nDeğişim',
              value: delta(weeklyChange, empty: '—'),
              icon: Icons.calendar_today_rounded,
              surfaceColor: c.morningSurface,
              borderColor: c.morningBorder,
              iconColor: c.morningAccent,
              valueColor: weeklyChange == null
                  ? c.heading
                  : (weeklyChange < 0
                        ? c.greenText
                        : weeklyChange > 0
                        ? c.orangeText
                        : c.heading),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _ReportMetricCard(
              title: 'Aylık\nDeğişim',
              value: delta(monthlyChange, empty: '—'),
              icon: Icons.calendar_month_rounded,
              surfaceColor: c.eveningSurface,
              borderColor: c.eveningBorder,
              iconColor: c.eveningAccent,
              valueColor: monthlyChange == null
                  ? c.heading
                  : (monthlyChange < 0
                        ? c.greenText
                        : monthlyChange > 0
                        ? c.orangeText
                        : c.heading),
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      Row(
        children: [
          Expanded(
            child: _ReportMetricCard(
              title: 'Ortalama\nKilo',
              value: kg(avgWeight),
              icon: Icons.bar_chart_rounded,
              iconColor: c.primaryBlue,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _ReportMetricCard(
              title: 'Toplam\nKayıt',
              value: '$count',
              icon: Icons.layers_outlined,
              iconColor: c.primaryBlue,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _ReportMetricCard(
              title: 'En Düşük\nKilo',
              value: kg(minWeightVal),
              icon: Icons.emoji_events_outlined,
              iconColor: c.primaryBlue,
            ),
          ),
        ],
      ),
      const SizedBox(height: 14),

      // 3. Genel İstatistikler Kartı
      AppCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Genel İstatistikler',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: c.heading,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Kilo takibinle ilgili genel görünüm',
                        style: TextStyle(fontSize: 12.5, color: c.subtitle),
                      ),
                    ],
                  ),
                ),
                const ScaleIllustration(size: 56),
              ],
            ),
            const SizedBox(height: 14),

            if (targetInfo != null) ...[
              Row(
                children: [
                  // Dairesel ilerleme göstergesi
                  SizedBox(
                    width: 96,
                    height: 96,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 86,
                          height: 86,
                          child: CircularProgressIndicator(
                            value: targetInfo.progressFraction,
                            strokeWidth: 9,
                            backgroundColor: c.primarySoft,
                            color: c.primaryBlue,
                            strokeCap: StrokeCap.round,
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '%${targetInfo.progressPercent}',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: c.heading,
                              ),
                            ),
                            Text(
                              'Hedef\nİlerlemesi',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 10,
                                height: 1.15,
                                color: c.subtitle,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      children: [
                        _GoalDetailRow(
                          icon: Icons.play_circle_outline_rounded,
                          label: 'Başlangıç Kilosu',
                          value: kg(targetInfo.startWeight),
                        ),
                        Divider(color: c.cardBorder, height: 14),
                        _GoalDetailRow(
                          icon: Icons.monitor_weight_outlined,
                          label: 'Güncel Kilo',
                          value: kg(targetInfo.currentWeight),
                        ),
                        Divider(color: c.cardBorder, height: 14),
                        _GoalDetailRow(
                          icon: Icons.track_changes_rounded,
                          label: 'Hedef Kilo',
                          value: kg(targetInfo.targetWeight),
                        ),
                        Divider(color: c.cardBorder, height: 14),
                        _GoalDetailRow(
                          icon: Icons.flag_outlined,
                          label: 'Kalan Kilo',
                          value: kg(targetInfo.remainingKg),
                          valueColor: c.greenText,
                        ),
                        Divider(color: c.cardBorder, height: 14),
                        _GoalDetailRow(
                          icon: Icons.event_available_rounded,
                          label: 'Tahmini Hedef Tarihi',
                          value: targetInfo.remainingKg <= 0.05
                              ? 'Hedefe Ulaşıldı!'
                              : targetInfo.estimatedTargetDate != null
                              ? '${formatShortDayMonth(targetInfo.estimatedTargetDate!)} ${targetInfo.estimatedTargetDate!.year}'
                              : 'Hesaplanıyor…',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: targetInfo.progressFraction,
                        minHeight: 9,
                        backgroundColor: c.primarySoft,
                        color: c.primaryBlue,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '%${targetInfo.progressPercent}',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: c.primaryBlue,
                    ),
                  ),
                ],
              ),
              // 11. Ara Hedefler (Milestone Rozetleri)
              if (targetInfo.milestones.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Ara Hedef Rozetleri',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: c.subtitle,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final m in targetInfo.milestones)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: m.reached ? c.greenSurface : c.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: m.reached ? c.greenBorder : c.cardBorder,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              m.reached
                                  ? Icons.workspace_premium_rounded
                                  : Icons.radio_button_unchecked_rounded,
                              size: 14,
                              color: m.reached ? c.greenText : c.subtitle,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              m.label,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: m.reached ? c.greenText : c.subtitle,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
              // 12. Kilo Koruma (Maintenance) Bandı Durumu
              if ((widget.settings?.maintenanceMode ?? false) ||
                  targetInfo.isInMaintenanceBand) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: targetInfo.isInMaintenanceBand
                        ? c.greenSurface
                        : c.primarySoft,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: targetInfo.isInMaintenanceBand
                          ? c.greenBorder
                          : c.morningBorder,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.verified_user_outlined,
                        size: 18,
                        color: targetInfo.isInMaintenanceBand
                            ? c.greenText
                            : c.primaryBlue,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          targetInfo.isInMaintenanceBand
                              ? 'Kilo Koruma Bandındasın (${formatWeightValue(targetInfo.maintenanceMinKg!)} – ${formatWeightValue(targetInfo.maintenanceMaxKg!)} kg)'
                              : 'Kilo Koruma Bandı: ${formatWeightValue(targetInfo.maintenanceMinKg!)} – ${formatWeightValue(targetInfo.maintenanceMaxKg!)} kg',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: targetInfo.isInMaintenanceBand
                                ? c.greenText
                                : c.primaryBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ] else ...[
              // Hedef kilo tanımlanmamışsa gerçek genel istatistikleri ve mesajı göster
              _GoalDetailRow(
                icon: Icons.play_circle_outline_rounded,
                label: 'Başlangıç Kilosu',
                value: kg(
                  widget.settings?.startWeight ?? stats.firstMeasurement?.kg,
                ),
              ),
              Divider(color: c.cardBorder, height: 16),
              _GoalDetailRow(
                icon: Icons.monitor_weight_outlined,
                label: 'Güncel Kilo',
                value: kg(stats.latestMeasurement?.kg),
              ),
              Divider(color: c.cardBorder, height: 16),
              _GoalDetailRow(
                icon: Icons.arrow_upward_rounded,
                label: 'En Yüksek Kilo (Seçili Dönem)',
                value: kg(maxWeightVal),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: c.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: c.cardBorder),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.track_changes_rounded,
                      size: 18,
                      color: c.primaryBlue,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Henüz hedef kilo belirlenmedi.',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: c.subtitle,
                        ),
                      ),
                    ),
                    if (widget.onOpenSettings != null)
                      TextButton(
                        onPressed: widget.onOpenSettings,
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                        ),
                        child: const Text('Hedef Belirle'),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      const SizedBox(height: 14),

      // 3B. VKİ (BMI), İdeal Kilo Aralığı ve Vücut Ölçüleri Kartı (Özellik 3 & 13)
      AppCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: c.primarySoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.accessibility_new_rounded,
                    color: c.primaryBlue,
                    size: 19,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'VKİ & Vücut Ölçüleri',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: c.heading,
                    ),
                  ),
                ),
                if (widget.onOpenSettings != null)
                  TextButton(
                    onPressed: widget.onOpenSettings,
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                    child: const Text('Düzenle'),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            if (bmi != null) ...[
              _GoalDetailRow(
                icon: Icons.speed_rounded,
                label: 'Vücut Kitle İndeksi (VKİ)',
                value: '${bmi.bmi.toStringAsFixed(1)} (${bmi.category})',
                valueColor: bmi.bmi >= 18.5 && bmi.bmi < 25.0
                    ? c.greenText
                    : c.orangeText,
              ),
              Divider(color: c.cardBorder, height: 14),
              _GoalDetailRow(
                icon: Icons.check_circle_outline_rounded,
                label: 'Boyuna Göre İdeal Aralık (${bmi.heightCm.round()} cm)',
                value:
                    '${formatWeightValue(bmi.idealMinKg)} – ${formatWeightValue(bmi.idealMaxKg)} kg',
                valueColor: c.greenText,
              ),
            ] else
              Text(
                'Ayarlar’dan boy (cm) bilgini girerek VKİ ve ideal kilo aralığını görebilirsin.',
                style: TextStyle(fontSize: 12.5, color: c.subtitle),
              ),
            if (widget.settings?.waistCm != null ||
                widget.settings?.hipCm != null ||
                widget.settings?.neckCm != null) ...[
              Divider(color: c.cardBorder, height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (widget.settings?.waistCm case final w?)
                    _MiniBodyChip(label: 'Bel: ${w.toStringAsFixed(1)} cm'),
                  if (widget.settings?.hipCm case final h?)
                    _MiniBodyChip(label: 'Kalça: ${h.toStringAsFixed(1)} cm'),
                  if (widget.settings?.neckCm case final n?)
                    _MiniBodyChip(label: 'Boyun: ${n.toStringAsFixed(1)} cm'),
                  if (waistRatio != null)
                    _MiniBodyChip(
                      label:
                          'Bel/Boy: ${waistRatio.toStringAsFixed(2)} (${waistRatio < 0.5 ? "İdeal" : "Dikkat"})',
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
      const SizedBox(height: 14),

      // 3C. Sabah–Akşam Metabolik Fark & Hafta İçi / Hafta Sonu Analizi (Özellik 4 & 5)
      AppCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: c.eveningSurface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.nights_stay_outlined,
                    color: c.eveningAccent,
                    size: 19,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Metabolik & Haftalık Döngü Analizi',
                    style: TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w800,
                      color: c.heading,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _GoalDetailRow(
              icon: Icons.wb_sunny_outlined,
              label: 'Gün İçi Ortalama Fark (Sabah → Akşam)',
              value: delta(metabolic.avgIntradayDiff, empty: '—'),
            ),
            Divider(color: c.cardBorder, height: 14),
            _GoalDetailRow(
              icon: Icons.bedtime_outlined,
              label: 'Gece Boyu Değişim (Akşam → Ertesi Sabah)',
              value: delta(metabolic.avgOvernightDrop, empty: '—'),
              valueColor: (metabolic.avgOvernightDrop ?? 0) <= 0
                  ? c.greenText
                  : c.orangeText,
            ),
            Divider(color: c.cardBorder, height: 14),
            _GoalDetailRow(
              icon: Icons.work_outline_rounded,
              label: 'Hafta İçi Ortalama (Pzt–Cum)',
              value: kg(weekdayWeekend.weekdayAvg),
            ),
            Divider(color: c.cardBorder, height: 14),
            _GoalDetailRow(
              icon: Icons.weekend_outlined,
              label: 'Hafta Sonu Ortalama (Cmt–Paz)',
              value: weekdayWeekend.weekendAvg == null
                  ? '—'
                  : '${kg(weekdayWeekend.weekendAvg)} (${delta(weekdayWeekend.weekendVsWeekdayDiff, empty: "0.0 kg")})',
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),

      // 4. Özet ve Etiket Etki Raporu Bölümü (Özellik 15)
      AppCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: c.primarySoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.article_outlined,
                    color: c.primaryBlue,
                    size: 19,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Özet & Etiket Etkileri',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: c.heading,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (summaryMessages.isEmpty && tagImpacts.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: c.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Seçilen döneme ait kayıt bulunmuyor.',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: c.subtitle,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )
            else ...[
              for (final (idx, msg) in summaryMessages.indexed) ...[
                if (idx > 0) const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: c.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: msg.$2,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(msg.$1, size: 16, color: msg.$3),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          msg.$4,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: c.heading,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (tagImpacts.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Etiket Bazlı Ertesi Gün Etkisi',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: c.subtitle,
                  ),
                ),
                const SizedBox(height: 6),
                for (final impact in tagImpacts) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: c.background,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: c.cardBorder),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${impact.tag} (${impact.count} gün)',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: c.heading,
                              ),
                            ),
                          ),
                          Text(
                            impact.avgNextMorningChange == null
                                ? 'Ertesi gün verisi bekleniyor'
                                : 'Ertesi sabah ort: ${delta(impact.avgNextMorningChange)}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: (impact.avgNextMorningChange ?? 0) <= 0
                                  ? c.greenText
                                  : c.orangeText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ],
          ],
        ),
      ),
    ]);
  }
}

class _MiniBodyChip extends StatelessWidget {
  const _MiniBodyChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: c.primarySoft,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: c.primaryBlue,
        ),
      ),
    );
  }
}

class _ReportMetricCard extends StatelessWidget {
  const _ReportMetricCard({
    required this.title,
    required this.value,
    required this.icon,
    this.surfaceColor,
    this.borderColor,
    this.iconColor,
    this.valueColor,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color? surfaceColor;
  final Color? borderColor;
  final Color? iconColor;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      borderRadius: 16,
      color: surfaceColor,
      borderColor: borderColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: iconColor ?? c.primaryBlue),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: c.heading,
                    height: 1.15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: valueColor ?? c.heading,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalDetailRow extends StatelessWidget {
  const _GoalDetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        Icon(icon, size: 18, color: c.primaryBlue),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: c.subtitle,
            ),
          ),
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: valueColor ?? c.heading,
            ),
          ),
        ),
      ],
    );
  }
}
