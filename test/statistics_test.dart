import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kilo_takip/domain/measurements.dart';
import 'package:kilo_takip/services/reminders.dart';
import 'package:timezone/data/latest_all.dart' as zones;
import 'package:timezone/timezone.dart' as tz;

void main() {
  test('Ondalık giriş, sınırlar ve geçersiz değerler', () {
    expect(parseWeight(' 135,40 '), 135.4);
    expect(parseWeight('135.40'), 135.4);
    for (final value in [
      '',
      '0',
      '-3',
      'NaN',
      '1,50',
      '500,01',
      '100,123',
      '1e2',
    ]) {
      expect(parseWeight(value), isNull, reason: value);
    }
    expect(parseWeight('2'), 2);
    expect(parseWeight('500'), 500);
  });

  test('Önceki ölçüm, gün içi fark, eksik günler, hedef ilerlemesi ve yıl geçişi', () {
    final dec = DateTime(2025, 12, 31);
    final jan = DateTime(2026, 1, 2);
    final later = DateTime(2026, 1, 10);
    final stats = Statistics([
      Measurement(jan, Slot.evening, 136.8, minutes: 22 * 60 + 30),
      Measurement(dec, Slot.morning, 136.5, minutes: 9 * 60, note: 'Başlangıç'),
      Measurement(later, Slot.morning, 136.1),
      Measurement(jan, Slot.morning, 136.1),
      Measurement(dec, Slot.evening, 137.2),
    ]);
    expect(stats.previousChange(jan, Slot.morning), -.4);
    expect(stats.previousChange(jan, Slot.evening), -.4);
    expect(stats.days[jan]!.difference, .7);
    expect(stats.days[later]!.difference, isNull);
    expect(stats.previous(later, Slot.evening)!.day, jan);

    // Tutarlı karşılaştırma sabah serisini önceliklendirir
    final comp = stats.comparableChange(stats.all);
    expect(comp.usedSlot, Slot.morning);
    expect(comp.change, -.4);

    // Hedef kilo tanımlı değilse ilerleme üretilmez
    expect(
      stats.targetProgress(configuredStartWeight: null, targetWeight: null),
      isNull,
    );

    // Hedef kilo tanımlıysa gerçek veriden hesaplanır
    final progress = stats.targetProgress(
      configuredStartWeight: 140.0,
      targetWeight: 130.0,
    )!;
    expect(progress.startWeight, 140.0);
    expect(progress.currentWeight, 136.1);
    expect(progress.remainingKg, 6.1);
    expect(progress.progressPercent, 39);

    final week = stats.period(weekOf(jan), shiftDay(weekOf(jan), 7));
    expect(week.start, DateTime(2025, 12, 29));
    expect(week.countDays, 2);
    expect(week.series[Slot.morning]!.change, -.4);
    expect(week.series[Slot.morning]!.first!.day, dec);
    expect(week.series[Slot.morning]!.last!.day, jan);
    final month = stats.grouped(monthOf).last;
    expect(month.countDays, 2);
    expect(month.series[Slot.morning]!.change, 0);
    expect(month.series[Slot.evening]!.change, isNull);
    expect(month.series[Slot.evening]!.average, 136.8);
  });

  test('Türkiye saati (Europe/Istanbul UTC+3) sabah 09:00 ve özel akşam saati planlaması', () {
    zones.initializeTimeZones();
    final trLoc = resolveLocalTimezone('Europe/Istanbul', const Duration(hours: 3));
    expect(trLoc.name, 'Europe/Istanbul');

    // Bilinmeyen kimlik olsa bile UTC+3 offset ile Türkiye saatini bulur
    final fallbackTr = resolveLocalTimezone(null, const Duration(hours: 3));
    expect(fallbackTr.currentTimeZone.offset, const Duration(hours: 3));

    // Türkiye saatiyle öğleden sonra 14:50'de kontrol:
    // Sabah 09:00 geçmiş olduğu için yarına (09:00 +03:00),
    // Akşam 22:30 henüz gelmediği için bugüne (22:30 +03:00) planlanır.
    final nowAfternoon = tz.TZDateTime(trLoc, 2026, 11, 9, 14, 50);
    final morning9 = nextReminder(
      nowAfternoon,
      const TimeOfDay(hour: 9, minute: 0),
    );
    final eveningCustom = nextReminder(
      nowAfternoon,
      const TimeOfDay(hour: 21, minute: 45),
    );

    expect(
      (morning9.year, morning9.month, morning9.day, morning9.hour, morning9.minute, morning9.timeZoneOffset.inHours),
      (2026, 11, 10, 9, 0, 3),
    );
    expect(
      (eveningCustom.year, eveningCustom.month, eveningCustom.day, eveningCustom.hour, eveningCustom.minute, eveningCustom.timeZoneOffset.inHours),
      (2026, 11, 9, 21, 45, 3),
    );

    // Türkiye saatiyle sabah 08:15'te kontrol: Sabah 09:00 bugüne planlanır.
    final nowEarlyMorning = tz.TZDateTime(trLoc, 2026, 11, 9, 8, 15);
    final morningSameDay = nextReminder(
      nowEarlyMorning,
      const TimeOfDay(hour: 9, minute: 0),
    );
    expect(
      (morningSameDay.day, morningSameDay.hour, morningSameDay.minute, morningSameDay.timeZoneOffset.inHours),
      (9, 9, 0, 3),
    );
  });

  test('Hatırlatma yerel saati ve yaz saati geçişini korur', () {
    zones.initializeTimeZones();
    final loc = tz.getLocation('Europe/Berlin');
    final now = tz.TZDateTime(loc, 2026, 3, 28, 10);
    final morning = nextReminder(now, const TimeOfDay(hour: 9, minute: 0));
    final evening = nextReminder(now, const TimeOfDay(hour: 22, minute: 30));
    expect(
      (morning.day, morning.hour, morning.timeZoneOffset.inHours),
      (29, 9, 2),
    );
    expect((evening.day, evening.hour, evening.minute), (28, 22, 30));
  });
}
