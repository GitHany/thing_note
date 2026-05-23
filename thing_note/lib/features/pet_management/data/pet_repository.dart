import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/pet_management/domain/pet.dart';
import 'package:thing_note/features/pet_management/domain/pet_care_log.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';

final petRepositoryProvider = Provider<PetRepository>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return PetRepository(dbAsync);
});

final petsProvider = StateNotifierProvider<PetsNotifier, AsyncValue<List<Pet>>>((ref) {
  final repository = ref.watch(petRepositoryProvider);
  return PetsNotifier(repository);
});

final petCareLogsProvider = StateNotifierProvider.family<PetCareLogsNotifier, AsyncValue<List<PetCareLog>>, int>((ref, petId) {
  final repository = ref.watch(petRepositoryProvider);
  return PetCareLogsNotifier(repository, petId);
});

class PetRepository {
  final AsyncValue<Database> _dbAsync;

  PetRepository(this._dbAsync);

  Future<Database> get _db async {
    final db = _dbAsync.value;
    if (db == null) throw Exception('Database not initialized');
    return db;
  }

  // Pet CRUD
  Future<int> insertPet(Pet pet) async {
    final db = await _db;
    return db.insert('pets', pet.toMap());
  }

  Future<int> updatePet(Pet pet) async {
    final db = await _db;
    return db.update('pets', pet.copyWith(updatedAt: DateTime.now()).toMap(),
        where: 'id = ?', whereArgs: [pet.id]);
  }

  Future<int> deletePet(int id) async {
    final db = await _db;
    return db.delete('pets', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Pet>> getAllPets() async {
    final db = await _db;
    final maps = await db.query('pets', orderBy: 'created_at DESC');
    return maps.map((m) => Pet.fromMap(m)).toList();
  }

  // Care Log CRUD
  Future<int> insertCareLog(PetCareLog log) async {
    final db = await _db;
    return db.insert('pet_care_logs', log.toMap());
  }

  Future<int> deleteCareLog(int id) async {
    final db = await _db;
    return db.delete('pet_care_logs', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<PetCareLog>> getCareLogsForPet(int petId) async {
    final db = await _db;
    final maps = await db.query(
      'pet_care_logs',
      where: 'pet_id = ?',
      whereArgs: [petId],
      orderBy: 'date DESC',
    );
    return maps.map((m) => PetCareLog.fromMap(m)).toList();
  }

  Future<List<PetCareLog>> getRecentCareLogs(int petId, {int limit = 10}) async {
    final db = await _db;
    final maps = await db.query(
      'pet_care_logs',
      where: 'pet_id = ?',
      whereArgs: [petId],
      orderBy: 'date DESC',
      limit: limit,
    );
    return maps.map((m) => PetCareLog.fromMap(m)).toList();
  }
}

class PetsNotifier extends StateNotifier<AsyncValue<List<Pet>>> {
  final PetRepository _repository;

  PetsNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadPets();
  }

  Future<void> loadPets() async {
    state = const AsyncValue.loading();
    try {
      final pets = await _repository.getAllPets();
      state = AsyncValue.data(pets);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addPet(Pet pet) async {
    try {
      await _repository.insertPet(pet);
      await loadPets();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updatePet(Pet pet) async {
    try {
      await _repository.updatePet(pet);
      await loadPets();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deletePet(int id) async {
    try {
      await _repository.deletePet(id);
      await loadPets();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

class PetCareLogsNotifier extends StateNotifier<AsyncValue<List<PetCareLog>>> {
  final PetRepository _repository;
  final int petId;

  PetCareLogsNotifier(this._repository, this.petId) : super(const AsyncValue.loading()) {
    loadCareLogs();
  }

  Future<void> loadCareLogs() async {
    state = const AsyncValue.loading();
    try {
      final logs = await _repository.getCareLogsForPet(petId);
      state = AsyncValue.data(logs);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addCareLog(PetCareLog log) async {
    try {
      await _repository.insertCareLog(log);
      await loadCareLogs();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteCareLog(int id) async {
    try {
      await _repository.deleteCareLog(id);
      await loadCareLogs();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}