import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/travel_log/domain/travel_log.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';

final travelLogRepositoryProvider = Provider<TravelLogRepository>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return TravelLogRepository(dbAsync);
});

final travelLogsProvider = StateNotifierProvider<TravelLogsNotifier, AsyncValue<List<TravelLog>>>((ref) {
  final repository = ref.watch(travelLogRepositoryProvider);
  return TravelLogsNotifier(repository);
});

final favoriteTravelLogsProvider = Provider<AsyncValue<List<TravelLog>>>((ref) {
  final logs = ref.watch(travelLogsProvider);
  return logs.whenData((list) => list.where((l) => l.isFavorite).toList());
});

class TravelLogRepository {
  final AsyncValue<Database> _dbAsync;

  TravelLogRepository(this._dbAsync);

  Future<Database> get _db async {
    final db = _dbAsync.value;
    if (db == null) throw Exception('Database not initialized');
    return db;
  }

  Future<int> insertTravelLog(TravelLog log) async {
    final db = await _db;
    return db.insert('travel_logs', log.toMap());
  }

  Future<int> updateTravelLog(TravelLog log) async {
    final db = await _db;
    return db.update(
      'travel_logs',
      log.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [log.id],
    );
  }

  Future<int> deleteTravelLog(int id) async {
    final db = await _db;
    return db.delete('travel_logs', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<TravelLog>> getAllTravelLogs() async {
    final db = await _db;
    final maps = await db.query('travel_logs', orderBy: 'start_date DESC');
    return maps.map((m) => TravelLog.fromMap(m)).toList();
  }

  Future<List<TravelLog>> getTravelLogsByYear(int year) async {
    final db = await _db;
    final startOfYear = DateTime(year, 1, 1).toIso8601String();
    final endOfYear = DateTime(year, 12, 31, 23, 59, 59).toIso8601String();
    final maps = await db.query(
      'travel_logs',
      where: 'start_date >= ? AND start_date <= ?',
      whereArgs: [startOfYear, endOfYear],
      orderBy: 'start_date DESC',
    );
    return maps.map((m) => TravelLog.fromMap(m)).toList();
  }

  Future<int> toggleFavorite(int id, bool isFavorite) async {
    final db = await _db;
    return db.update(
      'travel_logs',
      {'is_favorite': isFavorite ? 1 : 0, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

class TravelLogsNotifier extends StateNotifier<AsyncValue<List<TravelLog>>> {
  final TravelLogRepository _repository;

  TravelLogsNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadTravelLogs();
  }

  Future<void> loadTravelLogs() async {
    state = const AsyncValue.loading();
    try {
      final logs = await _repository.getAllTravelLogs();
      state = AsyncValue.data(logs);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addTravelLog(TravelLog log) async {
    try {
      await _repository.insertTravelLog(log);
      await loadTravelLogs();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateTravelLog(TravelLog log) async {
    try {
      await _repository.updateTravelLog(log);
      await loadTravelLogs();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteTravelLog(int id) async {
    try {
      await _repository.deleteTravelLog(id);
      await loadTravelLogs();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> toggleFavorite(int id, bool isFavorite) async {
    try {
      await _repository.toggleFavorite(id, isFavorite);
      await loadTravelLogs();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}