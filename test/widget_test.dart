import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kilo_takip/data/weight_repository.dart';
import 'package:kilo_takip/domain/measurements.dart';
import 'package:kilo_takip/main.dart';
import 'package:kilo_takip/services/reminders.dart';
import 'package:kilo_takip/state/weight_store.dart';

class MemoryWeights implements WeightRepository {
  final entries = <Measurement>[];
  @override
  Future<List<Measurement>> readAll() async => entries;

  @override
  Future<void> save(Measurement value, {Measurement? original}) async {
    if (entries.any(
      (m) => m != original && m.day == value.day && m.slot == value.slot,
    )) {
      throw DuplicateMeasurement();
    }
    entries.remove(original);
    entries.add(value);
  }

  @override
  Future<void> delete(Measurement value) async => entries.removeWhere(
    (m) => m.day == value.day && m.slot == value.slot,
  );
}

void main() {
  testWidgets(
    '6 ekranın tamamı: Sabah/akşam kayıt, günlük fark, grafikler, geçmiş, raporlar ve ayarlar',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final repository = MemoryWeights();
      final store = WeightStore(repository);
      final settings = AppSettings();
      await tester.pumpWidget(
        KiloTakip(
          store: store,
          settings: settings,
          reminders: Reminders(),
          useNotifications: false,
        ),
      );
      await tester.pumpAndSettle();

      Future<void> tapText(String text) async {
        final target = find.text(text).first;
        try {
          await tester.scrollUntilVisible(target, 50.0);
        } catch (_) {}
        await tester.ensureVisible(target);
        await tester.tap(target);
        await tester.pumpAndSettle();
      }

      Future<void> enterWeight(String value, {String? note}) async {
        await tester.enterText(
          find.byKey(const Key('weight_input_field')),
          value,
        );
        if (note != null) {
          await tester.enterText(
            find.byKey(const Key('note_input_field')),
            note,
          );
        }
        await tapText('Kaydet');
      }

      // 1. Hiç kayıt yokken boş durum ve sahte fark gösterilmemesi
      expect(find.text('Sabah kilosu eklenmedi.'), findsOneWidget);
      expect(find.text('Akşam kilosu eklenmedi.'), findsOneWidget);
      expect(find.text('Henüz hesaplanamadı.'), findsOneWidget);

      // 2. Sabah kilo kaydı ekleme (geçersiz değer doğrulaması + virgüllü giriş + not)
      await tapText('Sabah Kilosu');
      expect(find.text('Kilo Kaydet'), findsOneWidget);
      expect(find.text('Saat'), findsOneWidget);
      await enterWeight('-4');
      expect(find.textContaining('2 ile 500'), findsOneWidget);
      await enterWeight('136,6', note: 'Sabah aç karnına');
      expect(repository.entries.single.kg, 136.6);
      expect(repository.entries.single.cleanNote, 'Sabah aç karnına');

      await tester.drag(find.byType(Scrollable).first, const Offset(0, 500));
      await tester.pumpAndSettle();

      // Yalnızca sabah kaydı varken günlük fark hâlâ hesaplanamaz
      expect(find.text('Henüz hesaplanamadı.'), findsOneWidget);

      // 3. Sabah kartından (veya düzenleden) paneli açıp panel içinde "Akşam" sekmesine geçerek
      // akşam kilosunu girdiğimizde sabah verisi silinmez, her iki veri bağımsız olarak yerleşir!
      await tapText('Sabah Kilosu');
      await tapText('Akşam');
      await enterWeight('136.1', note: 'Yürüyüş sonrası');
      expect(repository.entries, hasLength(2));
      expect(store.stats.days.values.single.morning?.kg, 136.6);
      expect(store.stats.days.values.single.evening?.kg, 136.1);
      expect(store.stats.days.values.single.difference, -0.5);
      expect(find.text('-0.5 kg'), findsWidgets);

      // 4. Grafikler ekranını ve filtrelerini kontrol et
      await tapText('Grafikler');
      expect(find.text('Kilo Değişim Grafiği'), findsOneWidget);
      expect(find.text('Sabah - Akşam Karşılaştırması'), findsOneWidget);
      await tapText('14 Gün');
      await tapText('Aylık');
      await tapText('Tüm Zamanlar');
      await tapText('Sabah');
      await tapText('Akşam');
      await tapText('Karşılaştır');
      expect(tester.takeException(), isNull);

      // 5. Raporlar ekranını kontrol et (hedef yokken sahte hedef üretilmez)
      await tapText('Raporlar');
      expect(find.text('Genel İstatistikler'), findsOneWidget);
      expect(find.text('Henüz hedef kilo belirlenmedi.'), findsOneWidget);
      await tapText('Günlük');
      await tapText('Aylık');
      await tapText('Genel');
      expect(tester.takeException(), isNull);

      // 6. Geçmiş ekranı: filtreler, düzenleme ve silme onayı
      await tapText('Geçmiş');
      expect(find.text('Sadece Sabah'), findsOneWidget);
      await tapText('Sadece Sabah');
      expect(find.text('136.6 kg'), findsOneWidget);
      await tapText('Sadece Akşam');
      expect(find.text('136.1 kg'), findsOneWidget);
      await tapText('Tümü');

      // Sabah kaydının üzerine dokunarak düzenleme
      await tapText('136.6 kg');
      await enterWeight('136.8');
      expect(store.stats.days.values.single.difference, -0.7);

      // Silme işlemi (Sadece Sabah filtresindeyken tekil silme onayı)
      await tapText('Sadece Sabah');
      await tester.tap(find.byIcon(Icons.delete_outline_rounded).first);
      await tester.pumpAndSettle();
      expect(
        find.text('Bu kilo kaydını silmek istediğine emin misin?'),
        findsOneWidget,
      );
      await tapText('Vazgeç');
      expect(repository.entries, hasLength(2));

      await tester.tap(find.byIcon(Icons.delete_outline_rounded).first);
      await tester.pumpAndSettle();
      await tapText('Sil');
      expect(repository.entries.single.slot, Slot.evening);

      // 7. Ayarlar ekranı: Bildirim saatleri, kullanıcı geri bildirimi, tema ve Excel dışa aktarma
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();
      expect(find.text('Bildirimler'), findsOneWidget);
      expect(find.text('Her gün 09:00 saatinde hatırlatır'), findsOneWidget);
      expect(find.text('Her gün 22:30 saatinde hatırlatır'), findsOneWidget);

      // Sabah bildirimini kapatıp tekrar açtığımızda kullanıcıya saat bilgisiyle geri bildirim verilir
      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();
      expect(find.text('Sabah bildirimi kapatıldı.'), findsOneWidget);
      expect(find.text('Bildirim kapalı'), findsOneWidget);

      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();
      expect(
        find.text('Sabah bildirimi her gün saat 09:00 için aktif edildi.'),
        findsOneWidget,
      );
      ScaffoldMessenger.of(
        tester.element(find.byType(Scaffold).last),
      ).hideCurrentSnackBar();
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Görünüm'),
        200,
      );
      expect(find.text('Görünüm'), findsOneWidget);
      await tapText('Koyu');
      expect(settings.theme, ThemeMode.dark);
      await tapText('Açık');
      expect(settings.theme, ThemeMode.light);
      await tester.scrollUntilVisible(
        find.text('Excel Dışa Aktar (.xlsx)'),
        200,
      );
      expect(find.text('Excel Dışa Aktar (.xlsx)'), findsOneWidget);

      // Excel Dışa Aktar (.xlsx) tıklandığında alt panelin doğru dosya adıyla açılması
      await tapText('Excel Dışa Aktar (.xlsx)');
      expect(find.text('Cihaza Kaydet (.xlsx)'), findsOneWidget);
      expect(find.text('Paylaş / Excel ile Aç (.xlsx)'), findsOneWidget);
      expect(find.textContaining('1 kayıt'), findsOneWidget);
      // Alt paneli kapat
      await tester.tapAt(const Offset(20, 20));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'Tüm hedef ekran boyutlarında (360x640, 375x667, 390x844, 393x852, 412x915) taşma olmadan çalışır',
    (tester) async {
      final sizes = [
        const Size(360, 640),
        const Size(375, 667),
        const Size(390, 844),
        const Size(393, 852),
        const Size(412, 915),
      ];
      final today = dayOf(DateTime.now());
      final repository = MemoryWeights()
        ..entries.addAll([
          Measurement(shiftDay(today, -2), Slot.morning, 137.4),
          Measurement(shiftDay(today, -2), Slot.evening, 137.8),
          Measurement(shiftDay(today, -1), Slot.morning, 137.0),
          Measurement(today, Slot.morning, 136.6),
          Measurement(today, Slot.evening, 136.1),
        ]);
      final store = WeightStore(repository);
      final settings = AppSettings()
        ..startWeight = 140.0
        ..targetWeight = 130.0;

      for (final size in sizes) {
        await tester.binding.setSurfaceSize(size);
        await tester.pumpWidget(
          KiloTakip(
            store: store,
            settings: settings,
            reminders: Reminders(),
            useNotifications: false,
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'Ana Sayfa $size');

        for (final tabName in ['Grafikler', 'Geçmiş', 'Raporlar', 'Ana Sayfa']) {
          await tester.tap(find.text(tabName).last);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: '$tabName $size');
        }
      }
      await tester.binding.setSurfaceSize(null);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
