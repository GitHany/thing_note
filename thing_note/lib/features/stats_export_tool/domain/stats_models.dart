import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 统计报告类型
enum ReportType { daily, weekly, monthly, custom }

/// 导出格式
enum StatsExportFormat { pdf, csv, excel, json, markdown }

/// 报告模板
class ReportTemplate {
  final String id;
  final String name;
  final ReportType type;
  final List<String> includeSections;
  final bool includeCharts;
  final bool includeAIInsights;

  const ReportTemplate({
    required this.id,
    required this.name,
    required this.type,
    required this.includeSections,
    this.includeCharts = true,
    this.includeAIInsights = false,
  });

  static List<ReportTemplate> get defaults => [
    const ReportTemplate(id: '1', name: '日报', type: ReportType.daily, includeSections: ['记录统计', '时间分布', '标签统计'], includeCharts: true),
    const ReportTemplate(id: '2', name: '周报', type: ReportType.weekly, includeSections: ['记录统计', '趋势分析', '成就'], includeCharts: true, includeAIInsights: true),
    const ReportTemplate(id: '3', name: '月报', type: ReportType.monthly, includeSections: ['记录统计', '目标进度', '情绪分析'], includeCharts: true, includeAIInsights: true),
  ];
}

/// 统计导出工具 Provider
final statsExportProvider = StateNotifierProvider<StatsExportNotifier, AsyncValue<List<ReportTemplate>>>((ref) {
  return StatsExportNotifier();
});

class StatsExportNotifier extends StateNotifier<AsyncValue<List<ReportTemplate>>> {
  StatsExportNotifier() : super(const AsyncValue.loading());

  Future<void> loadTemplates() async {
    state = const AsyncValue.loading();
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      state = AsyncValue.data(ReportTemplate.defaults);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<String> exportReport(ReportTemplate template, StatsExportFormat format, DateTime startDate, DateTime endDate) async {
    // 模拟生成报告
    await Future.delayed(const Duration(seconds: 2));
    return '/path/to/report.${format.name}';
  }
}

/// 导出历史
final exportHistoryProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  await Future.delayed(const Duration(milliseconds: 200));
  return [
    {'fileName': 'daily_report_2024-01-15.pdf', 'date': DateTime.now().subtract(const Duration(days: 1)), 'format': 'pdf', 'size': '2.5 MB'},
    {'fileName': 'weekly_report_2024-W03.pdf', 'date': DateTime.now().subtract(const Duration(days: 7)), 'format': 'pdf', 'size': '5.2 MB'},
    {'fileName': 'stats_export.csv', 'date': DateTime.now().subtract(const Duration(days: 14)), 'format': 'csv', 'size': '1.1 MB'},
  ];
});