import 'package:thing_note/core/database/database_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/vehicle_entry.dart';

final vehicleRepositoryProvider = Provider<VehicleRepository>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return VehicleRepository(dbAsync);
});

class VehicleRepository {
  final AsyncValue<dynamic> _dbAsync;

  VehicleRepository(this._dbAsync);

  Future<dynamic> get _db async {
    final db = _dbAsync.value;
    if (db == null) throw Exception('Database not initialized');
    return db;
  }

  Future<int> insertVehicle(VehicleEntry vehicle) async {
    final db = await _db;
    return await db.insert('vehicles', vehicle.toMap());
  }

  Future<List<VehicleEntry>> getAllVehicles() async {
    final db = await _db;
    final maps = await db.query('vehicles', orderBy: 'name ASC');
    return maps.map((map) => VehicleEntry.fromMap(map)).toList();
  }

  Future<VehicleEntry?> getVehicleById(int id) async {
    final db = await _db;
    final maps = await db.query('vehicles', where: 'id = ?', whereArgs: [id], limit: 1);
    return maps.isNotEmpty ? VehicleEntry.fromMap(maps.first) : null;
  }

  Future<int> updateVehicle(VehicleEntry vehicle) async {
    final db = await _db;
    return await db.update('vehicles', vehicle.toMap(), where: 'id = ?', whereArgs: [vehicle.id]);
  }

  Future<int> deleteVehicle(int id) async {
    final db = await _db;
    return await db.delete('vehicles', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> insertFuelRecord(FuelRecord record) async {
    final db = await _db;
    return await db.insert('fuel_records', record.toMap());
  }

  Future<List<FuelRecord>> getFuelRecordsByVehicle(int vehicleId) async {
    final db = await _db;
    final maps = await db.query(
      'fuel_records',
      where: 'vehicle_id = ?',
      whereArgs: [vehicleId],
      orderBy: 'date DESC',
    );
    return maps.map((map) => FuelRecord.fromMap(map)).toList();
  }

  Future<double> getTotalFuelCost(int vehicleId) async {
    final db = await _db;
    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM fuel_records WHERE vehicle_id = ?',
      [vehicleId],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }
}