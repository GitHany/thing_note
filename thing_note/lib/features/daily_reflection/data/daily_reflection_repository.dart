import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';
import 'package:thing_note/features/daily_reflection/domain/daily_reflection.dart';

final dailyReflectionRepositoryProvider = Provider<DailyReflectionRepository>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return DailyReflectionRepository(dbAsync);
});

final dailyReflectionsProvider = StateNotifierProvider<DailyReflectionsNotifier, AsyncValue<List<DailyReflection>>>((ref) {
  final repository = ref.watch(dailyReflectionRepositoryProvider);
  return DailyReflectionsNotifier(repository);
});

final todayReflectionProvider = FutureProvider<DailyReflection?>((ref) async {
  final repository = ref.watch(dailyReflectionRepositoryProvider);
  return repository.getReflectionByDate(DateTime.now());
});

class DailyReflectionRepository {
  final AsyncValue<Database> _dbAsync;

  DailyReflectionRepository(this._dbAsync);

  Future<Database> get _db async {
    final db = _dbAsync.value;
    if (db == null) throw Exception('Database not initialized');
    return db;
  }

  Future<int> insertReflection(DailyReflection reflection) async {
    final db = await _db;
    return db.insert('daily_reflections', reflection.toMap());
  }

  Future<int> updateReflection(DailyReflection reflection) async {
    final db = await _db;
    return db.update(
      'daily_reflections',
      reflection.toMap(),
      where: 'id = ?',
      whereArgs: [reflection.id],
    );
  }

  Future<int> deleteReflection(int id) async {
    final db = await _db;
    return db.delete('daily_reflections', where: 'id = ?', whereArgs: [id]);
  }

  Future<DailyReflection?> getReflectionByDate(DateTime date) async {
    final db = await _db;
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final maps = await db.query(
      'daily_reflections',
      where: 'date LIKE ?',
      whereArgs: ['$dateStr%'],
    );
    if (maps.isEmpty) return null;
    return DailyReflection.fromMap(maps.first);
  }

  Future<List<DailyReflection>> getReflectionsRange(DateTime start, DateTime end) async {
    final db = await _db;
    final maps = await db.query(
      'daily_reflections',
      where: 'date >= ? AND date <= ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'date DESC',
    );
    return maps.map((m) => DailyReflection.fromMap(m)).toList();
  }

  Future<List<DailyReflection>> getRecentReflections(int days) async {
    final end = DateTime.now();
    final start = end.subtract(Duration(days: days));
    return getReflectionsRange(start, end);
  }

  Future<Map<String, dynamic>> getReflectionStats() async {
    final db = await _db;
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    
    final totalCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM daily_reflections'),
    ) ?? 0;
    
    final monthCount = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM daily_reflections WHERE date >= ?',
        [monthStart.toIso8601String()],
      ),
    ) ?? 0;
    
    return {
      'total_reflections': totalCount,
      'month_reflections': monthCount,
    };
  }
}

class DailyReflectionsNotifier extends StateNotifier<AsyncValue<List<DailyReflection>>> {
  final DailyReflectionRepository _repository;

  DailyReflectionsNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadReflections();
  }

  Future<void> loadReflections() async {
    state = const AsyncValue.loading();
    try {
      final reflections = await _repository.getRecentReflections(30);
      state = AsyncValue.data(reflections);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addReflection(DailyReflection reflection) async {
    try {
      await _repository.insertReflection(reflection);
      await loadReflections();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateReflection(DailyReflection reflection) async {
    try {
      await _repository.updateReflection(reflection);
      await loadReflections();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteReflection(int id) async {
    try {
      await _repository.deleteReflection(id);
      await loadReflections();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}