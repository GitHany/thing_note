import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';
import 'package:thing_note/features/distraction_tracker/domain/distraction_record.dart';

final distractionTrackerRepositoryProvider = Provider<DistractionTrackerRepository>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return DistractionTrackerRepository(dbAsync);
});

final distractionRecordsProvider = StateNotifierProvider<DistractionRecordsNotifier, AsyncValue<List<DistractionRecord>>>((ref) {
  final repository = ref.watch(distractionTrackerRepositoryProvider);
  return DistractionRecordsNotifier(repository);
});

final todayDistractionsProvider = FutureProvider<List<DistractionRecord>>((ref) async {
  final repository = ref.watch(distractionTrackerRepositoryProvider);
  return repository.getRecordsByDate(DateTime.now());
});

final distractionStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repository = ref.watch(distractionTrackerRepositoryProvider);
  return repository.getStats();
});

class DistractionTrackerRepository {
  final AsyncValue<Database> _dbAsync;

  DistractionTrackerRepository(this._dbAsync);

  Future<Database> get _db async {
    final db = _dbAsync.value;
    if (db == null) throw Exception('Database not initialized');
    return db;
  }

  Future<int> insertRecord(DistractionRecord record) async {
    final db = await _db;
    return db.insert('distraction_records', record.toMap());
  }

  Future<int> updateRecord(DistractionRecord record) async {
    final db = await _db;
    return db.update('distraction_records', record.toMap(), where: 'id = ?', whereArgs: [record.id]);
  }

  Future<int> deleteRecord(int id) async {
    final db = await _db;
    return db.delete('distraction_records', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<DistractionRecord>> getRecordsByDate(DateTime date) async {
    final db = await _db;
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final maps = await db.query(
      'distraction_records',
      where: 'distraction_date LIKE ?',
      whereArgs: ['$dateStr%'],
      orderBy: 'created_at DESC',
    );
    return maps.map((m) => DistractionRecord.fromMap(m)).toList();
  }

  Future<List<DistractionRecord>> getRecordsRange(DateTime start, DateTime end) async {
    final db = await _db;
    final maps = await db.query(
      'distraction_records',
      where: 'distraction_date >= ? AND distraction_date <= ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'distraction_date DESC',
    );
    return maps.map((m) => DistractionRecord.fromMap(m)).toList();
  }

  Future<List<DistractionRecord>> getRecentRecords(int days) async {
    final end = DateTime.now();
    final start = end.subtract(Duration(days: days));
    return getRecordsRange(start, end);
  }

  Future<Map<String, dynamic>> getStats() async {
    final db = await _db;
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final weekStart = todayStart.subtract(Duration(days: todayStart.weekday - 1));
    
    final todayCount = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM distraction_records WHERE distraction_date >= ?',
        [todayStart.toIso8601String()],
      ),
    ) ?? 0;
    
    final weekCount = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM distraction_records WHERE distraction_date >= ?',
        [weekStart.toIso8601String()],
      ),
    ) ?? 0;
    
    final todayMinutes = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT SUM(duration_minutes) FROM distraction_records WHERE distraction_date >= ?',
        [todayStart.toIso8601String()],
      ),
    ) ?? 0;
    
    final typeStats = <String, int>{};
    for (final type in DistractionRecord.distractionTypes) {
      typeStats[type] = Sqflite.firstIntValue(
        await db.rawQuery(
          'SELECT COUNT(*) FROM distraction_records WHERE distraction_type = ?',
          [type],
        ),
      ) ?? 0;
    }
    
    return {
      'today_count': todayCount,
      'week_count': weekCount,
      'today_minutes': todayMinutes,
      'type_stats': typeStats,
    };
  }

  Future<List<Map<String, dynamic>>> getTopDistractionSources() async {
    final db = await _db;
    final result = await db.rawQuery('''
      SELECT source, COUNT(*) as count, SUM(duration_minutes) as total_minutes
      FROM distraction_records
      WHERE source IS NOT NULL AND source != ''
      GROUP BY source
      ORDER BY count DESC
      LIMIT 5
    ''');
    return result;
  }
}

class DistractionRecordsNotifier extends StateNotifier<AsyncValue<List<DistractionRecord>>> {
  final DistractionTrackerRepository _repository;

  DistractionRecordsNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadRecords();
  }

  Future<void> loadRecords() async {
    state = const AsyncValue.loading();
    try {
      final records = await _repository.getRecentRecords(7);
      state = AsyncValue.data(records);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addRecord(DistractionRecord record) async {
    try {
      await _repository.insertRecord(record);
      await loadRecords();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateRecord(DistractionRecord record) async {
    try {
      await _repository.updateRecord(record);
      await loadRecords();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteRecord(int id) async {
    try {
      await _repository.deleteRecord(id);
      await loadRecords();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> quickAdd(String type, {String? source, int duration = 5}) async {
    final record = DistractionRecord(
      distractionType: type,
      source: source,
      durationMinutes: duration,
      costEstimate: duration,
      distractionDate: DateTime.now().toIso8601String(),
    );
    await addRecord(record);
  }
}