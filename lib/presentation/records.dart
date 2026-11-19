import 'package:flutter/material.dart' hide Text;

import '../app/app_theme.dart';
import '../domain/measurements.dart';
import '../services/reminders.dart';
import 'charts.dart';
import 'common.dart';

typedef OpenEditor = void Function(DateTime day, Slot slot);
typedef DeleteEntries = void Function(List<Measurement> entries);

class Dashboard extends StatelessWidget {
  const Dashboard(
    this.stats,
    this.today,
    this.times,
    this.open, {
    this.onNavigateToCharts,
    this.settings,
    this.onQuickSaveLastWeight,
    this.onSnoozeReminder,
    super.key,
  });

  final Statistics stats;
  final DateTime today;
  final Map<Slot, TimeOfDay> times;
  final OpenEditor open;
  final VoidCallback? onNavigateToCharts;
  final AppSettings? settings;
  final ValueChanged<Slot>? onQuickSaveLastWeight;
  final ValueChanged<Slot>? onSnoozeReminder;

  Slot _defaultSlotForAdd() {
    final dayValues = stats.days[today];
    if (dayValues?.morning == null) return Slot.morning;
    if (dayValues?.evening == null) return Slot.evening;
    return DateTime.now().hour < 15 ? Slot.morning : Slot.evening;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final todayData = stats.days[today];
    final morning = todayData?.morning;
    final evening = todayData?.evening;
    final diff = todayData?.difference;

    final last7Entries = stats.lastDays(today, 7);
    final last7Change = stats.comparableChange(last7Entries);
    final last7Average = stats.averageOf(last7Entries);
    final miniSeries = stats.miniChartSeries(today);
    final miniSlot = miniSeries.firstOrNull?.slot ?? Slot.morning;
    final streak = stats.streakInfo(today);
    final defaultSlot = _defaultSlotForAdd();
    final lastKnownWeight = stats.latestMeasurement?.kg;
    final missingDefaultSlot = todayData?.values[defaultSlot] == null;

    return PageBody([
      // Karşılama alanı + 10. Seri (Streak) Rozeti
      Padding(
        padding: const EdgeInsets.fromLTRB(2, 2, 2, 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bugünkü Takibin',
                    style: TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w800,
                      color: c.heading,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Sabah ve akşam kilonu kolayca takip et.',
                    style: TextStyle(
                      fontSize: 13.5,
                      color: c.subtitle,
                    ),
                  ),
                  if (streak.current > 0 || streak.best > 0) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: c.orangeSurface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: c.orangeBorder),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.local_fire_department_rounded,
                            size: 16,
                            color: c.orangeText,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              '${streak.current} Günlük Seri • Rekor: ${streak.best} gün',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: c.orangeText,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            const ScaleIllustration(size: 66),
          ],
        ),
      ),

      // Hiç kayıt yoksa yönlendirici mesaj
      if (stats.all.isEmpty) ...[
        const Note(
          'Henüz kilo kaydın bulunmuyor. İlk ölçümünü ekleyerek başlayabilirsin.',
        ),
        const SizedBox(height: 12),
      ],

      // Günlük Kilo Kartı
      AppCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Tarih başlığı ve Bugün rozeti
            Row(
              children: [
                Icon(
                  Icons.calendar_month_rounded,
                  color: c.primaryBlue,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    formatTurkishDateWithWeekday(today),
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      color: c.heading,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: c.primarySoft,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    'Bugün',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: c.primaryBlue,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Sabah Kilosu ve Akşam Kilosu Kartları
            Row(
              children: [
                Expanded(
                  child: _DailySlotCard(
                    slot: Slot.morning,
                    title: 'Sabah Kilosu',
                    measurement: morning,
                    emptyText: 'Sabah kilosu eklenmedi.',
                    onTap: () => open(today, Slot.morning),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _DailySlotCard(
                    slot: Slot.evening,
                    title: 'Akşam Kilosu',
                    measurement: evening,
                    emptyText: 'Akşam kilosu eklenmedi.',
                    onTap: () => open(today, Slot.evening),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Günlük Fark Alanı
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: diff == null
                    ? c.background
                    : (diff <= 0 ? c.greenSurface : c.orangeSurface),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: diff == null
                      ? c.cardBorder
                      : (diff <= 0 ? c.greenBorder : c.orangeBorder),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: diff == null
                          ? c.cardBorder
                          : (diff <= 0
                                ? c.greenText.withValues(alpha: 0.15)
                                : c.orangeText.withValues(alpha: 0.15)),
                    ),
                    child: Icon(
                      diff == null
                          ? Icons.swap_horiz_rounded
                          : (diff <= 0
                                ? Icons.arrow_downward_rounded
                                : Icons.arrow_upward_rounded),
                      size: 16,
                      color: diff == null
                          ? c.subtitle
                          : (diff <= 0 ? c.greenText : c.orangeText),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Günlük Fark',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: c.heading,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      diff == null
                          ? 'Henüz hesaplanamadı.'
                          : delta(diff),
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: diff == null ? 12.5 : 18,
                        fontWeight: diff == null
                            ? FontWeight.w600
                            : FontWeight.w800,
                        color: diff == null
                            ? c.subtitle
                            : (diff < 0
                                  ? c.greenText
                                  : diff > 0
                                  ? c.orangeText
                                  : c.heading),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (todayData?.waistCm != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: c.background,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: c.cardBorder),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: c.primarySoft,
                      ),
                      child: Icon(
                        Icons.straighten_rounded,
                        size: 16,
                        color: c.primaryBlue,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Günün Bel Ölçüsü',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: c.heading,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${todayData!.waistCm!.toStringAsFixed(1)} cm',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: c.primaryBlue,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      const SizedBox(height: 12),

      // Kısa İstatistikler (Son 7 Gün, Haftalık Ortalama, Toplam Kayıt)
      Row(
        children: [
          Expanded(
            child: _QuickStatCard(
              icon: Icons.calendar_today_rounded,
              label: 'Son 7 Gün',
              value: delta(last7Change.change, empty: '—'),
              valueColor: last7Change.change == null
                  ? c.heading
                  : (last7Change.change! < 0
                        ? c.greenText
                        : last7Change.change! > 0
                        ? c.orangeText
                        : c.heading),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _QuickStatCard(
              icon: Icons.bar_chart_rounded,
              label: 'Haftalık Ortalama',
              value: kg(last7Average),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _QuickStatCard(
              icon: Icons.layers_outlined,
              label: 'Toplam Kayıt',
              value: '${stats.all.length}',
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),

      // 14. Günlük Su Tüketimi Takibi Kartı
      if (settings != null) ...[
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: c.primarySoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.water_drop_rounded,
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
                      'Günlük Su Tüketimi',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: c.heading,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${settings!.waterGlassesFor(today)} Bardak (${settings!.waterLitersFor(today).toStringAsFixed(2)} L / Hedef 2.50 L)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: c.subtitle,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: trText('-1 Bardak'),
                visualDensity: VisualDensity.compact,
                onPressed: settings!.waterGlassesFor(today) <= 0
                    ? null
                    : () => settings!.setWaterGlasses(
                        today,
                        settings!.waterGlassesFor(today) - 1,
                      ),
                icon: const Icon(Icons.remove_circle_outline_rounded),
              ),
              FilledButton.tonalIcon(
                onPressed: () => settings!.setWaterGlasses(
                  today,
                  settings!.waterGlassesFor(today) + 1,
                ),
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                ),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text(
                  '250 ml',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
      ],

      // Mini Grafik Kartı
      AppCard(
        padding: const EdgeInsets.all(16),
        onTap: onNavigateToCharts,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: c.primarySoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.show_chart_rounded,
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
                        'Mini Grafik',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: c.heading,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Son 7 günün kilo değişimi',
                        style: TextStyle(fontSize: 12, color: c.subtitle),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: c.primarySoft,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    '7 Gün',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: c.primaryBlue,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            WeightLineChartContent(
              entries: miniSeries,
              slots: {miniSlot},
              height: 150,
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),

      // 8. Hızlı Aksiyonlar: Son Kiloyu Tek Tuşla Kaydet & 1 Saat Sonra Hatırlat
      if (missingDefaultSlot &&
          (onQuickSaveLastWeight != null || onSnoozeReminder != null)) ...[
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (lastKnownWeight != null && onQuickSaveLastWeight != null)
              ActionChip(
                avatar: Icon(
                  Icons.bolt_rounded,
                  size: 17,
                  color: c.primaryBlue,
                ),
                label: Text(
                  '${defaultSlot.label}: ${trText('Son Kiloyu Kaydet')} (${kg(lastKnownWeight)})',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: c.primaryBlue,
                  ),
                ),
                backgroundColor: c.primarySoft,
                side: BorderSide(color: c.morningBorder),
                onPressed: () => onQuickSaveLastWeight!(defaultSlot),
              ),
            if (onSnoozeReminder != null)
              ActionChip(
                avatar: Icon(
                  Icons.snooze_rounded,
                  size: 16,
                  color: c.subtitle,
                ),
                label: Text(
                  trText('1 Saat Sonra Hatırlat'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: c.heading,
                  ),
                ),
                backgroundColor: c.cardSurface,
                side: BorderSide(color: c.cardBorder),
                onPressed: () => onSnoozeReminder!(defaultSlot),
              ),
          ],
        ),
        const SizedBox(height: 12),
      ],

      // + Kilo Ekle Butonu
      SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          key: const Key('home_add_weight_button'),
          onPressed: () => open(today, _defaultSlotForAdd()),
          icon: const Icon(Icons.add_rounded, size: 22),
          label: Text(
            trText('Kilo Ekle'),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: c.primaryBlue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    ]);
  }
}

class _DailySlotCard extends StatelessWidget {
  const _DailySlotCard({
    required this.slot,
    required this.title,
    required this.measurement,
    required this.emptyText,
    required this.onTap,
  });

  final Slot slot;
  final String title;
  final Measurement? measurement;
  final String emptyText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: c.slotSurface(slot),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: c.slotBorder(slot)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SlotIcon(slot, size: 19),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: c.heading,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: c.subtitle,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (measurement != null) ...[
                Text(
                  kg(measurement!.kg),
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: c.heading,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Saat ${measurement!.timeLabel}',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: c.subtitle,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ] else ...[
                Text(
                  emptyText,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: c.subtitle,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Kilo Gir',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: c.slotAccent(slot),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickStatCard extends StatelessWidget {
  const _QuickStatCard({
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
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      borderRadius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: c.primaryBlue),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: c.subtitle,
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

enum HistoryFilter { all, morningOnly, eveningOnly }

class HistoryPage extends StatefulWidget {
  const HistoryPage(
    this.stats,
    this.today,
    this.open,
    this.deleteEntries, {
    super.key,
  });

  final Statistics stats;
  final DateTime today;
  final OpenEditor open;
  final DeleteEntries deleteEntries;

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  late DateTime month = monthOf(
    widget.stats.latestMeasurement?.day ?? widget.today,
  );
  DateTime? selectedDay;
  HistoryFilter filter = HistoryFilter.all;
  bool searching = false;
  final TextEditingController searchController = TextEditingController();

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  List<DateTime> _filteredDays() {
    final allDaysDesc = widget.stats.days.keys.toList().reversed.toList();
    final query = searchController.text.trim().toLowerCase();

    return allDaysDesc.where((date) {
      if (selectedDay != null && date != selectedDay) return false;
      final dayData = widget.stats.days[date]!;
      final matchesSlot = switch (filter) {
        HistoryFilter.all =>
          dayData.morning != null || dayData.evening != null,
        HistoryFilter.morningOnly => dayData.morning != null,
        HistoryFilter.eveningOnly => dayData.evening != null,
      };
      if (!matchesSlot) return false;
      if (query.isEmpty) return true;

      final dateText = formatTurkishDateWithWeekday(date).toLowerCase();
      final shortText = shortDate.format(date).toLowerCase();
      final noteText = (dayData.combinedNote ?? '').toLowerCase();
      return dateText.contains(query) ||
          shortText.contains(query) ||
          noteText.contains(query);
    }).toList();
  }

  void _onEditDay(DayMeasurements dayData) {
    if (filter == HistoryFilter.eveningOnly) {
      widget.open(dayData.day, Slot.evening);
      return;
    }
    if (filter == HistoryFilter.morningOnly) {
      widget.open(dayData.day, Slot.morning);
      return;
    }
    final initialSlot =
        dayData.morning != null ? Slot.morning : Slot.evening;
    widget.open(dayData.day, initialSlot);
  }

  Future<void> _onDeleteDay(DayMeasurements dayData) async {
    final morning = dayData.morning;
    final evening = dayData.evening;

    if (filter == HistoryFilter.morningOnly && morning != null) {
      widget.deleteEntries([morning]);
      return;
    }
    if (filter == HistoryFilter.eveningOnly && evening != null) {
      widget.deleteEntries([evening]);
      return;
    }
    if (morning != null && evening == null) {
      widget.deleteEntries([morning]);
      return;
    }
    if (evening != null && morning == null) {
      widget.deleteEntries([evening]);
      return;
    }
    if (morning != null && evening != null) {
      final selection = await showDialog<List<Measurement>>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Hangi ölçüm silinsin?'),
          content: Text(
            '${formatTurkishDate(dayData.day)} tarihinde hem sabah hem akşam kaydı bulunuyor. Silmek istediğin ölçümü seç:',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Vazgeç'),
            ),
            OutlinedButton(
              onPressed: () => Navigator.pop(ctx, [morning]),
              child: Text('Sabah (${kg(morning.kg)})'),
            ),
            OutlinedButton(
              onPressed: () => Navigator.pop(ctx, [evening]),
              child: Text('Akşam (${kg(evening.kg)})'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, [morning, evening]),
              child: const Text('Tüm Günü Sil (2 Kayıt)'),
            ),
          ],
        ),
      );
      if (selection != null && selection.isNotEmpty && mounted) {
        widget.deleteEntries(selection);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final thisMonthCount = widget.stats
        .forMonth(widget.today.year, widget.today.month)
        .length;
    final visibleDays = _filteredDays();

    return PageBody([
      // 1. Özet Kartları (Toplam Kayıt ve Bu Ay)
      AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.layers_outlined,
                      color: c.primaryBlue,
                      size: 26,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Toplam Kayıt',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: c.subtitle,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${widget.stats.all.length}',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: c.heading,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              VerticalDivider(color: c.cardBorder, width: 24, thickness: 1),
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_month_rounded,
                      color: c.primaryBlue,
                      size: 26,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bu Ay',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: c.subtitle,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$thisMonthCount Kayıt',
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              color: c.heading,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 12),

      // 2. Takvim Alanı
      _HistoryCalendarCard(
        month: month,
        today: widget.today,
        selectedDay: selectedDay,
        stats: widget.stats,
        onPreviousMonth: () => setState(() {
          month = DateTime(month.year, month.month - 1);
          selectedDay = null;
        }),
        onNextMonth: DateTime(month.year, month.month + 1).isAfter(widget.today)
            ? null
            : () => setState(() {
                month = DateTime(month.year, month.month + 1);
                selectedDay = null;
              }),
        onDayTapped: (day) => setState(() {
          selectedDay = selectedDay == day ? null : day;
        }),
        onClearSelectedDay: () => setState(() => selectedDay = null),
      ),
      const SizedBox(height: 12),

      // 3. Kayıt Filtreleri (Tümü, Sadece Sabah, Sadece Akşam + Arama)
      Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChipButton(
                    label: 'Tümü',
                    active: filter == HistoryFilter.all,
                    onTap: () => setState(() => filter = HistoryFilter.all),
                  ),
                  const SizedBox(width: 8),
                  _FilterChipButton(
                    label: 'Sadece Sabah',
                    icon: Icons.wb_twilight_rounded,
                    iconColor: c.morningAccent,
                    active: filter == HistoryFilter.morningOnly,
                    onTap: () =>
                        setState(() => filter = HistoryFilter.morningOnly),
                  ),
                  const SizedBox(width: 8),
                  _FilterChipButton(
                    label: 'Sadece Akşam',
                    icon: Icons.dark_mode_outlined,
                    iconColor: c.eveningAccent,
                    active: filter == HistoryFilter.eveningOnly,
                    onTap: () =>
                        setState(() => filter = HistoryFilter.eveningOnly),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: searching ? c.primaryBlue : c.cardSurface,
            shape: CircleBorder(side: BorderSide(color: c.cardBorder)),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => setState(() {
                searching = !searching;
                if (!searching) searchController.clear();
              }),
              child: Padding(
                padding: const EdgeInsets.all(9),
                child: Icon(
                  searching ? Icons.close_rounded : Icons.search_rounded,
                  size: 20,
                  color: searching ? Colors.white : c.heading,
                ),
              ),
            ),
          ),
        ],
      ),

      if (searching) ...[
        const SizedBox(height: 10),
        TextField(
          controller: searchController,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: trText('Tarih veya not içinde ara…'),
            prefixIcon: const Icon(Icons.search_rounded),
          ),
        ),
      ],
      const SizedBox(height: 12),

      // 4. Geçmiş Kayıt Satırları
      if (widget.stats.all.isEmpty)
        const Note('Henüz kilo kaydın bulunmuyor.')
      else if (visibleDays.isEmpty)
        AppCard(
          child: Column(
            children: [
              Text(
                'Bu tarihe ait kilo kaydı bulunamadı.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: c.subtitle,
                ),
              ),
              if (selectedDay != null) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: [
                    OutlinedButton(
                      onPressed: () => setState(() => selectedDay = null),
                      child: const Text('Tüm Kayıtları Göster'),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: () =>
                          widget.open(selectedDay!, Slot.morning),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Bu Güne Kayıt Ekle'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        )
      else
        for (final (idx, dayDate) in visibleDays.indexed) ...[
          if (idx > 0) const SizedBox(height: 10),
          _HistoryDayRowCard(
            dayData: widget.stats.days[dayDate]!,
            filter: filter,
            onTapSlot: (slot) => widget.open(dayDate, slot),
            onEdit: () => _onEditDay(widget.stats.days[dayDate]!),
            onDelete: () => _onDeleteDay(widget.stats.days[dayDate]!),
          ),
        ],
    ]);
  }
}

class _HistoryCalendarCard extends StatelessWidget {
  const _HistoryCalendarCard({
    required this.month,
    required this.today,
    required this.selectedDay,
    required this.stats,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onDayTapped,
    required this.onClearSelectedDay,
  });

  final DateTime month;
  final DateTime today;
  final DateTime? selectedDay;
  final Statistics stats;
  final VoidCallback onPreviousMonth;
  final VoidCallback? onNextMonth;
  final ValueChanged<DateTime> onDayTapped;
  final VoidCallback onClearSelectedDay;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final start = weekOf(month);
    final monthEnd = DateTime(month.year, month.month + 1);

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          // Ay başlığı ve ileri/geri butonları
          Row(
            children: [
              Icon(
                Icons.calendar_month_rounded,
                color: c.primaryBlue,
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  formatMonthYear(month),
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: c.heading,
                  ),
                ),
              ),
              if (selectedDay != null) ...[
                TextButton(
                  onPressed: onClearSelectedDay,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: const Text('Tüm Günler'),
                ),
                const SizedBox(width: 4),
              ],
              _SmallNavButton(
                icon: Icons.chevron_left_rounded,
                tooltip: trText('Önceki ay'),
                onTap: onPreviousMonth,
              ),
              const SizedBox(width: 6),
              _SmallNavButton(
                icon: Icons.chevron_right_rounded,
                tooltip: trText('Sonraki ay'),
                onTap: onNextMonth,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Türkçe gün başlıkları: Pzt, Sal, Çar, Per, Cum, Cmt, Paz
          Row(
            children: [
              for (final label in turkishShortWeekdays)
                Expanded(
                  child: Center(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: c.subtitle,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // Takvim günleri (doğru hafta-gün eşleşmesiyle)
          for (
            var week = 0;
            week < 6 && shiftDay(start, week * 7).isBefore(monthEnd);
            week++
          )
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  for (var i = 0; i < 7; i++)
                    Expanded(
                      child: _buildDayCell(
                        context,
                        shiftDay(start, week * 7 + i),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDayCell(BuildContext context, DateTime day) {
    final c = context.colors;
    if (day.month != month.month) {
      return const SizedBox(height: 54);
    }
    final dayData = stats.days[day];
    final hasRecord = dayData != null;
    final isSelected = selectedDay == day;
    final isFuture = day.isAfter(today);
    final repWeight = dayData?.representativeWeight;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: isSelected
            ? c.primaryBlue
            : (hasRecord ? c.primarySoft.withValues(alpha: 0.65) : Colors.transparent),
        borderRadius: BorderRadius.circular(11),
        child: InkWell(
          borderRadius: BorderRadius.circular(11),
          onTap: isFuture ? null : () => onDayTapped(day),
          child: SizedBox(
            height: 54,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${day.day}',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: isSelected
                        ? Colors.white
                        : isFuture
                        ? c.subtitle.withValues(alpha: 0.4)
                        : c.heading,
                  ),
                ),
                if (repWeight != null) ...[
                  const SizedBox(height: 1),
                  Text(
                    formatWeightValue(repWeight),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.9)
                          : c.subtitle,
                    ),
                  ),
                ],
                if (hasRecord) ...[
                  const SizedBox(height: 2),
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? Colors.white : c.greenText,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SmallNavButton extends StatelessWidget {
  const _SmallNavButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: c.primarySoft,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(
            icon,
            size: 20,
            color: onTap == null
                ? c.subtitle.withValues(alpha: 0.35)
                : c.primaryBlue,
          ),
        ),
      ),
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  const _FilterChipButton({
    required this.label,
    required this.active,
    required this.onTap,
    this.icon,
    this.iconColor,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;
  final IconData? icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: active ? c.primarySoft : c.cardSurface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: active ? c.primaryBlue.withValues(alpha: 0.4) : c.cardBorder,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 16,
                  color: active ? c.primaryBlue : (iconColor ?? c.subtitle),
                ),
                const SizedBox(width: 5),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                  color: active ? c.primaryBlue : c.heading,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryDayRowCard extends StatelessWidget {
  const _HistoryDayRowCard({
    required this.dayData,
    required this.filter,
    required this.onTapSlot,
    required this.onEdit,
    required this.onDelete,
  });

  final DayMeasurements dayData;
  final HistoryFilter filter;
  final ValueChanged<Slot> onTapSlot;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final morning = dayData.morning;
    final evening = dayData.evening;
    final diff = dayData.difference;
    final note = dayData.combinedNote;

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      borderRadius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: 18,
                color: c.primaryBlue,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formatTurkishDate(dayData.day),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: c.heading,
                      ),
                    ),
                    Text(
                      turkishWeekdays[dayData.day.weekday - 1],
                      style: TextStyle(
                        fontSize: 11.5,
                        color: c.subtitle,
                      ),
                    ),
                  ],
                ),
              ),
              if (dayData.waistCm != null) ...[
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3.5,
                  ),
                  decoration: BoxDecoration(
                    color: c.primarySoft,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: c.primaryBlue.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.straighten_rounded,
                        size: 13,
                        color: c.primaryBlue,
                      ),
                      const SizedBox(width: 3.5),
                      Text(
                        '${dayData.waistCm!.toStringAsFixed(1)} cm',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: c.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              IconButton(
                tooltip: trText('Düzenle'),
                visualDensity: VisualDensity.compact,
                onPressed: onEdit,
                icon: Icon(
                  Icons.edit_outlined,
                  size: 20,
                  color: c.primaryBlue,
                ),
              ),
              IconButton(
                tooltip: trText('Sil'),
                visualDensity: VisualDensity.compact,
                onPressed: onDelete,
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  size: 20,
                  color: Color(0xFFDC2626),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              if (filter != HistoryFilter.eveningOnly)
                Expanded(
                  child: _MiniMeasurementPill(
                    slot: Slot.morning,
                    measurement: morning,
                    onTap: () => onTapSlot(Slot.morning),
                  ),
                ),
              if (filter == HistoryFilter.all) const SizedBox(width: 6),
              if (filter != HistoryFilter.morningOnly)
                Expanded(
                  child: _MiniMeasurementPill(
                    slot: Slot.evening,
                    measurement: evening,
                    onTap: () => onTapSlot(Slot.evening),
                  ),
                ),
              if (filter == HistoryFilter.all && diff != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: diff <= 0 ? c.greenSurface : c.orangeSurface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            diff <= 0
                                ? Icons.arrow_downward_rounded
                                : Icons.arrow_upward_rounded,
                            size: 12,
                            color: diff <= 0 ? c.greenText : c.orangeText,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            'Fark',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: c.subtitle,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        delta(diff),
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: diff < 0
                              ? c.greenText
                              : diff > 0
                              ? c.orangeText
                              : c.heading,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          if (note != null) ...[
            const SizedBox(height: 8),
            if (extractTagsFromNote(note).isNotEmpty) ...[
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  for (final tag in extractTagsFromNote(note))
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: c.primarySoft,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: c.primaryBlue,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 5),
            ],
            Row(
              children: [
                Icon(Icons.notes_rounded, size: 14, color: c.subtitle),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    note,
                    style: TextStyle(
                      fontSize: 12,
                      color: c.subtitle,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _MiniMeasurementPill extends StatelessWidget {
  const _MiniMeasurementPill({
    required this.slot,
    required this.measurement,
    required this.onTap,
  });

  final Slot slot;
  final Measurement? measurement;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: c.slotSurface(slot),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SlotIcon(slot, size: 13),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      slot.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: c.subtitle,
                      ),
                    ),
                  ),
                  if (measurement != null) ...[
                    const SizedBox(width: 4),
                    Text(
                      measurement!.timeLabel,
                      style: TextStyle(
                        fontSize: 10,
                        color: c.subtitle,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(
                measurement == null ? '—' : kg(measurement!.kg),
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: measurement == null ? c.subtitle : c.heading,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
