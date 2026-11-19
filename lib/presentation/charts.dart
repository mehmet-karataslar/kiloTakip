import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart' hide Text;

import '../app/app_theme.dart';
import '../domain/measurements.dart';
import 'common.dart';

Color slotColor(BuildContext context, Slot slot) =>
    context.colors.slotAccent(slot);

int dayIndex(DateTime date) =>
    DateTime.utc(date.year, date.month, date.day).millisecondsSinceEpoch ~/
    Duration.millisecondsPerDay;

DateTime chartDate(double index) => DateTime.fromMillisecondsSinceEpoch(
  index.round() * Duration.millisecondsPerDay,
  isUtc: true,
);

enum ChartRange { days7, days14, monthly, allTime }

enum ChartSeriesMode { morning, evening, compare }

/// Ana Sayfadaki "Mini Grafik" ve Grafikler sayfasındaki "Kilo Değişim Grafiği" için
/// referans tasarıma birebir uyumlu çizgi grafik bileşeni.
class WeightLineChartContent extends StatelessWidget {
  const WeightLineChartContent({
    required this.entries,
    required this.slots,
    this.height = 200,
    this.showTrendLine = false,
    this.targetWeight,
    this.maintenanceBandTolerance,
    super.key,
  });

  final List<Measurement> entries;
  final Set<Slot> slots;
  final double height;
  final bool showTrendLine;
  final double? targetWeight;
  final double? maintenanceBandTolerance;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final data = entries.where((m) => slots.contains(m.slot)).toList();
    if (data.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            'Grafik oluşturmak için daha fazla kayıt eklemelisin.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13.5, color: c.subtitle),
          ),
        ),
      );
    }

    final first = dayIndex(data.first.day).toDouble();
    final last = dayIndex(data.last.day).toDouble();
    final minVal = data.map((m) => m.kg).reduce(math.min);
    final maxVal = data.map((m) => m.kg).reduce(math.max);
    final span = math.max(1.0, maxVal - minVal);
    final pad = math.max(0.5, span * 0.22);
    final minY = ((minVal - pad) * 2).floorToDouble() / 2;
    final maxY = ((maxVal + pad) * 2).ceilToDouble() / 2;
    final yInterval = math.max(0.5, ((maxY - minY) / 4 * 2).roundToDouble() / 2);

    final drawnSlots = [
      for (final s in Slot.values)
        if (slots.contains(s) && data.any((m) => m.slot == s)) s,
    ];

    final trendPoints = showTrendLine
        ? Statistics(data).movingAverageSeries(data, windowDays: 7)
        : const <(DateTime, double)>[];

    final hasTargetInView =
        targetWeight != null &&
        targetWeight! >= minY - 2 &&
        targetWeight! <= maxY + 2;

    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          minX: first == last ? first - 1 : first,
          maxX: first == last ? last + 1 : last,
          minY: minY,
          maxY: maxY,
          clipData: const FlClipData.none(),
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              if (hasTargetInView)
                HorizontalLine(
                  y: targetWeight!,
                  color: c.greenText.withValues(alpha: 0.7),
                  strokeWidth: 1.5,
                  dashArray: [6, 4],
                  label: HorizontalLineLabel(
                    show: true,
                    alignment: Alignment.topRight,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: c.greenText,
                    ),
                    labelResolver: (_) =>
                        trText('Hedef ${formatWeightValue(targetWeight!)}'),
                  ),
                ),
            ],
          ),
          rangeAnnotations: RangeAnnotations(
            horizontalRangeAnnotations: [
              if (hasTargetInView && maintenanceBandTolerance != null)
                HorizontalRangeAnnotation(
                  y1: math.max(minY, targetWeight! - maintenanceBandTolerance!),
                  y2: math.min(maxY, targetWeight! + maintenanceBandTolerance!),
                  color: c.greenSurface.withValues(alpha: 0.45),
                ),
            ],
          ),
          borderData: FlBorderData(
            show: true,
            border: Border(
              bottom: BorderSide(color: c.cardBorder),
              left: BorderSide(color: c.cardBorder),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: yInterval,
            getDrawingHorizontalLine: (_) => FlLine(
              color: c.cardBorder.withValues(alpha: 0.8),
              strokeWidth: 1,
              dashArray: [4, 4],
            ),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 44,
                interval: yInterval,
                getTitlesWidget: (value, meta) => Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Text(
                    value.toStringAsFixed(1),
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 11,
                      color: c.subtitle,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: math.max(
                  1,
                  ((last - first) / 6).ceilToDouble(),
                ),
                getTitlesWidget: (value, meta) {
                  if (value < first || value > last) {
                    return const SizedBox.shrink();
                  }
                  if (value == last &&
                      first != last &&
                      (last - first) % meta.appliedInterval != 0 &&
                      (last - first) % meta.appliedInterval <
                          meta.appliedInterval * 0.5) {
                    return const SizedBox.shrink();
                  }
                  final day = chartDate(value);
                  return SideTitleWidget(
                    meta: meta,
                    fitInside: SideTitleFitInsideData.fromTitleMeta(meta),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        formatShortDayMonth(day),
                        style: TextStyle(
                          fontSize: 10.5,
                          color: c.subtitle,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          lineBarsData: [
            for (final slot in drawnSlots)
              _buildLineBar(
                context,
                slot,
                data.where((m) => m.slot == slot).toList(),
              ),
            if (trendPoints.length >= 2)
              LineChartBarData(
                spots: [
                  for (final pt in trendPoints)
                    FlSpot(dayIndex(pt.$1).toDouble(), pt.$2),
                ],
                isCurved: true,
                curveSmoothness: 0.3,
                preventCurveOverShooting: true,
                color: c.greenText,
                barWidth: 2.2,
                dashArray: [6, 4],
                dotData: const FlDotData(show: false),
              ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              fitInsideHorizontally: true,
              fitInsideVertically: true,
              getTooltipColor: (_) => const Color(0xFF0E2547),
              getTooltipItems: (spots) => [
                for (final spot in spots)
                  LineTooltipItem(
                    spot.barIndex < drawnSlots.length
                        ? '${formatShortDayMonth(chartDate(spot.x))} • ${drawnSlots[spot.barIndex].label}\n${kg(spot.y)}'
                        : '${formatShortDayMonth(chartDate(spot.x))} • ${trText("7G Trend")}\n${kg(spot.y)}',
                    const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ),
        ),
        duration: Duration.zero,
      ),
    );
  }

  LineChartBarData _buildLineBar(
    BuildContext context,
    Slot slot,
    List<Measurement> seriesData,
  ) {
    final c = context.colors;
    final lineColor = c.slotAccent(slot);
    // Çok sayıda kayıt varsa (örn. Tüm Zamanlar > 80 nokta) görsel akıcılık için örnekleme
    final displayPoints = seriesData.length <= 80
        ? seriesData
        : [
            for (var i = 0; i < seriesData.length; i++)
              if (i == 0 ||
                  i == seriesData.length - 1 ||
                  i % ((seriesData.length / 60).ceil()) == 0)
                seriesData[i],
          ];

    return LineChartBarData(
      spots: [
        for (final entry in displayPoints)
          FlSpot(dayIndex(entry.day).toDouble(), entry.kg),
      ],
      isCurved: true,
      curveSmoothness: 0.22,
      preventCurveOverShooting: true,
      color: lineColor,
      barWidth: 2.8,
      dotData: FlDotData(
        show: displayPoints.length <= 35,
        getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
          radius: 4.2,
          color: c.cardSurface,
          strokeWidth: 2.5,
          strokeColor: lineColor,
        ),
      ),
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            lineColor.withValues(alpha: slot == Slot.morning ? 0.22 : 0.12),
            lineColor.withValues(alpha: 0.01),
          ],
        ),
      ),
    );
  }
}

/// Sabah – Akşam karşılaştırmalı sütun grafiği (Referans Ekran 2).
class MorningEveningComparisonChart extends StatelessWidget {
  const MorningEveningComparisonChart({
    required this.days,
    required this.slots,
    super.key,
  });

  final List<DayMeasurements> days;
  final Set<Slot> slots;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final filteredDays = days
        .where((d) => slots.any((s) => d.values[s] != null))
        .toList();

    if (filteredDays.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Text(
            'Grafik oluşturmak için daha fazla kayıt eklemelisin.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13.5, color: c.subtitle),
          ),
        ),
      );
    }

    // Görsel okunabilirlik için en son 7 kayıtlı günü (veya yatay kaydırılabilir tümünü) göster
    final visibleDays = filteredDays.length > 14
        ? filteredDays.sublist(filteredDays.length - 14)
        : filteredDays;

    final allWeights = [
      for (final d in visibleDays)
        for (final s in slots)
          if (d.values[s] case final m?) m.kg,
    ];
    final minVal = allWeights.reduce(math.min);
    final maxVal = allWeights.reduce(math.max);
    final minY = ((minVal - 1.2) * 2).floorToDouble() / 2;
    final maxY = ((maxVal + 1.0) * 2).ceilToDouble() / 2;

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = math.max(
          (constraints.maxWidth - 42) /
              math.max(1, math.min(visibleDays.length, 5)),
          86.0,
        );
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Sol Y Ekseni Etiketleri
            SizedBox(
              width: 42,
              height: 184,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var i = 0; i < 5; i++)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Text(
                        (maxY - (maxY - minY) * (i / 4)).toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 10,
                          color: c.subtitle,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            // Sütunlar
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: math.max(
                    constraints.maxWidth - 42,
                    visibleDays.length * itemWidth,
                  ),
                  height: 184,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      for (final day in visibleDays)
                        _DayBarPair(
                          day: day,
                          slots: slots,
                          minY: minY,
                          maxY: maxY,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DayBarPair extends StatelessWidget {
  const _DayBarPair({
    required this.day,
    required this.slots,
    required this.minY,
    required this.maxY,
  });

  final DayMeasurements day;
  final Set<Slot> slots;
  final double minY;
  final double maxY;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    const maxBarHeight = 112.0;
    final span = math.max(1.0, maxY - minY);

    double heightFor(double kgVal) =>
        (((kgVal - minY) / span).clamp(0.12, 1.0)) * maxBarHeight;

    final activeMeasurements = [
      for (final s in Slot.values)
        if (slots.contains(s) && day.values[s] != null) day.values[s]!,
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final (idx, m) in activeMeasurements.indexed) ...[
                if (idx > 0) const SizedBox(width: 3),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 36,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          formatWeightValue(m.kg),
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: c.heading,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Container(
                      width: activeMeasurements.length == 1 ? 22 : 16,
                      height: heightFor(m.kg),
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6),
                          bottom: Radius.circular(3),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: m.slot == Slot.morning
                              ? [
                                  c.morningAccent.withValues(alpha: 0.85),
                                  c.morningAccent.withValues(alpha: 0.45),
                                ]
                              : [
                                  c.eveningAccent.withValues(alpha: 0.85),
                                  c.eveningAccent.withValues(alpha: 0.45),
                                ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Text(
            formatShortDayMonth(day.day),
            style: TextStyle(
              fontSize: 10.5,
              color: c.subtitle,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class ChartsPage extends StatefulWidget {
  const ChartsPage(
    this.stats,
    this.today, {
    this.targetWeight,
    this.maintenanceBandTolerance,
    super.key,
  });
  final Statistics stats;
  final DateTime today;
  final double? targetWeight;
  final double? maintenanceBandTolerance;

  @override
  State<ChartsPage> createState() => _ChartsPageState();
}

class _ChartsPageState extends State<ChartsPage> {
  ChartRange range = ChartRange.days7;
  ChartSeriesMode seriesMode = ChartSeriesMode.compare;
  bool showTrendLine = true;
  late DateTime selectedMonth = monthOf(
    widget.stats.latestMeasurement?.day ?? widget.today,
  );

  Set<Slot> get activeSlots => switch (seriesMode) {
    ChartSeriesMode.morning => {Slot.morning},
    ChartSeriesMode.evening => {Slot.evening},
    ChartSeriesMode.compare => {Slot.morning, Slot.evening},
  };

  List<Measurement> _entriesForRange() => switch (range) {
    ChartRange.days7 => widget.stats.lastDays(widget.today, 7),
    ChartRange.days14 => widget.stats.lastDays(widget.today, 14),
    ChartRange.monthly => widget.stats.forMonth(
      selectedMonth.year,
      selectedMonth.month,
    ),
    ChartRange.allTime => widget.stats.all,
  };

  String get _rangeSubtitle => switch (range) {
    ChartRange.days7 => 'Son 7 günün sabah ve akşam kiloları',
    ChartRange.days14 => 'Son 14 günün sabah ve akşam kiloları',
    ChartRange.monthly =>
      '${formatMonthYear(selectedMonth)} sabah ve akşam kiloları',
    ChartRange.allTime => 'Tüm kayıtların sabah ve akşam kiloları',
  };

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final rawEntries = _entriesForRange();
    final filteredEntries = rawEntries
        .where((m) => activeSlots.contains(m.slot))
        .toList();
    final rangeStats = Statistics(rawEntries);
    final dayList = rangeStats.days.values.toList();

    final lowest = widget.stats.minOf(filteredEntries);
    final highest = widget.stats.maxOf(filteredEntries);
    final avg = widget.stats.averageOf(filteredEntries);
    final changeResult = widget.stats.comparableChange(
      rawEntries,
      slots: activeSlots,
    );

    return PageBody([
      // 1. Tarih Aralığı Seçimi (7 Gün, 14 Gün, Aylık, Tüm Zamanlar)
      PillSelector<ChartRange>(
        items: const [
          (ChartRange.days7, '7 Gün'),
          (ChartRange.days14, '14 Gün'),
          (ChartRange.monthly, 'Aylık'),
          (ChartRange.allTime, 'Tüm Zamanlar'),
        ],
        selected: range,
        onSelected: (value) => setState(() => range = value),
      ),
      if (range == ChartRange.monthly) ...[
        const SizedBox(height: 10),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            children: [
              IconButton(
                tooltip: 'Önceki Ay',
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.chevron_left_rounded),
                onPressed: () => setState(
                  () => selectedMonth = DateTime(
                    selectedMonth.year,
                    selectedMonth.month - 1,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  formatMonthYear(selectedMonth),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: c.heading,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Sonraki Ay',
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.chevron_right_rounded),
                onPressed:
                    DateTime(
                      selectedMonth.year,
                      selectedMonth.month + 1,
                    ).isAfter(widget.today)
                    ? null
                    : () => setState(
                        () => selectedMonth = DateTime(
                          selectedMonth.year,
                          selectedMonth.month + 1,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ],
      const SizedBox(height: 12),

      // 2. Grafik Türü Seçimi (Sabah, Akşam, Karşılaştır)
      AppCard(
        padding: const EdgeInsets.all(5),
        borderRadius: 16,
        child: Row(
          children: [
            _SeriesTabButton(
              label: 'Sabah',
              icon: Icons.wb_twilight_rounded,
              active: seriesMode == ChartSeriesMode.morning,
              onTap: () =>
                  setState(() => seriesMode = ChartSeriesMode.morning),
            ),
            _SeriesTabButton(
              label: 'Akşam',
              icon: Icons.dark_mode_outlined,
              active: seriesMode == ChartSeriesMode.evening,
              onTap: () =>
                  setState(() => seriesMode = ChartSeriesMode.evening),
            ),
            _SeriesTabButton(
              label: 'Karşılaştır',
              icon: Icons.compare_arrows_rounded,
              active: seriesMode == ChartSeriesMode.compare,
              onTap: () =>
                  setState(() => seriesMode = ChartSeriesMode.compare),
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),

      // 3. Kilo Değişim Grafiği (Çizgi Grafik)
      AppCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: c.primarySoft,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    Icons.trending_up_rounded,
                    color: c.primaryBlue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kilo Değişim Grafiği',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: c.heading,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        switch (seriesMode) {
                          ChartSeriesMode.morning => 'Sabah kilo değişimi',
                          ChartSeriesMode.evening => 'Akşam kilo değişimi',
                          ChartSeriesMode.compare =>
                            'Sabah ve akşam kilo değişimi',
                        },
                        style: TextStyle(fontSize: 12.5, color: c.subtitle),
                      ),
                    ],
                  ),
                ),
                // 1. 7 Günlük Hareketli Ortalama (Trend) Aç/Kapat Butonu
                FilterChip(
                  label: Text(
                    '7G Trend',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: showTrendLine ? c.greenText : c.subtitle,
                    ),
                  ),
                  selected: showTrendLine,
                  showCheckmark: false,
                  visualDensity: VisualDensity.compact,
                  backgroundColor: c.background,
                  selectedColor: c.greenSurface,
                  side: BorderSide(
                    color: showTrendLine ? c.greenBorder : c.cardBorder,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  onSelected: (v) => setState(() => showTrendLine = v),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Legend
            Wrap(
              spacing: 14,
              runSpacing: 6,
              children: [
                if (activeSlots.contains(Slot.morning))
                  _LegendItem(
                    label: 'Sabah Kilosu',
                    color: c.morningAccent,
                  ),
                if (activeSlots.contains(Slot.evening))
                  _LegendItem(
                    label: 'Akşam Kilosu',
                    color: c.eveningAccent,
                  ),
                if (showTrendLine)
                  _LegendItem(
                    label: '7G Ortalama Trendi',
                    color: c.greenText,
                  ),
              ],
            ),
            const SizedBox(height: 14),
            WeightLineChartContent(
              entries: rawEntries,
              slots: activeSlots,
              height: 185,
              showTrendLine: showTrendLine,
              targetWeight: widget.targetWeight,
              maintenanceBandTolerance: widget.maintenanceBandTolerance,
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),

      // 4. Sabah – Akşam Karşılaştırması (Gruplandırılmış Sütun Grafiği)
      AppCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: c.primarySoft,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    Icons.bar_chart_rounded,
                    color: c.primaryBlue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sabah - Akşam Karşılaştırması',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: c.heading,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _rangeSubtitle,
                        style: TextStyle(fontSize: 12.5, color: c.subtitle),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            MorningEveningComparisonChart(
              days: dayList,
              slots: activeSlots,
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),

      // 5. Alt İstatistikler (4 Kompakt Kart: En Düşük, En Yüksek, Ortalama, Toplam Değişim)
      Row(
        children: [
          Expanded(
            child: _ChartStatCard(
              label: 'En Düşük',
              value: kg(lowest),
              icon: Icons.arrow_downward_rounded,
              iconBg: c.morningSurface,
              iconColor: c.morningAccent,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _ChartStatCard(
              label: 'En Yüksek',
              value: kg(highest),
              icon: Icons.arrow_upward_rounded,
              iconBg: c.eveningSurface,
              iconColor: c.eveningAccent,
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),
      Row(
        children: [
          Expanded(
            child: _ChartStatCard(
              label: 'Ortalama',
              value: kg(avg),
              icon: Icons.bar_chart_rounded,
              iconBg: c.morningSurface,
              iconColor: c.morningAccent,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _ChartStatCard(
              label: 'Toplam Değişim',
              value: delta(changeResult.change, empty: '—'),
              subtitle: changeResult.usedSlot != null
                  ? '${changeResult.usedSlot!.label} serisi'
                  : null,
              icon: Icons.compare_arrows_rounded,
              iconBg: (changeResult.change ?? 0) <= 0
                  ? c.greenSurface
                  : c.orangeSurface,
              iconColor: (changeResult.change ?? 0) <= 0
                  ? c.greenText
                  : c.orangeText,
              valueColor: changeResult.change == null
                  ? c.heading
                  : (changeResult.change! < 0
                        ? c.greenText
                        : changeResult.change! > 0
                        ? c.orangeText
                        : c.heading),
            ),
          ),
        ],
      ),
    ]);
  }
}

class _SeriesTabButton extends StatelessWidget {
  const _SeriesTabButton({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Expanded(
      child: Material(
        color: active ? c.primaryBlue : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 17,
                  color: active ? Colors.white : c.subtitle,
                ),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                      color: active ? Colors.white : c.heading,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2.5),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: c.subtitle,
          ),
        ),
      ],
    );
  }
}

class _ChartStatCard extends StatelessWidget {
  const _ChartStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    this.valueColor,
    this.subtitle,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final Color? valueColor;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      borderRadius: 16,
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: c.subtitle,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: valueColor ?? c.heading,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 10.5, color: c.subtitle),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
