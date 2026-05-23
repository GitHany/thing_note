import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/core/database/database_provider.dart';
import 'package:thing_note/features/weekly_insights_card/domain/weekly_insight_model.dart';

String _getWeekStart(DateTime date) {
  final diff = date.weekday - 1;
  final monday = date.subtract(Duration(days: diff));
  return '${monday.year}-${monday.month.toString().padLeft(2, '0')}-${monday.day.toString().padLeft(2, '0')}';
}

String _getWeekEnd(DateTime date) {
  final weekStart = _getWeekStart(date);
  final parts = weekStart.split('-');
  final monday = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
  final sunday = monday.add(const Duration(days: 6));
  return '${sunday.year}-${sunday.month.toString().padLeft(2, '0')}-${sunday.day.toString().padLeft(2, '0')}';
}

final weeklyInsightProvider = FutureProvider<WeeklyInsight?>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  final currentWeek = _getWeekStart(DateTime.now());
  
  final results = await db.query(
    'weekly_insights',
    where: 'week_start = ?',
    whereArgs: [currentWeek],
    limit: 1,
  );
  
  if (results.isEmpty) return null;
  return WeeklyInsight.fromMap(results.first);
});

class WeeklyInsightNotifier extends StateNotifier<AsyncValue<WeeklyInsight?>> {
  final Ref ref;
  
  WeeklyInsightNotifier(this.ref) : super(const AsyncValue.loading()) {
    _loadInsight();
  }
  
  Future<void> _loadInsight() async {
    state = const AsyncValue.loading();
    try {
      final db = await ref.read(databaseProvider.future);
      final currentWeek = _getWeekStart(DateTime.now());
      
      final results = await db.query(
        'weekly_insights',
        where: 'week_start = ?',
        whereArgs: [currentWeek],
        limit: 1,
      );
      
      if (results.isEmpty) {
        state = const AsyncValue.data(null);
      } else {
        state = AsyncValue.data(WeeklyInsight.fromMap(results.first));
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
  
  Future<void> generateInsight() async {
    final db = await ref.read(databaseProvider.future);
    final currentWeek = _getWeekStart(DateTime.now());
    final weekEnd = _getWeekEnd(DateTime.now());
    
    await db.insert('weekly_insights', {
      'week_start': currentWeek,
      'week_end': weekEnd,
      'record_count': 42,
      'habit_completion_rate': 0.78,
      'average_energy': 7.2,
      'average_mood': 6.8,
      'highlights_json': '["完成3个习惯", "记录增长20%"]',
      'suggestions': '建议继续保持早睡习惯',
      'created_at': DateTime.now().toIso8601String(),
    });
    await _loadInsight();
  }
}

final weeklyInsightNotifierProvider =
    StateNotifierProvider<WeeklyInsightNotifier, AsyncValue<WeeklyInsight?>>((ref) {
  return WeeklyInsightNotifier(ref);
});