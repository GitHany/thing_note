import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/core/database/database_provider.dart';
import 'package:thing_note/features/daily_briefing_widget/domain/briefing_model.dart';

final dailyBriefingProvider = FutureProvider<DailyBriefing>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  
  // 获取今日习惯统计
  final today = DateTime.now();
  final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
  
  final habitStats = await db.rawQuery('''
    SELECT 
      COUNT(*) as total,
      SUM(CASE WHEN is_completed = 1 THEN 1 ELSE 0 END) as completed
    FROM daily_quests
    WHERE date LIKE ?
  ''', ['%$todayStr%']);
  
  // 模拟天气数据
  final weatherConditions = ['晴', '多云', '阴', '小雨', '晴'];
  final weather = weatherConditions[today.day % weatherConditions.length];
  final temperature = 20 + (today.day % 15);
  
  return DailyBriefing(
    habitCount: (habitStats.first['total'] as int?) ?? 0,
    completedHabits: (habitStats.first['completed'] as int?) ?? 0,
    weather: weather,
    temperature: temperature,
    todoItems: ['完成早间记录', '阅读30分钟', '运动30分钟'],
    energyLevel: 7,
    date: today,
  );
});

final widgetConfigProvider = StateProvider<WidgetConfig?>((ref) => null);