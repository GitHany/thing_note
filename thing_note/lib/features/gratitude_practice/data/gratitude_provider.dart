// Gratitude Practice Provider
// Version: 1.0

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/core/database/database_provider.dart';
import 'package:thing_note/features/gratitude_practice/domain/gratitude_models.dart';

// Today's gratitude entry provider
final todayGratitudeProvider = FutureProvider<GratitudeEntry?>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  final today = DateTime.now().toIso8601String().substring(0, 10);
  
  final results = await db.query(
    'gratitude_entries',
    where: 'date = ?',
    whereArgs: [today],
  );
  
  if (results.isEmpty) return null;
  return GratitudeEntry.fromMap(results.first);
});

// Weekly gratitude entries provider
final weeklyGratitudeProvider = FutureProvider<List<GratitudeEntry>>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  final now = DateTime.now();
  final weekStart = now.subtract(Duration(days: now.weekday - 1));
  final startDate = weekStart.toIso8601String().substring(0, 10);
  final endDate = now.toIso8601String().substring(0, 10);
  
  final results = await db.query(
    'gratitude_entries',
    where: 'date >= ? AND date <= ?',
    whereArgs: [startDate, endDate],
    orderBy: 'date DESC',
  );
  
  return results.map((r) => GratitudeEntry.fromMap(r)).toList();
});

// Monthly gratitude entries provider
final monthlyGratitudeProvider = FutureProvider<List<GratitudeEntry>>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  final now = DateTime.now();
  final monthStart = DateTime(now.year, now.month, 1);
  final startDate = monthStart.toIso8601String().substring(0, 10);
  final endDate = now.toIso8601String().substring(0, 10);
  
  final results = await db.query(
    'gratitude_entries',
    where: 'date >= ? AND date <= ?',
    whereArgs: [startDate, endDate],
    orderBy: 'date DESC',
  );
  
  return results.map((r) => GratitudeEntry.fromMap(r)).toList();
});

// Gratitude statistics provider
final gratitudeStatsProvider = FutureProvider<GratitudeStats>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  final now = DateTime.now();
  final thirtyDaysAgo = now.subtract(const Duration(days: 30));
  final startDate = thirtyDaysAgo.toIso8601String().substring(0, 10);
  final endDate = now.toIso8601String().substring(0, 10);
  
  final results = await db.query(
    'gratitude_entries',
    where: 'date >= ? AND date <= ?',
    whereArgs: [startDate, endDate],
  );
  
  int streak = 0;
  DateTime checkDate = now;
  while (true) {
    final dateStr = checkDate.toIso8601String().substring(0, 10);
    final hasEntry = results.any((r) => r['date'] == dateStr);
    if (hasEntry) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    } else {
      break;
    }
  }
  
  // Calculate average mood
  double avgMood = 0;
  int moodCount = 0;
  for (final r in results) {
    if (r['mood_level'] != null) {
      avgMood += r['mood_level'] as int;
      moodCount++;
    }
  }
  avgMood = moodCount > 0 ? avgMood / moodCount : 0;
  
  return GratitudeStats(
    totalEntries: results.length,
    streak: streak,
    avgMood: avgMood,
  );
});

class GratitudeStats {
  final int totalEntries;
  final int streak;
  final double avgMood;
  
  GratitudeStats({
    required this.totalEntries,
    required this.streak,
    required this.avgMood,
  });
}

class GratitudeRepository {
  final dynamic db;
  
  GratitudeRepository(this.db);
  
  Future<int> saveGratitudeEntry(GratitudeEntry entry) async {
    final existing = await db.query(
      'gratitude_entries',
      where: 'date = ?',
      whereArgs: [entry.date],
    );
    
    if (existing.isNotEmpty) {
      await db.update(
        'gratitude_entries',
        entry.toMap(),
        where: 'date = ?',
        whereArgs: [entry.date],
      );
      return existing.first['id'] as int;
    } else {
      return await db.insert('gratitude_entries', entry.toMap());
    }
  }
  
  Future<GratitudeEntry?> getEntry(String date) async {
    final results = await db.query(
      'gratitude_entries',
      where: 'date = ?',
      whereArgs: [date],
    );
    return results.isNotEmpty ? GratitudeEntry.fromMap(results.first) : null;
  }
  
  Future<void> deleteEntry(int id) async {
    await db.delete('gratitude_entries', where: 'id = ?', whereArgs: [id]);
  }
}