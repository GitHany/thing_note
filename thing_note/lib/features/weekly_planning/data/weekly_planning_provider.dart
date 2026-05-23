import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/weekly_planning/domain/weekly_planning.dart';

/// 本周计划
final weeklyPlanProvider = FutureProvider<WeeklyPlan?>((ref) async {
  // TODO: 从数据库获取
  return null;
});

/// 更新计划
final updateWeeklyPlanProvider = Provider((ref) {
  return UpdateWeeklyPlanNotifier(ref);
});

class UpdateWeeklyPlanNotifier extends StateNotifier<bool> {
  final Ref ref;
  
  UpdateWeeklyPlanNotifier(this.ref) : super(false);
  
  Future<void> update(WeeklyPlan plan) async {
    state = true;
    // TODO: 保存到数据库
    ref.invalidate(weeklyPlanProvider);
    state = false;
  }
}