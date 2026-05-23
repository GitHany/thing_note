import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';

final focusZonesRepositoryProvider = Provider<FocusZonesRepository>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return FocusZonesRepository(dbAsync);
});

class FocusZonesRepository {
  final AsyncValue<Database> _dbAsync;

  FocusZonesRepository(this._dbAsync);

  Future<Database> get _db async {
    final db = _dbAsync.value;
    if (db == null) throw Exception('Database not initialized');
    return db;
  }

  Future<List<Map<String, dynamic>>> getAllZones() async {
    final db = await _db;
    return db.query(
      'focus_zones',
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'created_at DESC',
    );
  }

  Future<int> insertZone(Map<String, dynamic> zone) async {
    final db = await _db;
    return db.insert('focus_zones', zone);
  }

  Future<int> deleteZone(int id) async {
    final db = await _db;
    return db.delete('focus_zones', where: 'id = ?', whereArgs: [id]);
  }
}
