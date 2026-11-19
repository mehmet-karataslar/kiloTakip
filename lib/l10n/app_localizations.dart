import 'package:flutter/material.dart';

enum AppLanguage {
  tr('tr', 'TR', '🇹🇷', 'Türkçe', 'Türkiye'),
  en('en', 'US', '🇬🇧', 'English', 'UK / USA'),
  de('de', 'DE', '🇩🇪', 'Deutsch', 'Deutschland'),
  deCh('de', 'CH', '🇨🇭', 'Schweizerdeutsch', 'Schweiz'),
  nl('nl', 'NL', '🇳🇱', 'Nederlands', 'Nederland'),
  fr('fr', 'FR', '🇫🇷', 'Français', 'France'),
  ga('ga', 'IE', '🇮🇪', 'Gaeilge', 'Éire / Ireland'),
  ru('ru', 'RU', '🇷🇺', 'Русский', 'Россия'),
  ar('ar', 'SA', '🇸🇦', 'العربية', 'العالم العربي'),
  zh('zh', 'CN', '🇨🇳', '中文 (简体)', '中国'),
  ja('ja', 'JP', '🇯🇵', '日本語', '日本'),
  ko('ko', 'KR', '🇰🇷', '한국어', '대한민국'),
  es('es', 'ES', '🇪🇸', 'Español', 'España'),
  it('it', 'IT', '🇮🇹', 'Italiano', 'Italia'),
  pt('pt', 'PT', '🇵🇹', 'Português', 'Portugal'),
  sv('sv', 'SE', '🇸🇪', 'Svenska', 'Sverige');

  const AppLanguage(
    this.langCode,
    this.countryCode,
    this.flag,
    this.nativeName,
    this.regionName,
  );

  final String langCode;
  final String countryCode;
  final String flag;
  final String nativeName;
  final String regionName;

  String get languageCode => langCode;
  String get trName => regionName;

  /// Flutter MaterialLocalizations tarafından doğrudan desteklenen Locale
  Locale get materialLocale => switch (this) {
    AppLanguage.ga => const Locale('en', 'IE'),
    AppLanguage.deCh => const Locale('de', 'CH'),
    _ => Locale(langCode, countryCode),
  };

  bool get isRtl => this == AppLanguage.ar;
}

class AppI18n {
  static AppLanguage current = AppLanguage.tr;

  static List<String> get months =>
      _monthsByLang[current] ?? _monthsByLang[AppLanguage.en]!;

  static List<String> get shortMonths =>
      _shortMonthsByLang[current] ?? _shortMonthsByLang[AppLanguage.en]!;

  static List<String> get weekdays =>
      _weekdaysByLang[current] ?? _weekdaysByLang[AppLanguage.en]!;

  static List<String> get shortWeekdays =>
      _shortWeekdaysByLang[current] ?? _shortWeekdaysByLang[AppLanguage.en]!;
}

String trText(String text, [AppLanguage? lang]) {
  final target = lang ?? AppI18n.current;
  if (target == AppLanguage.tr || text.isEmpty) return text;

  final baseTarget = target == AppLanguage.deCh ? AppLanguage.de : target;

  // 1. Doğrudan sözlük eşleşmesi
  final direct = _dictionary[text]?[target] ?? _dictionary[text]?[baseTarget];
  if (direct != null) return direct;

  // 2. Dinamik kalıp / şablon eşleşmeleri
  return _translateDynamic(text, target, baseTarget);
}

String _translateDynamic(
  String text,
  AppLanguage target,
  AppLanguage baseTarget,
) {
  String t(String key) =>
      _dictionary[key]?[target] ??
      _dictionary[key]?[baseTarget] ??
      _dictionary[key]?[AppLanguage.en] ??
      key;

  // "Saat 09:00"
  if (text.startsWith('Saat ')) {
    final clock = text.substring(5);
    return '${t('Saat')} $clock';
  }

  // "X Kayıt"
  if (text.endsWith(' Kayıt')) {
    final count = text.substring(0, text.length - 6);
    return '$count ${t('Kayıt')}';
  }

  // "X Günlük Seri • Rekor: Y gün"
  final streakMatch = RegExp(
    r'^(\d+) Günlük Seri • Rekor: (\d+) gün$',
  ).firstMatch(text);
  if (streakMatch != null) {
    final c = streakMatch.group(1)!;
    final b = streakMatch.group(2)!;
    return '$c ${t('Günlük Seri')} • ${t('Rekor')}: $b ${t('gün')}';
  }

  // "X Bardak (Y L / Hedef Z L)"
  final waterMatch = RegExp(
    r'^(\d+) Bardak \(([\d.]+) L / Hedef ([\d.]+) L\)$',
  ).firstMatch(text);
  if (waterMatch != null) {
    final g = waterMatch.group(1)!;
    final l = waterMatch.group(2)!;
    final goal = waterMatch.group(3)!;
    return '$g ${t('Bardak')} ($l L / ${t('Hedef')} $goal L)';
  }

  // "Sabah Kilosu (kg)" / "Akşam Kilosu (kg)"
  if (text.endsWith(' Kilosu (kg)')) {
    final prefix = text.substring(0, text.length - 12);
    return '${trText(prefix, target)} (${t('Kilo (kg)')})';
  }

  // "Renk Paleti (8 Seçenek)"
  final paletteMatch = RegExp(r'^Renk Paleti \((\d+) Seçenek\)$').firstMatch(
    text,
  );
  if (paletteMatch != null) {
    return '${t('Renk Paleti')} (${paletteMatch.group(1)})';
  }

  // "Hedef: X kg"
  if (text.startsWith('Hedef: ')) {
    final rest = text
        .substring(7)
        .replaceAll('(Koruma Modu)', '(${t('Kilo Koruma Modu (±1.0 kg)')})');
    return '${t('Hedef')}: $rest';
  }

  // "Başlangıç kilosu: X"
  if (text.startsWith('Başlangıç kilosu: ')) {
    final val = text.substring(18);
    return '${t('Başlangıç Kilosu')}: ${trText(val, target)}';
  }

  // "Boyuna Göre İdeal Aralık (175 cm)"
  final idealRangeMatch = RegExp(
    r'^Boyuna Göre İdeal Aralık \((\d+) cm\)$',
  ).firstMatch(text);
  if (idealRangeMatch != null) {
    return '${t('İdeal Kilo Aralığı')} (${idealRangeMatch.group(1)} cm)';
  }

  // "Boyuna Göre (175 cm) Kilo Sınıfları"
  final classesMatch = RegExp(
    r'^Boyuna Göre \((\d+) cm\) Kilo Sınıfları$',
  ).firstMatch(text);
  if (classesMatch != null) {
    return '${t('Kilo Sınıfları')} (${classesMatch.group(1)} cm)';
  }

  // "175 cm boy • 85.0 kg güncel ölçüm"
  final subMatch = RegExp(
    r'^(\d+) cm boy • ([\d.,]+ kg) güncel ölçüm$',
  ).firstMatch(text);
  if (subMatch != null) {
    return '${subMatch.group(1)} cm • ${subMatch.group(2)}';
  }

  // "Bazal Metabolizma: 1800 kcal • Koruma: 2475 kcal"
  final bmrMatch = RegExp(
    r'^Bazal Metabolizma: (\d+) kcal • Koruma: (\d+) kcal$',
  ).firstMatch(text);
  if (bmrMatch != null) {
    return 'BMR: ${bmrMatch.group(1)} kcal • TDEE: ${bmrMatch.group(2)} kcal';
  }

  // "Önerilen Günlük Makro Dağılımı (1975 kcal)"
  final macroMatch = RegExp(
    r'^Önerilen Günlük Makro Dağılımı \((\d+) kcal\)$',
  ).firstMatch(text);
  if (macroMatch != null) {
    return '${t('Önerilen Günlük Makro Dağılımı')} (${macroMatch.group(1)} kcal)';
  }

  // "%20.0 Yağ"
  if (text.endsWith(' Yağ') && text.startsWith('%')) {
    final pct = text.substring(1, text.length - 4);
    return '$pct% ${t('Yağ')}';
  }

  // "Yağsız Kütle: 68.0 kg"
  if (text.startsWith('Yağsız Kütle: ')) {
    final val = text.substring(14);
    return '${t('Yağsız Kütle')}: $val';
  }

  // "85.0 kg → 78.0 kg haftalık tahmini yolculuk"
  if (text.endsWith(' haftalık tahmini yolculuk')) {
    final pair = text.replaceAll(' haftalık tahmini yolculuk', '');
    return '$pair • ${t('Hedef Kilo Projeksiyon Grafiği')}';
  }

  // "İdeal aralığa inmek için -X kg" / "İdeal aralığa çıkmak için +X kg"
  if (text.startsWith('İdeal aralığa inmek için ')) {
    final diff = text.replaceAll('İdeal aralığa inmek için ', '');
    return '${t('İdeal Aralığa Fark')}: $diff';
  }
  if (text.startsWith('İdeal aralığa çıkmak için ')) {
    final diff = text.replaceAll('İdeal aralığa çıkmak için ', '');
    return '${t('İdeal Aralığa Fark')}: $diff';
  }

  // "Dil (16 Ülke / Bölge) • Türkiye"
  final langCountMatch = RegExp(
    r'^Dil \((\d+) Ülke / Bölge\) • (.+)$',
  ).firstMatch(text);
  if (langCountMatch != null) {
    return '${t('Uygulama Dili & Bölge')} (${langCountMatch.group(1)}) • ${langCountMatch.group(2)}';
  }

  // "Hedef 78.0"
  if (text.startsWith('Hedef ') && !text.startsWith('Hedef Kilo')) {
    return '${t('Hedef')} ${text.substring(6)}';
  }

  // "Sabah Bildirimi" / "Akşam Bildirimi"
  if (text.endsWith(' Bildirimi')) {
    final prefix = text.substring(0, text.length - 10);
    return '${trText(prefix, target)} • ${t('Bildirimler')}';
  }

  // "Her gün 09:00 saatinde hatırlatır"
  final remTimeMatch = RegExp(
    r'^Her gün (\d{2}:\d{2}) saatinde hatırlatır$',
  ).firstMatch(text);
  if (remTimeMatch != null) {
    return '${t('Saat')}: ${remTimeMatch.group(1)}';
  }

  // "X.Hf" (hafta kısaltması)
  final weekShortMatch = RegExp(r'^(\d+)\.Hf$').firstMatch(text);
  if (weekShortMatch != null) {
    return 'W${weekShortMatch.group(1)}';
  }

  // "X kcal/gün"
  if (text.endsWith(' kcal/gün')) {
    final kcal = text.substring(0, text.length - 9);
    return '$kcal kcal / ${t('gün')}';
  }

  // "X L (Y Brd)"
  final waterBrdMatch = RegExp(
    r'^([\d.]+ L) \((\d+) Brd\)$',
  ).firstMatch(text);
  if (waterBrdMatch != null) {
    return '${waterBrdMatch.group(1)} (${waterBrdMatch.group(2)} ${t('Bardak')})';
  }

  // "0.50 (Sağlıklı)" / "0.55 (Yüksek)"
  if (text.endsWith(' (Sağlıklı)')) {
    return '${text.replaceAll(' (Sağlıklı)', '')} (${t('İdeal (Normal)')})';
  }
  if (text.endsWith(' (Yüksek)')) {
    return '${text.replaceAll(' (Yüksek)', '')} (${t('Fazla Kilolu')})';
  }

  // "Tahmini Hedef Tarihi: X (Günlük hız: Y)"
  if (text.startsWith('Tahmini Hedef Tarihi: ')) {
    final cleaned = text
        .replaceFirst('Tahmini Hedef Tarihi: ', '${t('Tahmini Hedef Tarihi')}: ')
        .replaceFirst('Günlük hız:', t('Günlük Değişim'))
        .replaceFirst('/gün)', '/${t('gün')})');
    return cleaned;
  }

  // "Sıradaki Ara Hedef: X"
  if (text.startsWith('Sıradaki Ara Hedef: ')) {
    return '${t('Hedef')}: ${text.substring(20)}';
  }

  // "Bel: X cm" / "Kalça: X cm" / "Boyun: X cm" / "Boy: X cm" / "Başlangıç: X"
  if (text.startsWith('Bel: ')) {
    return '${t('Bel (cm)').replaceAll(' (cm)', '')}: ${text.substring(5)}';
  }
  if (text.startsWith('Kalça: ')) {
    return '${t('Kalça (cm)').replaceAll(' (cm)', '')}: ${text.substring(7)}';
  }
  if (text.startsWith('Boyun: ')) {
    return '${t('Boyun (cm)').replaceAll(' (cm)', '')}: ${text.substring(7)}';
  }
  if (text.startsWith('Boy: ')) {
    return '${t('Boy (cm)').replaceAll(' (cm)', '')}: ${text.substring(5)}';
  }
  if (text.startsWith('Başlangıç: ')) {
    final rest = text.substring(11);
    return '${t('Başlangıç Kilosu')}: ${trText(rest, target)}';
  }

  // Parçalı "•" ifadeleri
  if (text.contains(' • ')) {
    final parts = text.split(' • ');
    final translatedParts = parts.map((p) => trText(p, target)).toList();
    if (translatedParts.join(' • ') != text) {
      return translatedParts.join(' • ');
    }
  }

  
  // VKİ translation replacement
  if (text.contains('VKİ')) {
    final vkiTrans = t('VKİ');
    if (vkiTrans != 'VKİ') {
      text = text.replaceAll('VKİ', vkiTrans);
    }
  }

  // Quick tag emoji prefix: "🏋️ Spor Günü"
  final emojiTagMatch = RegExp(r'^(\S+)\s+(.+)$').firstMatch(text);
  if (emojiTagMatch != null) {
    final emoji = emojiTagMatch.group(1)!;
    final tagWord = emojiTagMatch.group(2)!;
    if (_dictionary.containsKey(tagWord)) {
      return '$emoji ${t(tagWord)}';
    }
  }

  // "Haftada ortalama 0.5 kg sağlıklı değişim hızıyla yaklaşık 14 haftada (15 Şubat 2026) hedefe ulaşabilirsin."
  final projMatch = RegExp(
    r'^Haftada ortalama ([\d.]+) kg sağlıklı değişim hızıyla yaklaşık (\d+) haftada \((.+)\) hedefe ulaşabilirsin\.$',
  ).firstMatch(text);
  if (projMatch != null) {
    final speed = projMatch.group(1)!;
    final weeks = projMatch.group(2)!;
    final date = projMatch.group(3)!;
    switch (target) {
      case AppLanguage.tr:
        return text;
      case AppLanguage.de:
      case AppLanguage.deCh:
        return 'Mit ca. $speed kg/Woche erreichst du dein Ziel in ~$weeks Wochen ($date).';
      case AppLanguage.nl:
        return 'Met ~$speed kg/week bereik je je doel in circa $weeks weken ($date).';
      case AppLanguage.fr:
        return 'Avec ~$speed kg/semaine, vous atteindrez votre objectif en ~$weeks semaines ($date).';
      case AppLanguage.ga:
        return 'Le ~$speed kg/seachtain, sroichfidh tú do sprioc i dtimpeall $weeks seachtaine ($date).';
      case AppLanguage.ru:
        return 'При темпе ~$speed кг/нед. вы достигнете цели примерно за $weeks нед. ($date).';
      case AppLanguage.ar:
        return 'بمعدل ~$speed كغ/أسبوع، يمكنك الوصول إلى هدفك في غضون $weeks أسابيع ($date).';
      case AppLanguage.zh:
        return '以每周约 $speed kg 的健康速度，您预计可在约 $weeks 周内（$date）达成目标。';
      case AppLanguage.ja:
        return '週あたり約 $speed kg のペースで、約 $weeks 週間（$date）で目標に到達できます。';
      case AppLanguage.ko:
        return '주당 약 $speed kg의 속도로 약 $weeks주 후($date)에 목표에 도달할 수 있습니다.';
      case AppLanguage.es:
        return 'Con ~$speed kg/sem., puedes alcanzar tu meta en unas $weeks semanas ($date).';
      case AppLanguage.it:
        return 'Con ~$speed kg/sett., puoi raggiungere il tuo obiettivo in circa $weeks settimane ($date).';
      case AppLanguage.pt:
        return 'A ~$speed kg/sem., podes atingir o teu objetivo em cerca de $weeks semanas ($date).';
      case AppLanguage.sv:
        return 'Med ~$speed kg/vecka kan du nå målet på cirka $weeks veckor ($date).';
      default:
        return 'At ~$speed kg/week healthy pace, you can reach your goal in ~$weeks weeks ($date).';
    }
  }

  // "Son 7 günde -0.5 kg değişim kaydedildi."
  final reportChangeMatch = RegExp(
    r'^(.+?)\s+([+-]?[\d.,]+\s*kg)\s+değişim kaydedildi\.$',
  ).firstMatch(text);
  if (reportChangeMatch != null) {
    final period = reportChangeMatch.group(1)!;
    final diff = reportChangeMatch.group(2)!;
    return '${trText(period, target)}: $diff • ${t('değişim kaydedildi.')}';
  }

  // "Son 7 günde ortalama kilon 85.0 kg oldu."
  final reportAvgMatch = RegExp(
    r'^(.+?)\s+ortalama kilon\s+([\d.,]+\s*kg)\s+oldu\.$',
  ).firstMatch(text);
  if (reportAvgMatch != null) {
    final period = reportAvgMatch.group(1)!;
    final avg = reportAvgMatch.group(2)!;
    return '${trText(period, target)}: ${t('ortalama kilon')} $avg';
  }

  // "En düşük ölçüm 84.5 kg, en yüksek ölçüm 86.0 kg olarak kaydedildi."
  final reportMinMaxMatch = RegExp(
    r'^En düşük ölçüm ([\d.,]+\s*kg), en yüksek ölçüm ([\d.,]+\s*kg) olarak kaydedildi\.$',
  ).firstMatch(text);
  if (reportMinMaxMatch != null) {
    final minW = reportMinMaxMatch.group(1)!;
    final maxW = reportMinMaxMatch.group(2)!;
    return '${t('En düşük ölçüm')}: $minW • ${t('en yüksek ölçüm')}: $maxW';
  }

  // "Kilo Koruma Bandındasın (77.0 – 79.0 kg)"
  if (text.startsWith('Kilo Koruma Bandındasın (')) {
    final range = text.substring(24);
    return '${t('Kilo Koruma Bandındasın')} ($range';
  }
  // "Kilo Koruma Bandı: 77.0 – 79.0 kg"
  if (text.startsWith('Kilo Koruma Bandı: ')) {
    final range = text.substring(19);
    return '${t('Kilo Koruma Bandı')}: $range';
  }

  // "Sabah bildirimi her gün saat 09:00 için aktif edildi."
  final notifEnabledMatch = RegExp(
    r'^(.+?) bildirimi her gün saat (\d{2}:\d{2}) için aktif edildi\.$',
  ).firstMatch(text);
  if (notifEnabledMatch != null) {
    final slotName = notifEnabledMatch.group(1)!;
    final time = notifEnabledMatch.group(2)!;
    switch (target) {
      case AppLanguage.tr: return text;
      case AppLanguage.de: case AppLanguage.deCh:
        return '${trText(slotName, target)}-Erinnerung täglich um $time Uhr aktiviert.';
      case AppLanguage.nl:
        return '${trText(slotName, target)}-melding dagelijks om $time ingeschakeld.';
      case AppLanguage.fr:
        return 'Rappel ${trText(slotName, target).toLowerCase()} activé chaque jour à $time.';
      case AppLanguage.ga:
        return 'Meabhrúchán ${trText(slotName, target)} gníomhachtaithe gach lá ag $time.';
      case AppLanguage.ru:
        return '${trText(slotName, target)}: напоминание включено ежедневно в $time.';
      case AppLanguage.ar:
        return 'تم تفعيل تنبيه ${trText(slotName, target)} يومياً الساعة $time.';
      case AppLanguage.zh:
        return '${trText(slotName, target)}提醒已开启，每天 $time。';
      case AppLanguage.ja:
        return '${trText(slotName, target)}のリマインダーが毎日 $time に設定されました。';
      case AppLanguage.ko:
        return '${trText(slotName, target)} 알림이 매일 $time 로 설정되었습니다.';
      case AppLanguage.es:
        return 'Recordatorio de ${trText(slotName, target).toLowerCase()} activado a las $time diariamente.';
      case AppLanguage.it:
        return 'Promemoria ${trText(slotName, target).toLowerCase()} attivato ogni giorno alle $time.';
      case AppLanguage.pt:
        return 'Lembrete de ${trText(slotName, target).toLowerCase()} ativado todos os dias às $time.';
      case AppLanguage.sv:
        return '${trText(slotName, target)}-påminnelse aktiverad varje dag kl. $time.';
      default:
        return '${trText(slotName, target)} reminder enabled daily at $time.';
    }
  }

  // "Sabah bildirimi her gün saat 09:00 için planlandı."
  final notifScheduledMatch = RegExp(
    r'^(.+?) bildirimi her gün saat (\d{2}:\d{2}) için planlandı\.$',
  ).firstMatch(text);
  if (notifScheduledMatch != null) {
    final slotName = notifScheduledMatch.group(1)!;
    final time = notifScheduledMatch.group(2)!;
    switch (target) {
      case AppLanguage.tr: return text;
      case AppLanguage.de: case AppLanguage.deCh:
        return '${trText(slotName, target)}-Erinnerung auf täglich $time Uhr eingestellt.';
      case AppLanguage.nl:
        return '${trText(slotName, target)}-melding ingesteld op dagelijks $time.';
      case AppLanguage.fr:
        return 'Rappel ${trText(slotName, target).toLowerCase()} programmé chaque jour à $time.';
      case AppLanguage.ga:
        return 'Meabhrúchán ${trText(slotName, target)} sceidealaithe gach lá ag $time.';
      case AppLanguage.ru:
        return '${trText(slotName, target)}: напоминание запланировано на $time.';
      case AppLanguage.ar:
        return 'تمت جدولة تنبيه ${trText(slotName, target)} يومياً الساعة $time.';
      case AppLanguage.zh:
        return '${trText(slotName, target)}提醒已计划在每天 $time。';
      case AppLanguage.ja:
        return '${trText(slotName, target)}のリマインダーが毎日 $time に変更されました。';
      case AppLanguage.ko:
        return '${trText(slotName, target)} 알림이 매일 $time 로 예약되었습니다.';
      case AppLanguage.es:
        return 'Recordatorio de ${trText(slotName, target).toLowerCase()} programado a las $time.';
      case AppLanguage.it:
        return 'Promemoria ${trText(slotName, target).toLowerCase()} programmato alle $time.';
      case AppLanguage.pt:
        return 'Lembrete de ${trText(slotName, target).toLowerCase()} agendado para as $time.';
      case AppLanguage.sv:
        return '${trText(slotName, target)}-påminnelse schemalagd dagligen kl. $time.';
      default:
        return '${trText(slotName, target)} reminder scheduled daily at $time.';
    }
  }

  // "Sabah bildirimi kapatıldı."
  final notifDisabledMatch = RegExp(r'^(.+?) bildirimi kapatıldı\.$').firstMatch(text);
  if (notifDisabledMatch != null) {
    final slotName = notifDisabledMatch.group(1)!;
    switch (target) {
      case AppLanguage.tr: return text;
      case AppLanguage.de: case AppLanguage.deCh:
        return '${trText(slotName, target)}-Erinnerung ausgeschaltet.';
      case AppLanguage.nl:
        return '${trText(slotName, target)}-melding uitgeschakeld.';
      case AppLanguage.fr:
        return 'Rappel ${trText(slotName, target).toLowerCase()} désactivé.';
      case AppLanguage.ga:
        return 'Meabhrúchán ${trText(slotName, target)} múchta.';
      case AppLanguage.ru:
        return '${trText(slotName, target)}: напоминание отключено.';
      case AppLanguage.ar:
        return 'تم إيقاف تنبيه ${trText(slotName, target)}.';
      case AppLanguage.zh:
        return '${trText(slotName, target)}提醒已关闭。';
      case AppLanguage.ja:
        return '${trText(slotName, target)}のリマインダーをオフにしました。';
      case AppLanguage.ko:
        return '${trText(slotName, target)} 알림이 꺼졌습니다.';
      case AppLanguage.es:
        return 'Recordatorio de ${trText(slotName, target).toLowerCase()} desactivado.';
      case AppLanguage.it:
        return 'Promemoria ${trText(slotName, target).toLowerCase()} disattivato.';
      case AppLanguage.pt:
        return 'Lembrete de ${trText(slotName, target).toLowerCase()} desativado.';
      case AppLanguage.sv:
        return '${trText(slotName, target)}-påminnelse inaktiverad.';
      default:
        return '${trText(slotName, target)} reminder turned off.';
    }
  }

  // "Sabah kilosu (85.0 kg) hızlıca kaydedildi."
  final quickSaveMatch = RegExp(
    r'^(.+?) kilosu \(([\d.,]+\s*kg)\) hızlıca kaydedildi\.$',
  ).firstMatch(text);
  if (quickSaveMatch != null) {
    final slotName = quickSaveMatch.group(1)!;
    final w = quickSaveMatch.group(2)!;
    switch (target) {
      case AppLanguage.tr: return text;
      case AppLanguage.de: case AppLanguage.deCh:
        return '${trText(slotName, target)}-Gewicht ($w) schnell gespeichert.';
      case AppLanguage.nl:
        return '${trText(slotName, target)}-gewicht ($w) snel opgeslagen.';
      case AppLanguage.fr:
        return 'Poids ${trText(slotName, target).toLowerCase()} ($w) enregistré rapidement.';
      case AppLanguage.ga:
        return 'Meáchan ${trText(slotName, target)} ($w) sábháilte go tapa.';
      case AppLanguage.ru:
        return '${trText(slotName, target)}: вес ($w) быстро сохранен.';
      case AppLanguage.ar:
        return 'تم حفظ وزن ${trText(slotName, target)} ($w) سريعاً.';
      case AppLanguage.zh:
        return '${trText(slotName, target)}体重 ($w) 已快速记录。';
      case AppLanguage.ja:
        return '${trText(slotName, target)}の体重 ($w) をクイック保存しました。';
      case AppLanguage.ko:
        return '${trText(slotName, target)} 체중 ($w) 빠른 저장 완료.';
      case AppLanguage.es:
        return 'Peso de ${trText(slotName, target).toLowerCase()} ($w) guardado rápidamente.';
      case AppLanguage.it:
        return 'Peso ${trText(slotName, target).toLowerCase()} ($w) salvato rapidamente.';
      case AppLanguage.pt:
        return 'Peso de ${trText(slotName, target).toLowerCase()} ($w) guardado rapidamente.';
      case AppLanguage.sv:
        return '${trText(slotName, target)}-vikt ($w) sparades snabbt.';
      default:
        return '${trText(slotName, target)} weight ($w) quick-saved.';
    }
  }

  // "Sabah hatırlatması 1 saat sonrasına ertelendi."
  final snoozeMatch = RegExp(
    r'^(.+?) hatırlatması 1 saat sonrasına ertelendi\.$',
  ).firstMatch(text);
  if (snoozeMatch != null) {
    final slotName = snoozeMatch.group(1)!;
    switch (target) {
      case AppLanguage.tr: return text;
      case AppLanguage.de: case AppLanguage.deCh:
        return '${trText(slotName, target)}-Erinnerung um 1 Stunde verschoben.';
      case AppLanguage.nl:
        return '${trText(slotName, target)}-herinnering met 1 uur uitgesteld.';
      case AppLanguage.fr:
        return 'Rappel ${trText(slotName, target).toLowerCase()} reporté de 1 heure.';
      case AppLanguage.ga:
        return 'Meabhrúchán ${trText(slotName, target)} curtha siar uair amháin.';
      case AppLanguage.ru:
        return '${trText(slotName, target)}: напоминание отложено на 1 час.';
      case AppLanguage.ar:
        return 'تم تأجيل تذكير ${trText(slotName, target)} لمدة ساعة واحدة.';
      case AppLanguage.zh:
        return '${trText(slotName, target)}提醒已推迟 1 小时。';
      case AppLanguage.ja:
        return '${trText(slotName, target)}のリマインダーを1時間スヌーズしました。';
      case AppLanguage.ko:
        return '${trText(slotName, target)} 알림이 1시간 연기되었습니다.';
      case AppLanguage.es:
        return 'Recordatorio de ${trText(slotName, target).toLowerCase()} pospuesto 1 hora.';
      case AppLanguage.it:
        return 'Promemoria ${trText(slotName, target).toLowerCase()} posticipato di 1 ora.';
      case AppLanguage.pt:
        return 'Lembrete de ${trText(slotName, target).toLowerCase()} adiado por 1 hora.';
      case AppLanguage.sv:
        return '${trText(slotName, target)}-påminnelse snoozad i 1 timme.';
      default:
        return '${trText(slotName, target)} reminder snoozed for 1 hour.';
    }
  }

  // "Excel dosyası (xxx) kaydedildi."
  final excelSavedMatch = RegExp(r'^Excel dosyası \((.+)\) kaydedildi\.$').firstMatch(text);
  if (excelSavedMatch != null) {
    final fn = excelSavedMatch.group(1)!;
    switch (target) {
      case AppLanguage.tr: return text;
      case AppLanguage.de: case AppLanguage.deCh:
        return 'Excel-Datei ($fn) gespeichert.';
      case AppLanguage.nl:
        return 'Excel-bestand ($fn) opgeslagen.';
      case AppLanguage.fr:
        return 'Fichier Excel ($fn) enregistré.';
      case AppLanguage.ga:
        return 'Comhad Excel ($fn) sábháilte.';
      case AppLanguage.ru:
        return 'Файл Excel ($fn) сохранен.';
      case AppLanguage.ar:
        return 'تم حفظ ملف Excel ($fn).';
      case AppLanguage.zh:
        return 'Excel 文件 ($fn) 已保存。';
      case AppLanguage.ja:
        return 'Excelファイル ($fn) を保存しました。';
      case AppLanguage.ko:
        return 'Excel 파일 ($fn) 저장 완료.';
      case AppLanguage.es:
        return 'Archivo Excel ($fn) guardado.';
      case AppLanguage.it:
        return 'File Excel ($fn) salvato.';
      case AppLanguage.pt:
        return 'Ficheiro Excel ($fn) guardado.';
      case AppLanguage.sv:
        return 'Excel-fil ($fn) sparad.';
      default:
        return 'Excel file ($fn) saved.';
    }
  }

  // "X tarihine ait sabah ve akşam kayıtları (...) birlikte silinecek."
  if (text.contains('birlikte silinecek.')) {
    switch (target) {
      case AppLanguage.tr: return text;
      case AppLanguage.de: case AppLanguage.deCh:
        return 'Beide Einträge für diesen Tag werden zusammen gelöscht.';
      case AppLanguage.nl:
        return 'Beide metingen voor deze dag worden samen verwijderd.';
      case AppLanguage.fr:
        return 'Les deux mesures de cette journée seront supprimées.';
      case AppLanguage.ga:
        return 'Scriosfar an dá thaifead don lá seo le chéile.';
      case AppLanguage.ru:
        return 'Обе записи за этот день будут удалены.';
      case AppLanguage.ar:
        return 'سيتم حذف كلا قياسي هذا اليوم معاً.';
      case AppLanguage.zh:
        return '该日期的两条记录将被一同删除。';
      case AppLanguage.ja:
        return 'この日の両方の記録がまとめて削除されます。';
      case AppLanguage.ko:
        return '해당 날짜의 두 기록이 모두 삭제됩니다.';
      case AppLanguage.es:
        return 'Se eliminarán ambos registros de este día.';
      case AppLanguage.it:
        return 'Entrambe le registrazioni del giorno saranno eliminate.';
      case AppLanguage.pt:
        return 'Ambos os registos deste dia serão eliminados.';
      case AppLanguage.sv:
        return 'Båda mätningarna för denna dag kommer att raderas.';
      default:
        return 'Both records for this day will be deleted together.';
    }
  }

  // "X tarihinde hem sabah hem akşam kaydı bulunuyor. Silmek istediğin ölçümü seç:"
  if (text.contains('tarihinde hem sabah hem akşam kaydı bulunuyor')) {
    final date = text.split(' tarihinde')[0];
    switch (target) {
      case AppLanguage.tr: return text;
      case AppLanguage.de: case AppLanguage.deCh:
        return 'Am $date gibt es sowohl Morgen- als auch Abendeinträge. Wähle die Messung zum Löschen:';
      case AppLanguage.nl:
        return 'Op $date zijn zowel ochtend- als avondmetingen aanwezig. Kies welke je wilt verwijderen:';
      case AppLanguage.fr:
        return 'Le $date comprend des mesures matin et soir. Choisissez celle à supprimer :';
      case AppLanguage.ga:
        return 'Tá taifead maidine agus tráthnóna araon ar $date. Roghnaigh cé acu atá le scriosadh:';
      case AppLanguage.ru:
        return 'На $date есть утренние и вечерние записи. Выберите измерение для удаления:';
      case AppLanguage.ar:
        return 'يوجد قياس صباحي ومسائي في $date. اختر القياس المراد حذفه:';
      case AppLanguage.zh:
        return '$date 同时存在早晚两条记录。请选择要删除的测量：';
      case AppLanguage.ja:
        return '$date には朝と夜の両方の記録があります。削除する測定を選択してください：';
      case AppLanguage.ko:
        return '$date 에 아침과 저녁 기록이 모두 있습니다. 삭제할 측정을 선택하세요:';
      case AppLanguage.es:
        return 'El $date tiene registros de mañana y tarde. Selecciona cuál eliminar:';
      case AppLanguage.it:
        return 'Il $date contiene sia la registrazione mattutina che serale. Scegli quale eliminare:';
      case AppLanguage.pt:
        return 'O dia $date tem registos de manhã e noite. Escolha qual pretende eliminar:';
      case AppLanguage.sv:
        return '$date har både morgon- och kvällsmätningar. Välj vilken du vill radera:';
      default:
        return '$date has both morning and evening records. Select the measurement to delete:';
    }
  }

  // "Sabah (85.0 kg)" in delete dialog
  if (text.startsWith('Sabah (') || text.startsWith('Akşam (')) {
    final slotName = text.split(' (')[0];
    final rest = text.substring(slotName.length);
    return '${trText(slotName, target)}$rest';
  }

  // "X kaydı (Y kg) düzenleniyor."
  if (text.contains(' kaydı (') && text.endsWith(' düzenleniyor.')) {
    return text
        .replaceAll(' kaydı (', ' (${t('Kayıt')}) (')
        .replaceAll(' düzenleniyor.', ' • ${t('Düzenle')}');
  }

  // "Sabah kilosu için 2 ile 500 kg arasında geçerli bir değer girin."
  if (text.contains('kilosu için 2 ile 500 kg arasında geçerli bir değer girin.')) {
    final slotName = text.split(' ')[0];
    return '${t('2 ile 500 kg arasında geçerli bir kilo değeri girin.')} (${trText(slotName, target)})';
  }

  // "Örn. 85.0"
  if (text.startsWith('Örn. ')) {
    return '${t('Örn.')} ${text.substring(5)}';
  }

  // "${formatMonthYear(selectedMonth)} sabah ve akşam kiloları"
  if (text.endsWith(' sabah ve akşam kiloları')) {
    final prefix = text.replaceAll(' sabah ve akşam kiloları', '');
    return '$prefix • ${t('Sabah ve Akşam Ölçümleri')}';
  }

  // "${slot.label} serisi"
  if (text.endsWith(' serisi')) {
    final prefix = text.replaceAll(' serisi', '');
    return '${trText(prefix, target)} • ${t('serisi')}';
  }

  // "Sabah: Son Kiloyu Kaydet (85.0 kg)"
  if (text.contains('Son Kiloyu Kaydet')) {
    final parts = text.split(': Son Kiloyu Kaydet');
    final slot = parts[0];
    final wMatch = RegExp(r'\(([\d.,]+\s*kg)\)').firstMatch(text);
    final w = wMatch != null ? ' (${wMatch.group(1)})' : '';
    return '${trText(slot, target)}: ${t('Son Kiloyu Kaydet')}$w';
  }

  // "Sabah Kilo Hatırlatması (09:00)" / "Morning Kilo Hatırlatması (09:00)"
  // "Sabah Kilo & Bel Hatırlatması (09:00)"
  final notifTitleMatch = RegExp(
    r'^(.+?)\s+Kilo(?:\s+&\s+Bel)?\s+Hatırlatması\s+\((.+?)\)$',
  ).firstMatch(text);
  if (notifTitleMatch != null) {
    final slot = notifTitleMatch.group(1)!;
    final timeOrStatus = notifTitleMatch.group(2)!;
    final localizedSlot = trText(slot, target);
    final isSnoozed = timeOrStatus == 'Ertelendi';
    final statusText = isSnoozed ? t('Ertelendi') : timeOrStatus;
    final hasWaist = text.contains('& Bel');
    switch (target) {
      case AppLanguage.tr:
        return text;
      case AppLanguage.de:
      case AppLanguage.deCh:
        return hasWaist
            ? '$localizedSlot-Gewichts- & Taillenerinnerung ($statusText)'
            : '$localizedSlot-Gewichtserinnerung ($statusText)';
      case AppLanguage.nl:
        return hasWaist
            ? '$localizedSlot-gewichts- & tailleherinnering ($statusText)'
            : '$localizedSlot-gewichtsherinnering ($statusText)';
      case AppLanguage.fr:
        return hasWaist
            ? 'Rappel de poids et tour de taille $localizedSlot ($statusText)'
            : 'Rappel de poids $localizedSlot ($statusText)';
      case AppLanguage.ga:
        return hasWaist
            ? 'Meabhrúchán Mheáchain & Choime $localizedSlot ($statusText)'
            : 'Meabhrúchán Mheáchain $localizedSlot ($statusText)';
      case AppLanguage.ru:
        return hasWaist
            ? 'Напоминание о весе и талии: $localizedSlot ($statusText)'
            : 'Напоминание о весе: $localizedSlot ($statusText)';
      case AppLanguage.ar:
        return hasWaist
            ? 'تنبيه وزن ومحيط خصر $localizedSlot ($statusText)'
            : 'تنبيه وزن $localizedSlot ($statusText)';
      case AppLanguage.zh:
        return hasWaist
            ? '$localizedSlot体重与腰围提醒 ($statusText)'
            : '$localizedSlot体重提醒 ($statusText)';
      case AppLanguage.ja:
        return hasWaist
            ? '$localizedSlotの体重＆腹囲リマインダー ($statusText)'
            : '$localizedSlotの体重リマインダー ($statusText)';
      case AppLanguage.ko:
        return hasWaist
            ? '$localizedSlot 체중 및 허리 둘레 알림 ($statusText)'
            : '$localizedSlot 체중 알림 ($statusText)';
      case AppLanguage.es:
        return hasWaist
            ? 'Recordatorio de peso y cintura de $localizedSlot ($statusText)'
            : 'Recordatorio de peso de $localizedSlot ($statusText)';
      case AppLanguage.it:
        return hasWaist
            ? 'Promemoria peso e vita $localizedSlot ($statusText)'
            : 'Promemoria peso $localizedSlot ($statusText)';
      case AppLanguage.pt:
        return hasWaist
            ? 'Lembrete de peso e cintura de $localizedSlot ($statusText)'
            : 'Lembrete de peso de $localizedSlot ($statusText)';
      case AppLanguage.sv:
        return hasWaist
            ? 'Vikt- och midjepåminnelse $localizedSlot ($statusText)'
            : 'Viktpåminnelse $localizedSlot ($statusText)';
      default:
        return hasWaist
            ? '$localizedSlot Weight & Waist Reminder ($statusText)'
            : '$localizedSlot Weight Reminder ($statusText)';
    }
  }

  // "1 saat önce ertelediğin sabah kilonu ve bel ölçünü şimdi kaydedebilirsin."
  final snoozeBodyMatch = RegExp(
    r'^1 saat önce ertelediğin (.+?) kilonu(?:\s+ve\s+bel\s+ölçünü)? şimdi kaydedebilirsin\.$',
  ).firstMatch(text);
  if (snoozeBodyMatch != null) {
    final slot = snoozeBodyMatch.group(1)!;
    final localizedSlot = trText(slot, target);
    final hasWaist = text.contains('bel ölçünü');
    switch (target) {
      case AppLanguage.tr:
        return text;
      case AppLanguage.de:
      case AppLanguage.deCh:
        return hasWaist
            ? 'Du kannst dein vor 1 Stunde verschobenes $localizedSlot-Gewicht und deinen Taillenumfang jetzt eintragen.'
            : 'Du kannst dein vor 1 Stunde verschobenes $localizedSlot-Gewicht jetzt eintragen.';
      case AppLanguage.nl:
        return hasWaist
            ? 'Je kunt nu je $localizedSlot-gewicht en tailleomvang registreren die je een uur geleden hebt uitgesteld.'
            : 'Je kunt nu je $localizedSlot-gewicht registreren dat je een uur geleden hebt uitgesteld.';
      case AppLanguage.fr:
        return hasWaist
            ? 'Vous pouvez maintenant enregistrer votre pesée et tour de taille $localizedSlot reportés il y a 1 heure.'
            : 'Vous pouvez maintenant enregistrer votre pesée $localizedSlot reportée il y a 1 heure.';
      case AppLanguage.ga:
        return hasWaist
            ? 'Is féidir leat do mheáchan agus do thomhas coime $localizedSlot a chuir tú siar uair an chloig ó shin a thaifeadadh anois.'
            : 'Is féidir leat do mheáchan $localizedSlot a chuir tú siar uair an chloig ó shin a thaifeadadh anois.';
      case AppLanguage.ru:
        return hasWaist
            ? 'Теперь вы можете записать свой $localizedSlot вес и обхват талии, отложенные час назад.'
            : 'Теперь вы можете записать свой $localizedSlot вес, отложенный час назад.';
      case AppLanguage.ar:
        return hasWaist
            ? 'يمكنك الآن تسجيل وزن ومحيط خصر $localizedSlot الذي أجلته قبل ساعة.'
            : 'يمكنك الآن تسجيل وزن $localizedSlot الذي أجلته قبل ساعة.';
      case AppLanguage.zh:
        return hasWaist
            ? '现在可以记录 1 小时前推迟的$localizedSlot体重和腰围了。'
            : '现在可以记录 1 小时前推迟的$localizedSlot体重了。';
      case AppLanguage.ja:
        return hasWaist
            ? '1時間前にスヌーズした$localizedSlotの体重と腹囲を今すぐ記録できます。'
            : '1時間前にスヌーズした$localizedSlotの体重を今すぐ記録できます。';
      case AppLanguage.ko:
        return hasWaist
            ? '1시간 전에 연기했던 $localizedSlot 체중과 허리 둘레를 지금 기록할 수 있습니다.'
            : '1시간 전에 연기했던 $localizedSlot 체중을 지금 기록할 수 있습니다.';
      case AppLanguage.es:
        return hasWaist
            ? 'Ya puedes registrar tu peso y cintura de $localizedSlot pospuestos hace 1 hora.'
            : 'Ya puedes registrar tu peso de $localizedSlot pospuesto hace 1 hora.';
      case AppLanguage.it:
        return hasWaist
            ? 'Ora puoi registrare il peso e la misura della vita $localizedSlot posticipati un\'ora fa.'
            : 'Ora puoi registrare il peso $localizedSlot posticipato un\'ora fa.';
      case AppLanguage.pt:
        return hasWaist
            ? 'Podes agora registar o teu peso e cintura de $localizedSlot adiados há 1 hora.'
            : 'Podes agora registar o teu peso de $localizedSlot adiado há 1 hora.';
      case AppLanguage.sv:
        return hasWaist
            ? 'Nu kan du registrera din $localizedSlot-vikt och midjemått som du snoozade för en timme sedan.'
            : 'Nu kan du registrera din $localizedSlot-vikt som du snoozade för en timme sedan.';
      default:
        return hasWaist
            ? 'You can now log your $localizedSlot weight and waist measurement that you snoozed an hour ago.'
            : 'You can now log your $localizedSlot weight that you snoozed an hour ago.';
    }
  }

  // "Son 7 günde sabah ölçümlerine göre -0.5 kg değişim kaydedildi."
  final reportSlotChangeMatch = RegExp(
    r'^(.+?)\s+(.+?)\s+ölçümlerine göre\s+([+-]?[\d.,]+\s*kg)\s+değişim kaydedildi\.$',
  ).firstMatch(text);
  if (reportSlotChangeMatch != null) {
    final period = reportSlotChangeMatch.group(1)!;
    final slot = reportSlotChangeMatch.group(2)!;
    final diff = reportSlotChangeMatch.group(3)!;
    return '${trText(period, target)} (${trText(slot, target)}): $diff • ${t('değişim kaydedildi.')}';
  }
return _dictionary[text]?[AppLanguage.en] ?? text;
}

const _monthsByLang = <AppLanguage, List<String>>{
  AppLanguage.tr: [
    'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
    'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık',
  ],
  AppLanguage.en: [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ],
  AppLanguage.de: [
    'Januar', 'Februar', 'März', 'April', 'Mai', 'Juni',
    'Juli', 'August', 'September', 'Oktober', 'November', 'Dezember',
  ],
  AppLanguage.deCh: [
    'Januar', 'Februar', 'März', 'April', 'Mai', 'Juni',
    'Juli', 'August', 'September', 'Oktober', 'November', 'Dezember',
  ],
  AppLanguage.nl: [
    'januari', 'februari', 'maart', 'april', 'mei', 'juni',
    'juli', 'augustus', 'september', 'oktober', 'november', 'december',
  ],
  AppLanguage.fr: [
    'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
    'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
  ],
  AppLanguage.ga: [
    'Eanáir', 'Feabhra', 'Márta', 'Aibreán', 'Bealtaine', 'Meitheamh',
    'Iúil', 'Lúnasa', 'Meán Fómhair', 'Deireadh Fómhair', 'Samhain', 'Nollaig',
  ],
  AppLanguage.ru: [
    'Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь',
    'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь',
  ],
  AppLanguage.ar: [
    'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
    'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
  ],
  AppLanguage.zh: [
    '1月', '2月', '3月', '4月', '5月', '6月',
    '7月', '8月', '9月', '10月', '11月', '12月',
  ],
  AppLanguage.ja: [
    '1月', '2月', '3月', '4月', '5月', '6月',
    '7月', '8月', '9月', '10月', '11月', '12月',
  ],
  AppLanguage.ko: [
    '1월', '2월', '3월', '4월', '5월', '6월',
    '7월', '8월', '9월', '10월', '11월', '12월',
  ],
  AppLanguage.es: [
    'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
    'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
  ],
  AppLanguage.it: [
    'gennaio', 'febbraio', 'marzo', 'aprile', 'maggio', 'giugno',
    'luglio', 'agosto', 'settembre', 'ottobre', 'novembre', 'dicembre',
  ],
  AppLanguage.pt: [
    'janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho',
    'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro',
  ],
  AppLanguage.sv: [
    'januari', 'februari', 'mars', 'april', 'maj', 'juni',
    'juli', 'augusti', 'september', 'oktober', 'november', 'december',
  ],
};

const _shortMonthsByLang = <AppLanguage, List<String>>{
  AppLanguage.tr: ['Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz', 'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'],
  AppLanguage.en: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'],
  AppLanguage.de: ['Jan', 'Feb', 'Mär', 'Apr', 'Mai', 'Jun', 'Jul', 'Aug', 'Sep', 'Okt', 'Nov', 'Dez'],
  AppLanguage.deCh: ['Jan', 'Feb', 'Mär', 'Apr', 'Mai', 'Jun', 'Jul', 'Aug', 'Sep', 'Okt', 'Nov', 'Dez'],
  AppLanguage.nl: ['jan', 'feb', 'mrt', 'apr', 'mei', 'jun', 'jul', 'aug', 'sep', 'okt', 'nov', 'dec'],
  AppLanguage.fr: ['janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin', 'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.'],
  AppLanguage.ga: ['Ean', 'Fea', 'Már', 'Aib', 'Bea', 'Mei', 'Iúi', 'Lún', 'MFó', 'DFó', 'Sam', 'Nol'],
  AppLanguage.ru: ['Янв', 'Фев', 'Мар', 'Апр', 'Май', 'Июн', 'Июл', 'Авг', 'Сен', 'Окт', 'Ноя', 'Дек'],
  AppLanguage.ar: ['ينا', 'فبر', 'مار', 'أبر', 'ماي', 'يون', 'يول', 'أغس', 'سبت', 'أكت', 'نوف', 'ديس'],
  AppLanguage.zh: ['1月', '2月', '3月', '4月', '5月', '6月', '7月', '8月', '9月', '10月', '11月', '12月'],
  AppLanguage.ja: ['1月', '2月', '3月', '4月', '5月', '6月', '7月', '8月', '9月', '10月', '11月', '12月'],
  AppLanguage.ko: ['1월', '2월', '3월', '4월', '5월', '6월', '7월', '8월', '9월', '10월', '11월', '12월'],
  AppLanguage.es: ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'],
  AppLanguage.it: ['gen', 'feb', 'mar', 'apr', 'mag', 'giu', 'lug', 'ago', 'set', 'ott', 'nov', 'dic'],
  AppLanguage.pt: ['jan', 'fev', 'mar', 'abr', 'mai', 'jun', 'jul', 'ago', 'set', 'out', 'nov', 'dez'],
  AppLanguage.sv: ['jan', 'feb', 'mar', 'apr', 'maj', 'jun', 'jul', 'aug', 'sep', 'okt', 'nov', 'dec'],
};

const _weekdaysByLang = <AppLanguage, List<String>>{
  AppLanguage.tr: ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'],
  AppLanguage.en: ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'],
  AppLanguage.de: ['Montag', 'Dienstag', 'Mittwoch', 'Donnerstag', 'Freitag', 'Samstag', 'Sonntag'],
  AppLanguage.deCh: ['Montag', 'Dienstag', 'Mittwoch', 'Donnerstag', 'Freitag', 'Samstag', 'Sonntag'],
  AppLanguage.nl: ['Maandag', 'Dinsdag', 'Woensdag', 'Donderdag', 'Vrijdag', 'Zaterdag', 'Zondag'],
  AppLanguage.fr: ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'],
  AppLanguage.ga: ['Dé Luain', 'Dé Máirt', 'Dé Céadaoin', 'Déardaoin', 'Dé hAoine', 'Dé Sathairn', 'Dé Domhnaigh'],
  AppLanguage.ru: ['Понедельник', 'Вторник', 'Среда', 'Четверг', 'Пятница', 'Суббота', 'Воскресенье'],
  AppLanguage.ar: ['الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'],
  AppLanguage.zh: ['星期一', '星期二', '星期三', '星期四', '星期五', '星期六', '星期日'],
  AppLanguage.ja: ['月曜日', '火曜日', '水曜日', '木曜日', '金曜日', '土曜日', '日曜日'],
  AppLanguage.ko: ['월요일', '화요일', '수요일', '목요일', '금요일', '토요일', '일요일'],
  AppLanguage.es: ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'],
  AppLanguage.it: ['Lunedì', 'Martedì', 'Mercoledì', 'Giovedì', 'Venerdì', 'Sabato', 'Domenica'],
  AppLanguage.pt: ['Segunda-feira', 'Terça-feira', 'Quarta-feira', 'Quinta-feira', 'Sexta-feira', 'Sábado', 'Domingo'],
  AppLanguage.sv: ['Måndag', 'Tisdag', 'Onsdag', 'Torsdag', 'Fredag', 'Lördag', 'Söndag'],
};

const _shortWeekdaysByLang = <AppLanguage, List<String>>{
  AppLanguage.tr: ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'],
  AppLanguage.en: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
  AppLanguage.de: ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'],
  AppLanguage.deCh: ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'],
  AppLanguage.nl: ['Ma', 'Di', 'Wo', 'Do', 'Vr', 'Za', 'Zo'],
  AppLanguage.fr: ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'],
  AppLanguage.ga: ['Lua', 'Mái', 'Céa', 'Déa', 'Aoi', 'Sat', 'Dom'],
  AppLanguage.ru: ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'],
  AppLanguage.ar: ['إثن', 'ثلا', 'أرب', 'خمي', 'جمع', 'سبت', 'أحد'],
  AppLanguage.zh: ['周一', '周二', '周三', '周四', '周五', '周六', '周日'],
  AppLanguage.ja: ['月', '火', '水', '木', '金', '土', '日'],
  AppLanguage.ko: ['월', '화', '수', '목', '금', '토', '일'],
  AppLanguage.es: ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'],
  AppLanguage.it: ['Lun', 'Mar', 'Mer', 'Gio', 'Ven', 'Sab', 'Dom'],
  AppLanguage.pt: ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'],
  AppLanguage.sv: ['Mån', 'Tis', 'Ons', 'Tor', 'Fre', 'Lör', 'Sön'],
};

Map<AppLanguage, String> _m({
  required String en,
  required String de,
  required String nl,
  required String fr,
  required String ga,
  required String ru,
  required String ar,
  required String zh,
  required String ja,
  required String ko,
  String? es,
  String? it,
  String? pt,
  String? sv,
  String? deCh,
}) => {
  AppLanguage.en: en,
  AppLanguage.de: de,
  AppLanguage.deCh: deCh ?? de,
  AppLanguage.nl: nl,
  AppLanguage.fr: fr,
  AppLanguage.ga: ga,
  AppLanguage.ru: ru,
  AppLanguage.ar: ar,
  AppLanguage.zh: zh,
  AppLanguage.ja: ja,
  AppLanguage.ko: ko,
  AppLanguage.es: es ?? en,
  AppLanguage.it: it ?? en,
  AppLanguage.pt: pt ?? en,
  AppLanguage.sv: sv ?? en,
};

final _dictionary = <String, Map<AppLanguage, String>>{
  // Navigasyon & Ana Başlıklar
  'Kilo Takip': _m(
    en: 'Weight Tracker', de: 'Gewichtstracker', nl: 'Gewichtsmeter',
    fr: 'Suivi du Poids', ga: 'Rianaire Meáchain', ru: 'Контроль Веса',
    ar: 'متتبع الوزن', zh: '体重追踪', ja: '体重管理', ko: '체중 관리',
    es: 'Control de Peso', it: 'Tracciamento Peso', pt: 'Controlo de Peso', sv: 'Viktspårare',
  ),
  'Ana Sayfa': _m(
    en: 'Home', de: 'Start', nl: 'Home', fr: 'Accueil', ga: 'Baile',
    ru: 'Главная', ar: 'الرئيسية', zh: '首页', ja: 'ホーム', ko: '홈',
    es: 'Inicio', it: 'Home', pt: 'Início', sv: 'Hem',
  ),
  'Grafikler': _m(
    en: 'Charts', de: 'Diagramme', nl: 'Grafieken', fr: 'Graphiques', ga: 'Cairteacha',
    ru: 'Графики', ar: 'الرسوم', zh: '图表', ja: 'グラフ', ko: '차트',
    es: 'Gráficos', it: 'Grafici', pt: 'Gráficos', sv: 'Diagram',
  ),
  'Geçmiş': _m(
    en: 'History', de: 'Verlauf', nl: 'Historie', fr: 'Historique', ga: 'Stair',
    ru: 'История', ar: 'السجل', zh: '历史', ja: '履歴', ko: '기록',
    es: 'Historial', it: 'Cronologia', pt: 'Histórico', sv: 'Historik',
  ),
  'Raporlar': _m(
    en: 'Reports', de: 'Berichte', nl: 'Rapporten', fr: 'Rapports', ga: 'Tuairiscí',
    ru: 'Отчёты', ar: 'التقارير', zh: '报告', ja: 'レポート', ko: '리포트',
    es: 'Informes', it: 'Report', pt: 'Relatórios', sv: 'Rapporter',
  ),
  'Hesap': _m(
    en: 'Calc', de: 'Rechner', nl: 'Bereken', fr: 'Calcul', ga: 'Áireamh',
    ru: 'Расчёт', ar: 'الحاسبة', zh: '计算器', ja: '計算', ko: '계산기',
    es: 'Cálculo', it: 'Calcolo', pt: 'Cálculo', sv: 'Kalkyl',
  ),
  'Hesap & Analiz': _m(
    en: 'BMI & Body Calculator', de: 'BMI & Körperrechner', nl: 'BMI & Lichaamscalculator',
    fr: 'Calculateur IMC & Corps', ga: 'Áireamhán BMI & Coirp', ru: 'ИМТ и Калькулятор тела',
    ar: 'حاسبة مؤشر كتلة الجسم', zh: 'BMI与身体计算器', ja: 'BMI・体組成計算', ko: 'BMI 및 신체 계산기',
    es: 'Calculadora IMC y Cuerpo', it: 'Calcolatore IMC e Corpo', pt: 'Calculadora IMC e Corpo', sv: 'BMI & Kroppskalkylator',
  ),
  'Ayarlar': _m(
    en: 'Settings', de: 'Einstellungen', nl: 'Instellingen', fr: 'Paramètres', ga: 'Socruithe',
    ru: 'Настройки', ar: 'الإعدادات', zh: '设置', ja: '設定', ko: '설정',
    es: 'Ajustes', it: 'Impostazioni', pt: 'Definições', sv: 'Inställningar',
  ),
  'Sabah': _m(
    en: 'Morning', de: 'Morgen', nl: 'Ochtend', fr: 'Matin', ga: 'Maidin',
    ru: 'Утро', ar: 'الصباح', zh: '早晨', ja: '朝', ko: '아침',
    es: 'Mañana', it: 'Mattina', pt: 'Manhã', sv: 'Morgon',
  ),
  'Akşam': _m(
    en: 'Evening', de: 'Abend', nl: 'Avond', fr: 'Soir', ga: 'Tráthnóna',
    ru: 'Вечер', ar: 'المساء', zh: '晚上', ja: '夜', ko: '저녁',
    es: 'Noche', it: 'Sera', pt: 'Noite', sv: 'Kväll',
  ),
  'Saat': _m(
    en: 'Time', de: 'Uhr', nl: 'Tijd', fr: 'Heure', ga: 'Am',
    ru: 'Время', ar: 'الساعة', zh: '时间', ja: '時刻', ko: '시간',
    es: 'Hora', it: 'Ora', pt: 'Hora', sv: 'Tid',
  ),
  'Tarih': _m(
    en: 'Date', de: 'Datum', nl: 'Datum', fr: 'Date', ga: 'Dáta',
    ru: 'Дата', ar: 'التاريخ', zh: '日期', ja: '日付', ko: '날짜',
    es: 'Fecha', it: 'Data', pt: 'Data', sv: 'Datum',
  ),
  'Bugün': _m(
    en: 'Today', de: 'Heute', nl: 'Vandaag', fr: "Aujourd'hui", ga: 'Inniu',
    ru: 'Сегодня', ar: 'اليوم', zh: '今天', ja: '今日', ko: '오늘',
    es: 'Hoy', it: 'Oggi', pt: 'Hoje', sv: 'Idag',
  ),
  'Bugünkü Takibin': _m(
    en: "Today's Tracking", de: 'Heutige Erfassung', nl: 'Tracking van Vandaag',
    fr: 'Suivi du Jour', ga: 'Rianú Inniu', ru: 'Сегодняшний учёт',
    ar: 'متابعة اليوم', zh: '今日追踪', ja: '今日の記録', ko: '오늘의 체중 기록',
    es: 'Seguimiento de Hoy', it: 'Tracciamento di Oggi', pt: 'Registo de Hoje', sv: 'Dagens Uppföljning',
  ),
  'Sabah ve akşam kilonu kolayca takip et.': _m(
    en: 'Easily track your morning and evening weight.',
    de: 'Verfolge einfach dein Morgen- und Abendgewicht.',
    nl: 'Volg eenvoudig je ochtend- en avondgewicht.',
    fr: 'Suivez facilement votre poids du matin et du soir.',
    ga: 'Rianaigh do mheáchan maidine agus tráthnóna go héasca.',
    ru: 'Легко отслеживайте утренний и вечерний вес.',
    ar: 'تابع وزنك صباحاً ومساءً بكل سهولة.',
    zh: '轻松追踪您的早晚体重变化。',
    ja: '朝と夜の体重を簡単に記録・管理できます。',
    ko: '아침과 저녁 체중을 쉽고 빠르게 기록하세요.',
    es: 'Sigue fácilmente tu peso de la mañana y de la noche.',
    it: 'Monitora facilmente il tuo peso mattutino e serale.',
    pt: 'Acompanhe facilmente o seu peso de manhã e à noite.',
    sv: 'Följ enkelt din morgon- och kvällsvikt.',
  ),
  'Henüz kilo kaydın bulunmuyor. İlk ölçümünü ekleyerek başlayabilirsin.': _m(
    en: 'No weight records yet. Start by adding your first measurement.',
    de: 'Noch keine Einträge. Füge deine erste Messung hinzu.',
    nl: 'Nog geen metingen. Voeg je eerste gewicht toe om te starten.',
    fr: 'Aucun enregistrement. Commencez par ajouter votre première pesée.',
    ga: 'Níl aon taifead meáchain fós. Cuir do chéad tomhas leis.',
    ru: 'Записей пока нет. Начните с добавления первого измерения.',
    ar: 'لا توجد سجلات وزن بعد. ابدأ بإضافة أول قياس لك.',
    zh: '暂无体重记录，添加您的第一次测量开始吧。',
    ja: 'まだ記録がありません。最初の体重を追加して始めましょう。',
    ko: '아직 기록이 없습니다. 첫 번째 체중을 추가해 보세요.',
    es: 'Aún no hay registros. Empieza añadiendo tu primera medición.',
    it: 'Nessuna registrazione. Inizia aggiungendo la prima misurazione.',
    pt: 'Ainda sem registos. Comece por adicionar a sua primeira medição.',
    sv: 'Inga viktposter ännu. Börja med att lägga till din första mätning.',
  ),
  'Sabah Kilosu': _m(
    en: 'Morning Weight', de: 'Morgengewicht', nl: 'Ochtendgewicht',
    fr: 'Poids du Matin', ga: 'Meáchan Maidine', ru: 'Утренний вес',
    ar: 'وزن الصباح', zh: '早晨体重', ja: '朝の体重', ko: '아침 체중',
    es: 'Peso Mañana', it: 'Peso Mattina', pt: 'Peso Manhã', sv: 'Morgonvikt',
  ),
  'Akşam Kilosu': _m(
    en: 'Evening Weight', de: 'Abendgewicht', nl: 'Avondgewicht',
    fr: 'Poids du Soir', ga: 'Meáchan Tráthnóna', ru: 'Вечерний вес',
    ar: 'وزن المساء', zh: '晚上体重', ja: '夜の体重', ko: '저녁 체중',
    es: 'Peso Noche', it: 'Peso Sera', pt: 'Peso Noite', sv: 'Kvällsvikt',
  ),
  'Sabah kilosu eklenmedi.': _m(
    en: 'Not logged yet', de: 'Nicht erfasst', nl: 'Niet ingevoerd',
    fr: 'Non renseigné', ga: 'Gan taifead', ru: 'Не добавлено',
    ar: 'لم يُسجل بعد', zh: '未记录', ja: '未入力', ko: '미입력',
    es: 'No registrado', it: 'Non inserito', pt: 'Não registado', sv: 'Ej registrerad',
  ),
  'Akşam kilosu eklenmedi.': _m(
    en: 'Not logged yet', de: 'Nicht erfasst', nl: 'Niet ingevoerd',
    fr: 'Non renseigné', ga: 'Gan taifead', ru: 'Не добавлено',
    ar: 'لم يُسجل بعد', zh: '未记录', ja: '未入力', ko: '미입력',
    es: 'No registrado', it: 'Non inserito', pt: 'Não registado', sv: 'Ej registrerad',
  ),
  'Kilo Gir': _m(
    en: 'Enter Weight', de: 'Gewicht eingeben', nl: 'Voer gewicht in',
    fr: 'Saisir le poids', ga: 'Cuir isteach', ru: 'Ввести вес',
    ar: 'أدخل الوزن', zh: '输入体重', ja: '体重を入力', ko: '체중 입력',
    es: 'Ingresar peso', it: 'Inserisci peso', pt: 'Inserir peso', sv: 'Ange vikt',
  ),
  'Günlük Fark': _m(
    en: 'Daily Difference', de: 'Tagesdifferenz', nl: 'Dagelijks Verschil',
    fr: 'Écart Quotidien', ga: 'Difríocht Laethúil', ru: 'Дневная разница',
    ar: 'الفرق اليومي', zh: '日内差值', ja: '1日の増減', ko: '일일 체중 차이',
    es: 'Diferencia Diaria', it: 'Differenza Giornaliera', pt: 'Diferença Diária', sv: 'Daglig Skillnad',
  ),
  'Henüz hesaplanamadı.': _m(
    en: 'Not calculated yet.', de: 'Noch nicht berechnet.', nl: 'Nog niet berekend.',
    fr: 'Pas encore calculé.', ga: 'Gan ríomh fós.', ru: 'Ещё не рассчитано.',
    ar: 'لم يُحسب بعد.', zh: '尚未计算', ja: '未計算', ko: '아직 계산되지 않음',
    es: 'Aún no calculado.', it: 'Non ancora calcolato.', pt: 'Ainda não calculado.', sv: 'Ännu ej beräknad.',
  ),
  'Son 7 Gün': _m(
    en: 'Last 7 Days', de: 'Letzte 7 Tage', nl: 'Laatste 7 Dagen',
    fr: '7 Derniers Jours', ga: '7 Lá Deireanacha', ru: 'За 7 дней',
    ar: 'آخر 7 أيام', zh: '最近7天', ja: '過去7日間', ko: '최근 7일',
    es: 'Últimos 7 Días', it: 'Ultimi 7 Giorni', pt: 'Últimos 7 Dias', sv: 'Senaste 7 Dagar',
  ),
  'Haftalık Ortalama': _m(
    en: 'Weekly Average', de: 'Wochenschnitt', nl: 'Weekgemiddelde',
    fr: 'Moyenne Hebdo', ga: 'Meán Seachtainiúil', ru: 'Среднее за неделю',
    ar: 'المتوسط الأسبوعي', zh: '周平均', ja: '週平均', ko: '주간 평균',
    es: 'Media Semanal', it: 'Media Settimanale', pt: 'Média Semanal', sv: 'Veckosnitt',
  ),
  'Toplam Kayıt': _m(
    en: 'Total Records', de: 'Einträge Gesamt', nl: 'Totaal Metingen',
    fr: 'Total Entrées', ga: 'Taifid Iomlána', ru: 'Всего записей',
    ar: 'إجمالي السجلات', zh: '总记录数', ja: '総記録数', ko: '총 기록 수',
    es: 'Total Registros', it: 'Totale Record', pt: 'Total Registos', sv: 'Totalt Antal',
  ),
  'Günlük Su Tüketimi': _m(
    en: 'Daily Water Intake', de: 'Tägliche Wasseraufnahme', nl: 'Dagelijkse Waterinname',
    fr: 'Hydratation Quotidienne', ga: 'Uisce Laethúil', ru: 'Потребление воды',
    ar: 'شرب الماء اليومي', zh: '每日饮水量', ja: '1日の水分摂取', ko: '일일 수분 섭취량',
    es: 'Consumo Diario de Agua', it: 'Idratazione Giornaliera', pt: 'Consumo Diário de Água', sv: 'Dagligt Vattenintag',
  ),
  'Bardak': _m(
    en: 'Glasses', de: 'Gläser', nl: 'Glazen', fr: 'Verres', ga: 'Gloine',
    ru: 'стак.', ar: 'أكواب', zh: '杯', ja: '杯', ko: '잔',
    es: 'Vasos', it: 'Bicchieri', pt: 'Copos', sv: 'Glas',
  ),
  'Hedef': _m(
    en: 'Goal', de: 'Ziel', nl: 'Doel', fr: 'Objectif', ga: 'Sprioc',
    ru: 'Цель', ar: 'الهدف', zh: '目标', ja: '目標', ko: '목표',
    es: 'Meta', it: 'Obiettivo', pt: 'Meta', sv: 'Mål',
  ),
  'Mini Grafik': _m(
    en: 'Mini Chart', de: 'Mini-Diagramm', nl: 'Minigrafiek',
    fr: 'Mini Graphique', ga: 'Mionchairt', ru: 'Мини-график',
    ar: 'رسم بياني مصغر', zh: '迷你趋势图', ja: 'ミニグラフ', ko: '미니 차트',
    es: 'Mini Gráfico', it: 'Mini Grafico', pt: 'Mini Gráfico', sv: 'Minidiagram',
  ),
  'Son 7 günün kilo değişimi': _m(
    en: 'Weight trend of the last 7 days', de: 'Gewichtsverlauf der letzten 7 Tage',
    nl: 'Gewichtsverloop van de laatste 7 dagen', fr: 'Évolution des 7 derniers jours',
    ga: 'Athruithe meáchain le 7 lá anuas', ru: 'Изменение веса за 7 дней',
    ar: 'تغير الوزن خلال آخر 7 أيام', zh: '最近7天体重变化趋势',
    ja: '過去7日間の体重推移', ko: '최근 7일간의 체중 변화',
    es: 'Evolución de los últimos 7 días', it: 'Andamento degli ultimi 7 giorni',
    pt: 'Evolução dos últimos 7 dias', sv: 'Viktutveckling senaste 7 dagarna',
  ),
  '7 Gün': _m(
    en: '7 Days', de: '7 Tage', nl: '7 Dagen', fr: '7 Jours', ga: '7 Lá',
    ru: '7 дней', ar: '7 أيام', zh: '7天', ja: '7日間', ko: '7일',
    es: '7 Días', it: '7 Giorni', pt: '7 Dias', sv: '7 Dagar',
  ),
  '14 Gün': _m(
    en: '14 Days', de: '14 Tage', nl: '14 Dagen', fr: '14 Jours', ga: '14 Lá',
    ru: '14 дней', ar: '14 يوماً', zh: '14天', ja: '14日間', ko: '14일',
    es: '14 Días', it: '14 Giorni', pt: '14 Dias', sv: '14 Dagar',
  ),
  'Aylık': _m(
    en: 'Monthly', de: 'Monatlich', nl: 'Maandelijks', fr: 'Mensuel', ga: 'Míosúil',
    ru: 'Месяц', ar: 'شهري', zh: '月度', ja: '月間', ko: '월간',
    es: 'Mensual', it: 'Mensile', pt: 'Mensal', sv: 'Månadsvis',
  ),
  'Tüm Zamanlar': _m(
    en: 'All Time', de: 'Gesamt', nl: 'Alles', fr: 'Tout', ga: 'An tAm Ar Fad',
    ru: 'За всё время', ar: 'كل الأوقات', zh: '全部时间', ja: '全期間', ko: '전체 기간',
    es: 'Todo', it: 'Tutto', pt: 'Tudo', sv: 'Alla tider',
  ),
  'Kilo Ekle': _m(
    en: 'Add Weight', de: 'Gewicht hinzufügen', nl: 'Gewicht toevoegen',
    fr: 'Ajouter un Poids', ga: 'Cuir Meáchan Leis', ru: 'Добавить вес',
    ar: 'إضافة وزن', zh: '添加体重', ja: '体重を追加', ko: '체중 추가',
    es: 'Añadir Peso', it: 'Aggiungi Peso', pt: 'Adicionar Peso', sv: 'Lägg till vikt',
  ),
  '1 Saat Sonra Hatırlat': _m(
    en: 'Snooze 1 Hour', de: 'In 1 Std. erinnern', nl: 'Herinner over 1 uur',
    fr: 'Rappeler dans 1h', ga: 'Meabhraigh i gceann 1 uair', ru: 'Напомнить через 1 ч.',
    ar: 'تذكير بعد ساعة', zh: '1小时后提醒', ja: '1時間後に再通知', ko: '1시간 후 다시 알림',
    es: 'Recordar en 1 hora', it: 'Ricorda tra 1 ora', pt: 'Lembrar em 1 hora', sv: 'Påminn om 1 timme',
  ),
  'Günlük Seri': _m(
    en: 'Day Streak', de: 'Tage-Serie', nl: 'Dagen Reeks', fr: 'Jours de Suite',
    ga: 'Sraith Laethanta', ru: 'дн. подряд', ar: 'أيام متتالية', zh: '天连续打卡',
    ja: '日連続記録', ko: '일 연속 기록', es: 'Días Seguidos', it: 'Giorni di Fila',
    pt: 'Dias Seguidos', sv: 'Dagar i Rad',
  ),
  'Rekor': _m(
    en: 'Best', de: 'Rekord', nl: 'Record', fr: 'Record', ga: 'Curiarracht',
    ru: 'Рекорд', ar: 'الرقم القياسي', zh: '最高纪录', ja: '最高記録', ko: '최고 기록',
    es: 'Récord', it: 'Record', pt: 'Recorde', sv: 'Rekord',
  ),
  'gün': _m(
    en: 'days', de: 'Tage', nl: 'dagen', fr: 'jours', ga: 'lá',
    ru: 'дн.', ar: 'يوم', zh: '天', ja: '日', ko: '일',
    es: 'días', it: 'giorni', pt: 'dias', sv: 'dagar',
  ),
  'Kayıt': _m(
    en: 'Records', de: 'Einträge', nl: 'Metingen', fr: 'Entrées', ga: 'Taifid',
    ru: 'зап.', ar: 'سجل', zh: '条记录', ja: '件', ko: '건',
    es: 'Registros', it: 'Record', pt: 'Registos', sv: 'Poster',
  ),

  // Grafikler Sayfası
  'Karşılaştır': _m(
    en: 'Compare', de: 'Vergleichen', nl: 'Vergelijk', fr: 'Comparer', ga: 'Cuir i gComparáid',
    ru: 'Сравнить', ar: 'مقارنة', zh: '对比', ja: '比較', ko: '비교',
    es: 'Comparar', it: 'Confronta', pt: 'Comparar', sv: 'Jämför',
  ),
  'Kilo Değişim Grafiği': _m(
    en: 'Weight Change Chart', de: 'Gewichtsverlauf', nl: 'Gewichtsverloop Grafiek',
    fr: 'Courbe de Poids', ga: 'Cairt Athraithe Meáchain', ru: 'График изменения веса',
    ar: 'منحنى تغير الوزن', zh: '体重变化曲线图', ja: '体重推移グラフ', ko: '체중 변화 그래프',
    es: 'Gráfico de Evolución', it: 'Grafico Andamento Peso', pt: 'Gráfico de Evolução', sv: 'Viktutvecklingsdiagram',
  ),
  'Sabah kilo değişimi': _m(
    en: 'Morning weight trend', de: 'Morgengewicht-Verlauf', nl: 'Ochtendgewicht verloop',
    fr: 'Évolution du poids du matin', ga: 'Treocht meáchain maidine', ru: 'Динамика утреннего веса',
    ar: 'تغير وزن الصباح', zh: '早晨体重趋势', ja: '朝の体重推移', ko: '아침 체중 변화',
  ),
  'Akşam kilo değişimi': _m(
    en: 'Evening weight trend', de: 'Abendgewicht-Verlauf', nl: 'Avondgewicht verloop',
    fr: 'Évolution du poids du soir', ga: 'Treocht meáchain tráthnóna', ru: 'Динамика вечернего веса',
    ar: 'تغير وزن المساء', zh: '晚上体重趋势', ja: '夜の体重推移', ko: '저녁 체중 변화',
  ),
  'Sabah ve akşam kilo değişimi': _m(
    en: 'Morning and evening weight trend', de: 'Morgen- und Abendgewicht-Verlauf',
    nl: 'Ochtend- en avondgewicht verloop', fr: 'Évolution matin et soir',
    ga: 'Treocht maidine agus tráthnóna', ru: 'Динамика утреннего и вечернего веса',
    ar: 'تغير الوزن صباحاً ومساءً', zh: '早晚体重变化趋势', ja: '朝と夜の体重推移', ko: '아침 및 저녁 체중 변화',
  ),
  '7G Trend': _m(
    en: '7D Trend', de: '7T-Trend', nl: '7D Trend', fr: 'Tendance 7J', ga: 'Treocht 7L',
    ru: 'Тренд 7д', ar: 'اتجاه 7 أيام', zh: '7日趋势', ja: '7日移動平均', ko: '7일 추세',
  ),
  '7G Ortalama Trendi': _m(
    en: '7D Moving Average', de: '7-Tage-Schnitt', nl: '7D Gemiddelde', fr: 'Moyenne Mobile 7J',
    ga: 'Meán Gluaisteach 7L', ru: 'Средняя за 7 дн.', ar: 'المتوسط المتحرك لـ7 أيام',
    zh: '7日移动平均线', ja: '7日間移動平均', ko: '7일 이동평균선',
  ),
  'Sabah - Akşam Karşılaştırması': _m(
    en: 'Morning vs Evening Comparison', de: 'Morgen-Abend-Vergleich',
    nl: 'Ochtend vs Avond Vergelijking', fr: 'Comparaison Matin - Soir',
    ga: 'Comparáid Maidin - Tráthnóna', ru: 'Сравнение Утро – Вечер',
    ar: 'مقارنة الصباح والمساء', zh: '早晚体重对比', ja: '朝・夜の体重比較', ko: '아침 - 저녁 체중 비교',
  ),
  'En Düşük': _m(
    en: 'Lowest', de: 'Minimum', nl: 'Laagste', fr: 'Plus Bas', ga: 'Is Ísle',
    ru: 'Минимум', ar: 'الأدنى', zh: '最低体重', ja: '最低値', ko: '최저 체중',
    es: 'Mínimo', it: 'Minimo', pt: 'Mínimo', sv: 'Lägsta',
  ),
  'En Yüksek': _m(
    en: 'Highest', de: 'Maximum', nl: 'Hoogste', fr: 'Plus Haut', ga: 'Is Airde',
    ru: 'Максимум', ar: 'الأعلى', zh: '最高体重', ja: '最高値', ko: '최고 체중',
    es: 'Máximo', it: 'Massimo', pt: 'Máximo', sv: 'Högsta',
  ),
  'Ortalama': _m(
    en: 'Average', de: 'Durchschnitt', nl: 'Gemiddelde', fr: 'Moyenne', ga: 'Meán',
    ru: 'Среднее', ar: 'المتوسط', zh: '平均体重', ja: '平均値', ko: '평균 체중',
    es: 'Promedio', it: 'Media', pt: 'Média', sv: 'Medel',
  ),
  'Toplam Değişim': _m(
    en: 'Total Change', de: 'Gesamtänderung', nl: 'Totale Verandering',
    fr: 'Variation Totale', ga: 'Athrú Iomlán', ru: 'Общее изменение',
    ar: 'التغير الكلي', zh: '总变化量', ja: '総変化量', ko: '총 변화량',
    es: 'Cambio Total', it: 'Variazione Totale', pt: 'Mudança Total', sv: 'Total Förändring',
  ),
  'Grafik oluşturmak için daha fazla kayıt eklemelisin.': _m(
    en: 'Add more weight records to generate the chart.',
    de: 'Füge weitere Einträge hinzu, um das Diagramm anzuzeigen.',
    nl: 'Voeg meer metingen toe om de grafiek te tonen.',
    fr: 'Ajoutez plus de pesées pour afficher le graphique.',
    ga: 'Cuir tuilleadh taifead leis chun an chairt a chruthú.',
    ru: 'Добавьте больше записей для построения графика.',
    ar: 'أضف المزيد من السجلات لإنشاء الرسم البياني.',
    zh: '请添加更多体重记录以生成图表。',
    ja: 'グラフを表示するには記録を追加してください。',
    ko: '차트를 생성하려면 기록을 더 추가하세요.',
  ),

  // Geçmiş Sayfası
  'Bu Ay': _m(
    en: 'This Month', de: 'Dieser Monat', nl: 'Deze Maand', fr: 'Ce Mois', ga: 'An Mhí Seo',
    ru: 'За месяц', ar: 'هذا الشهر', zh: '本月记录', ja: '今月', ko: '이번 달',
    es: 'Este Mes', it: 'Questo Mese', pt: 'Este Mês', sv: 'Denna Månad',
  ),
  'Tümü': _m(
    en: 'All', de: 'Alle', nl: 'Alles', fr: 'Tous', ga: 'Gach Rud',
    ru: 'Все', ar: 'الكل', zh: '全部', ja: 'すべて', ko: '전체',
    es: 'Todos', it: 'Tutti', pt: 'Todos', sv: 'Alla',
  ),
  'Sadece Sabah': _m(
    en: 'Morning Only', de: 'Nur Morgen', nl: 'Alleen Ochtend', fr: 'Matin Seul',
    ga: 'Maidin Amháin', ru: 'Только утро', ar: 'الصباح فقط', zh: '仅早晨', ja: '朝のみ', ko: '아침만',
  ),
  'Sadece Akşam': _m(
    en: 'Evening Only', de: 'Nur Abend', nl: 'Alleen Avond', fr: 'Soir Seul',
    ga: 'Tráthnóna Amháin', ru: 'Только вечер', ar: 'المساء فقط', zh: '仅晚上', ja: '夜のみ', ko: '저녁만',
  ),
  'Tüm Günler': _m(
    en: 'All Days', de: 'Alle Tage', nl: 'Alle Dagen', fr: 'Tous les Jours',
    ga: 'Gach Lá', ru: 'Все дни', ar: 'كل الأيام', zh: '所有日期', ja: '全日程', ko: '모든 날짜',
  ),
  'Tarih veya not içinde ara…': _m(
    en: 'Search by date or note…', de: 'Nach Datum oder Notiz suchen…',
    nl: 'Zoek op datum of notitie…', fr: 'Rechercher par date ou note…',
    ga: 'Cuardaigh de réir dáta nó nóta…', ru: 'Поиск по дате или заметке…',
    ar: 'ابحث بالتاريخ أو الملاحظة…', zh: '搜索日期或备注…', ja: '日付やメモで検索…', ko: '날짜 또는 메모 검색…',
  ),
  'Fark': _m(
    en: 'Diff', de: 'Diff', nl: 'Verschil', fr: 'Écart', ga: 'Difr',
    ru: 'Разн.', ar: 'الفرق', zh: '差值', ja: '差', ko: '차이',
  ),

  // Raporlar Sayfası
  'Günlük': _m(
    en: 'Daily', de: 'Täglich', nl: 'Dagelijks', fr: 'Quotidien', ga: 'Laethúil',
    ru: 'День', ar: 'يومي', zh: '每日', ja: '日次', ko: '일간',
    es: 'Diario', it: 'Giornaliero', pt: 'Diário', sv: 'Dagligen',
  ),
  'Haftalık': _m(
    en: 'Weekly', de: 'Wöchentlich', nl: 'Wekelijks', fr: 'Hebdo', ga: 'Seachtainiúil',
    ru: 'Неделя', ar: 'أسبوعي', zh: '每周', ja: '週次', ko: '주간',
    es: 'Semanal', it: 'Settimanale', pt: 'Semanal', sv: 'Veckovis',
  ),
  'Genel': _m(
    en: 'Overall', de: 'Gesamt', nl: 'Algemeen', fr: 'Global', ga: 'Foriomlán',
    ru: 'Общий', ar: 'شامل', zh: '总体', ja: '総合', ko: '전체',
    es: 'General', it: 'Generale', pt: 'Geral', sv: 'Övergripande',
  ),
  'Günlük\nDeğişim': _m(
    en: 'Daily\nChange', de: 'Tägliche\nÄnderung', nl: 'Dagelijkse\nVerandering',
    fr: 'Variation\nJour', ga: 'Athrú\nLaethúil', ru: 'Дневное\nизм.',
    ar: 'التغير\nاليومي', zh: '每日\n变化', ja: '日次\n変化', ko: '일일\n변화',
  ),
  'Haftalık\nDeğişim': _m(
    en: 'Weekly\nChange', de: 'Wochen-\nÄnderung', nl: 'Wekelijkse\nVerandering',
    fr: 'Variation\nHebdo', ga: 'Athrú\nSeachtaine', ru: 'Недельное\nизм.',
    ar: 'التغير\nالأسبوعي', zh: '每周\n变化', ja: '週次\n変化', ko: '주간\n변화',
  ),
  'Aylık\nDeğişim': _m(
    en: 'Monthly\nChange', de: 'Monats-\nÄnderung', nl: 'Maandelijkse\nVerandering',
    fr: 'Variation\nMensuelle', ga: 'Athrú\nMíosúil', ru: 'Месячное\nизм.',
    ar: 'التغير\nالشهري', zh: '每月\n变化', ja: '月次\n変化', ko: '월간\n변화',
  ),
  'Ortalama\nKilo': _m(
    en: 'Average\nWeight', de: 'Durchschn.\nGewicht', nl: 'Gemiddeld\nGewicht',
    fr: 'Poids\nMoyen', ga: 'Meán-\nMheáchan', ru: 'Средний\nвес',
    ar: 'متوسط\nالوزن', zh: '平均\n体重', ja: '平均\n体重', ko: '평균\n체중',
  ),
  'Toplam\nKayıt': _m(
    en: 'Total\nRecords', de: 'Einträge\nGesamt', nl: 'Totaal\nMetingen',
    fr: 'Total\nEntrées', ga: 'Taifid\nIomlána', ru: 'Всего\nзаписей',
    ar: 'إجمالي\nالسجلات', zh: '总记录\n次数', ja: '合計\n記録', ko: '총\n기록',
  ),
  'En Düşük\nKilo': _m(
    en: 'Lowest\nWeight', de: 'Niedrigstes\nGewicht', nl: 'Laagste\nGewicht',
    fr: 'Poids\nMinimum', ga: 'Meáchan\nIs Ísle', ru: 'Мин.\nвес',
    ar: 'أقل\nوزن', zh: '最低\n体重', ja: '最低\n体重', ko: '최저\n체중',
  ),
  'Genel İstatistikler': _m(
    en: 'General Statistics', de: 'Allgemeine Statistiken', nl: 'Algemene Statistieken',
    fr: 'Statistiques Générales', ga: 'Staitisticí Ginearálta', ru: 'Общая статистика',
    ar: 'الإحصائيات العامة', zh: '总体统计与目标', ja: '総合統計・目標進捗', ko: '종합 통계 및 목표',
  ),
  'Kilo takibinle ilgili genel görünüm': _m(
    en: 'Overview of your weight tracking progress',
    de: 'Überblick über deinen Gewichtsfortschritt',
    nl: 'Overzicht van je gewichtsverloop',
    fr: 'Vue d’ensemble de votre progression',
    ga: 'Forbhreathnú ar do dhul chun cinn meáchain',
    ru: 'Общий обзор вашего прогресса',
    ar: 'نظرة عامة على تقدمك في متابعة الوزن',
    zh: '您的体重追踪与目标进度总览',
    ja: '体重管理と目標達成度の概要',
    ko: '체중 관리 및 목표 달성 현황 요약',
  ),
  'Hedef\nİlerlemesi': _m(
    en: 'Goal\nProgress', de: 'Ziel-\nFortschritt', nl: 'Doel-\nVoortgang',
    fr: 'Progrès\nObjectif', ga: 'Dul Chun\nCinn', ru: 'Прогресс\nцели',
    ar: 'تقدم\nالهدف', zh: '目标\n进度', ja: '目標\n進捗', ko: '목표\n진행률',
  ),
  'Başlangıç Kilosu': _m(
    en: 'Starting Weight', de: 'Startgewicht', nl: 'Startgewicht',
    fr: 'Poids de Départ', ga: 'Meáchan Tosaigh', ru: 'Начальный вес',
    ar: 'وزن البداية', zh: '初始体重', ja: '開始体重', ko: '시작 체중',
  ),
  'Güncel Kilo': _m(
    en: 'Current Weight', de: 'Aktuelles Gewicht', nl: 'Huidig Gewicht',
    fr: 'Poids Actuel', ga: 'Meáchan Reatha', ru: 'Текущий вес',
    ar: 'الوزن الحالي', zh: '当前体重', ja: '現在の体重', ko: '현재 체중',
  ),
  'Hedef Kilo': _m(
    en: 'Target Weight', de: 'Zielgewicht', nl: 'Streefgewicht',
    fr: 'Poids Cible', ga: 'Spriocmheáchan', ru: 'Целевой вес',
    ar: 'الوزن المستهدف', zh: '目标体重', ja: '目標体重', ko: '목표 체중',
  ),
  'Kalan Kilo': _m(
    en: 'Remaining Weight', de: 'Verbleibend', nl: 'Resterend',
    fr: 'Poids Restant', ga: 'Meáchan Fágtha', ru: 'Осталось',
    ar: 'الوزن المتبقي', zh: '剩余体重', ja: '残り体重', ko: '남은 체중',
  ),
  'Tahmini Hedef Tarihi': _m(
    en: 'Estimated Target Date', de: 'Voraussichtliches Zieldatum',
    nl: 'Geschatte Einddatum', fr: 'Date Cible Estimée',
    ga: 'Dáta Sprioc Measta', ru: 'Ожидаемая дата цели',
    ar: 'التاريخ المتوقع للهدف', zh: '预计达标日期', ja: '目標達成予定日', ko: '목표 달성 예상일',
  ),
  'Hedefe Ulaşıldı!': _m(
    en: 'Goal Reached!', de: 'Ziel erreicht!', nl: 'Doel bereikt!',
    fr: 'Objectif atteint !', ga: 'Sprioc bainte amach!', ru: 'Цель достигнута!',
    ar: 'تم الوصول للهدف!', zh: '已达成目标！', ja: '目標達成！', ko: '목표 달성 완료!',
  ),
  'Hesaplanıyor…': _m(
    en: 'Calculating…', de: 'Wird berechnet…', nl: 'Berekenen…',
    fr: 'Calcul en cours…', ga: 'Ag ríomh…', ru: 'Расчёт…',
    ar: 'جاري الحساب…', zh: '计算中…', ja: '計算中…', ko: '계산 중…',
  ),
  'Ara Hedef Rozetleri': _m(
    en: 'Milestone Badges', de: 'Meilenstein-Abzeichen', nl: 'Mijlpaal Badges',
    fr: 'Badges d’Étape', ga: 'Suaitheantais Cloiche Míle', ru: 'Промежуточные цели',
    ar: 'شارات المراحل المرحلية', zh: '阶段里程碑徽章', ja: 'マイルストーンバッジ', ko: '중간 목표 달성 배지',
  ),
  'Henüz hedef kilo belirlenmedi.': _m(
    en: 'No target weight set yet.', de: 'Noch kein Zielgewicht festgelegt.',
    nl: 'Nog geen streefgewicht ingesteld.', fr: 'Aucun poids cible défini.',
    ga: 'Níl spriocmheáchan socraithe fós.', ru: 'Целевой вес ещё не задан.',
    ar: 'لم يتم تحديد الوزن المستهدف بعد.', zh: '尚未设置目标体重。', ja: '目標体重が未設定です。', ko: '아직 목표 체중이 설정되지 않았습니다.',
  ),
  'Hedef Belirle': _m(
    en: 'Set Goal', de: 'Ziel setzen', nl: 'Stel doel in', fr: 'Définir',
    ga: 'Socraigh Sprioc', ru: 'Задать цель', ar: 'تحديد هدف', zh: '设置目标', ja: '目標を設定', ko: '목표 설정',
  ),
  'VKİ & Vücut Ölçüleri': _m(
    en: 'BMI & Body Measurements', de: 'BMI & Körpermaße', nl: 'BMI & Lichaamsmaten',
    fr: 'IMC & Mensurations', ga: 'BMI & Tomhais Choirp', ru: 'ИМТ и Параметры тела',
    ar: 'مؤشر الكتلة وقياسات الجسم', zh: 'BMI与身体围度', ja: 'BMI・身体サイズ', ko: 'BMI 및 신체 치수',
  ),
  'Düzenle': _m(
    en: 'Edit', de: 'Bearbeiten', nl: 'Bewerken', fr: 'Modifier', ga: 'Cuir in Eagar',
    ru: 'Изменить', ar: 'تعديل', zh: '编辑', ja: '編集', ko: '편집',
  ),
  'Vücut Kitle İndeksi (VKİ)': _m(
    en: 'Body Mass Index (BMI)', de: 'Body-Mass-Index (BMI)', nl: 'Body Mass Index (BMI)',
    fr: 'Indice de Masse Corporelle (IMC)', ga: 'Innéacs Mais Choirp (BMI)',
    ru: 'Индекс массы тела (ИМТ)', ar: 'مؤشر كتلة الجسم (BMI)', zh: '身体质量指数 (BMI)',
    ja: 'ボディマス指数 (BMI)', ko: '체질량지수 (BMI)',
  ),
  'Metabolik & Haftalık Döngü Analizi': _m(
    en: 'Metabolic & Weekly Cycle Analysis', de: 'Stoffwechsel- & Wochenanalyse',
    nl: 'Metabolische & Weekanalyse', fr: 'Analyse Métabolique & Hebdo',
    ga: 'Anailís Meitibileach & Seachtainiúil', ru: 'Метаболический и недельный анализ',
    ar: 'تحليل الأيض والدورة الأسبوعية', zh: '代谢与周周期分析', ja: '代謝・週間サイクル分析', ko: '대사 및 주간 패턴 분석',
  ),
  'Gün İçi Ortalama Fark (Sabah → Akşam)': _m(
    en: 'Avg Intraday Change (Morning → Evening)', de: 'Tagesschnitt (Morgen → Abend)',
    nl: 'Gem. Dagverschil (Ochtend → Avond)', fr: 'Écart Jour Moyen (Matin → Soir)',
    ga: 'Meánathrú Lae (Maidin → Tráthnóna)', ru: 'Средняя разница за день (Утро → Вечер)',
    ar: 'متوسط فرق النهار (الصباح ← المساء)', zh: '日内平均变化 (早 → 晚)',
    ja: '日中平均変化 (朝 → 夜)', ko: '일중 평균 변화 (아침 → 저녁)',
  ),
  'Gece Boyu Değişim (Akşam → Ertesi Sabah)': _m(
    en: 'Avg Overnight Drop (Evening → Next Morning)', de: 'Nachtänderung (Abend → Morgen)',
    nl: 'Nachtelijk Verschil (Avond → Ochtend)', fr: 'Variation Nocturne (Soir → Matin)',
    ga: 'Athrú Thar Oíche (Tráthnóna → Maidin)', ru: 'Изменение за ночь (Вечер → Утро)',
    ar: 'التغير الليلي (المساء ← صباح الغد)', zh: '夜间平均代谢变化 (晚 → 次日早)',
    ja: '夜間平均変化 (夜 → 翌朝)', ko: '야간 평균 변화 (저녁 → 다음날 아침)',
  ),
  'Hafta İçi Ortalama (Pzt–Cum)': _m(
    en: 'Weekday Average (Mon–Fri)', de: 'Wochentage Schnitt (Mo–Fr)',
    nl: 'Doordeweeks Gem. (Ma–Vr)', fr: 'Moyenne Semaine (Lun–Ven)',
    ga: 'Meán Lár na Seachtaine (Lua–Aoi)', ru: 'Среднее в будни (Пн–Пт)',
    ar: 'متوسط أيام الأسبوع (الإثنين–الجمعة)', zh: '工作日平均 (周一至周五)',
    ja: '平日平均 (月〜金)', ko: '평일 평균 (월~금)',
  ),
  'Hafta Sonu Ortalama (Cmt–Paz)': _m(
    en: 'Weekend Average (Sat–Sun)', de: 'Wochenende Schnitt (Sa–So)',
    nl: 'Weekend Gem. (Za–Zo)', fr: 'Moyenne Week-end (Sam–Dim)',
    ga: 'Meán Deireadh Seachtaine (Sat–Dom)', ru: 'Среднее в выходные (Сб–Вс)',
    ar: 'متوسط عطلة نهاية الأسبوع (السبت–الأحد)', zh: '周末平均 (周六至周日)',
    ja: '週末平均 (土・日)', ko: '주말 평균 (토~일)',
  ),
  'Özet & Etiket Etkileri': _m(
    en: 'Summary & Tag Impact', de: 'Zusammenfassung & Tag-Effekte',
    nl: 'Samenvatting & Tag-Impact', fr: 'Résumé & Impact des Tags',
    ga: 'Achoimre & Tionchar Clibeanna', ru: 'Сводка и влияние тегов',
    ar: 'الملخص وتأثير الوسوم', zh: '总结与标签影响分析', ja: 'サマリー・タグ影響分析', ko: '요약 및 태그 영향 분석',
  ),
  'Etiket Bazlı Ertesi Gün Etkisi': _m(
    en: 'Next-Morning Impact by Tag', de: 'Tag-Auswirkung am nächsten Morgen',
    nl: 'Effect volgende ochtend per tag', fr: 'Impact le lendemain matin par tag',
    ga: 'Tionchar Maidin Lá Arna Mhárach', ru: 'Влияние тегов на следующее утро',
    ar: 'تأثير الوسم على صباح اليوم التالي', zh: '标签对次日早晨体重的影响',
    ja: 'タグ別の翌朝体重への影響', ko: '태그별 다음날 아침 체중 영향',
  ),

  // Hesap & Analiz Sayfası
  'Kişisel Bilgiler & Hesaplama': _m(
    en: 'Personal Profile & Calculator', de: 'Persönliche Daten & Rechner',
    nl: 'Persoonlijk Profiel & Calculator', fr: 'Profil Personnel & Calculs',
    ga: 'Próifíl Phearsanta & Áireamhán', ru: 'Личные данные и расчёт',
    ar: 'البيانات الشخصية والحاسبة', zh: '个人资料与健康计算', ja: '身体データ・自動計算', ko: '개인 프로필 및 건강 계산',
  ),
  'Değerleri girdiğinde tüm grafikler anında güncellenir.': _m(
    en: 'All charts and metrics update live as you type.',
    de: 'Alle Diagramme aktualisieren sich sofort bei Eingabe.',
    nl: 'Alle grafieken worden direct bijgewerkt tijdens het typen.',
    fr: 'Tous les graphiques se mettent à jour instantanément.',
    ga: 'Nuashonraítear gach cairt láithreach.',
    ru: 'Все графики обновляются мгновенно при вводе.',
    ar: 'تتحدث جميع الرسوم البيانية فوراً عند إدخال القيم.',
    zh: '输入数值后所有图表将实时自动更新。',
    ja: '数値を入力するとすべてのグラフがリアルタイムで更新されます。',
    ko: '값을 입력하면 모든 그래프가 실시간으로 업데이트됩니다.',
  ),
  'Kaydet': _m(
    en: 'Save', de: 'Speichern', nl: 'Opslaan', fr: 'Enregistrer', ga: 'Sábháil',
    ru: 'Сохранить', ar: 'حفظ', zh: '保存', ja: '保存', ko: '저장',
    es: 'Guardar', it: 'Salva', pt: 'Guardar', sv: 'Spara',
  ),
  'İptal': _m(
    en: 'Cancel', de: 'Abbrechen', nl: 'Annuleren', fr: 'Annuler', ga: 'Cealaigh',
    ru: 'Отмена', ar: 'إلغاء', zh: '取消', ja: 'キャンセル', ko: '취소',
    es: 'Cancelar', it: 'Annulla', pt: 'Cancelar', sv: 'Avbryt',
  ),
  'Temizle': _m(
    en: 'Clear', de: 'Löschen', nl: 'Wissen', fr: 'Effacer', ga: 'Glan',
    ru: 'Очистить', ar: 'مسح', zh: '清除', ja: 'クリア', ko: '초기화',
  ),
  'Erkek': _m(
    en: 'Male', de: 'Männlich', nl: 'Man', fr: 'Homme', ga: 'Fireann',
    ru: 'Мужчина', ar: 'ذكر', zh: '男', ja: '男性', ko: '남성',
    es: 'Hombre', it: 'Uomo', pt: 'Homem', sv: 'Man',
  ),
  'Kadın': _m(
    en: 'Female', de: 'Weiblich', nl: 'Vrouw', fr: 'Femme', ga: 'Baineann',
    ru: 'Женщина', ar: 'أنثى', zh: '女', ja: '女性', ko: '여성',
    es: 'Mujer', it: 'Donna', pt: 'Mulher', sv: 'Kvinna',
  ),
  'Kilo (kg)': _m(
    en: 'Weight (kg)', de: 'Gewicht (kg)', nl: 'Gewicht (kg)', fr: 'Poids (kg)',
    ga: 'Meáchan (kg)', ru: 'Вес (кг)', ar: 'الوزن (كجم)', zh: '体重 (kg)', ja: '体重 (kg)', ko: '체중 (kg)',
  ),
  'Boy (cm)': _m(
    en: 'Height (cm)', de: 'Größe (cm)', nl: 'Lengte (cm)', fr: 'Taille (cm)',
    ga: 'Airde (cm)', ru: 'Рост (см)', ar: 'الطول (سم)', zh: '身高 (cm)', ja: '身長 (cm)', ko: '신장 (cm)',
  ),
  'Yaş': _m(
    en: 'Age', de: 'Alter', nl: 'Leeftijd', fr: 'Âge', ga: 'Aois',
    ru: 'Возраст', ar: 'العمر', zh: '年龄', ja: '年齢', ko: '나이',
  ),
  'Hedef Kilo (kg)': _m(
    en: 'Target Weight (kg)', de: 'Zielgewicht (kg)', nl: 'Streefgewicht (kg)',
    fr: 'Poids Cible (kg)', ga: 'Spriocmheáchan (kg)', ru: 'Целевой вес (кг)',
    ar: 'الوزن المستهدف (كجم)', zh: '目标体重 (kg)', ja: '目標体重 (kg)', ko: '목표 체중 (kg)',
  ),
  'Günlük Aktivite Düzeyi': _m(
    en: 'Daily Activity Level', de: 'Tägliches Aktivitätslevel', nl: 'Dagelijks Activiteitsniveau',
    fr: 'Niveau d’Activité Quotidien', ga: 'Leibhéal Gníomhaíochta', ru: 'Уровень активности',
    ar: 'مستوى النشاط اليومي', zh: '日常活动水平', ja: '1日の活動レベル', ko: '일일 활동량 수준',
  ),
  'Hareketsiz': _m(
    en: 'Sedentary', de: 'Sitzend', nl: 'Zittend', fr: 'Sédentaire', ga: 'Suiteach',
    ru: 'Сидячий', ar: 'قليل الحركة', zh: '久坐少动', ja: 'ほぼ運動しない', ko: '활동 적음',
  ),
  'Hafif Aktif': _m(
    en: 'Lightly Active', de: 'Leicht aktiv', nl: 'Licht actief', fr: 'Légèrement actif',
    ga: 'Beagán Gníomhach', ru: 'Лёгкая акт.', ar: 'نشاط خفيف', zh: '轻度活动', ja: '軽い運動', ko: '가벼운 활동',
  ),
  'Orta Aktif': _m(
    en: 'Moderately Active', de: 'Mäßig aktiv', nl: 'Matig actief', fr: 'Modérément actif',
    ga: 'Measartha Gníomhach', ru: 'Средняя акт.', ar: 'نشاط متوسط', zh: '中度运动', ja: '中程度の運動', ko: '보통 활동',
  ),
  'Çok Aktif': _m(
    en: 'Very Active', de: 'Sehr aktiv', nl: 'Zeer actief', fr: 'Très actif',
    ga: 'An-Ghníomhach', ru: 'Высокая акт.', ar: 'نشاط عالي', zh: '高强度运动', ja: '激しい運動', ko: '매우 활동적',
  ),
  'Bel, Kalça & Boyun Ölçüleri (Yağ Oranı İçin)': _m(
    en: 'Waist, Hip & Neck (For Body Fat %)', de: 'Taille, Hüfte & Hals (für Körperfett %)',
    nl: 'Taille, Heup & Nek (voor Vetpercentage)', fr: 'Tour de Taille, Hanche & Cou',
    ga: 'Coim, Cromán & Muineál', ru: 'Талия, бёдра и шея (для % жира)',
    ar: 'قياسات الخصر والورك والرقبة (لحساب الدهون)', zh: '腰围、臀围与颈围 (用于体脂率)',
    ja: 'ウエスト・ヒップ・首周り (体脂肪率計算用)', ko: '허리, 엉덩이 및 목둘레 (체지방률 계산용)',
  ),
  'Bel (cm)': _m(
    en: 'Waist (cm)', de: 'Taille (cm)', nl: 'Taille (cm)', fr: 'Taille (cm)',
    ga: 'Coim (cm)', ru: 'Талия (см)', ar: 'الخصر (سم)', zh: '腰围 (cm)', ja: '腹囲 (cm)', ko: '허리 (cm)',
  ),
  'Kalça (cm)': _m(
    en: 'Hip (cm)', de: 'Hüfte (cm)', nl: 'Heup (cm)', fr: 'Hanche (cm)',
    ga: 'Cromán (cm)', ru: 'Бёдра (см)', ar: 'الورك (سم)', zh: '臀围 (cm)', ja: 'ヒップ (cm)', ko: '엉덩이 (cm)',
  ),
  'Boyun (cm)': _m(
    en: 'Neck (cm)', de: 'Hals (cm)', nl: 'Nek (cm)', fr: 'Cou (cm)',
    ga: 'Muineál (cm)', ru: 'Шея (см)', ar: 'الرقبة (سم)', zh: '颈围 (cm)', ja: '首周り (cm)', ko: '목둘레 (cm)',
  ),
  'VKİ & İdeal Kilo Kadranı': _m(
    en: 'BMI & Ideal Weight Gauge', de: 'BMI & Idealgewicht-Tacho',
    nl: 'BMI & Ideaal Gewicht Meter', fr: 'Cadran IMC & Poids Idéal',
    ga: 'Tomhais BMI & Meáchan Idéalach', ru: 'Шкала ИМТ и Идеального веса',
    ar: 'مؤشر كتلة الجسم والوزن المثالي', zh: 'BMI与理想体重仪表盘',
    ja: 'BMI・適正体重メーター', ko: 'BMI 및 이상적인 체중 게이지',
  ),
  'VKİ SKORU': _m(
    en: 'BMI SCORE', de: 'BMI-WERT', nl: 'BMI SCORE', fr: 'SCORE IMC',
    ga: 'SCÓR BMI', ru: 'ИНДЕКС ИМТ', ar: 'مؤشر الكتلة', zh: 'BMI 指数', ja: 'BMI スコア', ko: 'BMI 지수',
  ),
  'Düşük Kilolu': _m(
    en: 'Underweight', de: 'Untergewicht', nl: 'Ondergewicht', fr: 'Insuffisance pondérale',
    ga: 'Faoi Mheáchan', ru: 'Недостаточный вес', ar: 'نقص الوزن', zh: '体重偏轻', ja: '低体重 (痩せ)', ko: '저체중',
  ),
  'İdeal (Normal)': _m(
    en: 'Ideal (Normal)', de: 'Ideal (Normal)', nl: 'Ideaal (Normaal)', fr: 'Idéal (Normal)',
    ga: 'Idéalach (Gnáth)', ru: 'Норма (Идеал)', ar: 'وزن مثالي (طبيعي)', zh: '理想 (正常)', ja: '適正 (標準)', ko: '정상 (이상적)',
  ),
  'İdeal Sağlıklı Kilo': _m(
    en: 'Healthy Ideal Weight', de: 'Gesundes Idealgewicht', nl: 'Gezond Ideaal Gewicht',
    fr: 'Poids Santé Idéal', ga: 'Meáchan Sláintiúil Idéalach', ru: 'Здоровый идеальный вес',
    ar: 'الوزن الصحي المثالي', zh: '健康理想体重', ja: '適正健康体重', ko: '건강한 이상적 체중',
  ),
  'Fazla Kilolu': _m(
    en: 'Overweight', de: 'Übergewicht', nl: 'Overgewicht', fr: 'Surpoids',
    ga: 'Rómheáchan', ru: 'Избыточный вес', ar: 'زيادة الوزن', zh: '超重', ja: '過体重', ko: '과체중',
  ),
  'Obezite Sınırı Üstü': _m(
    en: 'Obese Range', de: 'Adipositas-Bereich', nl: 'Obesitas Bereik', fr: 'Obésité',
    ga: 'Murtall', ru: 'Ожирение', ar: 'نطاق السمنة', zh: '肥胖范围', ja: '肥満域', ko: '비만 구간',
  ),
  'Sen': _m(
    en: 'You', de: 'Du', nl: 'Jij', fr: 'Vous', ga: 'Thú',
    ru: 'Вы', ar: 'أنت', zh: '当前', ja: '現在', ko: '현재',
  ),
  'Kilo Sınıfları': _m(
    en: 'Weight Classes', de: 'Gewichtsklassen', nl: 'Gewichtsklassen',
    fr: 'Catégories de Poids', ga: 'Aicmí Meáchain', ru: 'Весовые категории',
    ar: 'فئات الوزن', zh: '对应体重范围', ja: '身長別の体重区分', ko: '신장별 체중 구간',
  ),
  'Sağlıklı Sınır': _m(
    en: 'Healthy Range', de: 'Gesunder Bereich', nl: 'Gezond Bereik',
    fr: 'Plage Santé', ga: 'Raon Sláintiúil', ru: 'Здоровая норма',
    ar: 'النطاق الصحي', zh: '健康范围', ja: '適正範囲', ko: '건강 범위',
  ),
  'Altın Oran (22 VKİ)': _m(
    en: 'Golden Ideal (22 BMI)', de: 'Optimalwert (22 BMI)', nl: 'Optimaal (22 BMI)',
    fr: 'Poids Optimal (22 IMC)', ga: 'Meáchan Órga (22 BMI)', ru: 'Золотая норма (22 ИМТ)',
    ar: 'الوزن الذهبي (22 BMI)', zh: '黄金标准 (22 BMI)', ja: '標準体重 (BMI 22)', ko: '표준 체중 (BMI 22)',
  ),
  'Mevcut Fark': _m(
    en: 'Current Gap', de: 'Aktuelle Differenz', nl: 'Huidig Verschil',
    fr: 'Écart Actuel', ga: 'Difríocht Reatha', ru: 'Текущая разница',
    ar: 'الفرق الحالي', zh: '距离理想范围', ja: '適正範囲との差', ko: '적정 범위와의 차이',
  ),
  'İdeal Aralığa Fark': _m(
    en: 'Gap to Ideal Range', de: 'Abstand zum Idealbereich', nl: 'Afstand tot Ideaal',
    fr: 'Écart à la Plage Idéale', ga: 'Bearna go dtí an Raon Idéalach', ru: 'До нормы',
    ar: 'الفرق عن النطاق المثالي', zh: '距离健康范围', ja: '適正範囲までの差', ko: '이상적 범위까지 차이',
  ),
  'Tebrikler! Boyuna göre sağlıklı ideal kilo aralığındasın': _m(
    en: 'Great job! You are within your healthy ideal weight range.',
    de: 'Super! Du liegst im gesunden Idealgewichtsbereich.',
    nl: 'Geweldig! Je zit binnen je gezonde ideale gewichtsbereik.',
    fr: 'Bravo ! Vous êtes dans votre plage de poids idéale.',
    ga: 'Maith thú! Tá tú laistigh de do raon meáchain idéalach.',
    ru: 'Отлично! Ваш вес находится в пределах здоровой нормы.',
    ar: 'رائع! وزنك الحالي يقع ضمن النطاق الصحي المثالي لطولك.',
    zh: '太棒了！您目前的体重处于健康理想范围内。',
    ja: '素晴らしい！身長に対する適正体重の範囲内です。',
    ko: '훌륭합니다! 현재 신장 대비 건강한 정상 체중 범위 내에 있습니다.',
  ),
  'Kalori & Metabolizma Grafiği': _m(
    en: 'Calorie & Metabolism Chart', de: 'Kalorien- & Stoffwechselgrafik',
    nl: 'Calorie & Metabolisme Grafiek', fr: 'Calories & Métabolisme',
    ga: 'Cairt Calraí & Meitibileachta', ru: 'Калории и метаболизм',
    ar: 'مخطط السعرات والأيض', zh: '每日热量与代谢图表', ja: '消費カロリー・代謝グラフ', ko: '칼로리 및 대사량 그래프',
  ),
  'Hızlı Kilo Verme (-1.0 kg/hf)': _m(
    en: 'Fast Weight Loss (-1.0 kg/wk)', de: 'Schnell abnehmen (-1,0 kg/Wo)',
    nl: 'Snel afvallen (-1,0 kg/wk)', fr: 'Perte Rapide (-1,0 kg/sem)',
    ga: 'Cailliúint Thapa (-1.0 kg/ts)', ru: 'Быстрое снижение (-1,0 кг/нед)',
    ar: 'خسارة سريعة (-1.0 كجم/أسبوع)', zh: '快速减重 (-1.0 kg/周)', ja: '急速減量 (-1.0 kg/週)', ko: '빠른 감량 (-1.0 kg/주)',
  ),
  'Sağlıklı Kilo Verme (-0.5 kg/hf)': _m(
    en: 'Healthy Weight Loss (-0.5 kg/wk)', de: 'Gesund abnehmen (-0,5 kg/Wo)',
    nl: 'Gezond afvallen (-0,5 kg/wk)', fr: 'Perte Saine (-0,5 kg/sem)',
    ga: 'Cailliúint Shláintiúil (-0.5 kg/ts)', ru: 'Здоровое снижение (-0,5 кг/нед)',
    ar: 'خسارة صحية (-0.5 كجم/أسبوع)', zh: '健康减重 (-0.5 kg/周)', ja: '健康的な減量 (-0.5 kg/週)', ko: '건강한 감량 (-0.5 kg/주)',
  ),
  'Kilo Koruma (Sabit)': _m(
    en: 'Weight Maintenance (Steady)', de: 'Gewicht halten (Konstant)',
    nl: 'Gewicht behouden (Stabiel)', fr: 'Maintien du Poids',
    ga: 'Cothabháil Meáchain', ru: 'Поддержание веса',
    ar: 'الحفاظ على الوزن (ثابت)', zh: '维持当前体重', ja: '体重維持 (キープ)', ko: '체중 유지 (유지 칼로리)',
  ),
  'Kilo Alma (+0.4 kg/hf)': _m(
    en: 'Weight Gain (+0.4 kg/wk)', de: 'Zunehmen (+0,4 kg/Wo)',
    nl: 'Aankomen (+0,4 kg/wk)', fr: 'Prise de Poids (+0,4 kg/sem)',
    ga: 'Meáchan a Bhaint Amach (+0.4 kg/ts)', ru: 'Набор веса (+0,4 кг/нед)',
    ar: 'زيادة الوزن (+0.4 كجم/أسبوع)', zh: '健康增重 (+0.4 kg/周)', ja: '増量 (+0.4 kg/週)', ko: '체중 증량 (+0.4 kg/주)',
  ),
  'Önerilen Günlük Makro Dağılımı': _m(
    en: 'Recommended Daily Macros', de: 'Empfohlene Makronährstoffe',
    nl: 'Aanbevolen Dagelijkse Macro’s', fr: 'Macronutriments Recommandés',
    ga: 'Macrachothaitheacha Laethúla', ru: 'Рекомендуемые БЖУ в день',
    ar: 'توزيع المغذيات الكبرى اليومي', zh: '每日推荐宏量营养素', ja: '推奨PFCバランス', ko: '권장 일일 탄단지 비율',
  ),
  'Protein (%30)': _m(
    en: 'Protein (30%)', de: 'Eiweiß (30%)', nl: 'Eiwit (30%)', fr: 'Protéines (30%)',
    ga: 'Próitéin (30%)', ru: 'Белки (30%)', ar: 'بروتين (30%)', zh: '蛋白质 (30%)', ja: 'タンパク質 (30%)', ko: '단백질 (30%)',
  ),
  'Karb (%40)': _m(
    en: 'Carbs (40%)', de: 'Kohlenh. (40%)', nl: 'Koolhydr. (40%)', fr: 'Glucides (40%)',
    ga: 'Carb (40%)', ru: 'Углеводы (40%)', ar: 'كربوهيدرات (40%)', zh: '碳水 (40%)', ja: '炭水化物 (40%)', ko: '탄수화물 (40%)',
  ),
  'Yağ (%30)': _m(
    en: 'Fat (30%)', de: 'Fett (30%)', nl: 'Vet (30%)', fr: 'Lipides (30%)',
    ga: 'Saill (30%)', ru: 'Жиры (30%)', ar: 'دهون (30%)', zh: '脂肪 (30%)', ja: '脂質 (30%)', ko: '지방 (30%)',
  ),
  'Yağ': _m(
    en: 'Body Fat', de: 'Fett', nl: 'Vet', fr: 'Lipides', ga: 'Saill',
    ru: 'жира', ar: 'دهون', zh: '体脂', ja: '体脂肪', ko: '체지방',
  ),
  'Yağsız Kütle': _m(
    en: 'Lean Mass', de: 'Magermasse', nl: 'Vetvrije Massa', fr: 'Masse Maigre',
    ga: 'Mais Thanaí', ru: 'Безжировая масса', ar: 'الكتلة الصافية', zh: '去脂体重', ja: '除脂肪体重', ko: '제지방량',
  ),
  'Vücut Kompozisyonu & Yağ Oranı': _m(
    en: 'Body Composition & Body Fat %', de: 'Körperzusammensetzung & Körperfett',
    nl: 'Lichaamssamenstelling & Vet %', fr: 'Composition Corporelle & Masse Grasse',
    ga: 'Comhdhéanamh Coirp & Saill %', ru: 'Состав тела и % жира',
    ar: 'تركيب الجسم ونسبة الدهون', zh: '身体成分与体脂率', ja: '体組成・体脂肪率', ko: '체성분 및 체지방률',
  ),
  'US Navy Mezura Formülü': _m(
    en: 'US Navy Tape Formula', de: 'US-Navy-Maßbandformel', nl: 'US Navy Meetlint Formule',
    fr: 'Formule Ruban US Navy', ga: 'Foirmle US Navy', ru: 'Формула ВМС США (по обхватам)',
    ar: 'معادلة البحرية الأمريكية بالقياسات', zh: '美国海军围度公式', ja: '米海軍式メジャー計算式', ko: '미 해군 둘레 공식',
  ),
  'VKİ & Yaş Formülü': _m(
    en: 'BMI & Age Formula', de: 'BMI- & Altersformel', nl: 'BMI & Leeftijd Formule',
    fr: 'Formule IMC & Âge', ga: 'Foirmle BMI & Aoise', ru: 'Формула по ИМТ и возрасту',
    ar: 'معادلة مؤشر الكتلة والعمر', zh: 'BMI与年龄估算公式', ja: 'BMI・年齢推定式', ko: 'BMI 및 연령 추정 공식',
  ),
  'Günlük Su İhtiyacı': _m(
    en: 'Daily Water Need', de: 'Täglicher Wasserbedarf', nl: 'Dagelijkse Waterbehoefte',
    fr: 'Besoin en Eau Quotidien', ga: 'Riachtanas Uisce Laethúil', ru: 'Норма воды в день',
    ar: 'احتياج الماء اليومي', zh: '每日建议饮水量', ja: '1日の推奨水分量', ko: '일일 권장 수분 섭취량',
  ),
  'Bel / Boy Oranı': _m(
    en: 'Waist / Height Ratio', de: 'Taille-Größe-Verhältnis', nl: 'Taille / Lengte Ratio',
    fr: 'Ratio Taille / Hauteur', ga: 'Cóimheas Coim / Airde', ru: 'Индекс талия / рост',
    ar: 'نسبة الخصر إلى الطول', zh: '腰高比 (WHtR)', ja: 'ウエスト身長比', ko: '허리 / 신장 비율',
  ),
  'Hedef Kilo Projeksiyon Grafiği': _m(
    en: 'Target Weight Projection Chart', de: 'Zielgewicht-Prognosediagramm',
    nl: 'Streefgewicht Projectiegrafiek', fr: 'Projection du Poids Cible',
    ga: 'Cairt Teilgin Spriocmheáchain', ru: 'Прогноз достижения цели',
    ar: 'مخطط توقعات الوصول للوزن المستهدف', zh: '目标体重达成预测图', ja: '目標体重到達シミュレーション', ko: '목표 체중 달성 예측 그래프',
  ),

  // Kilo Kaydet Paneli (Editor)
  'Kilo Kaydet': _m(
    en: 'Log Weight', de: 'Gewicht speichern', nl: 'Gewicht opslaan',
    fr: 'Enregistrer le Poids', ga: 'Taifead Meáchan', ru: 'Записать вес',
    ar: 'تسجيل الوزن', zh: '记录体重', ja: '体重を記録', ko: '체중 기록',
  ),
  'Sabah ve akşam ölçümlerini birbirinden bağımsız olarak girebilir veya düzenleyebilirsin.': _m(
    en: 'Enter or edit morning and evening measurements independently.',
    de: 'Morgen- und Abendmessungen unabhängig voneinander eingeben oder bearbeiten.',
    nl: 'Voer ochtend- en avondmetingen onafhankelijk van elkaar in.',
    fr: 'Saisissez ou modifiez vos pesées du matin et du soir séparément.',
    ga: 'Cuir isteach tomhais maidine agus tráthnóna go neamhspleách.',
    ru: 'Вводите утренний и вечерний вес независимо друг от друга.',
    ar: 'يمكنك إدخال أو تعديل قياسات الصباح والمساء بشكل مستقل.',
    zh: '您可以独立输入或编辑早晨和晚上的体重记录。',
    ja: '朝と夜の測定値をそれぞれ独立して入力・編集できます。',
    ko: '아침과 저녁 체중을 서로 독립적으로 입력하거나 수정할 수 있습니다.',
  ),
  'Kayıt Türü': _m(
    en: 'Measurement Slot', de: 'Messzeitpunkt', nl: 'Meetmoment',
    fr: 'Moment de Pesée', ga: 'Cineál Taifid', ru: 'Тип записи',
    ar: 'نوع القياس', zh: '记录时段', ja: '記録タイプ', ko: '기록 구분',
  ),
  'Girilmedi': _m(
    en: 'Not set', de: 'Leer', nl: 'Leeg', fr: 'Vide', ga: 'Folamh',
    ru: 'Нет', ar: 'غير مدخل', zh: '未填写', ja: '未入力', ko: '미입력',
  ),
  'Hazır Etiketler & Not (opsiyonel)': _m(
    en: 'Quick Tags & Note (optional)', de: 'Schnell-Tags & Notiz (optional)',
    nl: 'Snelle Tags & Notitie (optioneel)', fr: 'Tags Rapides & Note (optionnel)',
    ga: 'Clibeanna Tapa & Nóta (roghnach)', ru: 'Быстрые теги и заметка (необяз.)',
    ar: 'وسوم سريعة وملاحظة (اختياري)', zh: '快捷标签与备注 (可选)', ja: 'クイックタグ・メモ (任意)', ko: '빠른 태그 및 메모 (선택)',
  ),
  'Örn. Spor sonrası, diyet 3. gün vb.': _m(
    en: 'E.g., Post-workout, diet day 3, etc.', de: 'Z.B. nach dem Sport, Diät Tag 3 usw.',
    nl: 'Bijv. na het sporten, dieet dag 3 enz.', fr: 'Ex. après le sport, jour 3 du régime…',
    ga: 'M.sh. tar éis aclaíochta, lá 3 den aiste bia…', ru: 'Напр., после тренировки, 3-й день диеты и т.д.',
    ar: 'مثال: بعد التمرين، اليوم الثالث من الحمية...', zh: '例如：运动后、饮食控制第3天等',
    ja: '例：運動後、ダイエット3日目など', ko: '예: 운동 후, 식단 3일차 등',
  ),

  // Hazır Etiketler (Quick Tags)
  '🏋️ Spor Günü': _m(
    en: '🏋️ Workout Day', de: '🏋️ Trainingstag', nl: '🏋️ Sportdag',
    fr: '🏋️ Jour de Sport', ga: '🏋️ Lá Aclaíochta', ru: '🏋️ Тренировка',
    ar: '🏋️ يوم رياضة', zh: '🏋️ 运动日', ja: '🏋️ 運動日', ko: '🏋️ 운동한 날',
  ),
  '🧂 Tuzlu Öğün': _m(
    en: '🧂 Salty Meal', de: '🧂 Salzige Mahlzeit', nl: '🧂 Zoute Maaltijd',
    fr: '🧂 Repas Salé', ga: '🧂 Béile Goirt', ru: '🧂 Солёная еда',
    ar: '🧂 وجبة مالحة', zh: '🧂 高盐饮食', ja: '🧂 塩分多め', ko: '🧂 짠 식사',
  ),
  '💧 Ödem': _m(
    en: '💧 Water Retention', de: '💧 Wassereinlagerung', nl: '💧 Vochtretentie',
    fr: '💧 Rétention d’Eau', ga: '💧 Coinneáil Uisce', ru: '💧 Отёк',
    ar: '💧 احتباس سوائل', zh: '💧 水肿', ja: '💧 むくみ', ko: '💧 부종/수분정체',
  ),
  '🍕 Kaçamak': _m(
    en: '🍕 Cheat Meal', de: '🍕 Cheat-Meal', nl: '🍕 Cheat Meal',
    fr: '🍕 Repas Écart', ga: '🍕 Béile Saoire', ru: '🍕 Читмил',
    ar: '🍕 وجبة مفتوحة', zh: '🍕 放纵餐', ja: '🍕 チートデイ', ko: '🍕 치팅데이',
  ),
  '😴 Az Uyku': _m(
    en: '😴 Low Sleep', de: '😴 Wenig Schlaf', nl: '😴 Weinig Slaap',
    fr: '😴 Manque de Sommeil', ga: '😴 Gan Dóthain Codlata', ru: '😴 Недосып',
    ar: '😴 نوم قليل', zh: '😴 睡眠不足', ja: '😴 睡眠不足', ko: '😴 수면 부족',
  ),
  '🤒 Hastalık': _m(
    en: '🤒 Sick / Unwell', de: '🤒 Krank', nl: '🤒 Ziek',
    fr: '🤒 Maladie', ga: '🤒 Tinneas', ru: '🤒 Болезнь',
    ar: '🤒 وعكة صحية', zh: '🤒 生病不适', ja: '🤒 体調不良', ko: '🤒 컨디션 난조',
  ),

  // Ayarlar Sayfası
  'Dil Seçimi': _m(
    en: 'Language', de: 'Sprache', nl: 'Taal', fr: 'Langue', ga: 'Teanga',
    ru: 'Язык приложения', ar: 'لغة التطبيق', zh: '应用语言', ja: '表示言語', ko: '언어 설정',
    es: 'Idioma', it: 'Lingua', pt: 'Idioma', sv: 'Språk',
  ),
  'Uygulama dilini değiştir.': _m(
    en: 'Choose your preferred display language.',
    de: 'Wähle deine bevorzugte Anzeigesprache.',
    nl: 'Kies de gewenste weergavetaal.',
    fr: 'Choisissez la langue d’affichage de l’application.',
    ga: 'Roghnaigh teanga taispeána an fheidhmchláir.',
    ru: 'Выберите язык интерфейса приложения.',
    ar: 'اختر لغة عرض التطبيق المفضلة لديك.',
    zh: '选择应用程序的显示语言。',
    ja: 'アプリの表示言語を選択します。',
    ko: '앱의 표시 언어를 선택하세요.',
  ),
  'Bildirimler': _m(
    en: 'Notifications', de: 'Benachrichtigungen', nl: 'Meldingen',
    fr: 'Notifications', ga: 'Fógraí', ru: 'Уведомления',
    ar: 'الإشعارات', zh: '通知提醒', ja: 'リマインダー通知', ko: '알림 설정',
  ),
  'Kilo takibini hatırlatacak bildirimleri ayarla.': _m(
    en: 'Set daily reminders to log your weight.',
    de: 'Tägliche Erinnerungen für deine Gewichtsmessung.',
    nl: 'Stel dagelijkse herinneringen in om te wegen.',
    fr: 'Configurez vos rappels quotidiens de pesée.',
    ga: 'Socraigh meabhrúcháin laethúla meáchain.',
    ru: 'Настройте ежедневные напоминания о взвешивании.',
    ar: 'اضبط التذكيرات اليومية لتسجيل وزنك.',
    zh: '设置每日早晚称重提醒通知。',
    ja: '毎日の体重測定リマインダーを設定します。',
    ko: '매일 체중 측정을 잊지 않도록 알림을 설정하세요.',
  ),
  'Sabah Bildirimi': _m(
    en: 'Morning Reminder', de: 'Morgen-Erinnerung', nl: 'Ochtendmelding',
    fr: 'Rappel du Matin', ga: 'Meabhrúchán Maidine', ru: 'Утреннее напоминание',
    ar: 'تذكير الصباح', zh: '早晨提醒', ja: '朝の通知', ko: '아침 알림',
  ),
  'Akşam Bildirimi': _m(
    en: 'Evening Reminder', de: 'Abend-Erinnerung', nl: 'Avondmelding',
    fr: 'Rappel du Soir', ga: 'Meabhrúchán Tráthnóna', ru: 'Вечернее напоминание',
    ar: 'تذكير المساء', zh: '晚上提醒', ja: '夜の通知', ko: '저녁 알림',
  ),
  'Görünüm & Renk Paleti': _m(
    en: 'Appearance & Color Palette', de: 'Design & Farbpalette',
    nl: 'Weergave & Kleurenpalet', fr: 'Apparence & Palette de Couleurs',
    ga: 'Cuma & Pailéad Dathanna', ru: 'Оформление и цветовая палитра',
    ar: 'المظهر ولوحة الألوان', zh: '外观与主题配色', ja: '外観・カラーパレット', ko: '테마 및 컬러 팔레트',
  ),
  'Uygulamanın tema modunu ve vurgu renk paletini seç.': _m(
    en: 'Choose theme mode and accent color palette.',
    de: 'Wähle Designmodus und Akzentfarbpalette.',
    nl: 'Kies themamodus en accentkleurenpalet.',
    fr: 'Choisissez le mode d’affichage et la palette de couleurs.',
    ga: 'Roghnaigh mód téama agus pailéad dathanna.',
    ru: 'Выберите тему и цветовую палитру приложения.',
    ar: 'اختر وضع المظهر ولوحة الألوان المفضلة.',
    zh: '选择浅色/深色模式及主题强调色。',
    ja: 'テーマモードとアクセントカラーを選択します。',
    ko: '라이트/다크 모드와 포인트 컬러 팔레트를 선택하세요.',
  ),
  'Açık': _m(
    en: 'Light', de: 'Hell', nl: 'Licht', fr: 'Clair', ga: 'Geal',
    ru: 'Светлая', ar: 'فاتح', zh: '浅色', ja: 'ライト', ko: '라이트',
  ),
  'Koyu': _m(
    en: 'Dark', de: 'Dunkel', nl: 'Donker', fr: 'Sombre', ga: 'Dorcha',
    ru: 'Тёмная', ar: 'داكن', zh: '深色', ja: 'ダーク', ko: '다크',
  ),
  'Sistem': _m(
    en: 'System', de: 'System', nl: 'Systeem', fr: 'Système', ga: 'Córas',
    ru: 'Система', ar: 'النظام', zh: '跟随系统', ja: 'システム', ko: '시스템',
  ),
  'Renk Paleti': _m(
    en: 'Color Palette', de: 'Farbpalette', nl: 'Kleurenpalet',
    fr: 'Palette de Couleurs', ga: 'Pailéad Dathanna', ru: 'Цветовая палитра',
    ar: 'لوحة الألوان', zh: '配色方案', ja: 'カラーパレット', ko: '컬러 팔레트',
  ),
  'Okyanus Mavisi': _m(
    en: 'Ocean Blue', de: 'Ozeanblau', nl: 'Oceaanblauw', fr: 'Bleu Océan',
    ga: 'Gorm Aigéin', ru: 'Синий океан', ar: 'أزرق المحيط', zh: '海洋蓝', ja: 'オーシャンブルー', ko: '오션 블루',
  ),
  'Zümrüt Yeşili': _m(
    en: 'Emerald Green', de: 'Smaragdgrün', nl: 'Smaragdgroen', fr: 'Vert Émeraude',
    ga: 'Glas Smaragda', ru: 'Изумрудный', ar: 'أخضر زمردي', zh: '翡翠绿', ja: 'エメラルドグリーン', ko: '에메랄드 그린',
  ),
  'Kraliyet Moru': _m(
    en: 'Royal Amethyst', de: 'Königsviolett', nl: 'Koningspaars', fr: 'Violet Royal',
    ga: 'Corcra Ríoga', ru: 'Королевский пурпур', ar: 'بنفسجي ملكي', zh: '皇家紫', ja: 'ロイヤルパープル', ko: '로얄 퍼플',
  ),
  'Günbatımı Mercan': _m(
    en: 'Sunset Coral', de: 'Sonnenuntergang', nl: 'Zonsondergang Koraal', fr: 'Corail Coucher',
    ga: 'Coiréal Luí na Gréine', ru: 'Закатный коралл', ar: 'مرجاني الغروب', zh: '日落珊瑚', ja: 'サンセットコーラル', ko: '선셋 코랄',
  ),
  'Gül & Mürdüm': _m(
    en: 'Rose & Plum', de: 'Rose & Pflaume', nl: 'Roos & Pruim', fr: 'Rose & Prune',
    ga: 'Rós & Pluma', ru: 'Роза и слива', ar: 'وردي وبرقوقي', zh: '玫瑰与梅紫', ja: 'ローズ＆プラム', ko: '로즈 & 플럼',
  ),
  'Turkuaz Lagün': _m(
    en: 'Teal Lagoon', de: 'Türkis-Lagune', nl: 'Turkoois Lagune', fr: 'Lagon Turquoise',
    ga: 'Lagún Turcaide', ru: 'Бирюзовая лагуна', ar: 'فيروزي البحيرة', zh: '青碧泻湖', ja: 'ティールラグーン', ko: '틸 라군',
  ),
  'Safir İndigo': _m(
    en: 'Sapphire Indigo', de: 'Saphir-Indigo', nl: 'Saffier Indigo', fr: 'Indigo Saphir',
    ga: 'Indigo Saifír', ru: 'Сапфировый индиго', ar: 'نيلي ياقوتي', zh: '蓝宝石靛', ja: 'サファイアインディゴ', ko: '사파이어 인디고',
  ),
  'Antrasit Grafit': _m(
    en: 'Slate Graphite', de: 'Anthrazit-Graphit', nl: 'Antraciet Grafiet', fr: 'Graphite Ardoise',
    ga: 'Graifít Slinne', ru: 'Графитовый сланец', ar: 'جرافيت داكن', zh: '石墨灰', ja: 'スレートグラファイト', ko: '슬레이트 그래파이트',
  ),
  'Hedef Kilo & Vücut Ölçüleri': _m(
    en: 'Target Weight & Body Measurements', de: 'Zielgewicht & Körpermaße',
    nl: 'Streefgewicht & Lichaamsmaten', fr: 'Poids Cible & Mensurations',
    ga: 'Spriocmheáchan & Tomhais Choirp', ru: 'Целевой вес и параметры тела',
    ar: 'الوزن المستهدف وقياسات الجسم', zh: '目标体重与身体围度', ja: '目標体重・身体サイズ', ko: '목표 체중 및 신체 치수',
  ),
  'Hedef kilo, boy (VKİ) ve mezura çevre ölçülerini tanımla.': _m(
    en: 'Configure target weight, height (BMI), and tape measurements.',
    de: 'Zielgewicht, Größe (BMI) und Umfangsmaße festlegen.',
    nl: 'Stel streefgewicht, lengte (BMI) en omtrekmaten in.',
    fr: 'Définissez votre poids cible, taille (IMC) et mensurations.',
    ga: 'Socraigh spriocmheáchan, airde (BMI) agus tomhais.',
    ru: 'Задайте целевой вес, рост (ИМТ) и обхваты тела.',
    ar: 'حدد الوزن المستهدف والطول وقياسات الجسم.',
    zh: '设置目标体重、身高(BMI)及腰臀颈围数据。',
    ja: '目標体重・身長(BMI)・身体サイズを設定します。',
    ko: '목표 체중, 신장(BMI) 및 신체 둘레 치수를 설정하세요.',
  ),
  'Bel, Kalça & Boyun Çevresi (cm)': _m(
    en: 'Waist, Hip & Neck Circumference (cm)', de: 'Taillen-, Hüft- & Halsumfang (cm)',
    nl: 'Taille-, Heup- & Nekomtrek (cm)', fr: 'Tour de Taille, Hanche & Cou (cm)',
    ga: 'Imchló Coim, Cromáin & Muiníl (cm)', ru: 'Обхват талии, бёдер и шеи (см)',
    ar: 'محيط الخصر والورك والرقبة (سم)', zh: '腰围、臀围与颈围 (cm)', ja: 'ウエスト・ヒップ・首周り (cm)', ko: '허리, 엉덩이 및 목둘레 (cm)',
  ),
  'Mezura ölçüsü girilmedi (Opsiyonel)': _m(
    en: 'No tape measurements set (Optional)', de: 'Keine Maße eingegeben (Optional)',
    nl: 'Geen maten ingevoerd (Optioneel)', fr: 'Aucune mesure saisie (Optionnel)',
    ga: 'Gan tomhais (Roghnach)', ru: 'Не указано (Необязательно)',
    ar: 'لم يتم إدخال قياسات (اختياري)', zh: '未设置围度数据 (可选)', ja: '未設定 (任意)', ko: '미입력 (선택사항)',
  ),
  'Veri Yönetimi': _m(
    en: 'Data Management', de: 'Datenverwaltung', nl: 'Gegevensbeheer',
    fr: 'Gestion des Données', ga: 'Bainistíocht Sonraí', ru: 'Управление данными',
    ar: 'إدارة البيانات', zh: '数据管理', ja: 'データ管理', ko: '데이터 관리',
  ),
  'Kilo verilerini dışa aktar, yerel veri bilgisini görüntüle.': _m(
    en: 'Export weight records to Excel and view local storage status.',
    de: 'Gewichtsdaten als Excel exportieren und Speicherstatus prüfen.',
    nl: 'Exporteer gewichtsgegevens naar Excel en bekijk opslagstatus.',
    fr: 'Exportez vos données vers Excel et vérifiez le stockage local.',
    ga: 'Easpórtáil sonraí meáchain go Excel.',
    ru: 'Экспорт данных в Excel и статус локального хранилища.',
    ar: 'تصدير بيانات الوزن إلى Excel وعرض حالة التخزين المحلي.',
    zh: '将体重记录导出为Excel文件并查看本地存储状态。',
    ja: '体重データをExcelに出力し、ローカル保存状態を確認します。',
    ko: '체중 데이터를 엑셀로 내보내고 로컬 저장 상태를 확인하세요.',
  ),
  'Excel Dışa Aktar (.xlsx)': _m(
    en: 'Export to Excel (.xlsx)', de: 'Excel-Export (.xlsx)', nl: 'Exporteer naar Excel (.xlsx)',
    fr: 'Exporter vers Excel (.xlsx)', ga: 'Easpórtáil go Excel (.xlsx)', ru: 'Экспорт в Excel (.xlsx)',
    ar: 'تصدير إلى إكسل (.xlsx)', zh: '导出为 Excel (.xlsx)', ja: 'Excelエクスポート (.xlsx)', ko: 'Excel 내보내기 (.xlsx)',
  ),
  'Tüm kilo kayıtlarını Excel dosyası olarak indir.': _m(
    en: 'Download all weight records as an Excel spreadsheet.',
    de: 'Alle Gewichtseinträge als Excel-Datei herunterladen.',
    nl: 'Download alle metingen als een Excel-bestand.',
    fr: 'Télécharger toutes les pesées sous forme de fichier Excel.',
    ga: 'Íoslódáil gach taifead meáchain mar chomhad Excel.',
    ru: 'Скачать все записи о весе в виде файла Excel.',
    ar: 'تنزيل جميع سجلات الوزن كملف Excel.',
    zh: '将所有体重记录下载为Excel表格文件。',
    ja: 'すべての体重記録をExcelファイルとして保存します。',
    ko: '모든 체중 기록을 엑셀 파일로 다운로드합니다.',
  ),
  'Yerel Veri Bilgisi': _m(
    en: 'Local Storage Status', de: 'Lokaler Datenspeicher', nl: 'Lokale Opslagstatus',
    fr: 'Stockage Local', ga: 'Stóráil Áitiúil', ru: 'Локальное хранилище',
    ar: 'حالة التخزين المحلي', zh: '本地数据存储', ja: 'ローカルデータ保存', ko: '로컬 데이터 저장소',
  ),
  'Verileriniz bu cihazda saklanır. İnternet bağlantısı gerekmez.': _m(
    en: 'Your data is stored privately on this device. Works 100% offline.',
    de: 'Deine Daten werden lokal auf diesem Gerät gespeichert. 100% offline.',
    nl: 'Je gegevens worden lokaal op dit apparaat bewaard. Geen internet nodig.',
    fr: 'Vos données sont stockées sur cet appareil. Fonctionne hors ligne.',
    ga: 'Stóráiltear do chuid sonraí ar an ngléas seo. Oibríonn sé as líne.',
    ru: 'Данные хранятся на устройстве. Интернет не требуется.',
    ar: 'يتم حفظ بياناتك محلياً على جهازك. يعمل بدون إنترنت.',
    zh: '您的数据保存在本机SQLite中，无需联网即可使用。',
    ja: 'データはこの端末内に安全に保存されます。通信不要。',
    ko: '모든 데이터는 기기 내부에 안전하게 보관되며 오프라인으로 작동합니다.',
  ),
  'Hakkında': _m(
    en: 'About', de: 'Über', nl: 'Over', fr: 'À Propos', ga: 'Maidir Leis',
    ru: 'О приложении', ar: 'حول التطبيق', zh: '关于应用', ja: 'アプリについて', ko: '앱 정보',
  ),
  'Uygulama Adı': _m(
    en: 'Application Name', de: 'App-Name', nl: 'App-naam', fr: 'Nom de l’Application',
    ga: 'Ainm an Fheidhmchláir', ru: 'Название', ar: 'اسم التطبيق', zh: '应用名称', ja: 'アプリ名', ko: '앱 이름',
  ),
  'Sürüm': _m(
    en: 'Version', de: 'Version', nl: 'Versie', fr: 'Version', ga: 'Leagan',
    ru: 'Версия', ar: 'الإصدار', zh: '版本', ja: 'バージョン', ko: '버전',
  ),
  'Tamamen Çevrimdışı Çalışır': _m(
    en: 'Works 100% Offline', de: 'Funktioniert 100% Offline', nl: 'Werkt 100% Offline',
    fr: 'Fonctionne 100% Hors Ligne', ga: 'Oibríonn 100% As Líne', ru: 'Работает полностью офлайн',
    ar: 'يعمل بالكامل بدون إنترنت', zh: '完全离线运行', ja: '完全オフライン対応', ko: '100% 오프라인 작동',
  ),
  'Geri Al': _m(
    en: 'Undo', de: 'Rückgängig', nl: 'Ongedaan maken', fr: 'Annuler', ga: 'Cealaigh',
    ru: 'Отменить', ar: 'تراجع', zh: '撤销', ja: '元に戻す', ko: '실행 취소',
  ),
  'Kilo kaydı silindi.': _m(
    en: 'Weight record deleted.', de: 'Eintrag gelöscht.', nl: 'Meting verwijderd.',
    fr: 'Pesée supprimée.', ga: 'Scriosadh an taifead.', ru: 'Запись удалена.',
    ar: 'تم حذف سجل الوزن.', zh: '体重记录已删除。', ja: '記録を削除しました。', ko: '체중 기록이 삭제되었습니다.',
  ),
  'Silinen kayıt geri yüklendi.': _m(
    en: 'Deleted record restored.', de: 'Gelöschter Eintrag wiederhergestellt.',
    nl: 'Verwijderde meting hersteld.', fr: 'Pesée restaurée.',
    ga: 'Athchóiríodh an taifead.', ru: 'Запись восстановлена.',
    ar: 'تم استعادة السجل المحذوف.', zh: '已恢复删除的记录。', ja: '削除した記録を復元しました。', ko: '삭제된 기록이 복원되었습니다.',
  ),
  'Kilo kaydı başarıyla kaydedildi.': _m(
    en: 'Weight record saved successfully.', de: 'Gewicht erfolgreich gespeichert.',
    nl: 'Gewicht succesvol opgeslagen.', fr: 'Pesée enregistrée avec succès.',
    ga: 'Sábháladh an taifead meáchain.', ru: 'Запись о весе успешно сохранена.',
    ar: 'تم حفظ سجل الوزن بنجاح.', zh: '体重记录已成功保存。', ja: '体重記録を保存しました。', ko: '체중 기록이 성공적으로 저장되었습니다.',
  ),
  'Kişisel hesaplama bilgileri ve hedefler kaydedildi.': _m(
    en: 'Personal profile and target settings saved.',
    de: 'Persönliches Profil und Ziele gespeichert.',
    nl: 'Persoonlijk profiel en doelen opgeslagen.',
    fr: 'Profil personnel et objectifs enregistrés.',
    ga: 'Sábháladh an phróifíl phearsanta agus na spriocanna.',
    ru: 'Личные данные и цели сохранены.',
    ar: 'تم حفظ البيانات الشخصية والأهداف.',
    zh: '个人计算资料与目标已保存。',
    ja: '身体データと目標設定を保存しました。',
    ko: '개인 계산 정보와 목표가 저장되었습니다.',
  ),
  'Sil': _m(
    en: 'Delete', de: 'Löschen', nl: 'Verwijderen', fr: 'Supprimer', ga: 'Scrios',
    ru: 'Удалить', ar: 'حذف', zh: '删除', ja: '削除', ko: '삭제',
  ),
  'Vazgeç': _m(
    en: 'Cancel', de: 'Abbrechen', nl: 'Annuleren', fr: 'Annuler', ga: 'Cealaigh',
    ru: 'Отмена', ar: 'إلغاء', zh: '取消', ja: 'キャンセル', ko: '취소',
  ),
  'Uygulama Dili': _m(
    en: 'App Language', de: 'App-Sprache', nl: 'App-taal', fr: 'Langue de l’App',
    ga: 'Teanga an Aip', ru: 'Язык приложения', ar: 'لغة التطبيق', zh: '应用语言', ja: '表示言語', ko: '앱 언어',
    es: 'Idioma de la App', it: 'Lingua dell’App', pt: 'Idioma da App', sv: 'Appspråk',
  ),
  'Uygulama Dili & Bölge': _m(
    en: 'Language & Region', de: 'Sprache & Region', nl: 'Taal & Regio', fr: 'Langue & Région',
    ga: 'Teanga & Réigiún', ru: 'Язык и регион', ar: 'اللغة والمنطقة', zh: '语言与地区', ja: '言語と地域', ko: '언어 및 지역',
    es: 'Idioma y Región', it: 'Lingua e Regione', pt: 'Idioma e Região', sv: 'Språk & Region',
  ),
  'Tüm ekranları, grafikleri, raporları ve hesaplamaları seçtiğin dilde görüntüle.': _m(
    en: 'Display all screens, charts, reports, and calculators in your preferred language.',
    de: 'Alle Ansichten, Diagramme, Berichte und Rechner in deiner gewählten Sprache anzeigen.',
    nl: 'Bekijk alle schermen, grafieken, rapporten en berekeningen in jouw gekozen taal.',
    fr: 'Affichez tous les écrans, graphiques, rapports et calculs dans la langue choisie.',
    ga: 'Taispeáin gach scáileán, cairt, tuairisc agus áireamhán sa teanga roghnaithe.',
    ru: 'Отображать все экраны, графики, отчёты и расчёты на выбранном языке.',
    ar: 'عرض جميع الشاشات والرسوم البيانية والتقارير والحاسبات باللغة المختارة.',
    zh: '以您选择的语言显示所有页面、图表、报告和计算器。',
    ja: 'すべての画面・グラフ・レポート・計算ツールを選択した言語で表示します。',
    ko: '모든 화면, 차트, 리포트 및 계산기를 선택한 언어로 표시합니다.',
    es: 'Muestra todas las pantallas, gráficos, informes y calculadoras en tu idioma.',
    it: 'Visualizza tutte le schermate, i grafici, i report e i calcoli nella tua lingua.',
    pt: 'Apresente todos os ecrãs, gráficos, relatórios e cálculos no seu idioma.',
    sv: 'Visa alla skärmar, diagram, rapporter och beräkningar på valt språk.',
  ),
  'Kilo Kayıtları': _m(
    en: 'Weight Records', de: 'Gewichtseinträge', nl: 'Gewichtsmetingen',
    fr: 'Historique des Pesées', ga: 'Taifid Mheáchain', ru: 'Записи веса',
    ar: 'سجلات الوزن', zh: '体重记录', ja: '体重記録', ko: '체중 기록',
  ),
  'Haftalık Rapor': _m(
    en: 'Weekly Report', de: 'Wochenbericht', nl: 'Weekrapport',
    fr: 'Rapport Hebdomadaire', ga: 'Tuairisc Sheachtainiúil', ru: 'Недельный отчёт',
    ar: 'التقرير الأسبوعي', zh: '周报', ja: '週次レポート', ko: '주간 리포트',
  ),
  'Aylık Rapor': _m(
    en: 'Monthly Report', de: 'Monatsbericht', nl: 'Maandrapport',
    fr: 'Rapport Mensuel', ga: 'Tuairisc Mhíosúil', ru: 'Месячный отчёт',
    ar: 'التقرير الشهري', zh: '月报', ja: '月次レポート', ko: '월간 리포트',
  ),
  'Not': _m(
    en: 'Note', de: 'Notiz', nl: 'Notitie', fr: 'Note', ga: 'Nóta',
    ru: 'Заметка', ar: 'ملاحظة', zh: '备注', ja: 'メモ', ko: '메모',
  ),
  'Hafta başlangıcı': _m(
    en: 'Week Start', de: 'Wochenbeginn', nl: 'Weekbegin', fr: 'Début de Semaine',
    ga: 'Tús na Seachtaine', ru: 'Начало недели', ar: 'بداية الأسبوع', zh: '周起始日', ja: '週の開始日', ko: '주간 시작일',
  ),
  'Ay başlangıcı': _m(
    en: 'Month Start', de: 'Monatsbeginn', nl: 'Maandbegin', fr: 'Début du Mois',
    ga: 'Tús na Míosa', ru: 'Начало месяца', ar: 'بداية الشهر', zh: '月起始日', ja: '月の開始日', ko: '월간 시작일',
  ),
  'Sabah Değişimi (kg)': _m(
    en: 'Morning Change (kg)', de: 'Morgen-Änderung (kg)', nl: 'Ochtendverschil (kg)',
    fr: 'Variation Matin (kg)', ga: 'Athrú Maidine (kg)', ru: 'Утреннее изменение (кг)',
    ar: 'تغير الصباح (كغ)', zh: '晨间变化 (kg)', ja: '朝の変動 (kg)', ko: '아침 변화량 (kg)',
  ),
  'Akşam Değişimi (kg)': _m(
    en: 'Evening Change (kg)', de: 'Abend-Änderung (kg)', nl: 'Avondverschil (kg)',
    fr: 'Variation Soir (kg)', ga: 'Athrú Tráthnóna (kg)', ru: 'Вечернее изменение (кг)',
    ar: 'تغير المساء (كغ)', zh: '晚间变化 (kg)', ja: '夜の変動 (kg)', ko: '저녁 변화량 (kg)',
  ),
  'Sabah Ortalaması (kg)': _m(
    en: 'Morning Average (kg)', de: 'Morgen-Durchschnitt (kg)', nl: 'Ochtendgemiddelde (kg)',
    fr: 'Moyenne Matin (kg)', ga: 'Meán Maidine (kg)', ru: 'Среднее утром (кг)',
    ar: 'متوسط الصباح (كغ)', zh: '晨间平均 (kg)', ja: '朝の平均 (kg)', ko: '아침 평균 (kg)',
  ),
  'Akşam Ortalaması (kg)': _m(
    en: 'Evening Average (kg)', de: 'Abend-Durchschnitt (kg)', nl: 'Avondgemiddelde (kg)',
    fr: 'Moyenne Soir (kg)', ga: 'Meán Tráthnóna (kg)', ru: 'Среднее вечером (кг)',
    ar: 'متوسط المساء (كغ)', zh: '晚间平均 (kg)', ja: '夜の平均 (kg)', ko: '저녁 평균 (kg)',
  ),
  'Ölçüm Günü': _m(
    en: 'Logged Days', de: 'Messtage', nl: 'Meetdagen', fr: 'Jours Mesurés',
    ga: 'Laethanta Tomhaiste', ru: 'Дней измерений', ar: 'أيام القياس', zh: '记录天数', ja: '測定日数', ko: '측정 일수',
  ),
  'Excel dosyasını kaydet': _m(
    en: 'Save Excel File', de: 'Excel-Datei speichern', nl: 'Excel-bestand opslaan',
    fr: 'Enregistrer le fichier Excel', ga: 'Sábháil comhad Excel', ru: 'Сохранить файл Excel',
    ar: 'حفظ ملف Excel', zh: '保存 Excel 文件', ja: 'Excelファイルを保存', ko: 'Excel 파일 저장',
  ),
  'Bildirim kapalı': _m(
    en: 'Notification off', de: 'Benachrichtigung aus', nl: 'Melding uit',
    fr: 'Notification désactivée', ga: 'Fógra múchta', ru: 'Уведомление выкл.',
    ar: 'التنبيه متوقف', zh: '通知已关闭', ja: '通知オフ', ko: '알림 꺼짐',
  ),
  'Ayarlar okunamadı. Varsayılan ayarlar kullanılıyor.': _m(
    en: 'Could not read settings. Using defaults.', de: 'Einstellungen konnten nicht geladen werden. Standardwerte verwendet.', nl: 'Kon instellingen niet lezen. Standaardwaarden gebruikt.', fr: 'Impossible de lire les paramètres. Valeurs par défaut utilisées.',
    ga: 'Níorbh fhéidir socruithe a léamh. Réamhshocruithe in úsáid.', ru: 'Не удалось прочитать настройки. Используются по умолчанию.', ar: 'تعذر قراءة الإعدادات. يتم استخدام الإعدادات الافتراضية.', zh: '无法读取设置，正在使用默认设置。', ja: '設定を読み込めませんでした。初期値を使用します。', ko: '설정을 읽을 수 없습니다. 기본값을 사용합니다.',
    es: 'No se pudo leer la configuración. Usando valores predeterminados.', it: 'Impossibile leggere le impostazioni. Vengono usati i valori predefiniti.', pt: 'Não foi possível ler as definições. A usar predefinições.', sv: 'Kunde inte läsa inställningar. Standardvärden används.', deCh: 'Einstellungen konnten nicht geladen werden. Standardwerte verwendet.',
  ),
  'Bu kilo kaydını silmek istediğine emin misin?': _m(
    en: 'Are you sure you want to delete this weight record?', de: 'Möchtest du diesen Eintrag wirklich löschen?', nl: 'Weet je zeker dat je deze meting wilt verwijderen?', fr: 'Voulez-vous vraiment supprimer cet enregistrement ?',
    ga: 'An bhfuil tú cinnte gur mhaith leat an taifead seo a scriosadh?', ru: 'Вы уверены, что хотите удалить эту запись о весе?', ar: 'هل أنت متأكد من رغبتك في حذف هذا السجل؟', zh: '您确定要删除此体重记录吗？', ja: 'この体重記録を削除してもよろしいですか？', ko: '이 체중 기록을 정말 삭제하시겠습니까?',
    es: '¿Seguro que deseas eliminar este registro de peso?', it: 'Sei sicuro di voler eliminare questa misurazione?', pt: 'Tem a certeza de que pretende eliminar este registo?', sv: 'Är du säker på att du vill ta bort denna viktpost?', deCh: 'Möchtest du diesen Eintrag wirklich löschen?',
  ),
  'Cihaza Kaydet (.xlsx)': _m(
    en: 'Save to Device (.xlsx)', de: 'Auf Gerät speichern (.xlsx)', nl: 'Opslaan op apparaat (.xlsx)', fr: 'Enregistrer sur l’appareil (.xlsx)',
    ga: 'Sábháil ar an ngléas (.xlsx)', ru: 'Сохранить на устройство (.xlsx)', ar: 'حفظ على الجهاز (.xlsx)', zh: '保存到设备 (.xlsx)', ja: '端末に保存 (.xlsx)', ko: '기기에 저장 (.xlsx)',
    es: 'Guardar en el dispositivo (.xlsx)', it: 'Salva sul dispositivo (.xlsx)', pt: 'Guardar no dispositivo (.xlsx)', sv: 'Spara på enhet (.xlsx)', deCh: 'Auf Gerät speichern (.xlsx)',
  ),
  'Telefon hafızasına veya İndirilenler klasörüne kaydet': _m(
    en: 'Save to device storage or Downloads folder', de: 'Im Telefonspeicher oder Download-Ordner speichern', nl: 'Opslaan in telefoongeheugen of Downloads', fr: 'Enregistrer dans la mémoire ou le dossier Téléchargements',
    ga: 'Sábháil i stóras an fhóin nó san fhillteán Íoslódálacha', ru: 'Сохранить в память телефона или папку Загрузки', ar: 'حفظ في ذاكرة الهاتف أو مجلد التنزيلات', zh: '保存至手机存储或下载文件夹', ja: '端末ストレージまたはダウンロードフォルダに保存', ko: '기기 저장소 또는 다운로드 폴더에 저장',
    es: 'Guardar en el almacenamiento o carpeta Descargas', it: 'Salva nella memoria del telefono o nei Download', pt: 'Guardar na memória do telemóvel ou em Transferências', sv: 'Spara i telefonens minne eller mappen Hämtade filer', deCh: 'Im Telefonspeicher oder Download-Ordner speichern',
  ),
  'Paylaş / Excel ile Aç (.xlsx)': _m(
    en: 'Share / Open with Excel (.xlsx)', de: 'Teilen / Mit Excel öffnen (.xlsx)', nl: 'Delen / Openen met Excel (.xlsx)', fr: 'Partager / Ouvrir avec Excel (.xlsx)',
    ga: 'Roinn / Oscail le Excel (.xlsx)', ru: 'Поделиться / Открыть в Excel (.xlsx)', ar: 'مشاركة / فتح بواسطة Excel (.xlsx)', zh: '分享 / 使用 Excel 打开 (.xlsx)', ja: '共有 / Excelで開く (.xlsx)', ko: '공유 / Excel로 열기 (.xlsx)',
    es: 'Compartir / Abrir con Excel (.xlsx)', it: 'Condividi / Apri con Excel (.xlsx)', pt: 'Partilhar / Abrir com Excel (.xlsx)', sv: 'Dela / Öppna med Excel (.xlsx)', deCh: 'Teilen / Mit Excel öffnen (.xlsx)',
  ),
  'Excel, WhatsApp, Drive veya E-posta ile aç/gönder': _m(
    en: 'Open or send via Excel, WhatsApp, Drive, or Email', de: 'Öffnen oder senden über Excel, WhatsApp, Drive oder E-Mail', nl: 'Open of verzend via Excel, WhatsApp, Drive of e-mail', fr: 'Ouvrir ou envoyer via Excel, WhatsApp, Drive ou Email',
    ga: 'Oscail nó seol trí Excel, WhatsApp, Drive nó Ríomhphost', ru: 'Открыть или отправить через Excel, WhatsApp, Drive или Email', ar: 'فتح أو إرسال عبر Excel أو WhatsApp أو Drive أو البريد', zh: '通过 Excel、WhatsApp、云端硬盘或电子邮件打开/发送', ja: 'Excel、WhatsApp、Drive、メール等で共有', ko: 'Excel, WhatsApp, Drive 또는 이메일로 열기/공유',
    es: 'Abrir o enviar vía Excel, WhatsApp, Drive o Correo', it: 'Apri o invia tramite Excel, WhatsApp, Drive o Email', pt: 'Abrir ou enviar por Excel, WhatsApp, Drive ou E-mail', sv: 'Öppna eller skicka via Excel, WhatsApp, Drive eller E-post', deCh: 'Öffnen oder senden über Excel, WhatsApp, Drive oder E-Mail',
  ),
  'Dışa aktarmak için önce bir kilo kaydı eklemelisin.': _m(
    en: 'You must add at least one weight record before exporting.', de: 'Füge vor dem Export mindestens einen Eintrag hinzu.', nl: 'Voeg minimaal één meting toe voordat je exporteert.', fr: 'Ajoutez au moins une pesée avant d’exporter.',
    ga: 'Ní mór taifead meáchain amháin ar a laghad a chur leis roimh easpórtáil.', ru: 'Добавьте хотя бы одну запись перед экспортом.', ar: 'يجب إضافة سجل وزن واحد على الأقل قبل التصدير.', zh: '导出前请先添加至少一条体重记录。', ja: '出力する前に体重記録を1件以上登録してください。', ko: '내보내려면 먼저 하나 이상의 체중 기록을 추가하세요.',
    es: 'Debes añadir al menos un registro antes de exportar.', it: 'Aggiungi almeno una misurazione prima di esportare.', pt: 'Adicione pelo menos um registo antes de exportar.', sv: 'Lägg till minst en mätning innan export.', deCh: 'Füge vor dem Export mindestens einen Eintrag hinzu.',
  ),
  'Excel dosyası hazırlanıyor…': _m(
    en: 'Preparing Excel spreadsheet…', de: 'Excel-Datei wird vorbereitet…', nl: 'Excel-bestand wordt voorbereid…', fr: 'Préparation du fichier Excel…',
    ga: 'Comhad Excel á ullmhú…', ru: 'Подготовка файла Excel…', ar: 'جاري تجهيز ملف Excel…', zh: '正在准备 Excel 文件…', ja: 'Excelファイルを準備中…', ko: 'Excel 파일을 준비 중입니다…',
    es: 'Preparando archivo Excel…', it: 'Preparazione file Excel…', pt: 'A preparar ficheiro Excel…', sv: 'Förbereder Excel-fil…', deCh: 'Excel-Datei wird vorbereitet…',
  ),
  'Excel dosyası oluşturulamadı. Tekrar deneyebilirsin.': _m(
    en: 'Could not create Excel file. Please try again.', de: 'Excel-Datei konnte nicht erstellt werden. Bitte erneut versuchen.', nl: 'Kon Excel-bestand niet maken. Probeer het opnieuw.', fr: 'Échec de création du fichier Excel. Veuillez réessayer.',
    ga: 'Níorbh fhéidir comhad Excel a chruthú. Bain triail as arís.', ru: 'Не удалось создать файл Excel. Попробуйте снова.', ar: 'تعذر إنشاء ملف Excel. يرجى المحاولة مرة أخرى.', zh: '无法生成 Excel 文件，请重试。', ja: 'Excelファイルを作成できませんでした。再試行してください。', ko: 'Excel 파일을 생성하지 못했습니다. 다시 시도해 주세요.',
    es: 'No se pudo crear el archivo Excel. Inténtalo de nuevo.', it: 'Impossibile creare il file Excel. Riprova.', pt: 'Não foi possível criar o ficheiro Excel. Tente novamente.', sv: 'Kunde inte skapa Excel-fil. Försök igen.', deCh: 'Excel-Datei konnte nicht erstellt werden. Bitte erneut versuchen.',
  ),
  'Hızlı kayıt yapılamadı.': _m(
    en: 'Quick log failed.', de: 'Schnellspeichern fehlgeschlagen.', nl: 'Snelle opslag mislukt.', fr: 'Échec de l’enregistrement rapide.',
    ga: 'Theip ar thaifead tapa.', ru: 'Быстрая запись не удалась.', ar: 'فشل التسجيل السريع.', zh: '快捷记录失败。', ja: 'クイック記録に失敗しました。', ko: '빠른 기록에 실패했습니다.',
    es: 'Error en el registro rápido.', it: 'Registrazione rapida non riuscita.', pt: 'Falha no registo rápido.', sv: 'Kunde inte snabbspara.', deCh: 'Schnellspeichern fehlgeschlagen.',
  ),
  'Kayıt silinemedi. Tekrar dene.': _m(
    en: 'Could not delete record. Please try again.', de: 'Eintrag konnte nicht gelöscht werden. Bitte erneut versuchen.', nl: 'Kon meting niet verwijderen. Probeer het opnieuw.', fr: 'Suppression impossible. Veuillez réessayer.',
    ga: 'Níorbh fhéidir an taifead a scriosadh. Bain triail as arís.', ru: 'Не удалось удалить запись. Попробуйте снова.', ar: 'تعذر حذف السجل. حاول مرة أخرى.', zh: '无法删除记录，请重试。', ja: '記録を削除できませんでした。再試行してください。', ko: '기록을 삭제하지 못했습니다. 다시 시도해 주세요.',
    es: 'No se pudo eliminar el registro. Inténtalo de nuevo.', it: 'Impossibile eliminare. Riprova.', pt: 'Não foi possível eliminar. Tente novamente.', sv: 'Kunde inte ta bort posten. Försök igen.', deCh: 'Eintrag konnte nicht gelöscht werden. Bitte erneut versuchen.',
  ),
  'Kayıtlar okunamadı. Tekrar deneyebilirsin.': _m(
    en: 'Could not read records. Please try again.', de: 'Einträge konnten nicht geladen werden. Bitte erneut versuchen.', nl: 'Kon metingen niet laden. Probeer het opnieuw.', fr: 'Impossible de lire les enregistrements. Réessayez.',
    ga: 'Níorbh fhéidir na taifid a léamh. Bain triail as arís.', ru: 'Не удалось загрузить записи. Попробуйте снова.', ar: 'تعذر قراءة السجلات. حاول مرة أخرى.', zh: '无法读取记录，请重试。', ja: '記録を読み込めませんでした。再試行してください。', ko: '기록을 읽을 수 없습니다. 다시 시도해 주세요.',
    es: 'No se pudieron leer los registros. Inténtalo de nuevo.', it: 'Impossibile leggere le misurazioni. Riprova.', pt: 'Não foi possível carregar os registos. Tente novamente.', sv: 'Kunde inte läsa poster. Försök igen.', deCh: 'Einträge konnten nicht geladen werden. Bitte erneut versuchen.',
  ),
  'Tekrar Dene': _m(
    en: 'Retry', de: 'Erneut versuchen', nl: 'Opnieuw proberen', fr: 'Réessayer',
    ga: 'Bain Triail As Arís', ru: 'Повторить', ar: 'إعادة المحاولة', zh: '重试', ja: '再試行', ko: '다시 시도',
    es: 'Reintentar', it: 'Riprova', pt: 'Tentar de novo', sv: 'Försök igen', deCh: 'Erneut versuchen',
  ),
  'Ölçümlerini kaydetmek için Kilo Takip’i Android veya iOS cihazında aç.': _m(
    en: 'Open Weight Tracker on your Android or iOS device to record measurements.', de: 'Öffne den Gewichtstracker auf deinem Android- oder iOS-Gerät, um Messungen zu erfassen.', nl: 'Open Gewichtsmeter op je Android- of iOS-apparaat om metingen vast te leggen.', fr: 'Ouvrez Suivi du Poids sur Android ou iOS pour enregistrer vos mesures.',
    ga: 'Oscail Rianaire Meáchain ar ghléas Android nó iOS chun tomhais a thaifeadadh.', ru: 'Откройте приложение на Android или iOS для записи веса.', ar: 'افتح تطبيق متتبع الوزن على جهاز Android أو iOS لتسجيل قياساتك.', zh: '请在 Android 或 iOS 设备上打开体重追踪应用以记录数据。', ja: '体重を記録するにはAndroidまたはiOS端末でアプリを開いてください。', ko: '측정값을 기록하려면 Android 또는 iOS 기기에서 체중 관리 앱을 여세요.',
    es: 'Abre Control de Peso en tu dispositivo Android o iOS para registrar mediciones.', it: 'Apri Tracciamento Peso su Android o iOS per registrare le misurazioni.', pt: 'Abra o Controlo de Peso no seu Android ou iOS para registar medições.', sv: 'Öppna Viktspårare på din Android- eller iOS-enhet för att registrera mätningar.', deCh: 'Öffne den Gewichtstracker auf deinem Android- oder iOS-Gerät, um Messungen zu erfassen.',
  ),
  '2 ile 500 kg arasında geçerli bir kilo değeri girin.': _m(
    en: 'Please enter a valid weight between 2 and 500 kg.', de: 'Bitte gib ein gültiges Gewicht zwischen 2 und 500 kg ein.', nl: 'Voer een geldig gewicht in tussen 2 en 500 kg.', fr: 'Veuillez saisir un poids valide entre 2 et 500 kg.',
    ga: 'Cuir isteach meáchan bailí idir 2 agus 500 kg.', ru: 'Пожалуйста, введите вес от 2 до 500 кг.', ar: 'يرجى إدخال وزن صحيح بين 2 و 500 كجم.', zh: '请输入 2 至 500 kg 之间的有效体重数值。', ja: '2〜500 kgの有効な数値を入力してください。', ko: '2에서 500 kg 사이의 올바른 체중을 입력하세요.',
    es: 'Ingresa un peso válido entre 2 y 500 kg.', it: 'Inserisci un peso valido tra 2 e 500 kg.', pt: 'Introduza um peso válido entre 2 e 500 kg.', sv: 'Ange en giltig vikt mellan 2 och 500 kg.', deCh: 'Bitte gib ein gültiges Gewicht zwischen 2 und 500 kg ein.',
  ),
  'Kaydetmek için bir kilo değeri girin.': _m(
    en: 'Enter a weight value to save.', de: 'Gib einen Wert zum Speichern ein.', nl: 'Voer een gewicht in om op te slaan.', fr: 'Saisissez un poids pour enregistrer.',
    ga: 'Cuir isteach meáchan chun é a shábháil.', ru: 'Введите вес для сохранения.', ar: 'أدخل وزناً للحفظ.', zh: '请输入体重数值后再保存。', ja: '保存する体重の数値を入力してください。', ko: '저장할 체중 값을 입력해 주세요.',
    es: 'Ingresa un valor para guardar.', it: 'Inserisci un valore per salvare.', pt: 'Introduza um valor para guardar.', sv: 'Ange ett värde för att spara.', deCh: 'Gib einen Wert zum Speichern ein.',
  ),
  'Bu tarih ve kayıt türü için zaten bir ölçüm mevcut.': _m(
    en: 'A measurement already exists for this date and slot.', de: 'Für dieses Datum und diesen Zeitpunkt existiert bereits ein Eintrag.', nl: 'Er bestaat al een meting voor deze datum en tijd.', fr: 'Une mesure existe déjà pour cette date et ce créneau.',
    ga: 'Tá tomhas ann cheana don dáta agus don chineál seo.', ru: 'Для этой даты и времени уже существует запись.', ar: 'يوجد قياس مسجل بالفعل لهذا التاريخ والوقت.', zh: '该日期和时段已有记录。', ja: 'この日付と時間帯の記録は既に存在します。', ko: '해당 날짜 및 시간대에 이미 기록이 존재합니다.',
    es: 'Ya existe una medición para esta fecha y horario.', it: 'Esiste già una misurazione per questa data e fascia.', pt: 'Já existe uma medição para esta data e hora.', sv: 'Det finns redan en mätning för detta datum och pass.', deCh: 'Für dieses Datum und diesen Zeitpunkt existiert bereits ein Eintrag.',
  ),
  'Kilo kaydı kaydedilemedi. Lütfen tekrar dene.': _m(
    en: 'Could not save weight record. Please try again.', de: 'Eintrag konnte nicht gespeichert werden. Bitte erneut versuchen.', nl: 'Kon meting niet opslaan. Probeer het opnieuw.', fr: 'Échec de l’enregistrement. Veuillez réessayer.',
    ga: 'Níorbh fhéidir an taifead a shábháil. Bain triail as arís.', ru: 'Не удалось сохранить запись. Попробуйте снова.', ar: 'تعذر حفظ السجل. يرجى المحاولة مرة أخرى.', zh: '保存失败，请重试。', ja: '体重記録を保存できませんでした。再試行してください。', ko: '체중 기록을 저장하지 못했습니다. 다시 시도해 주세요.',
    es: 'No se pudo guardar el registro. Inténtalo de nuevo.', it: 'Impossibile salvare la misurazione. Riprova.', pt: 'Não foi possível guardar. Tente novamente.', sv: 'Kunde inte spara viktposten. Försök igen.', deCh: 'Eintrag konnte nicht gespeichert werden. Bitte erneut versuchen.',
  ),
  'Kaydediliyor…': _m(
    en: 'Saving…', de: 'Wird gespeichert…', nl: 'Opslaan…', fr: 'Enregistrement…',
    ga: 'Ag sábháil…', ru: 'Сохранение…', ar: 'جاري الحفظ…', zh: '正在保存…', ja: '保存中…', ko: '저장 중…',
    es: 'Guardando…', it: 'Salvataggio…', pt: 'A guardar…', sv: 'Sparar…', deCh: 'Wird gespeichert…',
  ),
  'Kapat': _m(
    en: 'Close', de: 'Schließen', nl: 'Sluiten', fr: 'Fermer',
    ga: 'Dún', ru: 'Закрыть', ar: 'إغلاق', zh: '关闭', ja: '閉じる', ko: '닫기',
    es: 'Cerrar', it: 'Chiudi', pt: 'Fechar', sv: 'Stäng', deCh: 'Schließen',
  ),
  'Azalt (-0.1 kg)': _m(
    en: 'Decrease (-0.1 kg)', de: 'Verringern (-0.1 kg)', nl: 'Verlagen (-0.1 kg)', fr: 'Diminuer (-0.1 kg)',
    ga: 'Laghdaigh (-0.1 kg)', ru: 'Уменьшить (-0.1 кг)', ar: 'تقليل (-0.1 كجم)', zh: '减少 (-0.1 kg)', ja: '減らす (-0.1 kg)', ko: '감소 (-0.1 kg)',
    es: 'Disminuir (-0.1 kg)', it: 'Diminuisci (-0.1 kg)', pt: 'Diminuir (-0.1 kg)', sv: 'Minska (-0.1 kg)', deCh: 'Verringern (-0.1 kg)',
  ),
  '-1 Bardak': _m(
    en: '-1 Glass', de: '-1 Glas', nl: '-1 Glas', fr: '-1 Verre',
    ga: '-1 Ghloine', ru: '-1 стакан', ar: '-1 كوب', zh: '-1 杯', ja: '-1 杯', ko: '-1 잔',
    es: '-1 Vaso', it: '-1 Bicchiere', pt: '-1 Copo', sv: '-1 Glas', deCh: '-1 Glas',
  ),
  '250 ml': _m(
    en: '250 ml', de: '250 ml', nl: '250 ml', fr: '250 ml',
    ga: '250 ml', ru: '250 мл', ar: '250 مل', zh: '250 毫升', ja: '250 ml', ko: '250 ml',
    es: '250 ml', it: '250 ml', pt: '250 ml', sv: '250 ml', deCh: '250 ml',
  ),
  'Bu Güne Kayıt Ekle': _m(
    en: 'Log on this Day', de: 'Für diesen Tag eintragen', nl: 'Voeg toe op deze dag', fr: 'Ajouter à cette date',
    ga: 'Cuir leis an Lá Seo', ru: 'Добавить на этот день', ar: 'إضافة لهذا اليوم', zh: '补录此日数据', ja: 'この日の記録を追加', ko: '이 날짜에 기록 추가',
    es: 'Añadir a esta fecha', it: 'Aggiungi a questo giorno', pt: 'Adicionar a este dia', sv: 'Lägg till denna dag', deCh: 'Für diesen Tag eintragen',
  ),
  'Bu tarihe ait kilo kaydı bulunamadı.': _m(
    en: 'No weight records found for this date.', de: 'Keine Einträge für dieses Datum gefunden.', nl: 'Geen metingen gevonden voor deze datum.', fr: 'Aucune pesée trouvée pour cette date.',
    ga: 'Ní bhfuarthas aon taifead don dáta seo.', ru: 'Нет записей веса за эту дату.', ar: 'لا توجد سجلات وزن لهذا التاريخ.', zh: '该日期暂无体重记录。', ja: 'この日付の体重記録は見つかりませんでした。', ko: '이 날짜의 체중 기록을 찾을 수 없습니다.',
    es: 'No se encontraron registros para esta fecha.', it: 'Nessuna registrazione per questa data.', pt: 'Sem registos para esta data.', sv: 'Inga viktposter hittades för detta datum.', deCh: 'Keine Einträge für dieses Datum gefunden.',
  ),
  'Hangi ölçüm silinsin?': _m(
    en: 'Which entry to delete?', de: 'Welcher Eintrag soll gelöscht werden?', nl: 'Welke meting wil je verwijderen?', fr: 'Quelle pesée supprimer ?',
    ga: 'Cén tomhas le scriosadh?', ru: 'Какое измерение удалить?', ar: 'أي قياس تريد حذفه؟', zh: '选择要删除的记录：', ja: 'どちらの記録を削除しますか？', ko: '어떤 기록을 삭제하시겠습니까?',
    es: '¿Qué medición deseas eliminar?', it: 'Quale misurazione eliminare?', pt: 'Qual a medição a eliminar?', sv: 'Vilken mätning ska tas bort?', deCh: 'Welcher Eintrag soll gelöscht werden?',
  ),
  'Tüm Günü Sil (2 Kayıt)': _m(
    en: 'Delete Full Day (2 Records)', de: 'Ganzen Tag löschen (2 Einträge)', nl: 'Hele dag verwijderen (2 metingen)', fr: 'Supprimer la journée (2 pesées)',
    ga: 'Scrios an Lá ar Fad (2 Thaifead)', ru: 'Удалить оба замера (2 записи)', ar: 'حذف اليوم بالكامل (سجلين)', zh: '删除整天 (2条记录)', ja: '1日分すべて削除 (2件)', ko: '하루 전체 삭제 (2건)',
    es: 'Eliminar día completo (2 registros)', it: 'Elimina intera giornata (2 misurazioni)', pt: 'Eliminar dia completo (2 registos)', sv: 'Ta bort hela dagen (2 poster)', deCh: 'Ganzen Tag löschen (2 Einträge)',
  ),
  'Tüm Kayıtları Göster': _m(
    en: 'Show All Records', de: 'Alle Einträge anzeigen', nl: 'Toon alle metingen', fr: 'Afficher toutes les pesées',
    ga: 'Taispeáin Gach Taifead', ru: 'Показать все записи', ar: 'عرض جميع السجلات', zh: '查看全部记录', ja: 'すべての記録を表示', ko: '모든 기록 보기',
    es: 'Mostrar todos los registros', it: 'Mostra tutte le misurazioni', pt: 'Mostrar todos os registos', sv: 'Visa alla poster', deCh: 'Alle Einträge anzeigen',
  ),
  'Sonraki ay': _m(
    en: 'Next month', de: 'Nächster Monat', nl: 'Volgende maand', fr: 'Mois suivant',
    ga: 'Mí seo chugainn', ru: 'След. месяц', ar: 'الشهر التالي', zh: '下个月', ja: '翌月', ko: '다음 달',
    es: 'Mes siguiente', it: 'Mese successivo', pt: 'Mês seguinte', sv: 'Nästa månad', deCh: 'Nächster Monat',
  ),
  'Önceki ay': _m(
    en: 'Previous month', de: 'Vorheriger Monat', nl: 'Vorige maand', fr: 'Mois précédent',
    ga: 'Mí roimhe seo', ru: 'Пред. месяц', ar: 'الشهر السابق', zh: '上个月', ja: '前月', ko: '이전 달',
    es: 'Mes anterior', it: 'Mese precedente', pt: 'Mês anterior', sv: 'Föregående månad', deCh: 'Vorheriger Monat',
  ),
  'Sonraki Ay': _m(
    en: 'Next Month', de: 'Nächster Monat', nl: 'Volgende Maand', fr: 'Mois Suivant',
    ga: 'Mí Seo Chugainn', ru: 'След. месяц', ar: 'الشهر التالي', zh: '下个月', ja: '翌月', ko: '다음 달',
    es: 'Mes Siguiente', it: 'Mese Successivo', pt: 'Mês Seguinte', sv: 'Nästa Månad', deCh: 'Nächster Monat',
  ),
  'Önceki Ay': _m(
    en: 'Previous Month', de: 'Vorheriger Monat', nl: 'Vorige Maand', fr: 'Mois Précédent',
    ga: 'Mí Roimhe Seo', ru: 'Пред. месяц', ar: 'الشهر السابق', zh: '上个月', ja: '前月', ko: '이전 달',
    es: 'Mes Anterior', it: 'Mese Precedente', pt: 'Mês Anterior', sv: 'Föregående Månad', deCh: 'Vorheriger Monat',
  ),
  'En Yüksek Kilo (Seçili Dönem)': _m(
    en: 'Highest Weight (Period)', de: 'Höchstgewicht (Zeitraum)', nl: 'Hoogste Gewicht (Periode)', fr: 'Poids Max (Période)',
    ga: 'Meáchan Is Airde (Tréimhse)', ru: 'Макс. вес за период', ar: 'أعلى وزن (الفترة)', zh: '所选时期最高体重', ja: '期間内最高体重', ko: '해당 기간 최고 체중',
    es: 'Peso Máximo (Período)', it: 'Peso Massimo (Periodo)', pt: 'Peso Máximo (Período)', sv: 'Högsta vikt (Period)', deCh: 'Höchstgewicht (Zeitraum)',
  ),
  'Ayarlar’dan boy (cm) bilgini girerek VKİ ve ideal kilo aralığını görebilirsin.': _m(
    en: 'Enter your height (cm) in Settings to view your BMI and ideal weight range.', de: 'Trage deine Größe (cm) in den Einstellungen ein, um BMI und Idealgewicht zu sehen.', nl: 'Vul je lengte (cm) in bij Instellingen voor je BMI en ideaal gewicht.', fr: 'Saisissez votre taille (cm) dans les Paramètres pour voir votre IMC et poids idéal.',
    ga: 'Cuir d’airde (cm) isteach sna Socruithe chun do BMI agus réimse meáchain a fheiceáil.', ru: 'Укажите рост (см) в Настройках, чтобы увидеть ИМТ и диапазон идеального веса.', ar: 'أدخل طولك (سم) في الإعدادات لعرض مؤشر كتلة الجسم والنطاق المثالي.', zh: '在“设置”中输入您的身高(cm)即可查看BMI与健康理想体重范围。', ja: '「設定」で身長(cm)を入力すると、BMIと適正体重の範囲が表示されます。', ko: '설정에서 신장(cm)을 입력하면 BMI와 이상적인 체중 범위를 확인할 수 있습니다.',
    es: 'Ingresa tu altura (cm) en Ajustes para ver tu IMC y peso ideal.', it: 'Inserisci la tua altezza (cm) nelle Impostazioni per visualizzare IMC e peso ideale.', pt: 'Introduza a sua altura (cm) nas Definições para ver o IMC e o peso ideal.', sv: 'Ange din längd (cm) i Inställningar för att se BMI och idealviktsintervall.', deCh: 'Trage deine Größe (cm) in den Einstellungen ein, um BMI und Idealgewicht zu sehen.',
  ),
  'Seçilen döneme ait kayıt bulunmuyor.': _m(
    en: 'No records found for the selected period.', de: 'Keine Einträge für den ausgewählten Zeitraum.', nl: 'Geen metingen gevonden voor de gekozen periode.', fr: 'Aucune pesée trouvée pour la période sélectionnée.',
    ga: 'Ní bhfuarthas aon taifead don tréimhse seo.', ru: 'Нет записей за выбранный период.', ar: 'لا توجد سجلات للفترة المحددة.', zh: '所选时间范围内暂无记录。', ja: '選択された期間の記録はありません。', ko: '선택한 기간 동안의 기록이 없습니다.',
    es: 'No hay registros para el período seleccionado.', it: 'Nessuna registrazione per il periodo selezionato.', pt: 'Sem registos para o período selecionado.', sv: 'Inga mätningar för den valda perioden.', deCh: 'Keine Einträge für den ausgewählten Zeitraum.',
  ),
  'Ertesi gün verisi bekleniyor': _m(
    en: 'Next-day data pending', de: 'Warte auf Folgetags-Daten', nl: 'Wachten op volgende dag', fr: 'En attente de la pesée du lendemain',
    ga: 'Sonraí an lá arna mhárach ag teastáil', ru: 'Ожидаются данные на след. день', ar: 'في انتظار بيانات اليوم التالي', zh: '等待次日测量数据', ja: '翌日のデータ待ち', ko: '익일 측정 데이터 대기 중',
    es: 'Esperando datos del día siguiente', it: 'In attesa dei dati del giorno dopo', pt: 'A aguardar dados do dia seguinte', sv: 'Inväntar data för nästa dag', deCh: 'Warte auf Folgetags-Daten',
  ),
  'Kilo Koruma Bandındasın': _m(
    en: 'You are in the Maintenance Band', de: 'Du bist im Gewichtserhaltungsbereich', nl: 'Je zit in het gewichtsbehoudbereik', fr: 'Vous êtes dans la zone de maintien',
    ga: 'Tá tú sa Bhabhta Cothaithe Meáchain', ru: 'Вы в диапазоне поддержания веса', ar: 'أنت ضمن نطاق تثبيت الوزن', zh: '您正处于体重保持安全带内', ja: '体重キープ維持ゾーン内です', ko: '체중 유지 구간 내에 있습니다',
    es: 'Estás en la franja de mantenimiento', it: 'Sei nella fascia di mantenimento', pt: 'Está na faixa de manutenção', sv: 'Du är i viktbevarandeintervallet', deCh: 'Du bist im Gewichtserhaltungsbereich',
  ),
  'Kilo Koruma Bandı': _m(
    en: 'Maintenance Band', de: 'Erhaltungsbereich', nl: 'Gewichtsbehoudbereik', fr: 'Zone de Maintien',
    ga: 'Babhta Cothaithe', ru: 'Диапазон поддержания', ar: 'نطاق تثبيت الوزن', zh: '体重保持带', ja: '維持ゾーン', ko: '체중 유지 구간',
    es: 'Franja de Mantenimiento', it: 'Fascia di Mantenimento', pt: 'Faixa de Manutenção', sv: 'Viktbevarandeintervall', deCh: 'Erhaltungsbereich',
  ),
  'Ayar kaydedilemedi. Tekrar dene.': _m(
    en: 'Could not save setting. Please try again.', de: 'Einstellung konnte nicht gespeichert werden.', nl: 'Kon instelling niet opslaan. Probeer opnieuw.', fr: 'Échec de l’enregistrement du paramètre.',
    ga: 'Níorbh fhéidir an socrú a shábháil.', ru: 'Не удалось сохранить настройки.', ar: 'تعذر حفظ الإعداد. حاول مرة أخرى.', zh: '设置未能保存，请重试。', ja: '設定を保存できませんでした。再試行してください。', ko: '설정을 저장하지 못했습니다. 다시 시도해 주세요.',
    es: 'No se pudo guardar el ajuste.', it: 'Impossibile salvare l’impostazione.', pt: 'Não foi possível guardar a definição.', sv: 'Kunde inte spara inställningen.', deCh: 'Einstellung konnte nicht gespeichert werden.',
  ),
  'Hedef Kilo & Boy Ayarları': _m(
    en: 'Target Weight & Height Settings', de: 'Zielgewicht- & Größeneinstellungen', nl: 'Streefgewicht & Lengte-instellingen', fr: 'Paramètres Poids Cible & Taille',
    ga: 'Socruithe Spriocmheáchain & Airde', ru: 'Параметры цели и роста', ar: 'إعدادات الوزن المستهدف والطول', zh: '目标体重与身高设置', ja: '目標体重・身長設定', ko: '목표 체중 및 신장 설정',
    es: 'Ajustes de Peso Meta y Altura', it: 'Impostazioni Peso Obiettivo e Altezza', pt: 'Definições de Peso Alvo e Altura', sv: 'Målvikt- & Längdinställningar', deCh: 'Zielgewicht- & Größeneinstellungen',
  ),
  'Başlangıç kilosu, hedef kilo ve boy (cm) bilgini girerek VKİ, ideal kilo aralığı ve hedef tarihini takip edebilirsin.': _m(
    en: 'Enter starting weight, target weight, and height (cm) to track your BMI, healthy weight range, and target date.', de: 'Gib Startgewicht, Zielgewicht und Größe (cm) ein, um BMI, Idealgewicht und Zieldatum zu verfolgen.', nl: 'Vul startgewicht, streefgewicht en lengte (cm) in om je BMI, ideaal bereik en streefdatum te volgen.', fr: 'Saisissez votre poids de départ, cible et taille (cm) pour suivre votre IMC, poids idéal et date cible.',
    ga: 'Cuir isteach meáchan tosaigh, spriocmheáchan agus airde (cm) chun do BMI agus réamhaisnéis a leanúint.', ru: 'Укажите начальный и целевой вес, рост (см) для расчёта ИМТ, нормы и прогноза даты достижения.', ar: 'أدخل وزن البداية والوزن المستهدف والطول (سم) لتتبع مؤشر كتلة الجسم والنطاق المثالي والتاريخ المتوقع.', zh: '输入初始体重、目标体重和身高(cm)，以追踪BMI、理想体重区间和预估达成日期。', ja: '開始体重・目標体重・身長(cm)を設定すると、BMI・適正体重範囲・達成予測日を自動計算します。', ko: '시작 체중, 목표 체중 및 신장(cm)을 입력하여 BMI, 적정 체중 범위 및 예상 달성일을 확인하세요.',
    es: 'Ingresa tu peso inicial, meta y altura (cm) para seguir tu IMC, peso ideal y fecha estimada.', it: 'Inserisci peso iniziale, obiettivo e altezza (cm) per tracciare IMC, peso ideale e data prevista.', pt: 'Introduza o peso inicial, alvo e altura (cm) para acompanhar o IMC, peso ideal e data prevista.', sv: 'Ange startvikt, målvikt och längd (cm) för att följa BMI, idealvikt och beräknat måldatum.', deCh: 'Gib Startgewicht, Zielgewicht und Größe (cm) ein, um BMI, Idealgewicht und Zieldatum zu verfolgen.',
  ),
  'Başlangıç Kilosu (opsiyonel)': _m(
    en: 'Starting Weight (optional)', de: 'Startgewicht (optional)', nl: 'Startgewicht (optioneel)', fr: 'Poids de Départ (optionnel)',
    ga: 'Meáchan Tosaigh (roghnach)', ru: 'Начальный вес (необязательно)', ar: 'وزن البداية (اختياري)', zh: '初始体重 (可选)', ja: '開始体重 (任意)', ko: '시작 체중 (선택사항)',
    es: 'Peso Inicial (opcional)', it: 'Peso Iniziale (opzionale)', pt: 'Peso Inicial (opcional)', sv: 'Startvikt (valfritt)', deCh: 'Startgewicht (optional)',
  ),
  'Hedef Kilo (opsiyonel)': _m(
    en: 'Target Weight (optional)', de: 'Zielgewicht (optional)', nl: 'Streefgewicht (optioneel)', fr: 'Poids Cible (optionnel)',
    ga: 'Spriocmheáchan (roghnach)', ru: 'Целевой вес (необязательно)', ar: 'الوزن المستهدف (اختياري)', zh: '目标体重 (可选)', ja: '目標体重 (任意)', ko: '목표 체중 (선택사항)',
    es: 'Peso Meta (opcional)', it: 'Peso Obiettivo (opzionale)', pt: 'Peso Alvo (opcional)', sv: 'Målvikt (valfritt)', deCh: 'Zielgewicht (optional)',
  ),
  'Boy (cm - VKİ hesabı için)': _m(
    en: 'Height (cm - for BMI calculation)', de: 'Größe (cm - für BMI-Berechnung)', nl: 'Lengte (cm - voor BMI berekening)', fr: 'Taille (cm - pour calcul IMC)',
    ga: 'Airde (cm - do ríomh BMI)', ru: 'Рост (см - для расчёта ИМТ)', ar: 'الطول (سم - لحساب مؤشر الكتلة)', zh: '身高 (cm - 用于BMI计算)', ja: '身長 (cm - BMI計算用)', ko: '신장 (cm - BMI 계산용)',
    es: 'Altura (cm - para cálculo de IMC)', it: 'Altezza (cm - per calcolo IMC)', pt: 'Altura (cm - para cálculo do IMC)', sv: 'Längd (cm - för BMI-beräkning)', deCh: 'Größe (cm - für BMI-Berechnung)',
  ),
  'Kilo Koruma Modu (±1.0 kg)': _m(
    en: 'Maintenance Mode (±1.0 kg)', de: 'Gewichtserhaltungsmodus (±1.0 kg)', nl: 'Gewichtsbehoud Modus (±1.0 kg)', fr: 'Mode Maintien du Poids (±1.0 kg)',
    ga: 'Modh Cothaithe Meáchain (±1.0 kg)', ru: 'Режим удержания веса (±1.0 кг)', ar: 'وضع تثبيت الوزن (±1.0 كجم)', zh: '体重保持模式 (±1.0 kg)', ja: '体重キープ維持モード (±1.0 kg)', ko: '체중 유지 관리 모드 (±1.0 kg)',
    es: 'Modo de Mantenimiento (±1.0 kg)', it: 'Modalità Mantenimento (±1.0 kg)', pt: 'Modo de Manutenção (±1.0 kg)', sv: 'Viktbevarandeläge (±1.0 kg)', deCh: 'Gewichtserhaltungsmodus (±1.0 kg)',
  ),
  'Hedef kiloya ulaştığında güvenli koruma bandını grafikte göster': _m(
    en: 'Display safe maintenance band on charts once goal is reached', de: 'Sichere Erhaltungszone im Diagramm anzeigen, sobald das Ziel erreicht ist', nl: 'Toon veilige behoudszone op grafieken zodra het doel is bereikt', fr: 'Afficher la zone de maintien sur les graphiques après atteinte de l’objectif',
    ga: 'Taispeáin crios sábháilte ar na cairteacha nuair a bhaintear an sprioc amach', ru: 'Показывать зелёную зону удержания на графике при достижении цели', ar: 'إظهار نطاق التثبيت الآمن على الرسوم البيانية عند الوصول للهدف', zh: '达成目标体重后在图表上显示绿色安全保持区间', ja: '目標体重に達した際、グラフ上に安全な維持ゾーンを表示します', ko: '목표 체중 달성 시 그래프에 안전 유지 구간을 시각화합니다',
    es: 'Mostrar banda segura de mantenimiento en el gráfico al alcanzar la meta', it: 'Mostra la fascia sicura di mantenimento nei grafici al raggiungimento dell’obiettivo', pt: 'Mostrar faixa segura de manutenção no gráfico ao atingir a meta', sv: 'Visa säker bevarandezon i diagrammet när målet har nåtts', deCh: 'Sichere Erhaltungszone im Diagramm anzeigen, sobald das Ziel erreicht ist',
  ),
  'Başlangıç kilosu 2 ile 500 kg arasında olmalıdır.': _m(
    en: 'Starting weight must be between 2 and 500 kg.', de: 'Startgewicht muss zwischen 2 und 500 kg liegen.', nl: 'Startgewicht moet tussen 2 en 500 kg zijn.', fr: 'Le poids de départ doit être compris entre 2 et 500 kg.',
    ga: 'Ní mór do mheáchan tosaigh a bheith idir 2 agus 500 kg.', ru: 'Начальный вес должен быть от 2 до 500 кг.', ar: 'يجب أن يكون وزن البداية بين 2 و 500 كجم.', zh: '初始体重必须在 2 至 500 kg 之间。', ja: '開始体重は2〜500 kgの間で入力してください。', ko: '시작 체중은 2에서 500 kg 사이여야 합니다.',
    es: 'El peso inicial debe estar entre 2 y 500 kg.', it: 'Il peso iniziale deve essere compreso tra 2 e 500 kg.', pt: 'O peso inicial deve situar-se entre 2 e 500 kg.', sv: 'Startvikten måste vara mellan 2 och 500 kg.', deCh: 'Startgewicht muss zwischen 2 und 500 kg liegen.',
  ),
  'Hedef kilo 2 ile 500 kg arasında olmalıdır.': _m(
    en: 'Target weight must be between 2 and 500 kg.', de: 'Zielgewicht muss zwischen 2 und 500 kg liegen.', nl: 'Streefgewicht moet tussen 2 en 500 kg zijn.', fr: 'Le poids cible doit être compris entre 2 et 500 kg.',
    ga: 'Ní mór don spriocmheáchan a bheith idir 2 agus 500 kg.', ru: 'Целевой вес должен быть от 2 до 500 кг.', ar: 'يجب أن يكون الوزن المستهدف بين 2 و 500 كجم.', zh: '目标体重必须在 2 至 500 kg 之间。', ja: '目標体重は2〜500 kgの間で入力してください。', ko: '목표 체중은 2에서 500 kg 사이여야 합니다.',
    es: 'El peso meta debe estar entre 2 y 500 kg.', it: 'Il peso obiettivo deve essere compreso tra 2 e 500 kg.', pt: 'O peso alvo deve situar-se entre 2 e 500 kg.', sv: 'Målvikten måste vara mellan 2 och 500 kg.', deCh: 'Zielgewicht muss zwischen 2 und 500 kg liegen.',
  ),
  'Boy 80 ile 250 cm arasında olmalıdır.': _m(
    en: 'Height must be between 80 and 250 cm.', de: 'Größe muss zwischen 80 und 250 cm liegen.', nl: 'Lengte moet tussen 80 en 250 cm zijn.', fr: 'La taille doit être comprise entre 80 et 250 cm.',
    ga: 'Ní mór d’airde a bheith idir 80 agus 250 cm.', ru: 'Рост должен быть от 80 до 250 см.', ar: 'يجب أن يكون الطول بين 80 و 250 سم.', zh: '身高必须在 80 至 250 cm 之间。', ja: '身長は80〜250 cmの間で入力してください。', ko: '신장은 80에서 250 cm 사이여야 합니다.',
    es: 'La altura debe estar entre 80 y 250 cm.', it: 'L’altezza deve essere compresa tra 80 e 250 cm.', pt: 'A altura deve situar-se entre 80 e 250 cm.', sv: 'Längden måste vara mellan 80 och 250 cm.', deCh: 'Größe muss zwischen 80 und 250 cm liegen.',
  ),
  'Vücut Çevre Ölçüleri (cm)': _m(
    en: 'Body Circumferences (cm)', de: 'Körperumfänge (cm)', nl: 'Lichaamsomtrekken (cm)', fr: 'Mensurations Corporelles (cm)',
    ga: 'Tomhais Choirp (cm)', ru: 'Обхваты тела (см)', ar: 'قياسات محيط الجسم (سم)', zh: '身体围度测量 (cm)', ja: '身体サイズ・周囲径 (cm)', ko: '신체 둘레 측정 (cm)',
    es: 'Medidas Corporales (cm)', it: 'Circonferenze Corporee (cm)', pt: 'Medidas Corporais (cm)', sv: 'Kroppsomkrets (cm)', deCh: 'Körperumfänge (cm)',
  ),
  'Tartıdaki kilo sabit kalsa bile incelmeyi takip etmek için mezura ölçülerini kaydedebilirsin.': _m(
    en: 'Track fat loss with a tape measure even when scale weight fluctuates or stays constant.', de: 'Verfolge den Fettabbau mit dem Maßband, auch wenn die Waage unverändert bleibt.', nl: 'Volg centimeters met een meetlint, zelfs als de weegschaal stilstaat.', fr: 'Suivez l’amincissement au mètre ruban même si le poids sur la balance stagne.',
    ga: 'Rianaigh do chuid orlach le téipbheart fiú má fhanann an meáchan mar a chéile.', ru: 'Отслеживайте уменьшение объёмов с помощью сантиметра, даже если вес стоит на месте.', ar: 'تابع فقدان الدهون بشريط القياس حتى لو ثبت الوزن على الميزان.', zh: '即便体重秤数字短期停滞，您也可以通过皮尺围度直观观察体型塑形进展。', ja: '体重計の数値が停滞していても、メジャー計測で引き締まりを実感できます。', ko: '체중계 숫자가 정체되어 있어도 줄자 측정으로 체형 변화와 인치 감소를 추적할 수 있습니다.',
    es: 'Mide tu progreso con cinta métrica incluso si el peso en la báscula no cambia.', it: 'Monitora i centimetri con il metro da sarta anche quando il peso sulla bilancia non varia.', pt: 'Acompanhe a perda de centímetros mesmo quando o peso na balança estagnar.', sv: 'Mät centimeter med måttband även när vågen står stilla.', deCh: 'Verfolge den Fettabbau mit dem Maßband, auch wenn die Waage unverändert bleibt.',
  ),
  'Bel Çevresi (opsiyonel)': _m(
    en: 'Waist Circumference (optional)', de: 'Taillenumfang (optional)', nl: 'Tailleomtrek (optioneel)', fr: 'Tour de Taille (optionnel)',
    ga: 'Imchló Coim (roghnach)', ru: 'Обхват талии (необязательно)', ar: 'محيط الخصر (اختياري)', zh: '腰围 (可选)', ja: 'ウエスト周囲径 (任意)', ko: '허리둘레 (선택사항)',
    es: 'Cintura (opcional)', it: 'Girovita (opzionale)', pt: 'Cintura (opcional)', sv: 'Midjemått (valfritt)', deCh: 'Taillenumfang (optional)',
  ),
  'Kalça Çevresi (opsiyonel)': _m(
    en: 'Hip Circumference (optional)', de: 'Hüftumfang (optional)', nl: 'Heupomtrek (optioneel)', fr: 'Tour de Hanche (optionnel)',
    ga: 'Imchló Cromáin (roghnach)', ru: 'Обхват бёдер (необязательно)', ar: 'محيط الورك (اختياري)', zh: '臀围 (可选)', ja: 'ヒップ周囲径 (任意)', ko: '엉덩이둘레 (선택사항)',
    es: 'Cadera (opcional)', it: 'Fianchi (opzionale)', pt: 'Anca (opcional)', sv: 'Höftmått (valfritt)', deCh: 'Hüftumfang (optional)',
  ),
  'Boyun Çevresi (opsiyonel)': _m(
    en: 'Neck Circumference (optional)', de: 'Halsumfang (optional)', nl: 'Nekomtrek (optioneel)', fr: 'Tour de Cou (optionnel)',
    ga: 'Imchló Muiníl (roghnach)', ru: 'Обхват шеи (необязательно)', ar: 'محيط الرقبة (اختياري)', zh: '颈围 (可选)', ja: '首周り (任意)', ko: '목둘레 (선택사항)',
    es: 'Cuello (opcional)', it: 'Collo (opzionale)', pt: 'Pescoço (opcional)', sv: 'Halsmått (valfritt)', deCh: 'Halsumfang (optional)',
  ),
  'Lütfen 15 ile 250 cm arasında geçerli değerler girin.': _m(
    en: 'Please enter valid values between 15 and 250 cm.', de: 'Bitte gib gültige Werte zwischen 15 und 250 cm ein.', nl: 'Voer geldige waarden in tussen 15 en 250 cm.', fr: 'Veuillez saisir des valeurs valides entre 15 et 250 cm.',
    ga: 'Cuir isteach luachanna bailí idir 15 agus 250 cm.', ru: 'Пожалуйста, введите значения от 15 до 250 см.', ar: 'يرجى إدخال قيم صحيحة بين 15 و 250 سم.', zh: '请输入 15 至 250 cm 之间的有效数值。', ja: '15〜250 cmの有効な値を入力してください。', ko: '15에서 250 cm 사이의 올바른 값을 입력하세요.',
    es: 'Ingresa valores válidos entre 15 y 250 cm.', it: 'Inserisci valori validi tra 15 e 250 cm.', pt: 'Introduza valores válidos entre 15 e 250 cm.', sv: 'Ange giltiga värden mellan 15 och 250 cm.', deCh: 'Bitte gib gültige Werte zwischen 15 und 250 cm ein.',
  ),
  'Bildirim İznini Kontrol Et': _m(
    en: 'Check Notification Permission', de: 'Benachrichtigungsberechtigung prüfen', nl: 'Controleer meldingsrechten', fr: 'Vérifier l’autorisation des notifications',
    ga: 'Seiceáil Cead Fógraí', ru: 'Проверить разрешение на уведомления', ar: 'فحص إذن الإشعارات', zh: '检查通知权限', ja: '通知の権限を確認', ko: '알림 권한 확인',
    es: 'Comprobar permisos de notificación', it: 'Verifica permessi notifiche', pt: 'Verificar permissão de notificações', sv: 'Kontrollera aviseringstillstånd', deCh: 'Benachrichtigungsberechtigung prüfen',
  ),
  'Kesin Alarm İznini Aç': _m(
    en: 'Enable Exact Alarm Permission', de: 'Berechtigung für genaue Alarme aktivieren', nl: 'Schakel exacte alarmen in', fr: 'Activer les alarmes exactes',
    ga: 'Cumasaigh Cead Aláraim Chruinn', ru: 'Включить точные будильники', ar: 'تفعيل إذن المنبه الدقيق', zh: '开启精确闹钟权限', ja: '正確なアラーム権限を許可', ko: '정확한 알람 권한 켜기',
    es: 'Permitir alarmas exactas', it: 'Consenti allarmi precisi', pt: 'Ativar alarmes exatos', sv: 'Tillåt exakta larm', deCh: 'Berechtigung für genaue Alarme aktivieren',
  ),
  'Geri': _m(
    en: 'Back', de: 'Zurück', nl: 'Terug', fr: 'Retour',
    ga: 'Siar', ru: 'Назад', ar: 'رجوع', zh: '返回', ja: '戻る', ko: '뒤로',
    es: 'Atrás', it: 'Indietro', pt: 'Voltar', sv: 'Tillbaka', deCh: 'Zurück',
  ),
  'Kapalı': _m(
    en: 'Off', de: 'Aus', nl: 'Uit', fr: 'Désactivé',
    ga: 'Múchta', ru: 'Выкл.', ar: 'معطل', zh: '已关闭', ja: 'オフ', ko: '꺼짐',
    es: 'Desactivado', it: 'Disattivato', pt: 'Desativado', sv: 'Av', deCh: 'Aus',
  ),
  'İlk kayıt': _m(
    en: 'First entry', de: 'Erster Eintrag', nl: 'Eerste meting', fr: 'Première pesée',
    ga: 'An chéad taifead', ru: 'Первая запись', ar: 'أول قياس', zh: '首次记录', ja: '初回記録', ko: '첫 기록',
    es: 'Primer registro', it: 'Prima registrazione', pt: 'Primeiro registo', sv: 'Första posten', deCh: 'Erster Eintrag',
  ),
  'Sağlıklı': _m(
    en: 'Healthy', de: 'Gesund', nl: 'Gezond', fr: 'Sain',
    ga: 'Sláintiúil', ru: 'Норма', ar: 'صحي', zh: '健康', ja: '良好', ko: '건강',
    es: 'Saludable', it: 'Sano', pt: 'Saudável', sv: 'Hälsosam', deCh: 'Gesund',
  ),
  'Yüksek': _m(
    en: 'High', de: 'Hoch', nl: 'Hoog', fr: 'Élevé',
    ga: 'Ard', ru: 'Высокий', ar: 'مرتفع', zh: '偏高', ja: '高め', ko: '높음',
    es: 'Alto', it: 'Alto', pt: 'Alto', sv: 'Hög', deCh: 'Hoch',
  ),
  'Dikkat': _m(
    en: 'Caution', de: 'Achtung', nl: 'Let op', fr: 'Attention',
    ga: 'Rabhadh', ru: 'Внимание', ar: 'انتباه', zh: '需留意', ja: '注意', ko: '주의',
    es: 'Atención', it: 'Attenzione', pt: 'Atenção', sv: 'Varning', deCh: 'Achtung',
  ),
  'İdeal': _m(
    en: 'Ideal', de: 'Ideal', nl: 'Ideaal', fr: 'Idéal',
    ga: 'Idéalach', ru: 'Идеал', ar: 'مثالي', zh: '理想', ja: '理想的', ko: '이상적',
    es: 'Ideal', it: 'Ideale', pt: 'Ideal', sv: 'Ideal', deCh: 'Ideal',
  ),
  'Mevcut kilon zaten hedef kilona çok yakın! Kilo koruma kalorisiyle devam edebilirsin.': _m(
    en: 'Your current weight is already very close to your goal! You can stay on maintenance calories.', de: 'Dein aktuelles Gewicht ist bereits sehr nah an deinem Ziel! Du kannst mit Erhaltungskalorien fortfahren.', nl: 'Je gewicht is al heel dicht bij je doel! Je kunt doorgaan met behoudcalorieën.', fr: 'Votre poids actuel est déjà très proche de votre objectif ! Poursuivez en maintien calorique.',
    ga: 'Tá do mheáchan an-ghar do do sprioc cheana féin! Lean ar aghaidh le calraí cothaithe.', ru: 'Ваш вес уже очень близок к цели! Можете придерживаться нормы калорий для поддержания.', ar: 'وزنك الحالي قريب جداً من هدفك! يمكنك الاستمرار بسعرات التثبيت.', zh: '您当前的体重已非常接近目标体重！可按维持期卡路里继续保持。', ja: '現在の体重は既に目標に極めて近いです！現状維持カロリーで継続できます。', ko: '현재 체중이 이미 목표 체중에 매우 근접합니다! 유지 칼로리로 지속해 보세요.',
    es: '¡Tu peso actual ya está muy cerca de tu meta! Puedes continuar con calorías de mantenimiento.', it: 'Il tuo peso è già vicinissimo all’obiettivo! Puoi proseguire con le calorie di mantenimento.', pt: 'O seu peso atual já está muito próximo da meta! Pode continuar com calorias de manutenção.', sv: 'Din nuvarande vikt är redan mycket nära ditt mål! Fortsätt med balanskalorier.', deCh: 'Dein aktuelles Gewicht ist bereits sehr nah an deinem Ziel! Du kannst mit Erhaltungskalorien fortfahren.',
  ),
  'İdeal aralığa inmek için': _m(
    en: 'To reach ideal range:', de: 'Bis zum Idealgewicht:', nl: 'Tot ideaal bereik:', fr: 'Pour atteindre la zone idéale :',
    ga: 'Chun an réimse idéalach a bhaint amach:', ru: 'До идеальной нормы:', ar: 'للوصول للنطاق المثالي:', zh: '距理想区间还需减：', ja: '適正範囲まであと：', ko: '적정 범위까지 감량 필요:',
    es: 'Para alcanzar el rango ideal:', it: 'Per raggiungere la fascia ideale:', pt: 'Para atingir a faixa ideal:', sv: 'För att nå idealintervallet:', deCh: 'Bis zum Idealgewicht:',
  ),
  'İdeal aralığa çıkmak için': _m(
    en: 'To reach ideal range:', de: 'Bis zum Idealgewicht:', nl: 'Tot ideaal bereik:', fr: 'Pour atteindre la zone idéale :',
    ga: 'Chun an réimse idéalach a bhaint amach:', ru: 'До идеальной нормы:', ar: 'للوصول للنطاق المثالي:', zh: '距理想区间还需增：', ja: '適正範囲まであと：', ko: '적정 범위까지 증량 필요:',
    es: 'Para alcanzar el rango ideal:', it: 'Per raggiungere la fascia ideale:', pt: 'Para atingir a faixa ideal:', sv: 'För att nå idealintervallet:', deCh: 'Bis zum Idealgewicht:',
  ),
  'Masa başı iş, az hareket': _m(
    en: 'Desk job, little movement', de: 'Schreibtischjob, wenig Bewegung', nl: 'Kantoorbaan, weinig beweging', fr: 'Travail sédentaire, peu d’activité',
    ga: 'Obair dheisce, beagán gluaiseachta', ru: 'Сидячая работа, мало движений', ar: 'عمل مكتبي، حركة قليلة', zh: '伏案久坐，平时缺少运动', ja: 'デスクワーク中心、活動少なめ', ko: '좌식 업무, 활동량 적음',
    es: 'Trabajo de oficina, poco movimiento', it: 'Lavoro sedentario, poco movimento', pt: 'Trabalho de escritório, pouco movimento', sv: 'Skrivbordsjobb, lite rörelse', deCh: 'Schreibtischjob, wenig Bewegung',
  ),
  'Haftada 1-3 gün egzersiz': _m(
    en: 'Exercise 1-3 days/week', de: '1-3 Tage Sport pro Woche', nl: '1-3 dagen sport per week', fr: 'Exercice 1 à 3 jours par semaine',
    ga: 'Aclaíocht 1-3 lá sa tseachtain', ru: 'Тренировки 1-3 раза в неделю', ar: 'تمارين 1-3 أيام بالأسبوع', zh: '每周轻度锻炼 1-3 天', ja: '週1〜3回の軽い運動', ko: '주 1~3일 가벼운 운동',
    es: 'Ejercicio 1-3 días por semana', it: 'Esercizio 1-3 giorni a settimana', pt: 'Exercício 1-3 dias por semana', sv: 'Träning 1-3 dagar/vecka', deCh: '1-3 Tage Sport pro Woche',
  ),
  'Haftada 3-5 gün spor': _m(
    en: 'Sports 3-5 days/week', de: '3-5 Tage Sport pro Woche', nl: '3-5 dagen sport per week', fr: 'Sport 3 à 5 jours par semaine',
    ga: 'Spórt 3-5 lá sa tseachtain', ru: 'Спорт 3-5 раз в неделю', ar: 'رياضة 3-5 أيام بالأسبوع', zh: '每周运动 3-5 天', ja: '週3〜5回の中程度運動', ko: '주 3~5일 규칙적 운동',
    es: 'Deporte 3-5 días por semana', it: 'Sport 3-5 giorni a settimana', pt: 'Desporto 3-5 dias por semana', sv: 'Träning 3-5 dagar/vecka', deCh: '3-5 Tage Sport pro Woche',
  ),
  'Haftada 6-7 gün yoğun spor': _m(
    en: 'Intense sports 6-7 days/week', de: '6-7 Tage intensiver Sport', nl: '6-7 dagen intensief sporten', fr: 'Sport intense 6 à 7 jours/sem',
    ga: 'Spórt dian 6-7 lá sa tseachtain', ru: 'Интенсивный спорт 6-7 раз в неделю', ar: 'تمارين شاقة 6-7 أيام بالأسبوع', zh: '每周高强度健身 6-7 天', ja: '週6〜7回のハードな運動', ko: '주 6~7일 고강도 트레이닝',
    es: 'Deporte intenso 6-7 días por semana', it: 'Sport intenso 6-7 giorni a settimana', pt: 'Desporto intenso 6-7 dias por semana', sv: 'Hårdträning 6-7 dagar/vecka', deCh: '6-7 Tage intensiver Sport',
  ),
  'yıl': _m(
    en: 'yrs', de: 'Jahre', nl: 'jaar', fr: 'ans',
    ga: 'bliana', ru: 'лет', ar: 'سنة', zh: '岁', ja: '歳', ko: '세',
    es: 'años', it: 'anni', pt: 'anos', sv: 'år', deCh: 'Jahre',
  ),
  'VKİ': _m(
    en: 'BMI', de: 'BMI', nl: 'BMI', fr: 'IMC',
    ga: 'BMI', ru: 'ИМТ', ar: 'BMI', zh: 'BMI', ja: 'BMI', ko: 'BMI',
    es: 'IMC', it: 'IMC', pt: 'IMC', sv: 'BMI', deCh: 'BMI',
  ),
  'Son 7 günün sabah ve akşam kiloları': _m(
    en: 'Morning & evening weights for the last 7 days', de: 'Morgen- & Abendgewichte der letzten 7 Tage', nl: 'Ochtend- en avondmetingen van de laatste 7 dagen', fr: 'Poids matin et soir des 7 derniers jours',
    ga: 'Meáchan maidine agus tráthnóna le 7 lá anuas', ru: 'Утренний и вечерний вес за последние 7 дней', ar: 'أوزان الصباح والمساء لآخر 7 أيام', zh: '最近7天的早晨与傍晚体重数据', ja: '過去7日間の朝と夜の体重記録', ko: '최근 7일간의 아침 및 저녁 체중 추이',
    es: 'Pesos de mañana y noche de los últimos 7 días', it: 'Pesi di mattina e sera degli ultimi 7 giorni', pt: 'Pesos de manhã e noite dos últimos 7 dias', sv: 'Morgon- och kvällsvikt för de senaste 7 dagarna', deCh: 'Morgen- & Abendgewichte der letzten 7 Tage',
  ),
  'Son 14 günün sabah ve akşam kiloları': _m(
    en: 'Morning & evening weights for the last 14 days', de: 'Morgen- & Abendgewichte der letzten 14 Tage', nl: 'Ochtend- en avondmetingen van de laatste 14 dagen', fr: 'Poids matin et soir des 14 derniers jours',
    ga: 'Meáchan maidine agus tráthnóna le 14 lá anuas', ru: 'Утренний и вечерний вес за последние 14 дней', ar: 'أوزان الصباح والمساء لآخر 14 يوماً', zh: '最近14天的早晨与傍晚体重数据', ja: '過去14日間の朝と夜の体重記録', ko: '최근 14일간의 아침 및 저녁 체중 추이',
    es: 'Pesos de mañana y noche de los últimos 14 días', it: 'Pesi di mattina e sera degli ultimi 14 giorni', pt: 'Pesos de manhã e noite dos últimos 14 dias', sv: 'Morgon- och kvällsvikt för de senaste 14 dagarna', deCh: 'Morgen- & Abendgewichte der letzten 14 Tage',
  ),
  'Tüm kayıtların sabah ve akşam kiloları': _m(
    en: 'Morning & evening weights across all records', de: 'Morgen- & Abendgewichte aller Einträge', nl: 'Ochtend- en avondmetingen van alle gegevens', fr: 'Poids matin et soir sur l’ensemble des pesées',
    ga: 'Meáchan maidine agus tráthnóna ar feadh gach taifid', ru: 'Утренний и вечерний вес за всё время', ar: 'أوزان الصباح والمساء لجميع السجلات', zh: '所有记录中的早晚体重完整数据', ja: '全記録の朝と夜の体重データ', ko: '전체 기간의 아침 및 저녁 체중 기록',
    es: 'Pesos de mañana y noche de todos los registros', it: 'Pesi di mattina e sera di tutte le registrazioni', pt: 'Pesos de manhã e noite de todos os registos', sv: 'Morgon- och kvällsvikt för alla mätningar', deCh: 'Morgen- & Abendgewichte aller Einträge',
  ),
  'serisi': _m(
    en: 'series', de: 'Serie', nl: 'serie', fr: 'série',
    ga: 'sraith', ru: 'серия', ar: 'سلسلة', zh: '系列', ja: '系列', ko: '계열',
    es: 'serie', it: 'serie', pt: 'série', sv: 'serie', deCh: 'Serie',
  ),
  'Son 7 günde': _m(
    en: 'In the last 7 days', de: 'In den letzten 7 Tagen', nl: 'In de laatste 7 dagen', fr: 'Sur les 7 derniers jours',
    ga: 'Le 7 lá anuas', ru: 'За последние 7 дней', ar: 'في آخر 7 أيام', zh: '在过去7天内', ja: '過去7日間で', ko: '최근 7일 동안',
    es: 'En los últimos 7 días', it: 'Negli ultimi 7 giorni', pt: 'Nos últimos 7 dias', sv: 'Under de senaste 7 dagarna', deCh: 'In den letzten 7 Tagen',
  ),
  'Son 30 günde': _m(
    en: 'In the last 30 days', de: 'In den letzten 30 Tagen', nl: 'In de laatste 30 dagen', fr: 'Sur les 30 derniers jours',
    ga: 'Le 30 lá anuas', ru: 'За последние 30 дней', ar: 'في آخر 30 يوماً', zh: '在过去30天内', ja: '過去30日間で', ko: '최근 30일 동안',
    es: 'En los últimos 30 días', it: 'Negli ultimi 30 giorni', pt: 'Nos últimos 30 dias', sv: 'Under de senaste 30 dagarna', deCh: 'In den letzten 30 Tagen',
  ),
  'Tüm zamanlarda': _m(
    en: 'All time', de: 'Über den gesamten Zeitraum', nl: 'In de gehele periode', fr: 'Sur toute la période',
    ga: 'Leis an am ar fad', ru: 'За всё время', ar: 'على مدار كامل الفترة', zh: '有记录以来', ja: '全期間を通じて', ko: '전체 기간 동안',
    es: 'En todo el tiempo', it: 'In tutto il periodo', pt: 'Em todo o período', sv: 'Under hela perioden', deCh: 'Über den gesamten Zeitraum',
  ),
  'değişim kaydedildi.': _m(
    en: 'change recorded.', de: 'Veränderung verzeichnet.', nl: 'verandering geregistreerd.', fr: 'de variation enregistrée.',
    ga: 'd’athrú taifeadta.', ru: 'изменения зафиксировано.', ar: 'تغير مسجل.', zh: '的变化已记录。', ja: 'の変動が記録されました。', ko: '변화가 기록되었습니다.',
    es: 'de cambio registrado.', it: 'di variazione registrata.', pt: 'de alteração registada.', sv: 'förändring noterad.', deCh: 'Veränderung verzeichnet.',
  ),
  'ortalama kilon': _m(
    en: 'your average weight was', de: 'betrug dein Durchschnittsgewicht', nl: 'was je gemiddelde gewicht', fr: 'votre poids moyen était de',
    ga: 'ba é do mheánmheáchan ná', ru: 'ваш средний вес составил', ar: 'كان متوسط وزنك', zh: '您的平均体重为', ja: 'の平均体重は', ko: '평균 체중은',
    es: 'tu peso promedio fue', it: 'il tuo peso medio è stato', pt: 'o seu peso médio foi de', sv: 'var din medelvikt', deCh: 'betrug dein Durchschnittsgewicht',
  ),
  'oldu.': _m(
    en: '.', de: '.', nl: '.', fr: '.',
    ga: '.', ru: '.', ar: '.', zh: '。', ja: 'でした。', ko: '이었습니다.',
    es: '.', it: '.', pt: '.', sv: '.', deCh: '.',
  ),
  'En düşük ölçüm': _m(
    en: 'Lowest logged at', de: 'Niedrigster Wert lag bei', nl: 'Laagste meting was', fr: 'Mesure la plus basse :',
    ga: 'Tomhas is ísle ag', ru: 'Мин. вес был', ar: 'أقل قياس مسجل كان', zh: '最低记录为', ja: '最低測定値は', ko: '최저 측정값은',
    es: 'La medición más baja fue', it: 'La misurazione più bassa è stata', pt: 'A medição mais baixa foi', sv: 'Lägsta mätning var', deCh: 'Niedrigster Wert lag bei',
  ),
  'en yüksek ölçüm': _m(
    en: 'highest at', de: 'Höchstwert bei', nl: 'hoogste bij', fr: 'la plus haute à',
    ga: 'is airde ag', ru: 'макс. вес был', ar: 'وأعلى قياس كان', zh: '最高记录为', ja: '最高測定値は', ko: '최고 측정값은',
    es: 'y la más alta', it: 'e la più alta', pt: 'e a mais alta', sv: 'och högsta', deCh: 'Höchstwert bei',
  ),
  'olarak kaydedildi.': _m(
    en: 'recorded.', de: 'verzeichnet.', nl: 'geregistreerd.', fr: 'enregistrés.',
    ga: 'taifeadta.', ru: 'зафиксированы.', ar: 'مسجلة.', zh: '。', ja: 'と記録されました。', ko: '으로 기록되었습니다.',
    es: 'recorded.', it: 'recorded.', pt: 'recorded.', sv: 'recorded.', deCh: 'verzeichnet.',
  ),
  'Sabah bildirimi': _m(
    en: 'Morning reminder', de: 'Morgen-Erinnerung', nl: 'Ochtendherinnering', fr: 'Rappel du matin',
    ga: 'Meabhrúchán maidine', ru: 'Утреннее напоминание', ar: 'تنبيه الصباح', zh: '早晨提醒', ja: '朝のリマインダー', ko: '아침 알림',
    es: 'Morning reminder', it: 'Morning reminder', pt: 'Morning reminder', sv: 'Morning reminder', deCh: 'Morgen-Erinnerung',
  ),
  'Akşam bildirimi': _m(
    en: 'Evening reminder', de: 'Abend-Erinnerung', nl: 'Avondherinnering', fr: 'Rappel du soir',
    ga: 'Meabhrúchán tráthnóna', ru: 'Вечернее напоминание', ar: 'تنبيه المساء', zh: '晚间提醒', ja: '夜のリマインダー', ko: '저녁 알림',
    es: 'Evening reminder', it: 'Evening reminder', pt: 'Evening reminder', sv: 'Evening reminder', deCh: 'Abend-Erinnerung',
  ),
  'Örn.': _m(
    en: 'e.g.', de: 'z. B.', nl: 'bijv.', fr: 'par ex.',
    ga: 'm.sh.', ru: 'напр.', ar: 'مثلاً', zh: '例如', ja: '例:', ko: '예:',
    es: 'ej.', it: 'es.', pt: 'ex.', sv: 't.ex.', deCh: 'z. B.',
  ),

  'Kilo hatırlatmaları': _m(
    en: 'Weight Reminders', de: 'Gewichtserinnerungen', nl: 'Gewichtsherinneringen', fr: 'Rappels de poids',
    ga: 'Meabhrúcháin Mheáchain', ru: 'Напоминания о весе', ar: 'تنبيهات الوزن', zh: '体重提醒', ja: '体重リマインダー', ko: '체중 알림',
    es: 'Recordatorios de peso', it: 'Promemoria peso', pt: 'Lembretes de peso', sv: 'Viktpåminnelser', deCh: 'Gewichtserinnerungen',
  ),
  'Günlük sabah ve akşam kilo ölçüm hatırlatmaları': _m(
    en: 'Daily morning and evening weight measurement reminders', de: 'Tägliche Erinnerungen an die Morgen- und Abend-Gewichtsmessung', nl: 'Dagelijkse herinneringen voor ochtend- en avondmeting', fr: 'Rappels quotidiens de pesée matin et soir',
    ga: 'Meabhrúcháin laethúla do mheáchain maidine agus tráthnóna', ru: 'Ежедневные утренние и вечерние напоминания о взвешивании', ar: 'تنبيهات يومية لتسجيل الوزن صباحاً ومساءً', zh: '每日早晚体重测量提醒', ja: '毎日の朝と夜の体重測定リマインダー', ko: '매일 아침 및 저녁 체중 측정 알림',
    es: 'Recordatorios diarios de pesaje por la mañana y por la noche', it: 'Promemoria giornalieri per la misurazione del peso mattina e sera', pt: 'Lembretes diários de pesagem de manhã e à noite', sv: 'Dagliga påminnelser om morgon- och kvällsvägning', deCh: 'Tägliche Erinnerungen an die Morgen- und Abend-Gewichtsmessung',
  ),
  'Günaydın! Sabah kilonu kaydetmeyi unutma.': _m(
    en: 'Good morning! Don\'t forget to log your morning weight.', de: 'Guten Morgen! Vergiss nicht, dein Morgengewicht einzutragen.', nl: 'Goedemorgen! Vergeet niet je ochtendgewicht in te vullen.', fr: 'Bonjour ! N\'oubliez pas d\'enregistrer votre poids du matin.',
    ga: 'Maidin mhaith! Ná déan dearmad do mheáchan maidine a thaifeadadh.', ru: 'Доброе утро! Не забудьte записать утренний вес.', ar: 'صباح الخير! لا تنسَ تسجيل وزنك الصباحي.', zh: '早上好！别忘了记录早晨的体重。', ja: 'おはようございます！朝の体重を記録しましょう。', ko: '좋은 아침입니다! 아침 체중 기록을 잊지 마세요.',
    es: '¡Buenos días! No olvides registrar tu peso matutino.', it: 'Buongiorno! Non dimenticare di registrare il peso del mattino.', pt: 'Bom dia! Não te esqueças de registar o teu peso matinal.', sv: 'God morgon! Glöm inte att registrera din morgonvikt.', deCh: 'Guete Morge! Vergiss nöd, dis Morgengwicht izträäge.',
  ),
  'Günaydın! Sabah kilonu ve bel ölçünü kaydetmeyi unutma.': _m(
    en: 'Good morning! Don\'t forget to log your morning weight and waist measurement.', de: 'Guten Morgen! Vergiss nicht, dein Morgengewicht und deinen Taillenumfang einzutragen.', nl: 'Goedemorgen! Vergeet niet je ochtendgewicht en tailleomvang in te vullen.', fr: 'Bonjour ! N\'oubliez pas d\'enregistrer votre poids et votre tour de taille du matin.',
    ga: 'Maidin mhaith! Ná déan dearmad do mheáchan maidine agus do thomhas coime a thaifeadadh.', ru: 'Доброе утро! Не забудьте записать утренний вес и обхват талии.', ar: 'صباح الخير! لا تنسَ تسجيل وزنك ومحيط خصرك الصباحي.', zh: '早上好！别忘了记录早晨的体重和腰围。', ja: 'おはようございます！朝の体重と腹囲を記録しましょう。', ko: '좋은 아침입니다! 아침 체중과 허리 둘레 기록을 잊지 마세요.',
    es: '¡Buenos días! No olvides registrar tu peso y tu cintura matutina.', it: 'Buongiorno! Non dimenticare di registrare il peso e la vita del mattino.', pt: 'Bom dia! Não te esqueças de registar o teu peso e cintura matinal.', sv: 'God morgon! Glöm inte att registrera din morgonvikt och midjemått.', deCh: 'Guete Morge! Vergiss nöd, dis Morgengwicht und din Taillenumfang izträäge.',
  ),
  'Akşam kilonu kaydederek günlük değişimini takip et.': _m(
    en: 'Log your evening weight to track your daily progress.', de: 'Trage dein Abendgewicht ein, um den Tagesverlauf zu verfolgen.', nl: 'Vul je avondgewicht in om je dagelijkse voortgang te volgen.', fr: 'Enregistrez votre poids du soir pour suivre l\'évolution de la journée.',
    ga: 'Taifead do mheáchan tráthnóna chun d\'athrú laethúil a leanúint.', ru: 'Запишите вечерний вес, чтобы отслеживать динамику за день.', ar: 'سجّل وزنك المسائي لمتابعة تغيرك اليومي.', zh: '记录傍晚体重以追踪全天变化。', ja: '夜の体重を記録して、1日の変化を確認しましょう。', ko: '저녁 체중을 기록하여 하루의 변화를 확인하세요.',
    es: 'Registra tu peso de la tarde para seguir tu progreso diario.', it: 'Registra il peso serale per monitorare l\'andamento giornaliero.', pt: 'Regista o teu peso da noite para acompanhar a evolução do dia.', sv: 'Registrera din kvällsvikt för att följa dagens förändring.', deCh: 'Träg dis Abedgwicht ii, zum de Tagesverlauf verfolge.',
  ),
  'Akşam kilonu ve bel ölçünü kaydederek günlük değişimini takip et.': _m(
    en: 'Log your evening weight and waist measurement to track your daily progress.', de: 'Trage dein Abendgewicht und deinen Taillenumfang ein, um den Tagesverlauf zu verfolgen.', nl: 'Vul je avondgewicht en tailleomvang in om je voortgang te volgen.', fr: 'Enregistrez votre poids et tour de taille du soir pour suivre votre progression.',
    ga: 'Taifead do mheáchan agus do thomhas coime tráthnóna chun do dhul chun cinn a leanúint.', ru: 'Запишите вечерний вес и обхват талии, чтобы отслеживать динамику дня.', ar: 'سجّل وزنك ومحيط خصرك المسائي لمتابعة تغيرك اليومي.', zh: '记录傍晚体重和腰围以追踪全天变化。', ja: '夜の体重と腹囲を記録して、1日の変化を確認しましょう。', ko: '저녁 체중과 허리 둘레를 기록하여 하루의 변화를 확인하세요.',
    es: 'Registra tu peso y cintura de la tarde para seguir tu progreso diario.', it: 'Registra il peso e la misura della vita serale per monitorare l\'andamento.', pt: 'Regista o teu peso e cintura da noite para acompanhar a evolução.', sv: 'Registrera din kvällsvikt och midjemått för att följa dagens förändring.', deCh: 'Träg dis Abedgwicht und din Taillenumfang ii, zum de Tagesverlauf verfolge.',
  ),
  'Kilo ve Bel Hatırlatmaları': _m(
    en: 'Weight & Waist Reminders', de: 'Gewichts- & Taillenerinnerungen', nl: 'Gewichts- & tailleherinneringen', fr: 'Rappels poids et tour de taille',
    ga: 'Meabhrúcháin Mheáchain & Choime', ru: 'Напоминания о весе и талии', ar: 'تنبيهات الوزن ومحيط الخصر', zh: '体重与腰围提醒', ja: '体重＆腹囲リマインダー', ko: '체중 및 허리 둘레 알림',
    es: 'Recordatorios de peso y cintura', it: 'Promemoria peso e vita', pt: 'Lembretes de peso e cintura', sv: 'Vikt- och midjepåminnelser', deCh: 'Gewichts- & Taillenerinnerungen',
  ),
  'Günlük sabah ve akşam kilo ve bel ölçümü hatırlatmaları': _m(
    en: 'Daily morning and evening weight and waist measurement reminders', de: 'Tägliche Erinnerungen an die Morgen- und Abend-Gewichts- und Taillenmessung', nl: 'Dagelijkse herinneringen voor ochtend- en avondmeting van gewicht en taille', fr: 'Rappels quotidiens de pesée et de tour de taille matin et soir',
    ga: 'Meabhrúcháin laethúla do mheáchan agus thomhas coime maidine agus tráthnóna', ru: 'Ежедневные утренние и вечерние напоминания о взвешивании и замере талии', ar: 'تنبيهات يومية لقياس الوزن ومحيط الخصر صباحاً ومساءً', zh: '每日早晚体重与腰围测量提醒', ja: '毎日の朝と夜の体重および腹囲測定リマインダー', ko: '매일 아침 및 저녁 체중 및 허리 둘레 측정 알림',
    es: 'Recordatorios diarios de peso y cintura por la mañana y por la noche', it: 'Promemoria giornalieri per la misurazione di peso e vita mattina e sera', pt: 'Lembretes diários de medição de peso e cintura de manhã e à noite', sv: 'Dagliga påminnelser om morgon- och kvällsmätning av vikt och midja', deCh: 'Tägliche Erinnerungen an die Morgen- und Abend-Gewichts- und Taillenmessung',
  ),
  'Görünüm & Tema': _m(
    en: 'Appearance & Theme', de: 'Design & Thema', nl: 'Weergave & thema', fr: 'Apparence et thème',
    ga: 'Cuma & Téama', ru: 'Оформление и тема', ar: 'المظهر والسمة', zh: '外观与主题', ja: '外観とテーマ', ko: '화면 및 테마',
    es: 'Apariencia y tema', it: 'Aspetto e tema', pt: 'Aparência e tema', sv: 'Utseende och tema', deCh: 'Design & Thema',
  ),
  'Açık, koyu veya sistem teması ile 8 uyumlu renk paletinden birini seç.': _m(
    en: 'Choose light, dark or system theme with one of 8 harmonious color palettes.',
    de: 'Wähle ein helles, dunkles oder System-Design mit 8 harmonischen Farbpaletten.',
    nl: 'Kies een licht, donker of systeemthema met 8 harmonieuze kleurenpaletten.',
    fr: 'Choisissez un thème clair, sombre ou système avec 8 palettes de couleurs harmonieuses.',
    ga: 'Roghnaigh téama geal, dorcha nó córais le 8 pailéad dathanna comhchuí.',
    ru: 'Выберите светлую, тёмную или системную тему с 8 гармоничными палитрами цветов.',
    ar: 'اختر السمة الفاتحة أو الداكنة أو سمة النظام مع 8 لوحات ألوان متناسقة.',
    zh: '选择浅色、深色或跟随系统的配色，并提供 8 种和谐色彩搭配。',
    ja: 'ライト、ダーク、またはシステムテーマと8つの調和のとれたカラーパレットを選択。',
    ko: '8가지 조화로운 색상 팔레트와 함께 라이트, 다크 또는 시스템 테마를 선택하세요.',
    es: 'Elige tema claro, oscuro o del sistema con 8 paletas de colores armoniosas.',
    it: 'Scegli il tema chiaro, scuro o di sistema con 8 armoniose palette di colori.',
    pt: 'Escolhe o tema claro, escuro ou do sistema com 8 paletas de cores harmoniosas.',
    sv: 'Välj ljust, mörkt eller systemtema med 8 harmoniska färgpaletter.',
    deCh: 'Wähl es hells, dunkels oder System-Design mit 8 harmonische Farbpalette.',
  ),
  'Bel Ölçüsü (cm - opsiyonel)': _m(
    en: 'Waist Measurement (cm - optional)', de: 'Taillenumfang (cm - optional)', nl: 'Tailleomvang (cm - optioneel)', fr: 'Tour de taille (cm - facultatif)',
    ga: 'Tomhas Coime (cm - roghnach)', ru: 'Обхват талии (см - необязательно)', ar: 'محيط الخصر (سم - اختياري)', zh: '腰围 (cm - 可选)', ja: '腹囲 (cm - 任意)', ko: '허리 둘레 (cm - 선택)',
    es: 'Medida de cintura (cm - opcional)', it: 'Circonferenza vita (cm - facoltativo)', pt: 'Medida da cintura (cm - opcional)', sv: 'Midjemått (cm - valfritt)', deCh: 'Taillenumfang (cm - optional)',
  ),
  'Bel ölçüsü için 15 ile 250 cm arasında geçerli bir değer girin.': _m(
    en: 'Enter a valid waist measurement between 15 and 250 cm.', de: 'Gib einen gültigen Taillenumfang zwischen 15 und 250 cm ein.', nl: 'Voer een geldige tailleomvang in tussen 15 en 250 cm.', fr: 'Entrez un tour de taille valide entre 15 et 250 cm.',
    ga: 'Iontráil tomhas coime bailí idir 15 agus 250 cm.', ru: 'Введите корректный обхват талии от 15 до 250 см.', ar: 'أدخل قياس خصر صالحاً بين 15 و 250 سم.', zh: '请输入 15 至 250 cm 之间的有效腰围。', ja: '15〜250cmの有効な腹囲を入力してください。', ko: '15에서 250cm 사이의 유효한 허리 둘레를 입력하세요.',
    es: 'Introduce una medida de cintura válida entre 15 y 250 cm.', it: 'Inserisci una misura della vita valida tra 15 e 250 cm.', pt: 'Introduz uma medida de cintura válida entre 15 e 250 cm.', sv: 'Ange ett giltigt midjemått mellan 15 och 250 cm.', deCh: 'Gib en gültige Taillenumfang zwüsche 15 und 250 cm ii.',
  ),
  'Günün Bel Ölçüsü': _m(
    en: 'Today\'s Waist Measurement', de: 'Heutiger Taillenumfang', nl: 'Tailleomvang van vandaag', fr: 'Tour de taille du jour',
    ga: 'Tomhas Coime an Lae Inniu', ru: 'Обхват талии за сегодня', ar: 'محيط الخصر لليوم', zh: '今日腰围', ja: '今日の腹囲', ko: '오늘의 허리 둘레',
    es: 'Cintura de hoy', it: 'Misura vita di oggi', pt: 'Medida da cintura de hoje', sv: 'Dagens midjemått', deCh: 'Hütige Taillenumfang',
  ),
  'Ertelendi': _m(
    en: 'Snoozed', de: 'Verschoben', nl: 'Uitgesteld', fr: 'Reporté',
    ga: 'Curtha siar', ru: 'Отложено', ar: 'مؤجل', zh: '已推迟', ja: 'スヌーズ中', ko: '연기됨',
    es: 'Pospuesto', it: 'Posticipato', pt: 'Adiado', sv: 'Snoozad', deCh: 'Verschobe',
  ),
  'Son Kiloyu Kaydet': _m(
    en: 'Quick Log Last Weight', de: 'Letztes Gewicht speichern', nl: 'Laatste gewicht opslaan', fr: 'Enregistrer dernier poids',
    ga: 'Sábháil an Meáchan Deireanach', ru: 'Сохранить последний вес', ar: 'حفظ آخر وزن', zh: '快速记录上次体重', ja: '前回の体重を保存', ko: '최근 체중 저장',
    es: 'Guardar último peso', it: 'Salva ultimo peso', pt: 'Guardar último peso', sv: 'Spara senaste vikt', deCh: 'Letztes Gewicht speichern',
  ),
  '1 Saat Ertele': _m(
    en: 'Snooze 1 Hour', de: '1 Std. verschieben', nl: '1 uur uitstellen', fr: 'Reporter d\'1 heure',
    ga: 'Cuir Siar Uair Amháin', ru: 'Отложить на 1 час', ar: 'تأجيل ساعة واحدة', zh: '推迟 1 小时', ja: '1時間スヌーズ', ko: '1시간 연기',
    es: 'Posponer 1 hora', it: 'Posticipa di 1 ora', pt: 'Adiar 1 hora', sv: 'Snooza 1 timme', deCh: '1 Std. verschiebe',
  ),
  'Mavi & Koyu Lacivert Tonları': _m(
    en: 'Blue & Deep Navy Tones', de: 'Blau- & Dunkelblau-Töne', nl: 'Blauw- & marineblauwtinten', fr: 'Nuances de bleu et bleu marine',
    ga: 'Foinn Ghorma & Dúghorma', ru: 'Синие и тёмно-синие тона', ar: 'درجات الأزرق والكحلي الداكن', zh: '海蓝与深海军蓝', ja: 'ブルー＆ディープネイビー調', ko: '블루 & 딥 네이비 톤',
    es: 'Tonos azul y azul marino oscuro', it: 'Tonalità blu e blu notte', pt: 'Tons de azul e azul-escuro', sv: 'Blåa och marinblå toner', deCh: 'Blau- & Dunkelblau-Tön',
  ),
  'Canlı Zümrüt & Nane Yeşili': _m(
    en: 'Vibrant Emerald & Mint Green', de: 'Lebendiges Smaragd- & Minzgrün', nl: 'Levendig smaragd & muntgroen', fr: 'Émeraude vif et vert menthe',
    ga: 'Smáraig Bheo & Glas Miontais', ru: 'Яркий изумрудный и мятный', ar: 'زمردي نابض وأخضر نعناعي', zh: '明亮翡翠绿与薄荷绿', ja: '鮮やかなエメラルド＆ミントグリーン', ko: '선명한 에메랄드 & 민트 그린',
    es: 'Esmeralda vibrante y verde menta', it: 'Smeraldo vivace e verde menta', pt: 'Esmeralda vibrante e verde-menta', sv: 'Livfull smaragd & mintgrön', deCh: 'Läbigs Smaragd- & Minzgrüen',
  ),
  'Lacivert & Gece Mavisi': _m(
    en: 'Navy & Midnight Blue', de: 'Marineblau & Nachtblau', nl: 'Marineblauw & nachtblauw', fr: 'Bleu marine et bleu nuit',
    ga: 'Dúghorm & Gorm Oíche', ru: 'Тёмно-синий и ночной сапфир', ar: 'كحلي داكن وأزرق ليلي', zh: '深海军蓝与午夜蓝', ja: 'ネイビー＆ミッドナイトブルー', ko: '네이비 & 미드나잇 블루',
    es: 'Azul marino y azul noche', it: 'Blu notte e blu navy', pt: 'Azul-marinho e azul-noite', sv: 'Marinblå & midnattsblå', deCh: 'Marineblau & Nachtblau',
  ),
  'Asil Koyu Mavi & Lacivert Tonları': _m(
    en: 'Classic Dark Blue & Navy Tones', de: 'Elegante Dunkelblau- & Marinetöne', nl: 'Klassiek donkerblauw & marine', fr: 'Nuances classiques de bleu foncé et marine',
    ga: 'Foinn Dúghorma Chlasaiceacha', ru: 'Классический тёмно-синий и лазурный', ar: 'درجات كحلي وأزرق داكن كلاسيكية', zh: '典雅深蓝与海军蓝', ja: '深みのあるダークブルー＆ネイビー', ko: '클래식 다크 블루 & 네이비',
    es: 'Tonos elegantes de azul oscuro y marino', it: 'Tonalità classiche di blu scuro e navy', pt: 'Tons clássicos de azul-escuro e marinho', sv: 'Klassiska mörkblå & marinblå toner', deCh: 'Eleganti Dunkelblau- & Marinetön',
  ),
  'Orman Yeşili': _m(
    en: 'Forest Green', de: 'Waldgrün', nl: 'Bosgroen', fr: 'Vert Forêt',
    ga: 'Glas Foraoise', ru: 'Лесной зелёный', ar: 'أخضر الغابة', zh: '森林绿', ja: 'フォレストグリーン', ko: '포레스트 그린',
    es: 'Verde Bosque', it: 'Verde Foresta', pt: 'Verde Floresta', sv: 'Skogsgrön', deCh: 'Waldgrüen',
  ),
  'Doğal Yaprak & Botanik Yeşil': _m(
    en: 'Natural Leaf & Botanical Green', de: 'Natürliches Blatt- & Botanikgrün', nl: 'Natuurlijk blad- & botanisch groen', fr: 'Feuille naturelle et vert botanique',
    ga: 'Duilleog Nádúrtha & Glas Luibheolaíoch', ru: 'Природная листва и ботанический зелёный', ar: 'أخضر نباتي وأوراق طبيعية', zh: '自然叶绿与植物青', ja: 'ナチュラルリーフ＆ボタニカルグリーン', ko: '내추럴 리프 & 보태니컬 그린',
    es: 'Hoja natural y verde botánico', it: 'Foglia naturale e verde botanico', pt: 'Folha natural e verde botânico', sv: 'Naturlig bladgrön & botanisk grön', deCh: 'Natürlechs Blatt- & Botanikgrüen',
  ),
  'Enerjik Turuncu': _m(
    en: 'Energetic Orange', de: 'Energetisches Orange', nl: 'Energiek oranje', fr: 'Orange Énergique',
    ga: 'Oráiste Fuinniúil', ru: 'Энергичный оранжевый', ar: 'برتقالي حيوي', zh: '活力橙', ja: 'エネルギッシュオレンジ', ko: '에너제틱 오렌지',
    es: 'Naranja Enérgico', it: 'Arancione Energetico', pt: 'Laranja Energético', sv: 'Energisk orange', deCh: 'Energetischs Orange',
  ),
  'Dinamik Turuncu & Kehribar Tonları': _m(
    en: 'Dynamic Orange & Amber Tones', de: 'Dynamische Orange- & Bernsteintöne', nl: 'Dynamisch oranje & amber', fr: 'Nuances dynamiques orange et ambre',
    ga: 'Foinn Oráiste Dhinimiciúil & Ómra', ru: 'Динамичный оранжевый и янтарный', ar: 'درجات برتقالي وعنبري ديناميكية', zh: '动感橙色与琥珀色调', ja: 'ダイナミックオレンジ＆アンバー調', ko: '다이내믹 오렌지 & 앰버 톤',
    es: 'Tonos dinámicos naranja y ámbar', it: 'Tonalità dinamiche di arancione e ambra', pt: 'Tons dinâmicos de laranja e âmbar', sv: 'Dynamisk orange & bärnstenstoner', deCh: 'Dynamischi Orange- & Bärnsteintön',
  ),
  'Minimalist Antrasit & Çelik Gri': _m(
    en: 'Minimalist Anthracite & Steel Gray', de: 'Minimalistisches Anthrazit & Stahlgrau', nl: 'Minimalistisch antraciet & staalgrijs', fr: 'Anthracite minimaliste et gris acier',
    ga: 'Antraicít Íosta & Liath Cruach', ru: 'Минималистичный антрацит и стальной серый', ar: 'رمادي أنثراسيت وحديدي بسيط', zh: '极简烟灰与钢铁灰', ja: 'ミニマルなアンスラサイト＆スチールグレー', ko: '미니멀 앤트러사이트 & 스틸 그레이',
    es: 'Antracita minimalista y gris acero', it: 'Antracite minimalista e grigio acciaio', pt: 'Antracite minimalista e cinzento-aço', sv: 'Minimalistisk antracit & stålgrå', deCh: 'Minimalistischs Anthrazit & Stahlgrau',
  ),
  'Ferah Turkuaz & Deniz Mavisi': _m(
    en: 'Fresh Turquoise & Sea Blue', de: 'Frisches Türkis & Meeresblau', nl: 'Fris turquoise & zeeblauw', fr: 'Turquoise frais et bleu marine',
    ga: 'Turcaid Úr & Gorm na Farraige', ru: 'Свежая бирюза и морской синий', ar: 'تركواز منعش وأزرق بحري', zh: '清爽绿松石与海水蓝', ja: '爽やかなターコイズ＆シーブルー', ko: '프레시 터콰이즈 & 씨 블루',
    es: 'Turquesa fresca y azul marino', it: 'Turchese fresco e blu mare', pt: 'Turquesa fresca e azul-marinho', sv: 'Fräsch turkos & havsblå', deCh: 'Frisches Türkis & Meeresblau',
  ),
  'Bakır & Antrasit': _m(
    en: 'Copper & Anthracite', de: 'Kupfer & Anthrazit', nl: 'Koper & antraciet', fr: 'Cuivre et Anthracite',
    ga: 'Copar & Antraicít', ru: 'Медь и антрацит', ar: 'نحاسي وأنثراسيت', zh: '琥珀铜与烟灰', ja: 'カッパー＆アンスラサイト', ko: '코퍼 & 앤트러사이트',
    es: 'Cobre y Antracita', it: 'Rame e Antracite', pt: 'Cobre e Antracite', sv: 'Koppar & antracit', deCh: 'Chupfer & Anthrazit',
  ),
  'Sıcak Bakır Turuncu & Koyu Antrasit': _m(
    en: 'Warm Copper Orange & Dark Anthracite', de: 'Warmes Kupferorange & Dunkelanthrazit', nl: 'Warm koperoranje & donkerantraciet', fr: 'Orange cuivré chaud et anthracite foncé',
    ga: 'Oráiste Te Copair & Dú-antraicít', ru: 'Тёплый медный оранжевый и тёмный антрацит', ar: 'نحاسي برتقالي دافئ وأنثراسيت داكن', zh: '温暖铜橙与深烟煤灰', ja: '温かみのあるカッパーオレンジ＆ダークアンスラサイト', ko: '웜 코퍼 오렌지 & 다크 앤트러사이트',
    es: 'Naranja cobre cálido y antracita oscuro', it: 'Arancione rame caldo e antracite scuro', pt: 'Laranja-cobre quente e antracite escuro', sv: 'Varm kopparorange & mörk antracit', deCh: 'Warmes Chupferorange & Dunkelanthrazit',
  ),
  'Aktif': _m(
    en: 'Active', de: 'Aktiv', nl: 'Actief', fr: 'Actif',
    ga: 'Gníomhach', ru: 'Активно', ar: 'نشط', zh: '已启用', ja: '適用中', ko: '적용 중',
    es: 'Activo', it: 'Attivo', pt: 'Ativo', sv: 'Aktiv', deCh: 'Aktiv',
  ),
  'Değiştir': _m(
    en: 'Change', de: 'Ändern', nl: 'Wijzigen', fr: 'Modifier',
    ga: 'Athraigh', ru: 'Изменить', ar: 'تغيير', zh: '更改', ja: '変更', ko: '변경',
    es: 'Cambiar', it: 'Modifica', pt: 'Alterar', sv: 'Ändra', deCh: 'Ändere',
  ),

  'Okyanus & Altın Sarısı': _m(
    en: 'Ocean Blue & Golden Amber', de: 'Ozeanblau & Goldener Bernstein', nl: 'Oceaanblauw & goudamber', fr: 'Bleu Océan & Ambre Doré',
    ga: 'Gorm an Aigéin & Ómra Órga', ru: 'Океанский синий и золотой янтарь', ar: 'أزرق المحيط والعنبر الذهبي', zh: '海洋蓝与金琥珀', ja: 'オーシャンブルー＆ゴールデンアンバー', ko: '오션 블루 & 골든 앰버',
    es: 'Azul Océano y Ámbar Dorado', it: 'Blu Oceano e Ambra Dorata', pt: 'Azul Oceano e Âmbar Dourado', sv: 'Oceanblå & gyllene bärnsten', deCh: 'Ozeanblau & Goldige Bärnstei',
  ),
  'Mavi & Sıcak Kehribar Uyumu': _m(
    en: 'Blue & Warm Amber Harmony', de: 'Harmonie aus Blau & warmem Bernstein', nl: 'Blauw & warme amber harmonie', fr: 'Harmonie Bleu et Ambre Chaud',
    ga: 'Comhchuibheas Gorm & Ómra Te', ru: 'Гармония синего и тёплого янтаря', ar: 'تناغم الأزرق والعنبر الدافئ', zh: '深蓝与暖琥珀和谐搭配', ja: 'ブルー＆ウォームアンバーの調和', ko: '블루 & 웜 앰버 하모니',
    es: 'Armonía de azul y ámbar cálido', it: 'Armonia di blu e ambra calda', pt: 'Harmonia de azul e âmbar quente', sv: 'Harmoni av blått & varm bärnsten', deCh: 'Harmonii vo Blau & warmem Bärnstei',
  ),
  'Zümrüt & Güneş Sarısı': _m(
    en: 'Emerald & Sunny Gold', de: 'Smaragd & Sonnengold', nl: 'Smaragd & zonnegoud', fr: 'Émeraude & Jaune Solaire',
    ga: 'Smáraig & Ór na Gréine', ru: 'Изумруд и солнечное золото', ar: 'زمرد وأصفر شمسي', zh: '翡翠绿与日光金', ja: 'エメラルド＆サニーゴールド', ko: '에메랄드 & 써니 골드',
    es: 'Esmeralda y Oro Solar', it: 'Smeraldo e Oro Solare', pt: 'Esmeralda e Ouro Solar', sv: 'Smaragd & solgult', deCh: 'Smaragd & Sunnegold',
  ),
  'Zümrüt Yeşili & Canlı Altın Uyumu': _m(
    en: 'Emerald Green & Vibrant Gold Harmony', de: 'Harmonie aus Smaragdgrün & Gold', nl: 'Smaragdgroen & levendig goud', fr: 'Harmonie Vert Émeraude et Or Vif',
    ga: 'Comhchuibheas Smáraige & Óir Bheo', ru: 'Гармония изумрудного и яркого золота', ar: 'تناغم الزمرد الأخضر والذهب النابض', zh: '翡翠绿与明亮金和谐搭配', ja: 'エメラルドグリーン＆鮮やかゴールドの調和', ko: '에메랄드 그린 & 생생한 골드 하모니',
    es: 'Armonía de verde esmeralda y oro vibrante', it: 'Armonia di verde smeraldo e oro vivido', pt: 'Harmonia de verde-esmeralda e ouro vibrante', sv: 'Harmoni av smaragdgrönt & guld', deCh: 'Harmonii vo Smaragdgrüen & Gold',
  ),
  'Ateş Kırmızısı & Lacivert': _m(
    en: 'Crimson Red & Deep Navy', de: 'Karmesinrot & Marineblau', nl: 'Karmozijnrood & marineblauw', fr: 'Rouge Cramoisi & Bleu Marine',
    ga: 'Dearg Lasrach & Dúghorm', ru: 'Пламенный красный и лазурный индиго', ar: 'أحمر قرمزي وكحلي داكن', zh: '火红与深海军蓝', ja: 'クリムゾンレッド＆ディープネイビー', ko: '크림슨 레드 & 딥 네이비',
    es: 'Rojo Carmesí y Azul Marino', it: 'Rosso Cremisi e Blu Navy', pt: 'Vermelho Carmesim e Azul-Marinho', sv: 'Karmosinröd & marinblå', deCh: 'Charmesinrot & Marineblau',
  ),
  'Dinamik Kırmızı & Koyu Mavi Uyumu': _m(
    en: 'Dynamic Red & Dark Blue Harmony', de: 'Dynamische Harmonie aus Rot & Dunkelblau', nl: 'Dynamisch rood & donkerblauw', fr: 'Harmonie Rouge Dynamique et Bleu Foncé',
    ga: 'Comhchuibheas Dearg & Dúghorm Dinimiciúil', ru: 'Динамичный контраст красного и тёмно-синего', ar: 'تناغم ديناميكي بين الأحمر والأزرق الداكن', zh: '动感红与沉稳深蓝对比', ja: 'ダイナミックレッド＆ダークブルーの調和', ko: '다이내믹 레드 & 다크 블루 하모니',
    es: 'Armonía dinámica de rojo y azul oscuro', it: 'Armonia dinamica di rosso e blu scuro', pt: 'Harmonia dinâmica de vermelho e azul-escuro', sv: 'Dynamisk harmoni av rött & mörkblått', deCh: 'Dynamischi Harmonii vo Rot & Dunkelblau',
  ),
  'Koyu Lacivert & Nane Yeşili': _m(
    en: 'Deep Navy & Mint Green', de: 'Dunkelmarine & Minzgrün', nl: 'Donkermarine & muntgroen', fr: 'Bleu Marine Profond & Vert Menthe',
    ga: 'Dúghorm & Glas Miontais', ru: 'Тёмный индиго и мятный зелёный', ar: 'كحلي داكن وأخضر نعناعي', zh: '深海军蓝与清新薄荷', ja: 'ディープネイビー＆ミントグリーン', ko: '딥 네이비 & 민트 그린',
    es: 'Azul Marino Profundo y Verde Menta', it: 'Blu Notte e Verde Menta', pt: 'Azul-Marinho Profundo e Verde-Menta', sv: 'Mörk marinblå & mintgrön', deCh: 'Dunkelmarine & Minzgrüen',
  ),
  'Asil Lacivert & Ferah Yeşil Uyumu': _m(
    en: 'Classic Navy & Fresh Green Harmony', de: 'Klassische Marine & Frisches Grün', nl: 'Klassiek marine & fris groen', fr: 'Harmonie Marine Classique et Vert Frais',
    ga: 'Comhchuibheas Dúghorm & Glas Úr', ru: 'Благородный синий и свежая мята', ar: 'تناغم الكحلي الكلاسيكي والأخضر المنعش', zh: '经典海军蓝与清爽绿意', ja: 'クラシックネイビー＆フレッシュグリーンの調和', ko: '클래식 네이비 & 산뜻한 그린 하모니',
    es: 'Armonía de azul marino clásico y verde fresco', it: 'Armonia di navy classico e verde fresco', pt: 'Harmonia de marinho clássico e verde fresco', sv: 'Harmoni av klassisk marinblå & fräsch grön', deCh: 'Klassischi Marine & Frisches Grüen',
  ),
  'Kehribar Sarısı & Gece Mavisi': _m(
    en: 'Amber Yellow & Midnight Blue', de: 'Bernsteingelb & Nachtblau', nl: 'Ambergeel & nachtblauw', fr: 'Jaune Ambre & Bleu Nuit',
    ga: 'Buí Ómra & Gorm Oíche', ru: 'Янтарно-жёлтый и ночной синий', ar: 'أصفر عنبري وأزرق ليلي', zh: '琥珀金黄与夜空蓝', ja: 'アンバーイエロー＆ミッドナイトブルー', ko: '앰버 옐로우 & 미드나잇 블루',
    es: 'Amarillo Ámbar y Azul Noche', it: 'Giallo Ambra e Blu Notte', pt: 'Amarelo-Âmbar e Azul-Noite', sv: 'Bärnstensgul & midnattsblå', deCh: 'Bärnsteingääl & Nachtblau',
  ),
  'Sıcak Sarı & Derin Mavi Uyumu': _m(
    en: 'Warm Yellow & Deep Blue Harmony', de: 'Harmonie aus warmem Gelb & Tiefblau', nl: 'Warm geel & diepblauw', fr: 'Harmonie Jaune Chaud et Bleu Profond',
    ga: 'Comhchuibheas Buí Te & Dúghorm', ru: 'Тёплый жёлтый свет на глубоком синем', ar: 'تناغم الأصفر الدافئ والأزرق العميق', zh: '温暖黄与深邃蓝辉映', ja: 'ウォームイエロー＆ディープブルーの調和', ko: '따뜻한 옐로우 & 딥 블루의 조화',
    es: 'Armonía de amarillo cálido y azul profundo', it: 'Armonia di giallo caldo e blu profondo', pt: 'Harmonia de amarelo quente e azul profundo', sv: 'Harmoni av varmgult & djupblått', deCh: 'Harmonii vo warmem Gääl & Tüüfblau',
  ),
  'Mercan & Turkuaz': _m(
    en: 'Coral Red & Turquoise', de: 'Korallenrot & Türkis', nl: 'Koraalrood & turquoise', fr: 'Rouge Corail & Turquoise',
    ga: 'Dearg Coiréil & Turcaid', ru: 'Коралловый красный и бирюза', ar: 'أحمر مرجاني وتركواز', zh: '珊瑚红与绿松石', ja: 'コーラルレッド＆ターコイズ', ko: '코랄 레드 & 터콰이즈',
    es: 'Rojo Coral y Turquesa', it: 'Rosso Corallo e Turchese', pt: 'Vermelho-Coral e Turquesa', sv: 'Korallröd & turkos', deCh: 'Korallerot & Türkis',
  ),
  'Sıcak Mercan Kırmızısı & Deniz Mavisi Uyumu': _m(
    en: 'Warm Coral Red & Sea Blue Harmony', de: 'Harmonie aus Korallenrot & Meeresblau', nl: 'Warm koraalrood & zeeblauw', fr: 'Harmonie Rouge Corail et Bleu Océan',
    ga: 'Comhchuibheas Dearg Coiréil & Gorm Farraige', ru: 'Тёплый коралл и морская волна', ar: 'تناغم المرجان الدافئ وأزرق البحر', zh: '暖调珊瑚红与海水蓝互补', ja: 'ウォームコーラル＆シーブルーの調和', ko: '웜 코랄 레드 & 씨 블루의 보색 조화',
    es: 'Armonía de rojo coral cálido y azul marino', it: 'Armonia di rosso corallo caldo e blu mare', pt: 'Harmonia de vermelho-coral quente e azul-marinho', sv: 'Harmoni av varm korallröd & havsblå', deCh: 'Harmonii vo Korallerot & Meeresblau',
  ),
  'Orman Yeşili & Kehribar': _m(
    en: 'Forest Green & Amber Gold', de: 'Waldgrün & Bernstein', nl: 'Bosgroen & amber', fr: 'Vert Forêt & Ambre',
    ga: 'Glas Foraoise & Ómra', ru: 'Лесной зелёный и янтарное золото', ar: 'أخضر الغابة والعنبر', zh: '森林绿与琥珀金', ja: 'フォレストグリーン＆アンバー', ko: '포레스트 그린 & 앰버 골드',
    es: 'Verde Bosque y Ámbar', it: 'Verde Foresta e Ambra', pt: 'Verde Floresta e Âmbar', sv: 'Skogsgrön & bärnsten', deCh: 'Waldgrüen & Bärnstei',
  ),
  'Doğal Yeşil & Sıcak Sarı Uyumu': _m(
    en: 'Natural Green & Warm Yellow Harmony', de: 'Natürliches Grün & Warmes Gelb', nl: 'Natuurlijk groen & warm geel', fr: 'Harmonie Vert Naturel et Jaune Chaud',
    ga: 'Comhchuibheas Glas Nádúrtha & Buí Te', ru: 'Природная зелень и тёплые солнечные лучи', ar: 'تناغم الأخضر الطبيعي والأصفر الدافئ', zh: '自然植绿与温暖明黄', ja: 'ナチュラルグリーン＆ウォームイエローの調和', ko: '자연스러운 그린 & 따뜻한 옐로우의 조화',
    es: 'Armonía de verde natural y amarillo cálido', it: 'Armonia di verde naturale e giallo caldo', pt: 'Harmonia de verde natural e amarelo quente', sv: 'Harmoni av naturligt grönt & varmgult', deCh: 'Natürlechs Grüen & Warmes Gääl',
  ),
  'Antrasit & Çelik Mavi': _m(
    en: 'Anthracite & Steel Blue', de: 'Anthrazit & Stahlblau', nl: 'Antraciet & staalblauw', fr: 'Anthracite & Bleu Acier',
    ga: 'Antraicít & Gorm Cruach', ru: 'Антрацит и стальной синий', ar: 'أنثراسيت وأزرق حديدي', zh: '烟煤灰与钢青蓝', ja: 'アンスラサイト＆スチールブルー', ko: '앤트러사이트 & 스틸 블루',
    es: 'Antracita y Azul Acero', it: 'Antracite e Blu Acciaio', pt: 'Antracite e Azul-Aço', sv: 'Antracit & stålblå', deCh: 'Anthrazit & Stahlblau',
  ),
  'Koyu Grafit & Canlı Mavi Uyumu': _m(
    en: 'Dark Graphite & Vivid Blue Harmony', de: 'Harmonie aus dunklem Graphit & leuchtendem Blau', nl: 'Donker grafiet & levendig blauw', fr: 'Harmonie Graphite Foncé et Bleu Vif',
    ga: 'Comhchuibheas Graifíte & Gorm Bheo', ru: 'Тёмный графит с акцентом яркого синего', ar: 'تناغم الجرافيت الداكن مع لمسة زرقاء ساطعة', zh: '沉稳石墨与明朗天蓝相得益彰', ja: 'ダークグラファイト＆鮮やかブルーの調和', ko: '다크 그래파이트 & 비비드 블루의 미니멀 조화',
    es: 'Armonía de grafito oscuro y azul brillante', it: 'Armonia di grafite scura e blu vivido', pt: 'Harmonia de grafite escuro e azul vivo', sv: 'Harmoni av mörk grafit & klarblått', deCh: 'Dunkels Graphit & Lüchtends Blau',
  ),
};
