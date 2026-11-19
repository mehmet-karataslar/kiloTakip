import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' show Rect;

import 'package:excel_plus/excel_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../domain/measurements.dart';
import '../l10n/app_localizations.dart';

const _mime =
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

String workbookFileName([DateTime? now]) =>
    'kilo_takip_${dateKey(now ?? DateTime.now())}.xlsx';

Uint8List buildWorkbook(List<Measurement> entries) {
  final stats = Statistics(entries);
  final book = Excel.createExcel();
  final initial = book.getDefaultSheet()!;
  final recordsName = trText('Kilo Kayıtları');
  book.rename(initial, recordsName);
  final records = book[recordsName];
  final weekly = book[trText('Haftalık Rapor')];
  final monthly = book[trText('Aylık Rapor')];

  void header(Sheet sheet, List<String> titles) {
    for (final (index, rawTitle) in titles.indexed) {
      final title = trText(rawTitle);
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: index, rowIndex: 0),
      );
      cell.value = TextCellValue(title);
      cell.cellStyle = CellStyle(bold: true);
      sheet.setColumnWidth(index, title.length + 8.0);
    }
  }

  void append(Sheet sheet, List<CellValue?> row) {
    final index = sheet.maxRows;
    sheet.appendRow(row);
    for (final (column, value) in row.indexed) {
      final format = switch (value) {
        DateCellValue() => const CustomDateTimeNumFormat(
          formatCode: 'dd.mm.yyyy',
        ),
        DoubleCellValue() => const CustomNumericNumFormat(formatCode: '0.0'),
        TimeCellValue() => const CustomTimeNumFormat(formatCode: 'hh:mm'),
        _ => null,
      };
      if (format != null) {
        sheet
            .cell(
              CellIndex.indexByColumnRow(columnIndex: column, rowIndex: index),
            )
            .cellStyle = CellStyle(
          numberFormat: format,
        );
      }
    }
  }

  CellValue date(DateTime d) =>
      DateCellValue(year: d.year, month: d.month, day: d.day);
  CellValue? number(double? n) =>
      n == null ? null : DoubleCellValue(rounded(n));
  CellValue clock(int minutes) =>
      TimeCellValue(hour: minutes ~/ 60, minute: minutes % 60);

  header(records, [
    'Tarih',
    'Saat',
    'Kayıt Türü',
    'Kilo (kg)',
    'Not',
  ]);
  for (final m in stats.all) {
    append(records, [
      date(m.day),
      clock(m.effectiveMinutes),
      TextCellValue(m.slot.label),
      number(m.kg),
      TextCellValue(m.cleanNote == null ? '' : trText(m.cleanNote!)),
    ]);
  }

  header(weekly, [
    'Hafta başlangıcı',
    'Sabah Değişimi (kg)',
    'Akşam Değişimi (kg)',
    'Ölçüm Günü',
  ]);
  for (final week in stats.grouped(weekOf)) {
    append(weekly, [
      date(week.start),
      for (final slot in Slot.values) number(week.series[slot]!.change),
      IntCellValue(week.countDays),
    ]);
  }

  header(monthly, [
    'Ay başlangıcı',
    'Sabah Ortalaması (kg)',
    'Akşam Ortalaması (kg)',
    'Sabah Değişimi (kg)',
    'Akşam Değişimi (kg)',
    'Ölçüm Günü',
  ]);
  for (final month in stats.grouped(monthOf)) {
    append(monthly, [
      date(month.start),
      for (final slot in Slot.values) number(month.series[slot]!.average),
      for (final slot in Slot.values) number(month.series[slot]!.change),
      IntCellValue(month.countDays),
    ]);
  }
  return Uint8List.fromList(book.encode()!);
}

class WorkbookExport {
  /// Excel (.xlsx) dosyasını geçici dizinde oluşturur ve dosya nesnesini döndürür.
  Future<File> writeTempWorkbook(
    List<Measurement> entries, {
    Directory? baseDir,
  }) async {
    final bytes = buildWorkbook(entries);
    final name = workbookFileName();
    final cache = baseDir ?? await getTemporaryDirectory();
    final root = Directory(path.join(cache.path, 'weight_reports'));
    await root.create(recursive: true);
    final cutoff = DateTime.now().subtract(const Duration(days: 1));
    await for (final item in root.list(followLinks: false)) {
      if (item is Directory && (await item.stat()).modified.isBefore(cutoff)) {
        await item.delete(recursive: true);
      }
    }
    final folder = await root.createTemp('rapor_');
    return File(path.join(folder.path, name)).writeAsBytes(bytes, flush: true);
  }

  Future<bool> export(
    List<Measurement> entries, {
    required bool share,
    required Rect origin,
  }) async {
    final bytes = buildWorkbook(entries);
    final name = workbookFileName();
    if (!share) {
      final savedUri = await FilePicker.saveFile(
        fileName: name,
        bytes: bytes,
        mimeType: _mime,
        dialogTitle: trText('Excel dosyasını kaydet'),
      );
      return savedUri != null;
    }

    final file = await writeTempWorkbook(entries);
    final result = await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: _mime, name: name)],
        sharePositionOrigin: origin,
      ),
    );
    return result.status != ShareResultStatus.dismissed;
  }
}
