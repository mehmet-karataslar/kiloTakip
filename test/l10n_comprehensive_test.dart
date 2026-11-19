import 'package:flutter_test/flutter_test.dart';
import 'package:kilo_takip/l10n/app_localizations.dart';

void main() {
  test('Verify all 16 languages translate key strings without staying in Turkish', () {
    final samplePhrases = [
      'Kaydet',
      'İptal',
      'Vazgeç',
      'Sil',
      'Düzenle',
      'Kilo Ekle',
      'Son Kiloyu Kaydet',
      'Sabah: Son Kiloyu Kaydet (85.0 kg)',
      '1 Saat Sonra Hatırlat',
      '1 Saat Ertele',
      'Kilo hatırlatmaları',
      'Günlük sabah ve akşam kilo ölçüm hatırlatmaları',
      'Günaydın! Sabah kilonu kaydetmeyi unutma.',
      'Akşam kilonu kaydederek günlük değişimini takip et.',
      '1 saat önce ertelediğin sabah kilonu şimdi kaydedebilirsin.',
      'Sabah Kilo Hatırlatması (09:00)',
      'Sabah Kilo Hatırlatması (Ertelendi)',
      'Son 7 günde sabah ölçümlerine göre -0.5 kg değişim kaydedildi.',
      'Bugünkü Takibin',
      'Hangi ölçüm silinsin?',
      'Kilo Koruma Bandı',
      'Kilo Koruma Bandındasın (77.0 – 79.0 kg)',
      '18.5 – 24.9 VKİ',
      'Örn. 85.0',
      'Sabah bildirimi her gün saat 09:00 için aktif edildi.',
      'Sabah bildirimi kapatıldı.',
      'Sabah kilosu (85.0 kg) hızlıca kaydedildi.',
      'Sabah hatırlatması 1 saat sonrasına ertelendi.',
      'Excel dosyası (kilo_takip.xlsx) kaydedildi.',
      'Haftada ortalama 0.5 kg sağlıklı değişim hızıyla yaklaşık 14 haftada (15 Şubat 2026) hedefe ulaşabilirsin.',
      'Son 7 günde -0.5 kg değişim kaydedildi.',
      'Son 7 günde ortalama kilon 85.0 kg oldu.',
      'En düşük ölçüm 84.5 kg, en yüksek ölçüm 86.0 kg olarak kaydedildi.',
      '🏋️ Spor Günü',
      '7 Günlük Seri • Rekor: 12 gün',
      '3 Bardak (0.75 L / Hedef 2.5 L)',
    ];

    for (final lang in AppLanguage.values) {
      if (lang == AppLanguage.tr) continue;
      for (final phrase in samplePhrases) {
        final translated = trText(phrase, lang);
        expect(
          translated != phrase,
          true,
          reason: 'Language ${lang.name} failed to translate: "$phrase" -> got "$translated"',
        );
      }
    }
  });
}
