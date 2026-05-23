import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/sleep_tracker/domain/sleep_record.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';

final sleepRepositoryProvider = Provider<SleepRepository>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return SleepRepository(dbAsync);
});

final sleepRecordsProvider = StateNotifierProvider<SleepRecordsNotifier, AsyncValue<List<SleepRecord>>>((ref) {
  final repository = ref.watch(sleepRepositoryProvider);
  return SleepRecordsNotifier(repository);
});

final sleepStatsProvider = FutureProvider<SleepStats>((ref) async {
  final repository = ref.watch(sleepRepositoryProvider);
  return repository.getSleepStats();
});

class SleepRepository {
  final AsyncValue<Database> _dbAsync;

  SleepRepository(this._dbAsync);

  Future<Database> get _db async {
    final db = _dbAsync.value;
    if (db == null) throw Exception('Database not initialized');
    return db;
  }

  Future<int> insertSleepRecord(SleepRecord record) async {
    final db = await _db;
    return db.insert('sleep_records', record.toMap());
  }

  Future<int> updateSleepRecord(SleepRecord record) async {
    final db = await _db;
    return db.update('sleep_records', record.toMap(), where: 'id = ?', whereArgs: [record.id]);
  }

  Future<int> deleteSleepRecord(int id) async {
    final db = await _db;
    return db.delete('sleep_records', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<SleepRecord>> getAllRecords() async {
    final db = await _db;
    final maps = await db.query('sleep_records', orderBy: 'date DESC');
    return maps.map((m) => SleepRecord.fromMap(m)).toList();
  }

  Future<SleepRecord?> getRecordForDate(String date) async {
    final db = await _db;
    final maps = await db.query('sleep_records', where: 'date = ?', whereArgs: [date]);
    if (maps.isEmpty) return null;
    return SleepRecord.fromMap(maps.first);
  }

  Future<List<SleepRecord>> getRecordsForRange(String startDate, String endDate) async {
    final db = await _db;
    final maps = await db.query(
      'sleep_records',
      where: 'date >= ? AND date <= ?',
      whereArgs: [startDate, endDate],
      orderBy: 'date DESC',
    );
    return maps.map((m) => SleepRecord.fromMap(m)).toList();
  }

  Future<SleepStats> getSleepStats() async {
    final db = await _db;
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final startDate = '${monthStart.year}-${monthStart.month.toString().padLeft(2, '0')}-01';

    final result = await db.rawQuery('''
      SELECT 
        AVG(duration_minutes) as avg_duration,
        AVG(quality) as avg_quality,
        COUNT(*) as total
      FROM sleep_records 
      WHERE date >= ?
    ''', [startDate]);

    final qualityResult = await db.rawQuery('''
      SELECT COUNT(*) as count FROM sleep_records 
      WHERE date >= ? AND quality >= 4
    ''', [startDate]);

    if (result.isEmpty || result.first['avg_duration'] == null) {
      return const SleepStats();
    }

    return SleepStats(
      avgDuration: (result.first['avg_duration'] as num).toDouble(),
      avgQuality: (result.first['avg_quality'] as num?)?.toDouble() ?? 0,
      totalNights: result.first['total'] as int? ?? 0,
      goodNights: qualityResult.first['count'] as int? ?? 0,
    );
  }
}

class SleepRecordsNotifier extends StateNotifier<AsyncValue<List<SleepRecord>>> {
  final SleepRepository _repository;

  SleepRecordsNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadRecords();
  }

  Future<void> loadRecords() async {
    state = const AsyncValue.loading();
    try {
      final records = await _repository.getAllRecords();
      state = AsyncValue.data(records);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addRecord(SleepRecord record) async {
    try {
      await _repository.insertSleepRecord(record);
      await loadRecords();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteRecord(int id) async {
    try {
      await _repository.deleteSleepRecord(id);
      await loadRecords();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}