import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/water_intake/domain/water_intake_record.dart';
import 'package:thing_note/core/database/database_provider.dart';
import 'package:sqflite/sqflite.dart';

final waterIntakeRepositoryProvider = Provider<WaterIntakeRepository>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return WaterIntakeRepository(dbAsync);
});

final waterIntakeTodayProvider = FutureProvider<WaterIntakeRecord?>((ref) async {
  final repo = ref.watch(waterIntakeRepositoryProvider);
  return repo.getRecordByDate(_todayDate());
});

final waterIntakeWeeklyProvider = FutureProvider<List<WaterIntakeRecord>>((ref) async {
  final repo = ref.watch(waterIntakeRepositoryProvider);
  return repo.getRecordsForWeek(_todayDate());
});

String _todayDate() {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
}

class WaterIntakeRepository {
  final AsyncValue<Database> _dbAsync;

  WaterIntakeRepository(this._dbAsync);

  Future<Database> get _db async {
    final db = _dbAsync.value;
    if (db == null) throw Exception('Database not initialized');
    return db;
  }

  Future<int> insertRecord(WaterIntakeRecord record) async {
    final db = await _db;
    return db.insert('water_intake_records', record.toMap());
  }

  Future<int> updateRecord(WaterIntakeRecord record) async {
    final db = await _db;
    return db.update(
      'water_intake_records',
      record.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }

  Future<int> addGlass(String date) async {
    final existing = await getRecordByDate(date);
    if (existing == null) {
      final now = DateTime.now();
      final record = WaterIntakeRecord(
        date: date,
        glasses: 1,
        totalMl: 250,
        createdAt: now,
        updatedAt: now,
      );
      return insertRecord(record);
    } else {
      final updated = existing.copyWith(
        glasses: existing.glasses + 1,
        totalMl: existing.totalMl + 250,
        updatedAt: DateTime.now(),
      );
      return updateRecord(updated);
    }
  }

  Future<int> setGoalMl(String date, int goalMl) async {
    final db = await _db;
    final existing = await getRecordByDate(date);
    if (existing == null) {
      final now = DateTime.now();
      final record = WaterIntakeRecord(
        date: date,
        glasses: 0,
        totalMl: 0,
        goalMl: goalMl,
        createdAt: now,
        updatedAt: now,
      );
      return insertRecord(record);
    }
    return db.update(
      'water_intake_records',
      {'goal_ml': goalMl, 'updated_at': DateTime.now().toIso8601String()},
      where: 'date = ?',
      whereArgs: [date],
    );
  }

  Future<WaterIntakeRecord?> getRecordByDate(String date) async {
    final db = await _db;
    final maps = await db.query(
      'water_intake_records',
      where: 'date = ?',
      whereArgs: [date],
    );
    if (maps.isEmpty) return null;
    return WaterIntakeRecord.fromMap(maps.first);
  }

  Future<List<WaterIntakeRecord>> getRecordsForWeek(String endDate) async {
    final db = await _db;
    final end = DateTime.parse(endDate);
    final start = end.subtract(const Duration(days: 6));
    final startStr = '${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}';
    final maps = await db.query(
      'water_intake_records',
      where: 'date BETWEEN ? AND ?',
      whereArgs: [startStr, endDate],
      orderBy: 'date ASC',
    );
    return maps.map((m) => WaterIntakeRecord.fromMap(m)).toList();
  }

  Future<List<WaterIntakeRecord>> getRecordsForMonth(int year, int month) async {
    final db = await _db;
    final startDate = '$year-${month.toString().padLeft(2, '0')}-01';
    final endDate = '$year-${month.toString().padLeft(2, '0')}-31';
    final maps = await db.query(
      'water_intake_records',
      where: 'date BETWEEN ? AND ?',
      whereArgs: [startDate, endDate],
      orderBy: 'date ASC',
    );
    return maps.map((m) => WaterIntakeRecord.fromMap(m)).toList();
  }

  Future<Map<String, int>> getWeeklyStats(String date) async {
    final records = await getRecordsForWeek(date);
    int totalMl = 0;
    int goalDays = 0;
    for (final r in records) {
      totalMl += r.totalMl;
      if (r.goalReached) goalDays++;
    }
    return {'total_ml': totalMl, 'goal_days': goalDays, 'total_glasses': records.fold(0, (sum, r) => sum + r.glasses)};
  }
}
