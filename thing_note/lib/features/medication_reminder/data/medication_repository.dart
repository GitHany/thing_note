import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/medication_reminder/domain/medication.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';

final medicationRepositoryProvider = Provider<MedicationRepository>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return MedicationRepository(dbAsync);
});

final medicationsProvider = StateNotifierProvider<MedicationsNotifier, AsyncValue<List<Medication>>>((ref) {
  final repository = ref.watch(medicationRepositoryProvider);
  return MedicationsNotifier(repository);
});

final activeMedicationsProvider = Provider<AsyncValue<List<Medication>>>((ref) {
  final meds = ref.watch(medicationsProvider);
  return meds.whenData((list) => list.where((m) => m.isActive).toList());
});

class MedicationRepository {
  final AsyncValue<Database> _dbAsync;

  MedicationRepository(this._dbAsync);

  Future<Database> get _db async {
    final db = _dbAsync.value;
    if (db == null) throw Exception('Database not initialized');
    return db;
  }

  Future<int> insertMedication(Medication med) async {
    final db = await _db;
    return db.insert('medications', med.toMap());
  }

  Future<int> updateMedication(Medication med) async {
    final db = await _db;
    return db.update('medications', med.copyWith(updatedAt: DateTime.now()).toMap(),
        where: 'id = ?', whereArgs: [med.id]);
  }

  Future<int> deleteMedication(int id) async {
    final db = await _db;
    return db.delete('medications', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Medication>> getAllMedications() async {
    final db = await _db;
    final maps = await db.query('medications', orderBy: 'created_at DESC');
    return maps.map((m) => Medication.fromMap(m)).toList();
  }

  Future<int> insertMedicationLog(MedicationLog log) async {
    final db = await _db;
    return db.insert('medication_logs', log.toMap());
  }

  Future<List<MedicationLog>> getMedicationLogs(int medicationId) async {
    final db = await _db;
    final maps = await db.query(
      'medication_logs',
      where: 'medication_id = ?',
      whereArgs: [medicationId],
      orderBy: 'taken_at DESC',
    );
    return maps.map((m) => MedicationLog.fromMap(m)).toList();
  }

  Future<List<MedicationLog>> getTodayMedicationLogs() async {
    final db = await _db;
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final maps = await db.query(
      'medication_logs',
      where: 'taken_at >= ? AND taken_at < ?',
      whereArgs: [startOfDay.toIso8601String(), endOfDay.toIso8601String()],
    );
    return maps.map((m) => MedicationLog.fromMap(m)).toList();
  }
}

class MedicationsNotifier extends StateNotifier<AsyncValue<List<Medication>>> {
  final MedicationRepository _repository;

  MedicationsNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadMedications();
  }

  Future<void> loadMedications() async {
    state = const AsyncValue.loading();
    try {
      final meds = await _repository.getAllMedications();
      state = AsyncValue.data(meds);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addMedication(Medication med) async {
    try {
      await _repository.insertMedication(med);
      await loadMedications();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateMedication(Medication med) async {
    try {
      await _repository.updateMedication(med);
      await loadMedications();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteMedication(int id) async {
    try {
      await _repository.deleteMedication(id);
      await loadMedications();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> logMedicationTaken(int medicationId) async {
    final log = MedicationLog(
      medicationId: medicationId,
      takenAt: DateTime.now(),
      createdAt: DateTime.now(),
    );
    await _repository.insertMedicationLog(log);
  }
}