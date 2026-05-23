import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';
import '../domain/energy_record_model.dart';

final energyManagementRepositoryProvider = Provider<EnergyManagementRepository>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return EnergyManagementRepository(dbAsync);
});

class EnergyManagementRepository {
  final AsyncValue<Database> _dbAsync;

  EnergyManagementRepository(this._dbAsync);

  Future<Database> get _db async {
    final db = _dbAsync.value;
    if (db == null) throw Exception('Database not initialized');
    return db;
  }

  Future<int> insertRecord(EnergyRecord record) async {
    final db = await _db;
    return await db.insert('energy_records', record.toMap());
  }

  Future<int> updateRecord(EnergyRecord record) async {
    final db = await _db;
    return await db.update(
      'energy_records',
      record.toMap(),
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }

  Future<int> deleteRecord(int id) async {
    final db = await _db;
    return await db.delete(
      'energy_records',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<EnergyRecord>> getAllRecords() async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      'energy_records',
      orderBy: 'recorded_at DESC',
    );
    return maps.map((map) => EnergyRecord.fromMap(map)).toList();
  }

  Future<EnergyRecord?> getTodayRecord() async {
    final db = await _db;
    final today = DateTime.now().toIso8601String().split('T')[0];
    final List<Map<String, dynamic>> maps = await db.query(
      'energy_records',
      where: 'recorded_at LIKE ?',
      whereArgs: ['$today%'],
      orderBy: 'recorded_at DESC',
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return EnergyRecord.fromMap(maps.first);
    }
    return null;
  }

  Future<Map<String, dynamic>> getStatistics() async {
    final db = await _db;
    
    final avgResult = await db.rawQuery('''
      SELECT AVG(energy_level) as avg FROM energy_records
    ''');
    final avgEnergy = avgResult.first['avg'] as double? ?? 0;
    
    final totalResult = await db.rawQuery('SELECT COUNT(*) as count FROM energy_records');
    final totalRecords = totalResult.first['count'] as int? ?? 0;
    
    final peakResult = await db.rawQuery('''
      SELECT MAX(energy_level) as peak FROM energy_records
    ''');
    final peakEnergy = peakResult.first['peak'] as int? ?? 0;
    
    return {
      'avg_energy': avgEnergy,
      'total_records': totalRecords,
      'peak_energy': peakEnergy,
      'best_hour': '10 AM',
    };
  }
}
