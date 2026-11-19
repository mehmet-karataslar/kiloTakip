import 'package:excel_plus/excel_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kilo_takip/data/weight_repository.dart';
import 'package:kilo_takip/domain/measurements.dart';
import 'package:kilo_takip/main.dart';
import 'package:kilo_takip/services/reminders.dart';
import 'package:kilo_takip/services/workbook.dart';
import 'package:kilo_takip/state/weight_store.dart';
import 'package:sqflite/sqflite.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Android SQLite bütünlüğü, saat/not kalıcılığı ve mobil gezinme', (
    tester,
  ) async {
    final dbPath = '${await getDatabasesPath()}/kilo_integration.db';
    await deleteDatabase(dbPath);
    addTearDown(() => deleteDatabase(dbPath));
    final day = shiftDay(dayOf(DateTime.now()), -1);
    final morning = Measurement(
      day,
      Slot.morning,
      134.2,
      minutes: 9 * 60 + 15,
      note: 'Sabah ölçümü',
    );
    final evening = Measurement(
      day,
      Slot.evening,
      135.6,
      minutes: 22 * 60 + 30,
      note: 'Akşam ölçümü',
    );
    final first = SqliteWeights(location: dbPath);
    await first.save(morning);
    await first.save(evening);
    await expectLater(
      first.save(morning),
      throwsA(isA<DuplicateMeasurement>()),
    );
    await expectLater(
      first.save(Measurement(shiftDay(day, 2), Slot.morning, 75)),
      throwsArgumentError,
    );
    await first.close();

    final repository = SqliteWeights(location: dbPath);
    addTearDown(repository.close);
    final store = WeightStore(repository);
    await store.load();
    expect(store.stats.days[day]!.difference, 1.4);
    expect(store.stats.days[day]!.morning!.minutes, 9 * 60 + 15);
    expect(store.stats.days[day]!.morning!.cleanNote, 'Sabah ölçümü');
    await store.save(
      Measurement(
        day,
        Slot.morning,
        135.4,
        minutes: 9 * 60 + 30,
        note: 'Güncellendi',
      ),
      original: morning,
    );
    await store.load();
    expect(store.stats.days[day]!.difference, .2);
    expect(store.stats.days[day]!.morning!.cleanNote, 'Güncellendi');

    await tester.pumpWidget(
      KiloTakip(
        store: store,
        settings: AppSettings(),
        reminders: Reminders(),
        useNotifications: false,
      ),
    );
    await tester.pumpAndSettle();
    for (final tabName in ['Grafikler', 'Geçmiş', 'Raporlar', 'Ana Sayfa']) {
      await tester.tap(find.text(tabName).last);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
    await store.delete(evening);
    await store.load();
    expect(store.stats.all.single.slot, Slot.morning);

    // Gerçek cihaz dosya sisteminde Excel (.xlsx) dosyası oluşturma ve doğrulama
    final excelFile = await WorkbookExport().writeTempWorkbook(store.stats.all);
    expect(await excelFile.exists(), isTrue);
    expect(excelFile.path.endsWith('.xlsx'), isTrue);
    final bytes = await excelFile.readAsBytes();
    // ZIP/OOXML imzası (PK\x03\x04) ve Excel içeriği doğrulaması
    expect(bytes.sublist(0, 2), [0x50, 0x4B]);
    final decoded = Excel.decodeBytes(bytes);
    final rows = decoded.tables['Kilo Kayıtları']!.rows;
    expect(rows[0][0]!.value, TextCellValue('Tarih'));
    expect(rows[1][1]!.value, const TimeCellValue(hour: 9, minute: 30));
    expect(rows[1][2]!.value, TextCellValue('Sabah'));
    expect(rows[1][3]!.value, const DoubleCellValue(135.4));
    expect(rows[1][4]!.value, TextCellValue('Güncellendi'));

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Android ayar kalıcılığı, Türkiye saatiyle 09:00 ve özel akşam saati planlama', (
    tester,
  ) async {
    final settings = AppSettings();
    await settings.load();
    final original = Map<Slot, Reminder>.of(settings.reminders);
    final reminders = Reminders();
    final plugin = FlutterLocalNotificationsPlugin();
    final android = plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()!;
    await reminders.initialize((_) {});
    addTearDown(() async {
      for (final entry in original.entries) {
        await settings.setReminder(entry.key, entry.value);
      }
      await reminders.sync(settings);
      reminders.dispose();
    });
    for (final slot in Slot.values) {
      await settings.setReminder(
        slot,
        Reminder(true, TimeOfDay(hour: slot.hour, minute: slot.minute)),
      );
    }
    await reminders.sync(settings);
    final allowed = await android.areNotificationsEnabled() == true;
    if (!allowed) {
      expect(reminders.value, ReminderStatus.blocked);
      expect(await plugin.pendingNotificationRequests(), isEmpty);
      return;
    }
    await reminders.sync(settings);
    final first = await plugin.pendingNotificationRequests();
    expect(first.map((r) => r.id), unorderedEquals([1, 2]));
    expect(
      first.map((r) => r.payload),
      unorderedEquals(['morning', 'evening']),
    );
    // Sabah 09:00 ve akşam 22:30 zamanlamalarının Türkiye saatiyle (veya cihaz yerel saatiyle) kontrolü
    expect(reminders.scheduledTimes[Slot.morning]!.hour, 9);
    expect(reminders.scheduledTimes[Slot.morning]!.minute, 0);
    expect(reminders.scheduledTimes[Slot.evening]!.hour, 22);
    expect(reminders.scheduledTimes[Slot.evening]!.minute, 30);

    // Akşam saatini 21:45 olarak değiştirdiğimizde bildirim başlığı ve hedef saati güncellenir
    await settings.setReminder(
      Slot.evening,
      const Reminder(true, TimeOfDay(hour: 21, minute: 45)),
    );
    await reminders.sync(settings);
    expect(reminders.scheduledTimes[Slot.evening]!.hour, 21);
    expect(reminders.scheduledTimes[Slot.evening]!.minute, 45);
    final updatedPending = await plugin.pendingNotificationRequests();
    final eveningReq = updatedPending.firstWhere((r) => r.id == 2);
    expect(eveningReq.title, 'Akşam Kilo Hatırlatması (21:45)');
    expect(
      eveningReq.body,
      'Akşam kilonu kaydederek günlük değişimini takip et.',
    );
    await settings.setReminder(
      Slot.morning,
      const Reminder(false, TimeOfDay(hour: 10, minute: 15)),
    );
    await reminders.sync(settings);
    expect((await plugin.pendingNotificationRequests()).single.id, 2);
    final reloaded = AppSettings();
    await reloaded.load();
    expect(reloaded.reminders[Slot.morning]!.enabled, false);
    expect(
      reloaded.reminders[Slot.morning]!.time,
      const TimeOfDay(hour: 10, minute: 15),
    );
    await settings.setReminder(
      Slot.morning,
      const Reminder(true, TimeOfDay(hour: 10, minute: 15)),
    );
    await reminders.sync(settings);
    expect(
      (await plugin.pendingNotificationRequests()).map((r) => r.id),
      unorderedEquals([1, 2]),
    );
  });
}
