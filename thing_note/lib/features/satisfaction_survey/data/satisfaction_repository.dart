import 'package:sqflite/sqflite.dart';
import 'package:thing_note/features/satisfaction_survey/domain/satisfaction_entry.dart';

class SatisfactionRepository {
  final Database db;

  SatisfactionRepository(this.db);

  Future<int> insert(SatisfactionEntry entry) async {
    final map = entry.toMap();
    map.remove('id');
    return db.insert('satisfaction_entries', map);
  }

  Future<List<SatisfactionEntry>> getAll() async {
    final List<Map<String, dynamic>> maps = await db.query(
      'satisfaction_entries',
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => SatisfactionEntry.fromMap(map)).toList();
  }

  Future<double> getAverageRating() async {
    final result = await db.rawQuery(
      'SELECT AVG(rating) as avg FROM satisfaction_entries',
    );
    return (result.first['avg'] as double?) ?? 0.0;
  }

  Future<int> getTotalCount() async {
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM satisfaction_entries',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<Map<int, int>> getRatingDistribution() async {
    final result = await db.rawQuery(
      'SELECT rating, COUNT(*) as count FROM satisfaction_entries GROUP BY rating',
    );

    final distribution = <int, int>{};
    for (final row in result) {
      distribution[row['rating'] as int] = row['count'] as int;
    }
    return distribution;
  }
}