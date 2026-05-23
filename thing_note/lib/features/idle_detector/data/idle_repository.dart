import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import '../../../core/database/database_provider.dart';
import '../domain/idle_models.dart';

final idleRepositoryProvider = Provider<IdleRepository>((ref) {
  return IdleRepository(ref.watch(databaseProvider).value!);
});

class IdleRepository {
  final Database _db;

  IdleRepository(this._db);

  Future<int> insert(IdleTimeRecord record) async {
    return await _db.insert('idle_time_records', record.toMap());
  }

  Future<List<IdleTimeRecord>> getAll() async {
    final maps = await _db.query('idle_time_records', orderBy: 'started_at DESC');
    return maps.map((m) => IdleTimeRecord.fromMap(m)).toList();
  }

  Future<IdleTimeRecord?> getActive() async {
    final maps = await _db.query(
      'idle_time_records',
      where: 'ended_at IS NULL',
      orderBy: 'started_at DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return IdleTimeRecord.fromMap(maps.first);
  }

  Future<int> update(IdleTimeRecord record) async {
    return await _db.update(
      'idle_time_records',
      record.toMap(),
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }

  Future<Map<String, dynamic>> getIdleStats({int days = 7}) async {
    final startDate = DateTime.now().subtract(Duration(days: days));
    final result = await _db.rawQuery('''
      SELECT 
        COUNT(*) as total_records,
        SUM(duration_minutes) as total_minutes,
        AVG(duration_minutes) as avg_minutes,
        SUM(CASE WHEN is_productive = 1 THEN duration_minutes ELSE 0 END) as productive_minutes,
        SUM(CASE WHEN is_productive = 0 THEN duration_minutes ELSE 0 END) as unproductive_minutes
      FROM idle_time_records
      WHERE started_at >= ?
    ''', [startDate.toIso8601String()]);
    return result.first;
  }
}