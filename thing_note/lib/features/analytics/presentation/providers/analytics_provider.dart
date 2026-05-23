import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/analytics/data/analytics_repository.dart';
import 'package:thing_note/features/analytics/domain/usage_analyzer.dart';
import 'package:thing_note/features/record/presentation/providers/record_provider.dart';

final analyticsRepositoryProvider = Provider((ref) => AnalyticsRepository());

final usageInsightsProvider = FutureProvider<List<UsageInsight>>((ref) async {
  final records = await ref.watch(recordListProvider.future);
  final analyzer = UsageAnalyzer();
  final insights = analyzer.analyzeUsage(records);

  // 保存分析结果
  final repo = ref.read(analyticsRepositoryProvider);
  await repo.saveInsights(insights);

  return insights;
});

final savedInsightsProvider = FutureProvider<List<UsageInsight>>((ref) async {
  final repo = ref.read(analyticsRepositoryProvider);
  return repo.getSavedInsights();
});

final lastAnalysisTimeProvider = FutureProvider<DateTime?>((ref) async {
  final repo = ref.read(analyticsRepositoryProvider);
  return repo.getLastAnalysisTime();
});