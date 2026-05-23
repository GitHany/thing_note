import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/stats_models.dart';

/// 统计导出工具屏幕
class StatsExportScreen extends ConsumerWidget {
  const StatsExportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templatesAsync = ref.watch(statsExportProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('统计报告'),
      ),
      body: templatesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
        data: (templates) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('📊 报告模板', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              ...templates.map((template) => Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(_getTypeIcon(template.type)),
                      title: Text(template.name),
                      subtitle: Text('类型: ${_getTypeName(template.type)}'),
                      trailing: template.includeAIInsights ? const Chip(label: Text('AI')) : null,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('包含内容:', style: TextStyle(fontSize: 12)),
                          Wrap(spacing: 4, runSpacing: 4, children: template.includeSections.map((s) => Chip(label: Text(s, style: const TextStyle(fontSize: 10)))).toList()),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.picture_as_pdf),
                              label: const Text('PDF'),
                              onPressed: () => _exportReport(context, ref, template, StatsExportFormat.pdf),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.table_chart),
                              label: const Text('CSV'),
                              onPressed: () => _exportReport(context, ref, template, StatsExportFormat.csv),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
              const SizedBox(height: 24),
              Text('📁 导出历史', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              Consumer(
                builder: (context, ref, _) {
                  final historyAsync = ref.watch(exportHistoryProvider);
                  return historyAsync.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (e, _) => const Text('加载失败'),
                    data: (history) => history.isEmpty
                        ? const Text('暂无导出记录')
                        : Column(
                            children: history.map((h) => Map<String, dynamic>.from(h)).map((item) => ListTile(
                              leading: const Icon(Icons.description),
                              title: Text(item['fileName'] as String),
                              subtitle: Text('${item['format']} • ${item['size']}'),
                              trailing: IconButton(icon: const Icon(Icons.download), onPressed: () {}),
                            )).toList(),
                          ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getTypeIcon(ReportType type) {
    switch (type) {
      case ReportType.daily: return Icons.today;
      case ReportType.weekly: return Icons.view_week;
      case ReportType.monthly: return Icons.calendar_month;
      case ReportType.custom: return Icons.tune;
    }
  }

  String _getTypeName(ReportType type) {
    switch (type) {
      case ReportType.daily: return '日报';
      case ReportType.weekly: return '周报';
      case ReportType.monthly: return '月报';
      case ReportType.custom: return '自定义';
    }
  }

  void _exportReport(BuildContext context, WidgetRef ref, ReportTemplate template, StatsExportFormat format) async {
    final now = DateTime.now();
    final path = await ref.read(statsExportProvider.notifier).exportReport(template, format, now.subtract(const Duration(days: 7)), now);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('报告已导出到: $path')));
    }
  }
}