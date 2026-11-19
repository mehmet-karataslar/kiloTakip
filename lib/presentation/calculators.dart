import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart' hide Text;

import '../app/app_theme.dart';
import '../domain/measurements.dart';
import '../services/reminders.dart';
import 'common.dart';

class CalculatorsPage extends StatefulWidget {
  const CalculatorsPage(
    this.stats,
    this.settings, {
    super.key,
  });

  final Statistics stats;
  final AppSettings settings;

  @override
  State<CalculatorsPage> createState() => _CalculatorsPageState();
}

class _CalculatorsPageState extends State<CalculatorsPage> {
  late final TextEditingController weightCtrl;
  late final TextEditingController heightCtrl;
  late final TextEditingController ageCtrl;
  late final TextEditingController targetCtrl;
  late final TextEditingController waistCtrl;
  late final TextEditingController hipCtrl;
  late final TextEditingController neckCtrl;

  late bool isMale;
  late int activityLevel;
  bool showCircumferences = false;

  static const _activityLabels = [
    ('Hareketsiz', 'Masa başı iş, az hareket', 1.2),
    ('Hafif Aktif', 'Haftada 1-3 gün egzersiz', 1.375),
    ('Orta Aktif', 'Haftada 3-5 gün spor', 1.55),
    ('Çok Aktif', 'Haftada 6-7 gün yoğun spor', 1.725),
  ];

  @override
  void initState() {
    super.initState();
    final initialWeight =
        widget.stats.latestMeasurement?.kg ??
        widget.settings.startWeight ??
        85.0;
    final initialHeight = widget.settings.heightCm ?? 175.0;
    final initialTarget = widget.settings.targetWeight ?? 78.0;

    weightCtrl = TextEditingController(text: formatWeightValue(initialWeight));
    heightCtrl = TextEditingController(
      text: initialHeight.round().toString(),
    );
    ageCtrl = TextEditingController(text: widget.settings.age.toString());
    targetCtrl = TextEditingController(text: formatWeightValue(initialTarget));
    waistCtrl = TextEditingController(
      text: widget.settings.waistCm == null
          ? '88'
          : formatWeightValue(widget.settings.waistCm!),
    );
    hipCtrl = TextEditingController(
      text: widget.settings.hipCm == null
          ? '100'
          : formatWeightValue(widget.settings.hipCm!),
    );
    neckCtrl = TextEditingController(
      text: widget.settings.neckCm == null
          ? '38'
          : formatWeightValue(widget.settings.neckCm!),
    );
    isMale = widget.settings.isMale;
    activityLevel = widget.settings.activityLevel;
  }

  @override
  void dispose() {
    weightCtrl.dispose();
    heightCtrl.dispose();
    ageCtrl.dispose();
    targetCtrl.dispose();
    waistCtrl.dispose();
    hipCtrl.dispose();
    neckCtrl.dispose();
    super.dispose();
  }

  double get _weight =>
      parseWeight(weightCtrl.text) ??
      widget.stats.latestMeasurement?.kg ??
      85.0;

  double get _height =>
      (double.tryParse(heightCtrl.text.trim().replaceAll(',', '.')) ?? 175.0)
          .clamp(100.0, 240.0);

  int get _age =>
      (int.tryParse(ageCtrl.text.trim()) ?? widget.settings.age).clamp(10, 100);

  double get _targetWeight =>
      parseWeight(targetCtrl.text) ?? widget.settings.targetWeight ?? 78.0;

  double? get _waist {
    final v = double.tryParse(waistCtrl.text.trim().replaceAll(',', '.'));
    return (v != null && v >= 40 && v <= 220) ? v : null;
  }

  double? get _hip {
    final v = double.tryParse(hipCtrl.text.trim().replaceAll(',', '.'));
    return (v != null && v >= 50 && v <= 230) ? v : null;
  }

  double? get _neck {
    final v = double.tryParse(neckCtrl.text.trim().replaceAll(',', '.'));
    return (v != null && v >= 20 && v <= 80) ? v : null;
  }

  Future<void> _persistProfile() async {
    await widget.settings.setCalculatorProfile(
      height: _height,
      target: _targetWeight,
      newAge: _age,
      male: isMale,
      activity: activityLevel,
      waist: _waist,
      hip: _hip,
      neck: _neck,
    );
    if (mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Kişisel hesaplama bilgileri ve hedefler kaydedildi.',
            ),
          ),
        );
    }
  }

  /// US Navy Vücut Yağ Oranı veya Deurenberg (VKİ tabanlı) yedek hesaplama
  ({double bodyFatPct, String method}) _calculateBodyFat(double bmi) {
    final w = _waist;
    final n = _neck;
    final h = _height;
    final hip = _hip;

    if (isMale && w != null && n != null && w > n) {
      final logDiff = math.log(w - n) / math.ln10;
      final logH = math.log(h) / math.ln10;
      final navy =
          495.0 / (1.0324 - 0.19077 * logDiff + 0.15456 * logH) - 450.0;
      if (navy.isFinite && navy >= 3 && navy <= 65) {
        return (bodyFatPct: rounded(navy), method: 'US Navy Mezura Formülü');
      }
    } else if (!isMale && w != null && hip != null && n != null && (w + hip) > n) {
      final logSum = math.log(w + hip - n) / math.ln10;
      final logH = math.log(h) / math.ln10;
      final navy =
          495.0 / (1.29579 - 0.35004 * logSum + 0.22100 * logH) - 450.0;
      if (navy.isFinite && navy >= 5 && navy <= 65) {
        return (bodyFatPct: rounded(navy), method: 'US Navy Mezura Formülü');
      }
    }

    // Yedek: Deurenberg VKİ formülü
    final est = (1.20 * bmi) + (0.23 * _age) - (10.8 * (isMale ? 1 : 0)) - 5.4;
    return (
      bodyFatPct: rounded(est.clamp(4.0, 60.0)),
      method: 'VKİ & Yaş Formülü',
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final weight = _weight;
    final heightCm = _height;
    final heightM = heightCm / 100.0;
    final age = _age;
    final targetW = _targetWeight;

    // 1. VKİ ve İdeal Kilo Hesabı
    final bmi = rounded(weight / (heightM * heightM));
    final idealMin = rounded(18.5 * heightM * heightM);
    final idealMax = rounded(24.9 * heightM * heightM);
    final idealMid = rounded(22.0 * heightM * heightM);

    final (String bmiCat, Color bmiColor, Color bmiSurface) = switch (bmi) {
      < 18.5 => ('Düşük Kilolu', c.primaryBlue, c.primarySoft),
      < 25.0 => ('İdeal (Normal)', c.greenText, c.greenSurface),
      < 30.0 => ('Fazla Kilolu', c.orangeText, c.orangeSurface),
      _ => ('Obezite Sınırı Üstü', const Color(0xFFDC2626), c.orangeSurface),
    };

    // 2. BMR (Mifflin-St Jeor) & TDEE Kalori Hesabı
    final bmr =
        (10 * weight) + (6.25 * heightCm) - (5 * age) + (isMale ? 5 : -161);
    final multiplier = _activityLabels[activityLevel].$3;
    final tdee = (bmr * multiplier).round();
    final lossMild = math.max(1200, tdee - 500);
    final lossFast = math.max(1200, tdee - 1000);
    final gainMild = tdee + 400;

    // Hedef kaloriye göre günlük makro dağılımı (30% Protein, 40% Karb, 30% Yağ)
    final activeGoalCal = targetW < weight
        ? lossMild
        : (targetW > weight ? gainMild : tdee);
    final proteinGrams = ((activeGoalCal * 0.30) / 4).round();
    final carbGrams = ((activeGoalCal * 0.40) / 4).round();
    final fatGrams = ((activeGoalCal * 0.30) / 9).round();

    // 3. Vücut Yağ Oranı, Yağ Kütlesi & Yağsız Kütle
    final fatRes = _calculateBodyFat(bmi);
    final bodyFatPct = fatRes.bodyFatPct;
    final fatMassKg = rounded(weight * (bodyFatPct / 100.0));
    final leanMassKg = rounded(weight - fatMassKg);
    final waistToHeight = _waist != null ? rounded(_waist! / heightCm) : null;

    // 4. Günlük Su İhtiyacı
    final waterLiters = rounded(weight * 0.035);
    final waterGlasses = (waterLiters / 0.25).round();

    return PageBody([
      // 1. KİŞİSEL BİLGİLER & ÖLÇÜLER GİRİŞ KARTI
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
                    Icons.tune_rounded,
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
                        'Kişisel Bilgiler & Hesaplama',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: c.heading,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Değerleri girdiğinde tüm grafikler anında güncellenir.',
                        style: TextStyle(fontSize: 12, color: c.subtitle),
                      ),
                    ],
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: _persistProfile,
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                  icon: const Icon(Icons.check_rounded, size: 16),
                  label: const Text(
                    'Kaydet',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Cinsiyet Seçimi
            Row(
              children: [
                Expanded(
                  child: _GenderChoiceButton(
                    label: 'Erkek',
                    icon: Icons.male_rounded,
                    selected: isMale,
                    onTap: () => setState(() => isMale = true),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _GenderChoiceButton(
                    label: 'Kadın',
                    icon: Icons.female_rounded,
                    selected: !isMale,
                    onTap: () => setState(() => isMale = false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Kilo, Boy, Yaş, Hedef Kilo (2x2 Grid)
            Row(
              children: [
                Expanded(
                  child: _CompactCalcField(
                    label: 'Kilo (kg)',
                    controller: weightCtrl,
                    suffix: 'kg',
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _CompactCalcField(
                    label: 'Boy (cm)',
                    controller: heightCtrl,
                    suffix: 'cm',
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _CompactCalcField(
                    label: 'Yaş',
                    controller: ageCtrl,
                    suffix: 'yıl',
                    decimal: false,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _CompactCalcField(
                    label: 'Hedef Kilo (kg)',
                    controller: targetCtrl,
                    suffix: 'kg',
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Aktivite Düzeyi
            Text(
              'Günlük Aktivite Düzeyi',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: c.heading,
              ),
            ),
            const SizedBox(height: 6),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final (idx, act) in _activityLabels.indexed) ...[
                    if (idx > 0) const SizedBox(width: 8),
                    ChoiceChip(
                      label: Text(
                        act.$1,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: activityLevel == idx
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: activityLevel == idx
                              ? Colors.white
                              : c.heading,
                        ),
                      ),
                      selected: activityLevel == idx,
                      showCheckmark: false,
                      selectedColor: c.primaryBlue,
                      backgroundColor: c.background,
                      side: BorderSide(
                        color: activityLevel == idx
                            ? c.primaryBlue
                            : c.cardBorder,
                      ),
                      onSelected: (_) => setState(() => activityLevel = idx),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Mezura (Bel / Kalça / Boyun) açılır alanı
            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () =>
                  setState(() => showCircumferences = !showCircumferences),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.straighten_rounded,
                      size: 17,
                      color: c.primaryBlue,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Bel, Kalça & Boyun Ölçüleri (Yağ Oranı İçin)',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: c.primaryBlue,
                        ),
                      ),
                    ),
                    Icon(
                      showCircumferences
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: c.primaryBlue,
                    ),
                  ],
                ),
              ),
            ),
            if (showCircumferences) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _CompactCalcField(
                      label: 'Bel (cm)',
                      controller: waistCtrl,
                      suffix: 'cm',
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _CompactCalcField(
                      label: 'Kalça (cm)',
                      controller: hipCtrl,
                      suffix: 'cm',
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _CompactCalcField(
                      label: 'Boyun (cm)',
                      controller: neckCtrl,
                      suffix: 'cm',
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
      const SizedBox(height: 14),

      // 2. ŞIK VKİ (VÜCUT KİTLE İNDEKSİ) YARIM DAİRE KADRAN & SINIF TABLOSU KARTI
      _BmiExecutiveCard(
        bmi: bmi,
        bmiCategory: bmiCat,
        bmiColor: bmiColor,
        bmiSurface: bmiSurface,
        weight: weight,
        heightCm: heightCm,
        idealMin: idealMin,
        idealMax: idealMax,
        idealMid: idealMid,
      ),
      const SizedBox(height: 14),

      // 3. GÜNLÜK KALORİ (BMR & TDEE) VE MAKRO BESİN GRAFİĞİ
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
                    color: c.orangeSurface,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    Icons.local_fire_department_rounded,
                    color: c.orangeText,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kalori & Metabolizma Grafiği',
                        style: TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                          color: c.heading,
                        ),
                      ),
                      Text(
                        'Bazal Metabolizma: ${bmr.round()} kcal • Koruma: $tdee kcal',
                        style: TextStyle(fontSize: 12, color: c.subtitle),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Kalori Senaryoları Görsel Bar Grafiği
            _CalorieScenarioBar(
              label: 'Hızlı Kilo Verme (-1.0 kg/hf)',
              kcal: lossFast,
              maxKcal: gainMild,
              color: const Color(0xFF0EA5E9),
            ),
            const SizedBox(height: 8),
            _CalorieScenarioBar(
              label: 'Sağlıklı Kilo Verme (-0.5 kg/hf)',
              kcal: lossMild,
              maxKcal: gainMild,
              color: c.greenText,
              highlight: targetW < weight,
            ),
            const SizedBox(height: 8),
            _CalorieScenarioBar(
              label: 'Kilo Koruma (Sabit)',
              kcal: tdee,
              maxKcal: gainMild,
              color: c.primaryBlue,
              highlight: (targetW - weight).abs() < 0.5,
            ),
            const SizedBox(height: 8),
            _CalorieScenarioBar(
              label: 'Kilo Alma (+0.4 kg/hf)',
              kcal: gainMild,
              maxKcal: gainMild,
              color: c.eveningAccent,
              highlight: targetW > weight,
            ),
            const SizedBox(height: 14),

            // Makro Besin Dağılımı (Protein / Karbonhidrat / Yağ)
            Text(
              'Önerilen Günlük Makro Dağılımı ($activeGoalCal kcal)',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: c.heading,
              ),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 12,
                child: Row(
                  children: [
                    Expanded(
                      flex: 30,
                      child: Container(color: c.primaryBlue),
                    ),
                    Expanded(
                      flex: 40,
                      child: Container(color: c.greenText),
                    ),
                    Expanded(
                      flex: 30,
                      child: Container(color: c.orangeText),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _MacroLegendPill(
                    title: 'Protein (%30)',
                    grams: '$proteinGrams g',
                    color: c.primaryBlue,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MacroLegendPill(
                    title: 'Karb (%40)',
                    grams: '$carbGrams g',
                    color: c.greenText,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MacroLegendPill(
                    title: 'Yağ (%30)',
                    grams: '$fatGrams g',
                    color: c.orangeText,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),

      // 4. VÜCUT KOMPOZİSYONU (YAĞ ORANI, KAS/SU KÜTLESİ & SU İHTİYACI)
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
                    color: c.eveningSurface,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    Icons.pie_chart_outline_rounded,
                    color: c.eveningAccent,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Vücut Kompozisyonu & Yağ Oranı',
                        style: TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                          color: c.heading,
                        ),
                      ),
                      Text(
                        fatRes.method,
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
                    color: c.eveningSurface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '%${bodyFatPct.toStringAsFixed(1)} Yağ',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: c.eveningAccent,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Yağsız Kütle vs Yağ Kütlesi Görsel Barı
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                height: 22,
                child: Row(
                  children: [
                    Expanded(
                      flex: (100 - bodyFatPct).round().clamp(10, 95),
                      child: Container(
                        color: c.primaryBlue,
                        alignment: Alignment.center,
                        child: Text(
                          'Yağsız Kütle: ${kg(leanMassKg)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: bodyFatPct.round().clamp(5, 90),
                      child: Container(
                        color: c.orangeText,
                        alignment: Alignment.center,
                        child: Text(
                          '${kg(fatMassKg)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _MiniMetricColumn(
                    label: 'Günlük Su İhtiyacı',
                    value: '${waterLiters.toStringAsFixed(2)} L ($waterGlasses Brd)',
                    valueColor: c.primaryBlue,
                  ),
                ),
                Container(width: 1, height: 32, color: c.cardBorder),
                Expanded(
                  child: _MiniMetricColumn(
                    label: 'Bel / Boy Oranı',
                    value: waistToHeight == null
                        ? '—'
                        : '${waistToHeight.toStringAsFixed(2)} (${waistToHeight < 0.50 ? "Sağlıklı" : "Yüksek"})',
                    valueColor: (waistToHeight ?? 0.45) < 0.50
                        ? c.greenText
                        : c.orangeText,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),

      // 5. HEDEF KİLO PROJEKSİYON ÇİZGİ GRAFİĞİ
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
                    color: c.greenSurface,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    Icons.auto_graph_rounded,
                    color: c.greenText,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hedef Kilo Projeksiyon Grafiği',
                        style: TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                          color: c.heading,
                        ),
                      ),
                      Text(
                        '${kg(weight)} → ${kg(targetW)} haftalık tahmini yolculuk',
                        style: TextStyle(fontSize: 12, color: c.subtitle),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _GoalProjectionChart(
              currentWeight: weight,
              targetWeight: targetW,
            ),
          ],
        ),
      ),
    ]);
  }
}

class _GenderChoiceButton extends StatelessWidget {
  const _GenderChoiceButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: selected ? c.primaryBlue : c.background,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? c.primaryBlue : c.cardBorder,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 19,
                color: selected ? Colors.white : c.primaryBlue,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : c.heading,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactCalcField extends StatelessWidget {
  const _CompactCalcField({
    required this.label,
    required this.controller,
    required this.suffix,
    required this.onChanged,
    this.decimal = true,
  });

  final String label;
  final TextEditingController controller;
  final String suffix;
  final ValueChanged<String> onChanged;
  final bool decimal;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: c.heading,
          ),
        ),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          keyboardType: TextInputType.numberWithOptions(decimal: decimal),
          onChanged: onChanged,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: c.heading,
          ),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 11,
            ),
            suffixText: suffix,
            suffixStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: c.subtitle,
            ),
          ),
        ),
      ],
    );
  }
}

class _BmiExecutiveCard extends StatelessWidget {
  const _BmiExecutiveCard({
    required this.bmi,
    required this.bmiCategory,
    required this.bmiColor,
    required this.bmiSurface,
    required this.weight,
    required this.heightCm,
    required this.idealMin,
    required this.idealMax,
    required this.idealMid,
  });

  final double bmi;
  final String bmiCategory;
  final Color bmiColor;
  final Color bmiSurface;
  final double weight;
  final double heightCm;
  final double idealMin;
  final double idealMax;
  final double idealMid;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final hM = heightCm / 100.0;
    final overMin = rounded(25.0 * hM * hM);
    final overMax = rounded(29.9 * hM * hM);
    final obeseMin = rounded(30.0 * hM * hM);

    final activeBandIndex = switch (bmi) {
      < 18.5 => 0,
      < 25.0 => 1,
      < 30.0 => 2,
      _ => 3,
    };

    final bands = [
      (
        'Düşük Kilolu',
        '< 18.5 VKİ',
        '< ${formatWeightValue(idealMin)} kg',
        const Color(0xFF0EA5E9),
      ),
      (
        'İdeal Sağlıklı Kilo',
        '18.5 – 24.9 VKİ',
        '${formatWeightValue(idealMin)} – ${formatWeightValue(idealMax)} kg',
        const Color(0xFF10B981),
      ),
      (
        'Fazla Kilolu',
        '25.0 – 29.9 VKİ',
        '${formatWeightValue(overMin)} – ${formatWeightValue(overMax)} kg',
        const Color(0xFFF59E0B),
      ),
      (
        'Obezite Sınırı Üstü',
        '30.0+ VKİ',
        '${formatWeightValue(obeseMin)}+ kg',
        const Color(0xFFEF4444),
      ),
    ];

    final diffText = weight > idealMax
        ? 'İdeal aralığa inmek için -${formatWeightValue(weight - idealMax)} kg'
        : weight < idealMin
        ? 'İdeal aralığa çıkmak için +${formatWeightValue(idealMin - weight)} kg'
        : 'Tebrikler! Boyuna göre sağlıklı ideal kilo aralığındasın';

    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Üst Başlık
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: c.primarySoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.analytics_outlined,
                  color: c.primaryBlue,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'VKİ & İdeal Kilo Kadranı',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: c.heading,
                      ),
                    ),
                    Text(
                      '${heightCm.round()} cm boy • ${kg(weight)} güncel ölçüm',
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
                  color: bmiSurface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  bmiCategory,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: bmiColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Orta Alan: Yarım Daire Özel Kadran + Merkez Skor Kartı
          Container(
            padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
            decoration: BoxDecoration(
              color: c.background,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: c.cardBorder),
            ),
            child: Column(
              children: [
                SizedBox(
                  width: 230,
                  height: 132,
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _BmiRadialArcPainter(
                            bmi: bmi,
                            pointerColor: c.heading,
                            surfaceColor: c.cardSurface,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'VKİ SKORU',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                                color: c.subtitle,
                              ),
                            ),
                            Text(
                              bmi.toStringAsFixed(1),
                              style: TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.w900,
                                height: 1.05,
                                color: c.heading,
                                letterSpacing: -0.8,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'kg/m²',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: c.subtitle,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: (weight >= idealMin && weight <= idealMax)
                        ? c.greenSurface
                        : c.primarySoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        (weight >= idealMin && weight <= idealMax)
                            ? Icons.verified_rounded
                            : Icons.flag_circle_rounded,
                        size: 16,
                        color: (weight >= idealMin && weight <= idealMax)
                            ? c.greenText
                            : c.primaryBlue,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          diffText,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: (weight >= idealMin && weight <= idealMax)
                                ? c.greenText
                                : c.primaryBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Boya Özel 4'lü VKİ & Kilo Sınıf Tablosu
          Text(
            'Boyuna Göre (${heightCm.round()} cm) Kilo Sınıfları',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: c.heading,
            ),
          ),
          const SizedBox(height: 8),
          for (final (idx, band) in bands.indexed) ...[
            if (idx > 0) const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: activeBandIndex == idx
                    ? band.$4.withValues(alpha: 0.11)
                    : c.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: activeBandIndex == idx ? band.$4 : c.cardBorder,
                  width: activeBandIndex == idx ? 1.6 : 1.0,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: band.$4,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                band.$1,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: activeBandIndex == idx
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                  color: c.heading,
                                ),
                              ),
                            ),
                            if (activeBandIndex == idx) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 1.5,
                                ),
                                decoration: BoxDecoration(
                                  color: band.$4,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'Sen',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        Text(
                          band.$2,
                          style: TextStyle(fontSize: 10.5, color: c.subtitle),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    band.$3,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: activeBandIndex == idx ? band.$4 : c.heading,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),

          // Alt 3'lü Özet Satırı
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            decoration: BoxDecoration(
              color: c.background,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: c.cardBorder),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _MiniMetricColumn(
                    label: 'Sağlıklı Sınır',
                    value:
                        '${formatWeightValue(idealMin)}–${formatWeightValue(idealMax)} kg',
                    valueColor: c.greenText,
                  ),
                ),
                Container(width: 1, height: 28, color: c.cardBorder),
                Expanded(
                  child: _MiniMetricColumn(
                    label: 'Altın Oran (22 VKİ)',
                    value: kg(idealMid),
                    valueColor: c.primaryBlue,
                  ),
                ),
                Container(width: 1, height: 28, color: c.cardBorder),
                Expanded(
                  child: _MiniMetricColumn(
                    label: 'Mevcut Fark',
                    value: weight > idealMax
                        ? '-${formatWeightValue(weight - idealMax)} kg'
                        : weight < idealMin
                        ? '+${formatWeightValue(idealMin - weight)} kg'
                        : '0.0 kg ✓',
                    valueColor: (weight >= idealMin && weight <= idealMax)
                        ? c.greenText
                        : c.orangeText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BmiRadialArcPainter extends CustomPainter {
  const _BmiRadialArcPainter({
    required this.bmi,
    required this.pointerColor,
    required this.surfaceColor,
  });

  final double bmi;
  final Color pointerColor;
  final Color surfaceColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height - 14);
    final radius = math.min(size.width / 2 - 14, size.height - 22);
    final rect = Rect.fromCircle(center: center, radius: radius);
    const strokeWidth = 16.0;

    // 4 renkli segment (Toplam π radyan: π -> 2π)
    // Ölçek: 14.0 ile 36.0 arası (22 birim)
    const minBmi = 14.0;
    const maxBmi = 36.0;
    const span = maxBmi - minBmi;

    final segments = [
      (14.0, 18.5, const Color(0xFF38BDF8)),
      (18.5, 25.0, const Color(0xFF10B981)),
      (25.0, 30.0, const Color(0xFFF59E0B)),
      (30.0, 36.0, const Color(0xFFEF4444)),
    ];

    const gap = 0.035;
    for (final seg in segments) {
      final startFrac = (seg.$1 - minBmi) / span;
      final endFrac = (seg.$2 - minBmi) / span;
      final startAngle = math.pi + startFrac * math.pi + gap / 2;
      final sweepAngle = (endFrac - startFrac) * math.pi - gap;
      final paint = Paint()
        ..color = seg.$3
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
    }

    // Kullanıcının VKİ değerine karşılık gelen açı
    final clampedBmi = bmi.clamp(minBmi, maxBmi);
    final norm = (clampedBmi - minBmi) / span;
    final angle = math.pi + norm * math.pi;

    final markerPos = Offset(
      center.dx + math.cos(angle) * radius,
      center.dy + math.sin(angle) * radius,
    );

    // İşaretçi halka
    canvas.drawCircle(
      markerPos,
      10,
      Paint()..color = pointerColor,
    );
    canvas.drawCircle(
      markerPos,
      5,
      Paint()..color = surfaceColor,
    );
  }

  @override
  bool shouldRepaint(covariant _BmiRadialArcPainter oldDelegate) =>
      oldDelegate.bmi != bmi || oldDelegate.pointerColor != pointerColor;
}

class _CalorieScenarioBar extends StatelessWidget {
  const _CalorieScenarioBar({
    required this.label,
    required this.kcal,
    required this.maxKcal,
    required this.color,
    this.highlight = false,
  });

  final String label;
  final int kcal;
  final int maxKcal;
  final Color color;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final ratio = (kcal / math.max(1, maxKcal)).clamp(0.25, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: highlight ? FontWeight.w800 : FontWeight.w600,
                  color: highlight ? color : c.heading,
                ),
              ),
            ),
            Text(
              '$kcal kcal/gün',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: highlight ? 9 : 7,
            backgroundColor: c.background,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _MacroLegendPill extends StatelessWidget {
  const _MacroLegendPill({
    required this.title,
    required this.grams,
    required this.color,
  });

  final String title;
  final String grams;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: c.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.cardBorder),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: c.subtitle,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            grams,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: c.heading,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniMetricColumn extends StatelessWidget {
  const _MiniMetricColumn({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: c.subtitle,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalProjectionChart extends StatelessWidget {
  const _GoalProjectionChart({
    required this.currentWeight,
    required this.targetWeight,
  });

  final double currentWeight;
  final double targetWeight;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final diff = (currentWeight - targetWeight).abs();
    if (diff < 0.2) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          'Mevcut kilon zaten hedef kilona çok yakın! Kilo koruma kalorisiyle devam edebilirsin.',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: c.greenText,
          ),
        ),
      );
    }

    final isLoss = targetWeight < currentWeight;
    final weeklyStep = isLoss ? -0.5 : 0.4;
    final totalWeeks = (diff / weeklyStep.abs()).ceil().clamp(1, 24);

    final spots = <FlSpot>[];
    for (var w = 0; w <= totalWeeks; w++) {
      final projected = isLoss
          ? math.max(targetWeight, currentWeight + weeklyStep * w)
          : math.min(targetWeight, currentWeight + weeklyStep * w);
      spots.add(FlSpot(w.toDouble(), rounded(projected)));
    }

    final minY = (math.min(currentWeight, targetWeight) - 1.5).floorToDouble();
    final maxY = (math.max(currentWeight, targetWeight) + 1.5).ceilToDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 165,
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: totalWeeks.toDouble(),
              minY: minY,
              maxY: maxY,
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
                getDrawingHorizontalLine: (_) => FlLine(
                  color: c.cardBorder.withValues(alpha: 0.7),
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
                    reservedSize: 40,
                    getTitlesWidget: (v, _) => Text(
                      v.toStringAsFixed(0),
                      style: TextStyle(fontSize: 10.5, color: c.subtitle),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 24,
                    interval: math.max(1, (totalWeeks / 5).ceilToDouble()),
                    getTitlesWidget: (v, _) => Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Text(
                        '${v.round()}.Hf',
                        style: TextStyle(fontSize: 10, color: c.subtitle),
                      ),
                    ),
                  ),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: c.greenText,
                  barWidth: 3,
                  dotData: FlDotData(show: totalWeeks <= 12),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        c.greenText.withValues(alpha: 0.22),
                        c.greenText.withValues(alpha: 0.02),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Haftada ortalama ${weeklyStep.abs().toStringAsFixed(1)} kg sağlıklı değişim hızıyla yaklaşık $totalWeeks haftada (${formatTurkishDate(shiftDay(DateTime.now(), totalWeeks * 7))}) hedefe ulaşabilirsin.',
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
