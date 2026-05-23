import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/daily_intention/domain/daily_intention.dart';
import 'package:thing_note/core/database/database_provider.dart';
import 'package:sqflite/sqflite.dart';

final dailyIntentionRepositoryProvider = Provider<DailyIntentionRepository>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return DailyIntentionRepository(dbAsync);
});

final todayIntentionProvider = FutureProvider<DailyIntention?>((ref) async {
  final repo = ref.watch(dailyIntentionRepositoryProvider);
  return repo.getIntentionByDate(_todayDate());
});

String _todayDate() {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
}

class DailyIntentionRepository {
  final AsyncValue<Database> _dbAsync;

  DailyIntentionRepository(this._dbAsync);

  Future<Database> get _db async {
    final db = _dbAsync.value;
    if (db == null) throw Exception('Database not initialized');
    return db;
  }

  Future<int> insertIntention(DailyIntention intention) async {
    final db = await _db;
    return db.insert('daily_intentions', intention.toMap());
  }

  Future<int> updateIntention(DailyIntention intention) async {
    final db = await _db;
    return db.update(
      'daily_intentions',
      intention.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [intention.id],
    );
  }

  Future<int> completeIntention(int id) async {
    final db = await _db;
    return db.update(
      'daily_intentions',
      {
        'is_completed': 1,
        'completed_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<DailyIntention?> getIntentionByDate(String date) async {
    final db = await _db;
    final maps = await db.query('daily_intentions', where: 'date = ?', whereArgs: [date]);
    if (maps.isEmpty) return null;
    return DailyIntention.fromMap(maps.first);
  }

  Future<List<DailyIntention>> getRecentIntentions(int days) async {
    final db = await _db;
    final maps = await db.query('daily_intentions', orderBy: 'date DESC', limit: days);
    return maps.map((m) => DailyIntention.fromMap(m)).toList();
  }

  Future<List<DailyIntention>> getIntentionsForMonth(int year, int month) async {
    final db = await _db;
    final startDate = '$year-${month.toString().padLeft(2, '0')}-01';
    final endDate = '$year-${month.toString().padLeft(2, '0')}-31';
    final maps = await db.query(
      'daily_intentions',
      where: 'date BETWEEN ? AND ?',
      whereArgs: [startDate, endDate],
      orderBy: 'date ASC',
    );
    return maps.map((m) => DailyIntention.fromMap(m)).toList();
  }

  Future<Map<String, int>> getCompletionStats(int year, int month) async {
    final intentions = await getIntentionsForMonth(year, month);
    final completed = intentions.where((i) => i.isCompleted).length;
    return {'total': intentions.length, 'completed': completed};
  }
}
