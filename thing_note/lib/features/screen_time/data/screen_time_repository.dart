import 'package:thing_note/core/database/database_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/screen_time_entry.dart';

final screenTimeRepositoryProvider = Provider<ScreenTimeRepository>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return ScreenTimeRepository(dbAsync);
});

class ScreenTimeRepository {
  final AsyncValue<dynamic> _dbAsync;

  ScreenTimeRepository(this._dbAsync);

  Future<dynamic> get _db async {
    final db = _dbAsync.value;
    if (db == null) throw Exception('Database not initialized');
    return db;
  }

  Future<int> insertScreenTime(ScreenTimeEntry entry) async {
    final db = await _db;
    return await db.insert('screen_time_entries', entry.toMap());
  }

  Future<List<ScreenTimeEntry>> getScreenTimeByDateRange(
      String startDate, String endDate) async {
    final db = await _db;
    final maps = await db.query(
      'screen_time_entries',
      where: 'date >= ? AND date <= ?',
      whereArgs: [startDate, endDate],
      orderBy: 'date DESC',
    );
    return maps.map((map) => ScreenTimeEntry.fromMap(map)).toList();
  }

  Future<List<ScreenTimeEntry>> getScreenTimeByDate(String date) async {
    final db = await _db;
    final maps = await db.query(
      'screen_time_entries',
      where: 'date = ?',
      whereArgs: [date],
    );
    return maps.map((map) => ScreenTimeEntry.fromMap(map)).toList();
  }

  Future<int> getTotalMinutesByDate(String date) async {
    final db = await _db;
    final result = await db.rawQuery(
      'SELECT SUM(duration_minutes) as total FROM screen_time_entries WHERE date = ?',
      [date],
    );
    return (result.first['total'] as int?) ?? 0;
  }

  Future<Map<String, int>> getCategoryStats(String startDate, String endDate) async {
    final db = await _db;
    final result = await db.rawQuery(
      '''SELECT category, SUM(duration_minutes) as total 
         FROM screen_time_entries 
         WHERE date >= ? AND date <= ?
         GROUP BY category''',
      [startDate, endDate],
    );
    return {
      for (final row in result)
        row['category'] as String: (row['total'] as int?) ?? 0
    };
  }

  Future<int> deleteScreenTime(int id) async {
    final db = await _db;
    return await db.delete(
      'screen_time_entries',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> updateScreenTime(ScreenTimeEntry entry) async {
    final db = await _db;
    return await db.update(
      'screen_time_entries',
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  Future<List<ScreenTimeEntry>> getAllScreenTime() async {
    final db = await _db;
    final maps = await db.query(
      'screen_time_entries',
      orderBy: 'date DESC, created_at DESC',
    );
    return maps.map((map) => ScreenTimeEntry.fromMap(map)).toList();
  }
}