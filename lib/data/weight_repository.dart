import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

import '../domain/measurements.dart';

class DuplicateMeasurement implements Exception {}

abstract interface class WeightRepository {
  Future<List<Measurement>> readAll();
  Future<void> save(Measurement value, {Measurement? original});
  Future<void> delete(Measurement value);
}

class SqliteWeights implements WeightRepository {
  SqliteWeights({DatabaseFactory? factory, this.location})
    : _factory = factory ?? databaseFactory;

  final DatabaseFactory _factory;
  final String? location;
  Future<Database>? _opening;

  Future<Database> get _db async {
    final pending = _opening ??= _open();
    try {
      return await pending;
    } catch (_) {
      if (identical(_opening, pending)) _opening = null;
      rethrow;
    }
  }

  Future<Database> _open() async => _factory.openDatabase(
    location ?? path.join(await _factory.getDatabasesPath(), 'kilo_takip.db'),
    options: OpenDatabaseOptions(
      version: 4,
      onUpgrade: (db, from, to) async {
        if (from < 2) {
          await db.execute(
            'ALTER TABLE measurements ADD COLUMN measured_minutes INTEGER CHECK(measured_minutes BETWEEN 0 AND 1439)',
          );
        }
        if (from < 3) {
          final columns = await db.rawQuery('PRAGMA table_info(measurements)');
          final names = columns.map((c) => c['name'] as String).toSet();
          if (!names.contains('entry_time')) {
            await db.execute(
              'ALTER TABLE measurements ADD COLUMN entry_time TEXT',
            );
          }
          if (!names.contains('note')) {
            await db.execute(
              'ALTER TABLE measurements ADD COLUMN note TEXT',
            );
          }
        }
        if (from < 4) {
          final columns = await db.rawQuery('PRAGMA table_info(measurements)');
          final names = columns.map((c) => c['name'] as String).toSet();
          if (!names.contains('waist_cm')) {
            await db.execute(
              'ALTER TABLE measurements ADD COLUMN waist_cm REAL',
            );
          }
        }
      },
      onCreate: (db, version) async {
        await db.execute("""
        CREATE TABLE measurements (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          measurement_date TEXT NOT NULL,
          entry_time TEXT,
          measurement_type TEXT NOT NULL CHECK(measurement_type IN ('morning', 'evening')),
          weight_kg REAL NOT NULL CHECK(weight_kg BETWEEN $minWeight AND $maxWeight),
          measured_minutes INTEGER CHECK(measured_minutes BETWEEN 0 AND 1439),
          note TEXT,
          waist_cm REAL,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          UNIQUE(measurement_date, measurement_type)
        )
      """);
      },
    ),
  );

  static const _key = 'measurement_date = ? AND measurement_type = ?';
  List<String> _args(Measurement m) => [dateKey(m.day), m.slot.name];

  @override
  Future<List<Measurement>> readAll() async => [
    for (final row in await (await _db).query(
      'measurements',
      orderBy: 'measurement_date',
    ))
      Measurement(
        DateTime.parse(row['measurement_date'] as String),
        Slot.values.byName(row['measurement_type'] as String),
        rounded((row['weight_kg'] as num).toDouble()),
        minutes:
            (row['measured_minutes'] as int?) ??
            parseClockMinutes(row['entry_time'] as String?),
        note: row['note'] as String?,
        waistCm: (row['waist_cm'] as num?)?.toDouble(),
      ),
  ];

  @override
  Future<void> save(Measurement value, {Measurement? original}) async {
    if (dayOf(value.day).isAfter(dayOf(DateTime.now())) ||
        !value.kg.isFinite ||
        value.kg < minWeight ||
        value.kg > maxWeight ||
        (value.minutes != null &&
            (value.minutes! < 0 || value.minutes! >= 1440))) {
      throw ArgumentError('Geçersiz ölçüm');
    }
    final now = DateTime.now().toUtc().toIso8601String();
    final mins = value.minutes;
    final row = <String, Object?>{
      'measurement_date': dateKey(value.day),
      'entry_time': mins == null ? null : clockLabel(mins),
      'measurement_type': value.slot.name,
      'weight_kg': rounded(value.kg),
      'measured_minutes': mins,
      'note': value.cleanNote,
      'waist_cm': value.waistCm == null ? null : rounded(value.waistCm!),
      'updated_at': now,
    };
    try {
      final db = await _db;
      if (original == null) {
        await db.insert('measurements', {...row, 'created_at': now});
      } else {
        final changed = await db.update(
          'measurements',
          row,
          where: _key,
          whereArgs: _args(original),
        );
        if (changed != 1) throw StateError('Ölçüm bulunamadı');
      }
    } on DatabaseException catch (error) {
      if (error.isUniqueConstraintError()) throw DuplicateMeasurement();
      rethrow;
    }
  }

  @override
  Future<void> delete(Measurement value) async {
    await (await _db).delete(
      'measurements',
      where: _key,
      whereArgs: _args(value),
    );
  }

  Future<void> close() async {
    final pending = _opening;
    if (pending == null) return;
    await (await pending).close();
    if (identical(_opening, pending)) _opening = null;
  }
}
