import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/smart_weekly_planner/data/weekly_planner_repository.dart';
import 'package:thing_note/features/smart_weekly_planner/domain/weekly_plan.dart';

final weeklyPlannerRepositoryProvider = Provider((ref) => WeeklyPlannerRepository(ref));

final allPlansProvider = FutureProvider<List<WeeklyPlan>>((ref) async {
  final repo = ref.read(weeklyPlannerRepositoryProvider);
  return repo.getAllPlans();
});

final todayPlansProvider = FutureProvider<List<WeeklyPlan>>((ref) async {
  final repo = ref.read(weeklyPlannerRepositoryProvider);
  return repo.getTodayPlans();
});

final weekCompletionStatsProvider = FutureProvider<Map<String, int>>((ref) async {
  final repo = ref.read(weeklyPlannerRepositoryProvider);
  return repo.getWeekCompletionStats();
});