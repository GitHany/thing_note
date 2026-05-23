import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';
import 'package:thing_note/features/location_history/domain/location_entry.dart';

final locationHistoryRepositoryProvider = Provider<LocationHistoryRepository>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return LocationHistoryRepository(dbAsync);
});

class LocationHistoryRepository {
  final AsyncValue<Database> _dbAsync;

  LocationHistoryRepository(this._dbAsync);

  Future<Database> get _db async {
    final db = _dbAsync.value;
    if (db == null) throw Exception('Database not initialized');
    return db;
  }

  Future<int> insert(LocationEntry entry) async {
    final db = await _db;
    return await db.insert('location_history', entry.toMap());
  }

  Future<List<LocationEntry>> getRecent(int limit) async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      'location_history',
      orderBy: 'recorded_at DESC',
      limit: limit,
    );
    return maps.map((map) => LocationEntry.fromMap(map)).toList();
  }

  Future<List<LocationEntry>> getByDateRange(DateTime start, DateTime end) async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      'location_history',
      where: 'recorded_at >= ? AND recorded_at <= ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'recorded_at DESC',
    );
    return maps.map((map) => LocationEntry.fromMap(map)).toList();
  }

  Future<int> delete(int id) async {
    final db = await _db;
    return await db.delete(
      'location_history',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<Map<String, int>> getPlaceFrequency(int days) async {
    final db = await _db;
    final result = await db.rawQuery('''
      SELECT place_name, COUNT(*) as count FROM location_history
      WHERE recorded_at >= datetime('now', '-$days days')
      GROUP BY place_name
      ORDER BY count DESC
      LIMIT 10
    ''');

    final Map<String, int> frequency = {};
    for (final row in result) {
      final placeName = row['place_name'] as String?;
      if (placeName != null && placeName.isNotEmpty) {
        frequency[placeName] = row['count'] as int? ?? 0;
      }
    }
    return frequency;
  }
}
