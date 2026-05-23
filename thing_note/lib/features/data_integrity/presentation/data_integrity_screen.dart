import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/data_integrity/data/data_integrity_provider.dart';

class DataIntegrityScreen extends ConsumerWidget {
  const DataIntegrityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(dataIntegrityCheckProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('数据完整性'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(dataIntegrityCheckProvider),
          ),
        ],
      ),
      body: reportAsync.when(
        data: (report) => _buildReport(context, report),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildReport(BuildContext context, DataIntegrityReport report) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Score Card
          _buildScoreCard(context, report),
          const SizedBox(height: 24),
          
          // Summary Stats
          _buildSummarySection(context, report),
          const SizedBox(height: 24),
          
          // Issues List
          Text(
            '发现的问题',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          if (report.issues.isEmpty)
            _buildNoIssuesState(context)
          else
            ...report.issues.map((issue) => _buildIssueCard(context, issue)),
          
          const SizedBox(height: 24),
          
          // Quick Actions
          _buildQuickActions(context),
        ],
      ),
    );
  }

  Widget _buildScoreCard(BuildContext context, DataIntegrityReport report) {
    return Card(
      color: report.scoreColor.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 100,
                  height: 100,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: report.overallScore / 100,
                        strokeWidth: 8,
                        backgroundColor: Colors.grey.withOpacity(0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(report.scoreColor),
                      ),
                      Text(
                        '${report.overallScore.toInt()}',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: report.scoreColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '数据健康度',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: report.scoreColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                report.scoreLabel,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummarySection(BuildContext context, DataIntegrityReport report) {
    final errorCount = report.issues.where((i) => i.severity == Severity.error).length;
    final warningCount = report.issues.where((i) => i.severity == Severity.warning).length;
    final infoCount = report.issues.where((i) => i.severity == Severity.info).length;

    return Row(
      children: [
        _buildStatCard(
          context,
          '错误',
          errorCount.toString(),
          Icons.error,
          Colors.red,
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          context,
          '警告',
          warningCount.toString(),
          Icons.warning,
          Colors.orange,
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          context,
          '提示',
          infoCount.toString(),
          Icons.info,
          Colors.blue,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 8),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoIssuesState(BuildContext context) {
    return Card(
      color: Colors.green.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const Icon(Icons.check_circle, size: 64, color: Colors.green),
            const SizedBox(height: 16),
            Text(
              '数据完整',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '未发现数据问题',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIssueCard(BuildContext context, DataIntegrityIssue issue) {
    final severityColor = _getSeverityColor(issue.severity);
    final severityIcon = _getSeverityIcon(issue.severity);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: severityColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(severityIcon, color: severityColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        issue.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '影响 ${issue.affectedCount} 项',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: severityColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              issue.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (issue.fixSuggestion != null) ...[
              const SizedBox(height: 8),
              Text(
                '修复建议: ${issue.fixSuggestion}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.blue,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () => _fixIssue(context, issue),
                  icon: const Icon(Icons.build, size: 16),
                  label: const Text('修复'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => _ignoreIssue(context, issue),
                  icon: const Icon(Icons.visibility_off, size: 16),
                  label: const Text('忽略'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '快速操作',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildActionChip(context, '清理孤立记录', Icons.cleaning_services),
            _buildActionChip(context, '压缩媒体', Icons.compress),
            _buildActionChip(context, '导出备份', Icons.backup),
            _buildActionChip(context, '检查重复', Icons.find_in_page),
          ],
        ),
      ],
    );
  }

  Widget _buildActionChip(BuildContext context, String label, IconData icon) {
    return ActionChip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('执行 $label...')),
        );
      },
    );
  }

  Color _getSeverityColor(Severity severity) {
    switch (severity) {
      case Severity.error:
        return Colors.red;
      case Severity.warning:
        return Colors.orange;
      case Severity.info:
        return Colors.blue;
    }
  }

  IconData _getSeverityIcon(Severity severity) {
    switch (severity) {
      case Severity.error:
        return Icons.error;
      case Severity.warning:
        return Icons.warning;
      case Severity.info:
        return Icons.info;
    }
  }

  void _fixIssue(BuildContext context, DataIntegrityIssue issue) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('正在修复: ${issue.title}')),
    );
  }

  void _ignoreIssue(BuildContext context, DataIntegrityIssue issue) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已忽略: ${issue.title}')),
    );
  }
}