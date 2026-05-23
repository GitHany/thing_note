import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/chart/data/chart_repository.dart';
import 'package:thing_note/features/chart/domain/chart_data.dart';
import 'package:thing_note/features/record/presentation/providers/record_provider.dart';

final chartRepositoryProvider = Provider((ref) => ChartRepository());

final durationTrendProvider = FutureProvider<List<ChartDataPoint>>((ref) async {
  final records = await ref.watch(recordListProvider.future);
  return ref.read(chartRepositoryProvider).getDurationTrend(records);
});

final recordCountTrendProvider = FutureProvider<List<ChartDataPoint>>((ref) async {
  final records = await ref.watch(recordListProvider.future);
  return ref.read(chartRepositoryProvider).getRecordCountTrend(records);
});

final hourlyDistributionProvider = FutureProvider<List<ChartDataPoint>>((ref) async {
  final records = await ref.watch(recordListProvider.future);
  return ref.read(chartRepositoryProvider).getHourlyDistribution(records);
});

final weeklyTrendProvider = FutureProvider<WeeklyTrendData>((ref) async {
  final records = await ref.watch(recordListProvider.future);
  return ref.read(chartRepositoryProvider).getWeeklyTrend(records);
});

final recordStatisticsProvider = FutureProvider<RecordStatistics>((ref) async {
  final records = await ref.watch(recordListProvider.future);
  return ref.read(chartRepositoryProvider).calculateStatistics(records);
});