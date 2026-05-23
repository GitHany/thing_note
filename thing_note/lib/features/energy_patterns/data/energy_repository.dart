import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import '../../../core/database/database_provider.dart';
import '../domain/energy_models.dart';

final energyRepositoryProvider = Provider<EnergyRepository>((ref) {
  return EnergyRepository(ref.watch(databaseProvider).value!);
});

class EnergyRepository {
  final Database _db;

  EnergyRepository(this._db);

  Future<int> insert(EnergyPattern pattern) async {
    return await _db.insert('energy_patterns', pattern.toMap());
  }

  Future<List<EnergyPattern>> getAllPatterns() async {
    final maps = await _db.query('energy_patterns', orderBy: 'hour_of_day');
    return maps.map((m) => EnergyPattern.fromMap(m)).toList();
  }

  Future<List<EnergyPattern>> getPatternsByDay(int dayOfWeek) async {
    final maps = await _db.query(
      'energy_patterns',
      where: 'day_of_week = ?',
      whereArgs: [dayOfWeek],
    );
    return maps.map((m) => EnergyPattern.fromMap(m)).toList();
  }

  Future<List<PeakEnergyTime>> getPeakTimes({int days = 30}) async {
    final startDate = DateTime.now().subtract(Duration(days: days));
    final results = await _db.rawQuery('''
      SELECT 
        hour_of_day,
        AVG(energy_level) as avg_energy,
        AVG(productivity_impact) as avg_productivity,
        SUM(sample_count) as total_samples
      FROM energy_patterns
      WHERE created_at >= ?
      GROUP BY hour_of_day
      HAVING total_samples >= 5
      ORDER BY avg_energy DESC
      LIMIT 5
    ''', [startDate.toIso8601String()]);

    return results.map((r) {
      final hour = r['hour_of_day'] as int;
      final avgEnergy = (r['avg_energy'] as num?)?.toDouble() ?? 0;
      return PeakEnergyTime(
        hour: hour,
        avgEnergy: avgEnergy,
        recommendation: _getRecommendation(hour, avgEnergy),
      );
    }).toList();
  }

  String _getRecommendation(int hour, double energy) {
    if (hour >= 6 && hour <= 10) {
      return 'Great for deep work and challenging tasks';
    }
    if (hour >= 14 && hour <= 16) {
      return 'Good for collaborative work';
    }
    if (hour >= 20 && hour <= 22) {
      return 'Consider winding down or light tasks';
    }
    return 'Moderate energy - focus on routine tasks';
  }

  Future<Map<String, dynamic>> getEnergyStats() async {
    final result = await _db.rawQuery('''
      SELECT 
        AVG(energy_level) as overall_avg,
        MAX(energy_level) as peak_energy,
        MIN(energy_level) as lowest_energy,
        SUM(sample_count) as total_samples
      FROM energy_patterns
    ''');
    return result.first;
  }
}