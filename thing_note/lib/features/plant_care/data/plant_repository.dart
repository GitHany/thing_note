import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/plant_care/domain/plant.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';

final plantRepositoryProvider = Provider<PlantRepository>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return PlantRepository(dbAsync);
});

final plantsProvider = StateNotifierProvider<PlantsNotifier, AsyncValue<List<Plant>>>((ref) {
  final repository = ref.watch(plantRepositoryProvider);
  return PlantsNotifier(repository);
});

final plantsNeedingWaterProvider = Provider<AsyncValue<List<Plant>>>((ref) {
  final plants = ref.watch(plantsProvider);
  return plants.whenData((list) => list.where((p) => p.needsWater).toList());
});

class PlantRepository {
  final AsyncValue<Database> _dbAsync;

  PlantRepository(this._dbAsync);

  Future<Database> get _db async {
    final db = _dbAsync.value;
    if (db == null) throw Exception('Database not initialized');
    return db;
  }

  Future<int> insertPlant(Plant plant) async {
    final db = await _db;
    return db.insert('plants', plant.toMap());
  }

  Future<int> updatePlant(Plant plant) async {
    final db = await _db;
    return db.update(
      'plants',
      plant.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [plant.id],
    );
  }

  Future<int> deletePlant(int id) async {
    final db = await _db;
    return db.delete('plants', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Plant>> getAllPlants() async {
    final db = await _db;
    final maps = await db.query('plants', orderBy: 'name ASC');
    return maps.map((m) => Plant.fromMap(m)).toList();
  }

  Future<int> waterPlant(int plantId) async {
    final db = await _db;
    return db.update(
      'plants',
      {'last_watered_at': DateTime.now().toIso8601String(), 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [plantId],
    );
  }

  Future<int> fertilizePlant(int plantId) async {
    final db = await _db;
    return db.update(
      'plants',
      {'last_fertilized_at': DateTime.now().toIso8601String(), 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [plantId],
    );
  }

  Future<int> prunePlant(int plantId) async {
    final db = await _db;
    return db.update(
      'plants',
      {'last_pruned_at': DateTime.now().toIso8601String(), 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [plantId],
    );
  }

  Future<List<Plant>> getPlantsNeedingWater() async {
    final db = await _db;
    final maps = await db.query('plants');
    final plants = maps.map((m) => Plant.fromMap(m)).toList();
    return plants.where((p) => p.needsWater).toList();
  }
}

class PlantsNotifier extends StateNotifier<AsyncValue<List<Plant>>> {
  final PlantRepository _repository;

  PlantsNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadPlants();
  }

  Future<void> loadPlants() async {
    state = const AsyncValue.loading();
    try {
      final plants = await _repository.getAllPlants();
      state = AsyncValue.data(plants);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addPlant(Plant plant) async {
    try {
      await _repository.insertPlant(plant);
      await loadPlants();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updatePlant(Plant plant) async {
    try {
      await _repository.updatePlant(plant);
      await loadPlants();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deletePlant(int id) async {
    try {
      await _repository.deletePlant(id);
      await loadPlants();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> waterPlant(int id) async {
    try {
      await _repository.waterPlant(id);
      await loadPlants();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> fertilizePlant(int id) async {
    try {
      await _repository.fertilizePlant(id);
      await loadPlants();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> prunePlant(int id) async {
    try {
      await _repository.prunePlant(id);
      await loadPlants();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}