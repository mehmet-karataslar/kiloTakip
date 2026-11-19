import 'package:excel_plus/excel_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kilo_takip/domain/measurements.dart';
import 'package:kilo_takip/services/workbook.dart';

void main() {
  test('Boş çalışma kitabında üç başlık sayfası var', () {
    final book = Excel.decodeBytes(buildWorkbook([]));
    expect(book.tables, hasLength(3));
    expect(book.tables.values.map((sheet) => sheet.maxRows), everyElement(1));
  });

  test('XLSX Tarih, Saat, Kayıt Türü, Kilo (kg), Not sütunlarını ve raporları korur', () {
    final day = DateTime(2026, 11, 7);
    final entries = [
      Measurement(
        day,
        Slot.morning,
        135.8,
        minutes: 8 * 60 + 44,
        note: 'Aç karnına',
      ),
      Measurement(shiftDay(day, 1), Slot.morning, 135.4, minutes: 9 * 60),
      Measurement(
        shiftDay(day, 1),
        Slot.evening,
        136.1,
        minutes: 22 * 60 + 30,
        note: 'Spor sonrası',
      ),
      Measurement(DateTime(2026, 12, 1), Slot.evening, 136.4),
    ];
    final book = Excel.decodeBytes(buildWorkbook(entries.reversed.toList()));
    final records = book.tables['Kilo Kayıtları']!.rows;
    final weeks = book.tables['Haftalık Rapor']!.rows;
    final months = book.tables['Aylık Rapor']!.rows;

    // Sütun başlıkları: Tarih, Saat, Kayıt Türü, Kilo (kg), Not
    expect(records[0][0]!.value, TextCellValue('Tarih'));
    expect(records[0][1]!.value, TextCellValue('Saat'));
    expect(records[0][2]!.value, TextCellValue('Kayıt Türü'));
    expect(records[0][3]!.value, TextCellValue('Kilo (kg)'));
    expect(records[0][4]!.value, TextCellValue('Not'));

    expect(records, hasLength(5));
    expect(records[1][0]!.value, DateCellValue(year: 2026, month: 11, day: 7));
    expect(records[1][1]!.value, const TimeCellValue(hour: 8, minute: 44));
    expect(records[1][2]!.value, TextCellValue('Sabah'));
    expect(records[1][3]!.value, const DoubleCellValue(135.8));
    expect(records[1][4]!.value, TextCellValue('Aç karnına'));

    expect(records[3][1]!.value, const TimeCellValue(hour: 22, minute: 30));
    expect(records[3][2]!.value, TextCellValue('Akşam'));
    expect(records[3][3]!.value, const DoubleCellValue(136.1));
    expect(records[3][4]!.value, TextCellValue('Spor sonrası'));

    expect(weeks[1][1]!.value, const DoubleCellValue(-.4));
    expect(weeks[1][2]?.value, isNull);
    expect(weeks[1][3]!.value, const IntCellValue(2));
    expect(months[1][1]!.value, const DoubleCellValue(135.6));
    expect(months[1][3]!.value, const DoubleCellValue(-.4));
    expect(months[2][1]?.value, isNull);
  });
}
