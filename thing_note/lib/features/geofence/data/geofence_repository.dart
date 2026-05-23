import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/geofence/domain/geofence.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';

final geofenceRepositoryProvider = Provider<GeofenceRepository>((ref) {
  final db = ref.watch(databaseProvider).requireValue;
  return GeofenceRepository(db);
});

class GeofenceRepository {
  final Database _db;

  GeofenceRepository(this._db);

  Future<int> insert(Geofence geofence) async {
    return _db.insert('geofences', geofence.toMap()..remove('id'));
  }

  Future<int> update(Geofence geofence) async {
    return _db.update(
      'geofences',
      geofence.toMap(),
      where: 'id = ?',
      whereArgs: [geofence.id],
    );
  }

  Future<int> delete(int id) async {
    return _db.delete('geofences', where: 'id = ?', whereArgs: [id]);
  }

  Future<Geofence?> getById(int id) async {
    final results = await _db.query(
      'geofences',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (results.isEmpty) return null;
    return Geofence.fromMap(results.first);
  }

  Future<List<Geofence>> getAll() async {
    final results = await _db.query('geofences', orderBy: 'created_at DESC');
    return results.map((e) => Geofence.fromMap(e)).toList();
  }

  Future<List<Geofence>> getEnabled() async {
    final results = await _db.query(
      'geofences',
      where: 'is_enabled = ?',
      whereArgs: [1],
    );
    return results.map((e) => Geofence.fromMap(e)).toList();
  }

  Future<List<Geofence>> getByTriggerType(String triggerType) async {
    final results = await _db.query(
      'geofences',
      where: 'trigger_type = ? AND is_enabled = ?',
      whereArgs: [triggerType, 1],
    );
    return results.map((e) => Geofence.fromMap(e)).toList();
  }
}