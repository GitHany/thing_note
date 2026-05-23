import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/weekly_wins/domain/weekly_wins.dart';

/// 本周成就列表
final weeklyWinsProvider = FutureProvider<List<WeeklyWin>>((ref) async {
  // TODO: 从数据库获取本周成就
  return [];
});

/// 周回顾总结
final weeklySummaryProvider = FutureProvider<WeeklySummary>((ref) async {
  final now = DateTime.now();
  final weekNumber = _getWeekNumber(now);
  
  // TODO: 从数据库计算总结
  return WeeklySummary(
    weekNumber: weekNumber,
    year: now.year,
    totalWins: 0,
    categories: [],
    createdAt: now,
  );
});

int _getWeekNumber(DateTime date) {
  final firstDayOfYear = DateTime(date.year, 1, 1);
  final days = date.difference(firstDayOfYear).inDays;
  return ((days + firstDayOfYear.weekday - 1) / 7).ceil();
}

/// 添加成就
final addWinProvider = Provider((ref) {
  return AddWinNotifier(ref);
});

class AddWinNotifier extends StateNotifier<bool> {
  final Ref ref;
  
  AddWinNotifier(this.ref) : super(false);
  
  Future<void> addWin(WeeklyWin win) async {
    state = true;
    // TODO: 保存到数据库
    ref.invalidate(weeklyWinsProvider);
    state = false;
  }
}