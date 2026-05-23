import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';
import 'package:thing_note/features/celebration_tracker/domain/celebration.dart';

final celebrationTrackerRepositoryProvider = Provider<CelebrationTrackerRepository>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return CelebrationTrackerRepository(dbAsync);
});

final celebrationsProvider = StateNotifierProvider<CelebrationsNotifier, AsyncValue<List<Celebration>>>((ref) {
  final repository = ref.watch(celebrationTrackerRepositoryProvider);
  return CelebrationsNotifier(repository);
});

final recentCelebrationsProvider = FutureProvider<List<Celebration>>((ref) async {
  final repository = ref.watch(celebrationTrackerRepositoryProvider);
  return repository.getRecentCelebrations(30);
});

final celebrationStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repository = ref.watch(celebrationTrackerRepositoryProvider);
  return repository.getStats();
});

class CelebrationTrackerRepository {
  final AsyncValue<Database> _dbAsync;

  CelebrationTrackerRepository(this._dbAsync);

  Future<Database> get _db async {
    final db = _dbAsync.value;
    if (db == null) throw Exception('Database not initialized');
    return db;
  }

  Future<int> insertCelebration(Celebration celebration) async {
    final db = await _db;
    return db.insert('celebrations', celebration.toMap());
  }

  Future<int> updateCelebration(Celebration celebration) async {
    final db = await _db;
    return db.update('celebrations', celebration.toMap(), where: 'id = ?', whereArgs: [celebration.id]);
  }

  Future<int> deleteCelebration(int id) async {
    final db = await _db;
    return db.delete('celebrations', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Celebration>> getRecentCelebrations(int days) async {
    final db = await _db;
    final startDate = DateTime.now().subtract(Duration(days: days));
    final maps = await db.query(
      'celebrations',
      where: 'achieved_at >= ?',
      whereArgs: [startDate.toIso8601String()],
      orderBy: 'achieved_at DESC',
    );
    return maps.map((m) => Celebration.fromMap(m)).toList();
  }

  Future<List<Celebration>> getCelebrationsByType(String type) async {
    final db = await _db;
    final maps = await db.query(
      'celebrations',
      where: 'celebration_type = ?',
      whereArgs: [type],
      orderBy: 'achieved_at DESC',
    );
    return maps.map((m) => Celebration.fromMap(m)).toList();
  }

  Future<List<Celebration>> getSharedCelebrations() async {
    final db = await _db;
    final maps = await db.query(
      'celebrations',
      where: 'shared = 1',
      orderBy: 'achieved_at DESC',
    );
    return maps.map((m) => Celebration.fromMap(m)).toList();
  }

  Future<Map<String, dynamic>> getStats() async {
    final db = await _db;
    final totalCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM celebrations'),
    ) ?? 0;
    
    final sharedCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM celebrations WHERE shared = 1'),
    ) ?? 0;
    
    final thisWeek = await _getThisWeekCount();
    final thisMonth = await _getThisMonthCount();
    
    final typeDistribution = <String, int>{};
    for (final type in Celebration.celebrationTypes) {
      typeDistribution[type] = Sqflite.firstIntValue(
        await db.rawQuery(
          'SELECT COUNT(*) FROM celebrations WHERE celebration_type = ?',
          [type],
        ),
      ) ?? 0;
    }
    
    return {
      'total_count': totalCount,
      'shared_count': sharedCount,
      'this_week': thisWeek,
      'this_month': thisMonth,
      'type_distribution': typeDistribution,
    };
  }

  Future<int> _getThisWeekCount() async {
    final db = await _db;
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    return Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM celebrations WHERE achieved_at >= ?',
        [DateTime(weekStart.year, weekStart.month, weekStart.day).toIso8601String()],
      ),
    ) ?? 0;
  }

  Future<int> _getThisMonthCount() async {
    final db = await _db;
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    return Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM celebrations WHERE achieved_at >= ?',
        [monthStart.toIso8601String()],
      ),
    ) ?? 0;
  }

  Future<bool> checkBadgeUnlock(String badgeId) async {
    final db = await _db;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM celebrations'),
    ) ?? 0;
    
    final badge = Celebration.badgeDefinitions.firstWhere(
      (b) => b['id'] == badgeId,
      orElse: () => {'requirement': 0},
    );
    
    return count >= (badge['requirement'] as int);
  }

  Future<List<String>> getUnlockedBadges() async {
    final db = await _db;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM celebrations'),
    ) ?? 0;
    
    return Celebration.badgeDefinitions
        .where((b) => count >= (b['requirement'] as int))
        .map((b) => b['id'] as String)
        .toList();
  }
}

class CelebrationsNotifier extends StateNotifier<AsyncValue<List<Celebration>>> {
  final CelebrationTrackerRepository _repository;

  CelebrationsNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadCelebrations();
  }

  Future<void> loadCelebrations() async {
    state = const AsyncValue.loading();
    try {
      final celebrations = await _repository.getRecentCelebrations(30);
      state = AsyncValue.data(celebrations);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addCelebration(Celebration celebration) async {
    try {
      await _repository.insertCelebration(celebration);
      await loadCelebrations();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> shareCelebration(int id) async {
    try {
      final celebrations = state.value ?? [];
      final celebration = celebrations.firstWhere((c) => c.id == id);
      final updated = celebration.copyWith(shared: 1);
      await _repository.updateCelebration(updated);
      await loadCelebrations();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteCelebration(int id) async {
    try {
      await _repository.deleteCelebration(id);
      await loadCelebrations();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}