import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';
import 'package:thing_note/features/scene_mode/domain/scene_mode.dart';

final sceneModeRepositoryProvider = Provider<SceneModeRepository>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return SceneModeRepository(dbAsync);
});

class SceneModeRepository {
  final AsyncValue<Database> _dbAsync;

  SceneModeRepository(this._dbAsync);

  Future<Database> get _db async {
    final db = _dbAsync.value;
    if (db == null) throw Exception('Database not initialized');
    return db;
  }

  Future<void> initializeDefaultScenes() async {
    final db = await _db;
    final existing = await db.query('scene_modes', limit: 1);
    
    if (existing.isEmpty) {
      final batch = db.batch();
      for (final scene in SceneMode.defaultScenes) {
        batch.insert('scene_modes', scene.toMap()..remove('id'));
      }
      await batch.commit(noResult: true);
    }
  }

  Future<List<SceneMode>> getAllScenes() async {
    final db = await _db;
    await initializeDefaultScenes();
    
    final result = await db.query(
      'scene_modes',
      orderBy: 'created_at ASC',
    );
    return result.map((map) => SceneMode.fromMap(map)).toList();
  }

  Future<SceneMode?> getActiveScene() async {
    final db = await _db;
    final result = await db.query(
      'scene_modes',
      where: 'is_active = ?',
      whereArgs: [1],
      limit: 1,
    );
    
    if (result.isEmpty) return null;
    return SceneMode.fromMap(result.first);
  }

  Future<void> setActiveScene(int sceneId) async {
    final db = await _db;
    
    await db.update(
      'scene_modes',
      {'is_active': 0},
    );
    
    await db.update(
      'scene_modes',
      {'is_active': 1},
      where: 'id = ?',
      whereArgs: [sceneId],
    );
    
    await db.insert('scene_switch_history', {
      'scene_id': sceneId,
      'switched_at': DateTime.now().toIso8601String(),
      'trigger_type': 'manual',
    });
  }

  Future<void> deactivateScene() async {
    final db = await _db;
    await db.update(
      'scene_modes',
      {'is_active': 0},
    );
  }

  Future<int> insertScene(SceneMode scene) async {
    final db = await _db;
    return await db.insert('scene_modes', scene.toMap()..remove('id'));
  }

  Future<void> updateScene(SceneMode scene) async {
    final db = await _db;
    await db.update(
      'scene_modes',
      scene.toMap(),
      where: 'id = ?',
      whereArgs: [scene.id],
    );
  }

  Future<void> deleteScene(int id) async {
    final db = await _db;
    await db.delete(
      'scene_modes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<SceneSwitchHistory>> getSwitchHistory({int limit = 20}) async {
    final db = await _db;
    final result = await db.query(
      'scene_switch_history',
      orderBy: 'switched_at DESC',
      limit: limit,
    );
    return result.map((map) => SceneSwitchHistory.fromMap(map)).toList();
  }
}
