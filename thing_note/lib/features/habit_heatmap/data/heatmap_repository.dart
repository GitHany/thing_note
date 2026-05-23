import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/habit_heatmap/domain/habit_heatmap.dart';
import 'package:thing_note/core/database/database_provider.dart';
import 'package:sqflite/sqflite.dart';

final heatmapRepositoryProvider = Provider<HeatmapRepository>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return HeatmapRepository(dbAsync);
});

final heatmapDataProvider = FutureProvider.family<List<HabitHeatmapData>, int>((ref, habitId) async {
  final repo = ref.watch(heatmapRepositoryProvider);
  return repo.getHeatmapDataForHabit(habitId);
});

final heatmapStatsProvider = FutureProvider.family<HeatmapStats, int>((ref, habitId) async {
  final repo = ref.watch(heatmapRepositoryProvider);
  return repo.getStatsForHabit(habitId);
});

class HeatmapRepository {
  final AsyncValue<Database> _dbAsync;

  HeatmapRepository(this._dbAsync);

  Future<Database> get _db async {
    final db = _dbAsync.value;
    if (db == null) throw Exception('Database not initialized');
    return db;
  }

  Future<int> upsertHeatmapData(HabitHeatmapData data) async {
    final db = await _db;
    final existing = await db.query(
      'habit_heatmap_data',
      where: 'habit_id = ? AND date = ?',
      whereArgs: [data.habitId, data.date],
    );
    if (existing.isNotEmpty) {
      return db.update(
        'habit_heatmap_data',
        data.toMap(),
        where: 'habit_id = ? AND date = ?',
        whereArgs: [data.habitId, data.date],
      );
    }
    return db.insert('habit_heatmap_data', data.toMap());
  }

  Future<List<HabitHeatmapData>> getHeatmapDataForHabit(int habitId, {int days = 365}) async {
    final db = await _db;
    final end = DateTime.now();
    final start = end.subtract(Duration(days: days));
    final startStr = '${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}';
    final endStr = '${end.year}-${end.month.toString().padLeft(2, '0')}-${end.day.toString().padLeft(2, '0')}';
    final maps = await db.query(
      'habit_heatmap_data',
      where: 'habit_id = ? AND date BETWEEN ? AND ?',
      whereArgs: [habitId, startStr, endStr],
      orderBy: 'date ASC',
    );
    return maps.map((m) => HabitHeatmapData.fromMap(m)).toList();
  }

  Future<HeatmapStats> getStatsForHabit(int habitId) async {
    final db = await _db;
    final maps = await db.query(
      'habit_heatmap_data',
      where: 'habit_id = ?',
      whereArgs: [habitId],
      orderBy: 'date DESC',
    );

    if (maps.isEmpty) {
      return const HeatmapStats();
    }

    final dataList = maps.map((m) => HabitHeatmapData.fromMap(m)).toList();
    int activeDays = 0;
    int currentStreak = 0;
    int longestStreak = 0;
    int tempStreak = 0;
    final Map<String, int> weekdayDist = {};

    for (int i = 0; i < dataList.length; i++) {
      final data = dataList[i];
      if (data.completionLevel > 0) {
        activeDays++;
        final dow = DateTime.parse(data.date).weekday;
        weekdayDist[dow.toString()] = (weekdayDist[dow.toString()] ?? 0) + 1;

        if (i < dataList.length - 1) {
          final prevDate = DateTime.parse(dataList[i + 1].date);
          final currDate = DateTime.parse(data.date);
          if (currDate.difference(prevDate).inDays == 1) {
            tempStreak++;
          } else {
            if (tempStreak > longestStreak) longestStreak = tempStreak;
            tempStreak = 1;
          }
        }
      }
    }

    // Check today's streak
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    for (final data in dataList) {
      if (data.date == todayStr && data.completionLevel > 0) {
        currentStreak = tempStreak > 0 ? tempStreak : 1;
        break;
      }
    }

    return HeatmapStats(
      totalDays: maps.length,
      activeDays: activeDays,
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      weekdayDistribution: weekdayDist,
    );
  }
}
