import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';
import 'package:thing_note/features/mood_calendar/domain/mood_entry.dart';

final moodCalendarRepositoryProvider = Provider<MoodCalendarRepository>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return MoodCalendarRepository(dbAsync);
});

class MoodCalendarRepository {
  final AsyncValue<Database> _dbAsync;

  MoodCalendarRepository(this._dbAsync);

  Future<Database> get _db async {
    final db = _dbAsync.value;
    if (db == null) throw Exception('Database not initialized');
    return db;
  }

  Future<int> insertOrUpdate(MoodEntry entry) async {
    final db = await _db;
    final existing = await db.query(
      'mood_entries',
      where: 'date = ?',
      whereArgs: [entry.date],
    );

    if (existing.isEmpty) {
      return await db.insert('mood_entries', entry.toMap());
    } else {
      return await db.update(
        'mood_entries',
        entry.toMap(),
        where: 'date = ?',
        whereArgs: [entry.date],
      );
    }
  }

  Future<MoodEntry?> getByDate(String date) async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      'mood_entries',
      where: 'date = ?',
      whereArgs: [date],
    );
    if (maps.isEmpty) return null;
    return MoodEntry.fromMap(maps.first);
  }

  Future<List<MoodEntry>> getByMonth(int year, int month) async {
    final db = await _db;
    final startDate = '$year-${month.toString().padLeft(2, '0')}-01';
    final endDate = '$year-${month.toString().padLeft(2, '0')}-31';

    final List<Map<String, dynamic>> maps = await db.query(
      'mood_entries',
      where: 'date >= ? AND date <= ?',
      whereArgs: [startDate, endDate],
      orderBy: 'date ASC',
    );
    return maps.map((map) => MoodEntry.fromMap(map)).toList();
  }

  Future<List<MoodEntry>> getRecent(int days) async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      'mood_entries',
      orderBy: 'date DESC',
      limit: days,
    );
    return maps.map((map) => MoodEntry.fromMap(map)).toList();
  }

  Future<double> getAverageMood(int days) async {
    final db = await _db;
    final result = await db.rawQuery('''
      SELECT AVG(level) as avg_mood FROM (
        SELECT level FROM mood_entries
        ORDER BY date DESC LIMIT ?
      )
    ''', [days]);
    return (result.first['avg_mood'] as num?)?.toDouble() ?? 3.0;
  }
}
