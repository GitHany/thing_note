import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/maintenance_log/domain/maintenance_item.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';

final maintenanceRepositoryProvider = Provider<MaintenanceRepository>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return MaintenanceRepository(dbAsync);
});

final maintenanceItemsProvider = StateNotifierProvider<MaintenanceItemsNotifier, AsyncValue<List<MaintenanceItem>>>((ref) {
  final repository = ref.watch(maintenanceRepositoryProvider);
  return MaintenanceItemsNotifier(repository);
});

class MaintenanceRepository {
  final AsyncValue<Database> _dbAsync;

  MaintenanceRepository(this._dbAsync);

  Future<Database> get _db async {
    final db = _dbAsync.value;
    if (db == null) throw Exception('Database not initialized');
    return db;
  }

  Future<int> insertMaintenanceItem(MaintenanceItem item) async {
    final db = await _db;
    return db.insert('maintenance_items', item.toMap());
  }

  Future<int> updateMaintenanceItem(MaintenanceItem item) async {
    final db = await _db;
    return db.update(
      'maintenance_items',
      item.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> deleteMaintenanceItem(int id) async {
    final db = await _db;
    return db.delete('maintenance_items', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<MaintenanceItem>> getAllMaintenanceItems() async {
    final db = await _db;
    final maps = await db.query('maintenance_items', orderBy: 'name ASC');
    return maps.map((m) => MaintenanceItem.fromMap(m)).toList();
  }

  Future<int> insertMaintenanceLog(MaintenanceLog log) async {
    final db = await _db;
    return db.insert('maintenance_logs', log.toMap());
  }

  Future<List<MaintenanceLog>> getMaintenanceLogs(int itemId) async {
    final db = await _db;
    final maps = await db.query(
      'maintenance_logs',
      where: 'item_id = ?',
      whereArgs: [itemId],
      orderBy: 'service_date DESC',
    );
    return maps.map((m) => MaintenanceLog.fromMap(m)).toList();
  }

  Future<List<MaintenanceItem>> getItemsNearWarrantyExpiry({int days = 30}) async {
    final db = await _db;
    final now = DateTime.now();
    final future = now.add(Duration(days: days));
    final maps = await db.query(
      'maintenance_items',
      where: 'warranty_end_date >= ? AND warranty_end_date <= ?',
      whereArgs: [now.toIso8601String(), future.toIso8601String()],
    );
    return maps.map((m) => MaintenanceItem.fromMap(m)).toList();
  }
}

class MaintenanceItemsNotifier extends StateNotifier<AsyncValue<List<MaintenanceItem>>> {
  final MaintenanceRepository _repository;

  MaintenanceItemsNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadItems();
  }

  Future<void> loadItems() async {
    state = const AsyncValue.loading();
    try {
      final items = await _repository.getAllMaintenanceItems();
      state = AsyncValue.data(items);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addMaintenanceItem(MaintenanceItem item) async {
    try {
      await _repository.insertMaintenanceItem(item);
      await loadItems();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateMaintenanceItem(MaintenanceItem item) async {
    try {
      await _repository.updateMaintenanceItem(item);
      await loadItems();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteMaintenanceItem(int id) async {
    try {
      await _repository.deleteMaintenanceItem(id);
      await loadItems();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addMaintenanceLog(MaintenanceLog log) async {
    await _repository.insertMaintenanceLog(log);
  }
}