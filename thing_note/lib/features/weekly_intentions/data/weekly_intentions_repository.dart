import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';
import 'package:thing_note/features/weekly_intentions/domain/weekly_intention.dart';

final weeklyIntentionsRepositoryProvider = Provider<WeeklyIntentionsRepository>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return WeeklyIntentionsRepository(dbAsync);
});

final weeklyIntentionsProvider = StateNotifierProvider<WeeklyIntentionsNotifier, AsyncValue<List<WeeklyIntention>>>((ref) {
  final repository = ref.watch(weeklyIntentionsRepositoryProvider);
  return WeeklyIntentionsNotifier(repository);
});

final currentWeekIntentionProvider = FutureProvider<WeeklyIntention?>((ref) async {
  final repository = ref.watch(weeklyIntentionsRepositoryProvider);
  return repository.getIntentionForWeek(DateTime.now());
});

class WeeklyIntentionsRepository {
  final AsyncValue<Database> _dbAsync;

  WeeklyIntentionsRepository(this._dbAsync);

  Future<Database> get _db async {
    final db = _dbAsync.value;
    if (db == null) throw Exception('Database not initialized');
    return db;
  }

  String _getWeekStart(DateTime date) {
    final weekday = date.weekday;
    final monday = date.subtract(Duration(days: weekday - 1));
    return '${monday.year}-${monday.month.toString().padLeft(2, '0')}-${monday.day.toString().padLeft(2, '0')}';
  }

  Future<int> insertIntention(WeeklyIntention intention) async {
    final db = await _db;
    return db.insert('weekly_intentions', intention.toMap());
  }

  Future<int> updateIntention(WeeklyIntention intention) async {
    final db = await _db;
    return db.update(
      'weekly_intentions',
      intention.toMap(),
      where: 'id = ?',
      whereArgs: [intention.id],
    );
  }

  Future<int> deleteIntention(int id) async {
    final db = await _db;
    return db.delete('weekly_intentions', where: 'id = ?', whereArgs: [id]);
  }

  Future<WeeklyIntention?> getIntentionForWeek(DateTime date) async {
    final db = await _db;
    final weekStart = _getWeekStart(date);
    final maps = await db.query(
      'weekly_intentions',
      where: 'week_start = ?',
      whereArgs: [weekStart],
    );
    if (maps.isEmpty) return null;
    return WeeklyIntention.fromMap(maps.first);
  }

  Future<List<WeeklyIntention>> getRecentIntentions(int weeks) async {
    final db = await _db;
    final maps = await db.query(
      'weekly_intentions',
      orderBy: 'week_start DESC',
      limit: weeks,
    );
    return maps.map((m) => WeeklyIntention.fromMap(m)).toList();
  }

  Future<List<WeeklyIntention>> getIntentionsWithThemeContinuation() async {
    final db = await _db;
    final maps = await db.query(
      'weekly_intentions',
      where: 'theme_continuation > 0',
      orderBy: 'week_start DESC',
    );
    return maps.map((m) => WeeklyIntention.fromMap(m)).toList();
  }

  Future<Map<String, dynamic>> getStats() async {
    final db = await _db;
    final totalWeeks = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM weekly_intentions'),
    ) ?? 0;
    final themes = await db.rawQuery(
      'SELECT COUNT(DISTINCT week_theme) FROM weekly_intentions WHERE week_theme IS NOT NULL',
    );
    return {
      'total_weeks': totalWeeks,
      'unique_themes': themes.first.values.first ?? 0,
    };
  }
}

class WeeklyIntentionsNotifier extends StateNotifier<AsyncValue<List<WeeklyIntention>>> {
  final WeeklyIntentionsRepository _repository;

  WeeklyIntentionsNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadIntentions();
  }

  Future<void> loadIntentions() async {
    state = const AsyncValue.loading();
    try {
      final intentions = await _repository.getRecentIntentions(12);
      state = AsyncValue.data(intentions);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addIntention(WeeklyIntention intention) async {
    try {
      await _repository.insertIntention(intention);
      await loadIntentions();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateIntention(WeeklyIntention intention) async {
    try {
      await _repository.updateIntention(intention);
      await loadIntentions();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteIntention(int id) async {
    try {
      await _repository.deleteIntention(id);
      await loadIntentions();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}