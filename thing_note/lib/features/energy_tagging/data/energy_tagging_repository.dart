import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';
import 'package:thing_note/features/energy_tagging/domain/energy_tag.dart';

final energyTaggingRepositoryProvider = Provider<EnergyTaggingRepository>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return EnergyTaggingRepository(dbAsync);
});

final activityEnergyTagsProvider = StateNotifierProvider<ActivityEnergyTagsNotifier, AsyncValue<List<ActivityEnergyTag>>>((ref) {
  final repository = ref.watch(energyTaggingRepositoryProvider);
  return ActivityEnergyTagsNotifier(repository);
});

final energyConsumptionStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repository = ref.watch(energyTaggingRepositoryProvider);
  return repository.getConsumptionStats();
});

class EnergyTaggingRepository {
  final AsyncValue<Database> _dbAsync;

  EnergyTaggingRepository(this._dbAsync);

  Future<Database> get _db async {
    final db = _dbAsync.value;
    if (db == null) throw Exception('Database not initialized');
    return db;
  }

  Future<int> insertTag(ActivityEnergyTag tag) async {
    final db = await _db;
    return db.insert('activity_energy_tags', tag.toMap());
  }

  Future<int> updateTag(ActivityEnergyTag tag) async {
    final db = await _db;
    return db.update('activity_energy_tags', tag.toMap(), where: 'id = ?', whereArgs: [tag.id]);
  }

  Future<int> deleteTag(int id) async {
    final db = await _db;
    return db.delete('activity_energy_tags', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<ActivityEnergyTag>> getAllTags() async {
    final db = await _db;
    final maps = await db.query('activity_energy_tags', orderBy: 'usage_count DESC');
    return maps.map((m) => ActivityEnergyTag.fromMap(m)).toList();
  }

  Future<ActivityEnergyTag?> getTagByActivity(String activityName) async {
    final db = await _db;
    final maps = await db.query(
      'activity_energy_tags',
      where: 'activity_name = ?',
      whereArgs: [activityName],
    );
    if (maps.isEmpty) return null;
    return ActivityEnergyTag.fromMap(maps.first);
  }

  Future<void> incrementUsage(int tagId) async {
    final db = await _db;
    await db.rawUpdate(
      'UPDATE activity_energy_tags SET usage_count = usage_count + 1 WHERE id = ?',
      [tagId],
    );
  }

  Future<Map<String, dynamic>> getConsumptionStats() async {
    final db = await _db;
    final totalActivities = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM activity_energy_tags'),
    ) ?? 0;
    
    final drainingActivities = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM activity_energy_tags WHERE energy_level >= 3 AND is_recharging = 0',
      ),
    ) ?? 0;
    
    final rechargingActivities = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM activity_energy_tags WHERE is_recharging = 1',
      ),
    ) ?? 0;
    
    final avgEnergy = await db.rawQuery(
      'SELECT AVG(energy_level) as avg FROM activity_energy_tags',
    );
    
    return {
      'total_activities': totalActivities,
      'draining_activities': drainingActivities,
      'recharging_activities': rechargingActivities,
      'average_energy': avgEnergy.first['avg'] ?? 0,
    };
  }

  Future<List<ActivityEnergyTag>> getHighConsumptionActivities() async {
    final db = await _db;
    final maps = await db.query(
      'activity_energy_tags',
      where: 'energy_level >= 4',
      orderBy: 'usage_count DESC',
    );
    return maps.map((m) => ActivityEnergyTag.fromMap(m)).toList();
  }

  Future<List<ActivityEnergyTag>> getRechargingActivities() async {
    final db = await _db;
    final maps = await db.query(
      'activity_energy_tags',
      where: 'is_recharging = 1',
      orderBy: 'usage_count DESC',
    );
    return maps.map((m) => ActivityEnergyTag.fromMap(m)).toList();
  }

  static const List<Map<String, dynamic>> defaultTags = [
    {'name': '工作', 'level': 4, 'recharging': 0},
    {'name': '学习', 'level': 4, 'recharging': 0},
    {'name': '运动', 'level': 5, 'recharging': 0},
    {'name': '冥想', 'level': 1, 'recharging': 1},
    {'name': '散步', 'level': 2, 'recharging': 1},
    {'name': '阅读', 'level': 2, 'recharging': 1},
    {'name': '社交', 'level': 3, 'recharging': 0},
    {'name': '睡眠', 'level': 1, 'recharging': 1},
  ];
}

class ActivityEnergyTagsNotifier extends StateNotifier<AsyncValue<List<ActivityEnergyTag>>> {
  final EnergyTaggingRepository _repository;

  ActivityEnergyTagsNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadTags();
  }

  Future<void> loadTags() async {
    state = const AsyncValue.loading();
    try {
      final tags = await _repository.getAllTags();
      state = AsyncValue.data(tags);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addTag(ActivityEnergyTag tag) async {
    try {
      await _repository.insertTag(tag);
      await loadTags();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateTag(ActivityEnergyTag tag) async {
    try {
      await _repository.updateTag(tag);
      await loadTags();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteTag(int id) async {
    try {
      await _repository.deleteTag(id);
      await loadTags();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}