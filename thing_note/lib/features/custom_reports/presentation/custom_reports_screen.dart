import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/l10n/generated/app_localizations.dart';

class CustomReportsScreen extends ConsumerStatefulWidget {
  const CustomReportsScreen({super.key});

  @override
  ConsumerState<CustomReportsScreen> createState() =>
      _CustomReportsScreenState();
}

class _CustomReportsScreenState extends ConsumerState<CustomReportsScreen> {
  String _selectedReportType = 'summary';
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();

  final List<_ReportTemplate> _templates = [
    _ReportTemplate(
      id: 'summary',
      name: '综合摘要',
      description: '包含记录数量、分类分布、时间趋势等',
      icon: Icons.summarize,
    ),
    _ReportTemplate(
      id: 'activity',
      name: '活动报告',
      description: '详细的日常活动记录分析',
      icon: Icons.timeline,
    ),
    _ReportTemplate(
      id: 'productivity',
      name: '效率报告',
      description: '专注时间、完成任务统计',
      icon: Icons.trending_up,
    ),
    _ReportTemplate(
      id: 'custom',
      name: '自定义报告',
      description: '根据您的需求定制报告内容',
      icon: Icons.tune,
    ),
  ];

  final List<_GeneratedReport> _reportHistory = [
    _GeneratedReport(
      title: '周报 - 2024年1月第3周',
      type: 'summary',
      generatedAt: DateTime.now().subtract(const Duration(days: 1)),
      size: '2.3 MB',
    ),
    _GeneratedReport(
      title: '活动报告 - 2024年1月',
      type: 'activity',
      generatedAt: DateTime.now().subtract(const Duration(days: 7)),
      size: '5.1 MB',
    ),
    _GeneratedReport(
      title: '效率报告 - 2024年1月',
      type: 'productivity',
      generatedAt: DateTime.now().subtract(const Duration(days: 14)),
      size: '1.8 MB',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 600;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.customReports),
        actions: [
          IconButton(
            icon: const Icon(Icons.schedule),
            onPressed: () => _showScheduledReports(),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(isWideScreen ? 24 : 16),
        children: [
          // Report type selector
          Text(
            AppLocalizations.of(context)!.selectReportType,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _templates
                .map((t) => ChoiceChip(
                      avatar: Icon(t.icon, size: 18),
                      label: Text(t.name),
                      selected: _selectedReportType == t.id,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedReportType = t.id);
                        }
                      },
                    ))
                .toList(),
          ),
          const SizedBox(height: 24),

          // Date range selector
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.dateRange,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _DatePickerField(
                          label: '开始日期',
                          date: _startDate,
                          onTap: () => _pickStartDate(),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _DatePickerField(
                          label: '结束日期',
                          date: _endDate,
                          onTap: () => _pickEndDate(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      ActionChip(
                        label: const Text('本周'),
                        onPressed: () => _setDateRange('week'),
                      ),
                      ActionChip(
                        label: const Text('本月'),
                        onPressed: () => _setDateRange('month'),
                      ),
                      ActionChip(
                        label: const Text('本季度'),
                        onPressed: () => _setDateRange('quarter'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Generate button
          FilledButton.icon(
            onPressed: _generateReport,
            icon: const Icon(Icons.description),
            label: Text(AppLocalizations.of(context)!.generateReport),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.all(16),
            ),
          ),
          const SizedBox(height: 24),

          // Report preview
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.reportPreview,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ReportSection(
                        title: '记录统计',
                        items: [
                          '总记录数: 128',
                          '平均每日: 18条',
                          '最高记录日: 周三 (25条)',
                        ],
                      ),
                      SizedBox(height: 16),
                      _ReportSection(
                        title: '分类分布',
                        items: [
                          '工作: 45% (58条)',
                          '生活: 30% (38条)',
                          '学习: 25% (32条)',
                        ],
                      ),
                      SizedBox(height: 16),
                      _ReportSection(
                        title: '时间趋势',
                        items: [
                          '上午活跃度: 高',
                          '下午活跃度: 中',
                          '晚间活跃度: 低',
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Export options
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    AppLocalizations.of(context)!.exportOptions,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.picture_as_pdf),
                  title: const Text('PDF 格式'),
                  subtitle: const Text('适合打印和分享'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.table_chart),
                  title: const Text('Excel 格式'),
                  subtitle: const Text('适合数据分析'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.code),
                  title: const Text('JSON 格式'),
                  subtitle: const Text('适合程序处理'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Report history
          Text(
            AppLocalizations.of(context)!.reportHistory,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          ...(_reportHistory.map((r) => _buildReportItem(r))),
        ],
      ),
    );
  }

  Widget _buildReportItem(_GeneratedReport report) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(_getReportIcon(report.type)),
        title: Text(report.title),
        subtitle: Text(
          '${_formatDate(report.generatedAt)} • ${report.size}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            PopupMenuItem(
              child: const ListTile(
                leading: Icon(Icons.download),
                title: Text('下载'),
                contentPadding: EdgeInsets.zero,
              ),
              onTap: () {},
            ),
            PopupMenuItem(
              child: const ListTile(
                leading: Icon(Icons.share),
                title: Text('分享'),
                contentPadding: EdgeInsets.zero,
              ),
              onTap: () {},
            ),
            PopupMenuItem(
              child: const ListTile(
                leading: Icon(Icons.delete),
                title: Text('删除'),
                contentPadding: EdgeInsets.zero,
              ),
              onTap: () {
                setState(() => _reportHistory.remove(report));
              },
            ),
          ],
        ),
        onTap: () {},
      ),
    );
  }

  IconData _getReportIcon(String type) {
    switch (type) {
      case 'summary':
        return Icons.summarize;
      case 'activity':
        return Icons.timeline;
      case 'productivity':
        return Icons.trending_up;
      default:
        return Icons.description;
    }
  }

  Future<void> _pickStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: _endDate,
    );
    if (date != null) {
      setState(() => _startDate = date);
    }
  }

  Future<void> _pickEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() => _endDate = date);
    }
  }

  void _setDateRange(String range) {
    final now = DateTime.now();
    switch (range) {
      case 'week':
        setState(() {
          _startDate = now.subtract(const Duration(days: 7));
          _endDate = now;
        });
        break;
      case 'month':
        setState(() {
          _startDate = DateTime(now.year, now.month, 1);
          _endDate = now;
        });
        break;
      case 'quarter':
        setState(() {
          _startDate = DateTime(now.year, ((now.month - 1) ~/ 3) * 3 + 1, 1);
          _endDate = now;
        });
        break;
    }
  }

  void _generateReport() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(AppLocalizations.of(ctx)!.generatingReport),
          ],
        ),
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('报告生成成功')),
        );
      }
    });
  }

  void _showScheduledReports() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '定时报告',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const ListTile(
            leading: Icon(Icons.calendar_today),
            title: Text('每日周报'),
            subtitle: Text('每天早上 9:00 生成'),
          ),
          const ListTile(
            leading: Icon(Icons.weekend),
            title: Text('周报告'),
            subtitle: Text('每周一生成上周报告'),
          ),
          ListTile(
            leading: const Icon(Icons.add),
            title: const Text('添加定时报告'),
            onTap: () {},
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

class _ReportTemplate {
  final String id;
  final String name;
  final String description;
  final IconData icon;

  _ReportTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
  });
}

class _GeneratedReport {
  final String title;
  final String type;
  final DateTime generatedAt;
  final String size;

  _GeneratedReport({
    required this.title,
    required this.type,
    required this.generatedAt,
    required this.size,
  });
}

class _DatePickerField extends StatelessWidget {
  final String label;
  final DateTime date;
  final VoidCallback onTap;

  const _DatePickerField({
    required this.label,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.outline),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportSection extends StatelessWidget {
  final String title;
  final List<String> items;

  const _ReportSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        ...(items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  const Text('• '),
                  Text(item),
                ],
              ),
            ))),
      ],
    );
  }
}