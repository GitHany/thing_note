import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import '../../../core/database/database_provider.dart';
import '../domain/prediction_models.dart';

final moodPredictionRepositoryProvider = Provider<MoodPredictionRepository>((ref) {
  return MoodPredictionRepository(ref.watch(databaseProvider).value!);
});

class MoodPredictionRepository {
  final Database _db;

  MoodPredictionRepository(this._db);

  Future<int> insert(MoodPrediction prediction) async {
    return await _db.insert('mood_predictions', prediction.toMap());
  }

  Future<int> update(MoodPrediction prediction) async {
    return await _db.update(
      'mood_predictions',
      prediction.toMap(),
      where: 'id = ?',
      whereArgs: [prediction.id],
    );
  }

  Future<List<MoodPrediction>> getPredictionsByDate(DateTime date) async {
    final dateStr = date.toIso8601String().split('T')[0];
    final maps = await _db.query(
      'mood_predictions',
      where: 'predicted_date = ?',
      whereArgs: [dateStr],
    );
    return maps.map((m) => MoodPrediction.fromMap(m)).toList();
  }

  Future<List<MoodPrediction>> getUpcomingPredictions({int days = 7}) async {
    final today = DateTime.now();
    final endDate = today.add(Duration(days: days));
    final maps = await _db.query(
      'mood_predictions',
      where: 'predicted_date >= ? AND predicted_date <= ?',
      whereArgs: [
        today.toIso8601String().split('T')[0],
        endDate.toIso8601String().split('T')[0],
      ],
      orderBy: 'predicted_date ASC',
    );
    return maps.map((m) => MoodPrediction.fromMap(m)).toList();
  }

  Future<List<MoodPrediction>> getHistoryWithAccuracy() async {
    final maps = await _db.query(
      'mood_predictions',
      where: 'actual_mood_level IS NOT NULL',
      orderBy: 'predicted_date DESC',
      limit: 30,
    );
    return maps.map((m) => MoodPrediction.fromMap(m)).toList();
  }

  Future<void> recordActualMood(DateTime date, int actualMood) async {
    final dateStr = date.toIso8601String().split('T')[0];
    final predictions = await _db.query(
      'mood_predictions',
      where: 'predicted_date = ?',
      whereArgs: [dateStr],
    );

    if (predictions.isNotEmpty) {
      final prediction = MoodPrediction.fromMap(predictions.first);
      final accuracy = (100 - (prediction.predictedMoodLevel - actualMood).abs() * 20).toDouble();
      final updated = MoodPrediction(
        id: prediction.id,
        predictedDate: prediction.predictedDate,
        predictedMoodLevel: prediction.predictedMoodLevel,
        confidenceScore: prediction.confidenceScore,
        factors: prediction.factors,
        predictionBasedOn: prediction.predictionBasedOn,
        actualMoodLevel: actualMood,
        predictionAccuracy: accuracy,
        createdAt: prediction.createdAt,
      );
      await update(updated);
    }
  }

  Future<Map<String, dynamic>> getPredictionAccuracy() async {
    final result = await _db.rawQuery('''
      SELECT 
        AVG(prediction_accuracy) as avg_accuracy,
        COUNT(*) as total_predictions,
        MAX(prediction_accuracy) as best,
        MIN(prediction_accuracy) as worst
      FROM mood_predictions
      WHERE prediction_accuracy IS NOT NULL
    ''');
    return result.first;
  }

  Future<MoodPrediction> generatePrediction(DateTime date) async {
    // Simple prediction based on patterns
    // In a real app, this would use ML models
    final dayOfWeek = date.weekday;
    
    // Get historical data for similar days
    final historyResult = await _db.rawQuery('''
      SELECT AVG(mood_score) as avg_mood
      FROM stress_indicators
      WHERE strftime('%w', recorded_at) = ?
    ''', [dayOfWeek.toString()]);

    final avgMood = (historyResult.first['avg_mood'] as num?)?.toDouble() ?? 3.0;
    
    // Add some variance based on time
    final month = date.month;
    double adjustedMood = avgMood;
    
    // Seasonal adjustments
    if (month >= 11 || month <= 1) {
      adjustedMood -= 0.3; // Winter blues
    }
    
    final moodLevel = adjustedMood.round().clamp(1, 5);
    
    return MoodPrediction(
      predictedDate: date,
      predictedMoodLevel: moodLevel,
      confidenceScore: 0.6,
      factors: ['Historical patterns', 'Seasonal adjustment'],
      predictionBasedOn: 'Simple averaging based on weekday patterns',
    );
  }
}