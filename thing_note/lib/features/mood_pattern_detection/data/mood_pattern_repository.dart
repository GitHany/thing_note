import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';
import 'package:thing_note/features/mood_pattern_detection/domain/mood_pattern.dart';

final moodPatternRepositoryProvider = Provider<MoodPatternRepository>((ref) {
  return MoodPatternRepository(ref.watch(databaseProvider.future));
});

class MoodPatternRepository {
  final Future<Database> _dbFuture;

  MoodPatternRepository(this._dbFuture);

  Future<Database> get _db => _dbFuture;

  Future<List<MoodPattern>> getAllPatterns() async {
    final db = await _db;
    final results = await db.query('mood_patterns', orderBy: 'confidence_score DESC');
    return results.map((e) => MoodPattern.fromMap(e)).toList();
  }

  Future<List<Map<String, dynamic>>> getMoodTrend({int days = 30}) async {
    final db = await _db;
    final startDate = DateTime.now().subtract(Duration(days: days));

    return await db.rawQuery('''
      SELECT DATE(occurred_at) as date, AVG(mood_level) as mood_score
      FROM mood_journals
      WHERE occurred_at >= ?
      GROUP BY DATE(occurred_at)
      ORDER BY date
    ''', [startDate.toIso8601String()]);
  }

  Future<void> initializeDefaultPatterns() async {
    final db = await _db;
    final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM mood_patterns')) ?? 0;

    if (count == 0) {
      final defaults = [
        MoodPattern(patternType: 'cyclical', confidenceScore: 0.85, occurrenceCount: 12),
        MoodPattern(patternType: 'positive', confidenceScore: 0.72, occurrenceCount: 8),
        MoodPattern(patternType: 'triggered', confidenceScore: 0.65, occurrenceCount: 5),
      ];

      for (final pattern in defaults) {
        await db.insert('mood_patterns', {
          'pattern_type': pattern.patternType,
          'confidence_score': pattern.confidenceScore,
          'occurrence_count': pattern.occurrenceCount,
          'created_at': DateTime.now().toIso8601String(),
        });
      }
    }
  }
}