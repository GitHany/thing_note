import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';
import 'package:thing_note/features/sensory_journal/domain/sensory_record.dart';

final sensoryJournalRepositoryProvider = Provider<SensoryJournalRepository>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return SensoryJournalRepository(dbAsync);
});

final sensoryRecordsProvider = StateNotifierProvider<SensoryRecordsNotifier, AsyncValue<List<SensoryRecord>>>((ref) {
  final repository = ref.watch(sensoryJournalRepositoryProvider);
  return SensoryRecordsNotifier(repository);
});

final todaySensoryRecordProvider = FutureProvider<SensoryRecord?>((ref) async {
  final repository = ref.watch(sensoryJournalRepositoryProvider);
  return repository.getRecordByDate(DateTime.now());
});

class SensoryJournalRepository {
  final AsyncValue<Database> _dbAsync;

  SensoryJournalRepository(this._dbAsync);

  Future<Database> get _db async {
    final db = _dbAsync.value;
    if (db == null) throw Exception('Database not initialized');
    return db;
  }

  Future<int> insertRecord(SensoryRecord record) async {
    final db = await _db;
    return db.insert('sensory_records', record.toMap());
  }

  Future<int> updateRecord(SensoryRecord record) async {
    final db = await _db;
    return db.update('sensory_records', record.toMap(), where: 'id = ?', whereArgs: [record.id]);
  }

  Future<int> deleteRecord(int id) async {
    final db = await _db;
    return db.delete('sensory_records', where: 'id = ?', whereArgs: [id]);
  }

  Future<SensoryRecord?> getRecordByDate(DateTime date) async {
    final db = await _db;
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final maps = await db.query(
      'sensory_records',
      where: 'recorded_at LIKE ?',
      whereArgs: ['$dateStr%'],
    );
    if (maps.isEmpty) return null;
    return SensoryRecord.fromMap(maps.first);
  }

  Future<List<SensoryRecord>> getRecentRecords(int days) async {
    final db = await _db;
    final startDate = DateTime.now().subtract(Duration(days: days));
    final maps = await db.query(
      'sensory_records',
      where: 'recorded_at >= ?',
      whereArgs: [startDate.toIso8601String()],
      orderBy: 'recorded_at DESC',
    );
    return maps.map((m) => SensoryRecord.fromMap(m)).toList();
  }

  Future<List<SensoryRecord>> getRecordsRange(DateTime start, DateTime end) async {
    final db = await _db;
    final maps = await db.query(
      'sensory_records',
      where: 'recorded_at >= ? AND recorded_at <= ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'recorded_at DESC',
    );
    return maps.map((m) => SensoryRecord.fromMap(m)).toList();
  }

  Future<Map<String, dynamic>> getStats() async {
    final db = await _db;
    final totalRecords = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM sensory_records'),
    ) ?? 0;
    
    final avgMood = await db.rawQuery(
      'SELECT AVG(mood_score) as avg FROM sensory_records',
    );
    
    return {
      'total_records': totalRecords,
      'average_mood': avgMood.first['avg'] ?? 0,
    };
  }

  Future<Map<String, int>> getSenseDistribution() async {
    final db = await _db;
    final distribution = <String, int>{};
    
    for (final sense in SensoryRecord.senseLabels.keys) {
      final field = '${sense}_environment';
      final count = Sqflite.firstIntValue(
        await db.rawQuery(
          'SELECT COUNT(*) FROM sensory_records WHERE $field IS NOT NULL AND $field != ""',
        ),
      ) ?? 0;
      distribution[sense] = count;
    }
    
    return distribution;
  }

  Future<List<Map<String, dynamic>>> getOptimalEnvironments() async {
    final db = await _db;
    final result = await db.rawQuery('''
      SELECT 
        visual_environment,
        auditory_environment,
        AVG(mood_score) as avg_mood,
        COUNT(*) as record_count
      FROM sensory_records
      WHERE mood_score IS NOT NULL
      GROUP BY visual_environment, auditory_environment
      HAVING record_count >= 3
      ORDER BY avg_mood DESC
      LIMIT 10
    ''');
    return result;
  }
}

class SensoryRecordsNotifier extends StateNotifier<AsyncValue<List<SensoryRecord>>> {
  final SensoryJournalRepository _repository;

  SensoryRecordsNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadRecords();
  }

  Future<void> loadRecords() async {
    state = const AsyncValue.loading();
    try {
      final records = await _repository.getRecentRecords(30);
      state = AsyncValue.data(records);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addRecord(SensoryRecord record) async {
    try {
      await _repository.insertRecord(record);
      await loadRecords();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateRecord(SensoryRecord record) async {
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
}