import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';
import '../domain/energy_record.dart';

final energyRepositoryProvider = Provider<EnergyRepository>((ref) {
  return EnergyRepository(ref);
});

class EnergyRepository {
  final Ref _ref;

  EnergyRepository(this._ref);

  Future<Database> get _db async {
    final dbAsync = _ref.watch(databaseProvider);
    return dbAsync.value!;
  }

  Future<int> insertEnergyRecord(EnergyRecord record) async {
    final db = await _db;
    return await db.insert('energy_records', record.toMap());
  }

  Future<List<EnergyRecord>> getEnergyByDateRange(String startDate, String endDate) async {
    final db = await _db;
    final maps = await db.query(
      'energy_records',
      where: 'date >= ? AND date <= ?',
      whereArgs: [startDate, endDate],
      orderBy: 'date DESC',
    );
    return maps.map((map) => EnergyRecord.fromMap(map)).toList();
  }

  Future<EnergyRecord?> getEnergyByDate(String date) async {
    final db = await _db;
    final maps = await db.query('energy_records', where: 'date = ?', whereArgs: [date], limit: 1);
    return maps.isNotEmpty ? EnergyRecord.fromMap(maps.first) : null;
  }

  Future<double> getAverageEnergy(String startDate, String endDate) async {
    final db = await _db;
    final result = await db.rawQuery(
      'SELECT AVG(level) as avg FROM energy_records WHERE date >= ? AND date <= ?',
      [startDate, endDate],
    );
    return (result.first['avg'] as num?)?.toDouble() ?? 0.0;
  }

  Future<Map<String, double>> getWeeklyStats() async {
    final db = await _db;
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final result = await db.rawQuery(
      'SELECT date, level FROM energy_records WHERE date >= ? ORDER BY date ASC',
      [weekAgo.toIso8601String().split('T')[0]],
    );
    return {for (final row in result) row['date'] as String: (row['level'] as num).toDouble()};
  }

  Future<List<EnergyTip>> getTipsForLevel(int level) async {
    final db = await _db;
    final maps = await db.query(
      'energy_tips',
      where: 'min_level <= ? AND max_level >= ?',
      whereArgs: [level, level],
    );
    return maps.map((map) => EnergyTip.fromMap(map)).toList();
  }

  Future<void> initializeDefaultTips() async {
    final db = await _db;
    final count = await db.rawQuery('SELECT COUNT(*) as count FROM energy_tips');
    if ((count.first['count'] as int?) == 0) {
      for (final tip in EnergyTip.defaultTips) {
        await db.insert('energy_tips', tip.toMap());
      }
    }
  }

  Future<int> updateEnergyRecord(EnergyRecord record) async {
    final db = await _db;
    return await db.update('energy_records', record.toMap(),
        where: 'id = ?', whereArgs: [record.id]);
  }
}