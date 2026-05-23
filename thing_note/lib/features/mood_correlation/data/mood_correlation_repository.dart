import 'package:sqflite/sqflite.dart';
import 'package:thing_note/features/mood_correlation/domain/mood_correlation_model.dart';

/// Repository for Mood Correlation data operations
class MoodCorrelationRepository {
  final Database db;

  MoodCorrelationRepository(this.db);

  /// Create a mood correlation entry
  Future<int> createEntry(MoodCorrelationEntry entry) async {
    return await db.insert('mood_correlation_entries', entry.toMap());
  }

  /// Update a mood correlation entry
  Future<int> updateEntry(MoodCorrelationEntry entry) async {
    return await db.update(
      'mood_correlation_entries',
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  /// Delete an entry
  Future<int> deleteEntry(int id) async {
    return await db.delete(
      'mood_correlation_entries',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Get all entries
  Future<List<MoodCorrelationEntry>> getAllEntries() async {
    final List<Map<String, dynamic>> maps = await db.query(
      'mood_correlation_entries',
      orderBy: 'date DESC',
    );
    return maps.map((map) => MoodCorrelationEntry.fromMap(map)).toList();
  }

  /// Get entries by date range
  Future<List<MoodCorrelationEntry>> getEntriesByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final List<Map<String, dynamic>> maps = await db.query(
      'mood_correlation_entries',
      where: 'date >= ? AND date <= ?',
      whereArgs: [start.toIso8601String().substring(0, 10), end.toIso8601String().substring(0, 10)],
      orderBy: 'date DESC',
    );
    return maps.map((map) => MoodCorrelationEntry.fromMap(map)).toList();
  }

  /// Get recent entries
  Future<List<MoodCorrelationEntry>> getRecentEntries({int limit = 30}) async {
    final List<Map<String, dynamic>> maps = await db.query(
      'mood_correlation_entries',
      orderBy: 'date DESC',
      limit: limit,
    );
    return maps.map((map) => MoodCorrelationEntry.fromMap(map)).toList();
  }

  /// Get activity impact analysis
  Future<List<ActivityMoodImpact>> getActivityImpactAnalysis() async {
    final List<Map<String, dynamic>> results = await db.rawQuery('''
      SELECT 
        activity,
        AVG(mood_score) as avg_mood,
        AVG(energy_level) as avg_energy,
        COUNT(*) as sample_count
      FROM mood_correlation_entries
      GROUP BY activity
      HAVING COUNT(*) >= 2
      ORDER BY avg_mood DESC
    ''');

    final List<ActivityMoodImpact> impacts = [];
    for (final row in results) {
      final avgMood = (row['avg_mood'] as num?)?.toDouble() ?? 0;
      final avgEnergy = (row['avg_energy'] as num?)?.toDouble() ?? 0;
      final sampleCount = (row['sample_count'] as int?) ?? 0;
      
      // Calculate mood impact score (based on how much it differs from neutral 3)
      final moodImpact = (avgMood - 3.0) * 10; // Scale to -20 to +20

      impacts.add(ActivityMoodImpact(
        activity: row['activity'] as String,
        avgMoodScore: avgMood,
        avgEnergyLevel: avgEnergy,
        sampleCount: sampleCount,
        moodImpactScore: moodImpact,
        isPositive: avgMood >= 3,
      ));
    }

    // Sort by impact score
    impacts.sort((a, b) => b.moodImpactScore.abs().compareTo(a.moodImpactScore.abs()));

    return impacts;
  }

  /// Get top positive activities
  Future<List<ActivityMoodImpact>> getTopPositiveActivities({int limit = 5}) async {
    final impacts = await getActivityImpactAnalysis();
    return impacts.where((i) => i.isPositive && i.moodImpactScore > 0).take(limit).toList();
  }

  /// Get top negative activities (activities that tend to lower mood)
  Future<List<ActivityMoodImpact>> getTopNegativeActivities({int limit = 5}) async {
    final impacts = await getActivityImpactAnalysis();
    return impacts.where((i) => !i.isPositive && i.moodImpactScore < 0).take(limit).toList();
  }

  /// Get statistics
  Future<MoodCorrelationStats> getStats() async {
    final entries = await getAllEntries();
    
    if (entries.isEmpty) {
      return MoodCorrelationStats.empty();
    }

    // Calculate averages
    double totalMood = 0;
    double totalEnergy = 0;
    for (final entry in entries) {
      totalMood += entry.moodScore;
      totalEnergy += entry.energyLevel;
    }
    final avgMood = totalMood / entries.length;
    final avgEnergy = totalEnergy / entries.length;

    // Get activity impacts
    final impacts = await getActivityImpactAnalysis();
    final positiveActivities = impacts.where((i) => i.isPositive && i.moodImpactScore > 0).toList();
    final negativeActivities = impacts.where((i) => !i.isPositive && i.moodImpactScore < 0).toList();

    // Get best and worst activities
    final bestActivity = positiveActivities.isNotEmpty 
        ? positiveActivities.first.activity 
        : '';
    final worstActivity = negativeActivities.isNotEmpty 
        ? negativeActivities.first.activity 
        : '';

    // Get weekly mood trend
    final now = DateTime.now();
    final weekStart = now.subtract(const Duration(days: 7));
    final recentEntries = await getEntriesByDateRange(weekStart, now);
    
    final weeklyMoodTrend = <String, double>{};
    for (final entry in recentEntries) {
      final dayKey = entry.date.toIso8601String().substring(0, 10);
      if (!weeklyMoodTrend.containsKey(dayKey)) {
        weeklyMoodTrend[dayKey] = entry.moodScore.toDouble();
      }
    }

    return MoodCorrelationStats(
      totalEntries: entries.length,
      averageMood: avgMood,
      averageEnergy: avgEnergy,
      bestActivity: bestActivity,
      worstActivity: worstActivity,
      topPositiveActivities: positiveActivities.take(5).toList(),
      topNegativeActivities: negativeActivities.take(5).toList(),
      weeklyMoodTrend: weeklyMoodTrend,
    );
  }

  /// Search entries by activity
  Future<List<MoodCorrelationEntry>> searchByActivity(String query) async {
    final List<Map<String, dynamic>> maps = await db.query(
      'mood_correlation_entries',
      where: 'activity LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'date DESC',
    );
    return maps.map((map) => MoodCorrelationEntry.fromMap(map)).toList();
  }

  /// Get entries by mood score range
  Future<List<MoodCorrelationEntry>> getEntriesByMoodRange(int minScore, int maxScore) async {
    final List<Map<String, dynamic>> maps = await db.query(
      'mood_correlation_entries',
      where: 'mood_score >= ? AND mood_score <= ?',
      whereArgs: [minScore, maxScore],
      orderBy: 'date DESC',
    );
    return maps.map((map) => MoodCorrelationEntry.fromMap(map)).toList();
  }

  /// Get mood pattern for a specific day of week
  Future<Map<int, double>> getDayOfWeekPattern() async {
    final results = await db.rawQuery('''
      SELECT 
        strftime('%w', date) as day_of_week,
        AVG(mood_score) as avg_mood
      FROM mood_correlation_entries
      GROUP BY day_of_week
    ''');

    final pattern = <int, double>{};
    for (final row in results) {
      final dayOfWeek = int.parse(row['day_of_week'] as String);
      final avgMood = (row['avg_mood'] as num?)?.toDouble() ?? 0;
      pattern[dayOfWeek] = avgMood;
    }
    return pattern;
  }
}