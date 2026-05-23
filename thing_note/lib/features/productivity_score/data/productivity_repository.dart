import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import '../../../core/database/database_provider.dart';
import '../domain/productivity_models.dart';

final productivityRepositoryProvider = Provider<ProductivityRepository>((ref) {
  return ProductivityRepository(ref.watch(databaseProvider).value!);
});

class ProductivityRepository {
  final Database _db;

  ProductivityRepository(this._db);

  Future<int> insertOrUpdate(DailyProductivityScore score) async {
    final existing = await _db.query(
      'daily_productivity_scores',
      where: 'date = ?',
      whereArgs: [score.date.toIso8601String().split('T')[0]],
    );
    
    if (existing.isNotEmpty) {
      return await _db.update(
        'daily_productivity_scores',
        score.toMap(),
        where: 'date = ?',
        whereArgs: [score.date.toIso8601String().split('T')[0]],
      );
    }
    return await _db.insert('daily_productivity_scores', score.toMap());
  }

  Future<DailyProductivityScore?> getScoreByDate(DateTime date) async {
    final dateStr = date.toIso8601String().split('T')[0];
    final maps = await _db.query(
      'daily_productivity_scores',
      where: 'date = ?',
      whereArgs: [dateStr],
    );
    if (maps.isEmpty) return null;
    return DailyProductivityScore.fromMap(maps.first);
  }

  Future<List<DailyProductivityScore>> getScoresByRange(DateTime start, DateTime end) async {
    final maps = await _db.query(
      'daily_productivity_scores',
      where: 'date >= ? AND date <= ?',
      whereArgs: [
        start.toIso8601String().split('T')[0],
        end.toIso8601String().split('T')[0],
      ],
      orderBy: 'date DESC',
    );
    return maps.map((m) => DailyProductivityScore.fromMap(m)).toList();
  }

  Future<Map<String, dynamic>> getAverageScores({int days = 30}) async {
    final startDate = DateTime.now().subtract(Duration(days: days));
    final result = await _db.rawQuery('''
      SELECT 
        AVG(overall_score) as avg_overall,
        AVG(focus_score) as avg_focus,
        AVG(energy_score) as avg_energy,
        AVG(output_score) as avg_output,
        SUM(deep_work_minutes) as total_deep_work,
        AVG(interruption_count) as avg_interruptions
      FROM daily_productivity_scores
      WHERE date >= ?
    ''', [startDate.toIso8601String().split('T')[0]]);
    return result.first;
  }
}