import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:thing_note/features/record/presentation/providers/record_provider.dart';

// Data Health Metrics
class DataHealthMetrics {
  final int totalRecords;
  final int recordsWithPhotos;
  final int recordsWithAudio;
  final int recordsWithLocation;
  final int totalTags;
  final int orphanedRecords;
  final int duplicatePotential;
  final double averageNoteLength;
  final double dataCompleteness;
  final int lastBackupDays;

  DataHealthMetrics({
    required this.totalRecords,
    required this.recordsWithPhotos,
    required this.recordsWithAudio,
    required this.recordsWithLocation,
    required this.totalTags,
    required this.orphanedRecords,
    required this.duplicatePotential,
    required this.averageNoteLength,
    required this.dataCompleteness,
    required this.lastBackupDays,
  });
}

final dataHealthProvider = FutureProvider<DataHealthMetrics>((ref) async {
  final records = await ref.watch(recordListProvider.future);

  // Calculate metrics
  final recordsWithPhotos = records.where((r) => r.hasPhotos).length;
  final recordsWithAudio = records.where((r) => r.hasAudio).length;
  final recordsWithLocation = records.where((r) => r.hasLocation).length;
  
  // Calculate average note length
  final totalNoteLength = records.fold<int>(0, (sum, r) => sum + r.note.length);
  final averageNoteLength = records.isEmpty ? 0.0 : totalNoteLength / records.length;

  // Estimate data completeness (simplified)
  final dataCompleteness = _calculateCompleteness(
    recordsWithPhotos,
    recordsWithAudio,
    recordsWithLocation,
    records.length,
  );

  return DataHealthMetrics(
    totalRecords: records.length,
    recordsWithPhotos: recordsWithPhotos,
    recordsWithAudio: recordsWithAudio,
    recordsWithLocation: recordsWithLocation,
    totalTags: 0, // Would need tag provider
    orphanedRecords: records.where((r) => r.note.isEmpty && !r.hasPhotos && !r.hasAudio).length,
    duplicatePotential: _findDuplicatePotential(records),
    averageNoteLength: averageNoteLength,
    dataCompleteness: dataCompleteness,
    lastBackupDays: 3, // Would need backup provider
  );
});

double _calculateCompleteness(int photos, int audio, int location, int total) {
  if (total == 0) return 0.0;
  double score = 0.0;
  score += (photos / total) * 30; // Photos contribute 30%
  score += (audio / total) * 20; // Audio contributes 20%
  score += (location / total) * 20; // Location contributes 20%
  score += 30; // Base completeness for having records
  return score.clamp(0.0, 100.0);
}

int _findDuplicatePotential(List records) {
  // Simplified duplicate detection
  return 0;
}

class DataHealthDashboardScreen extends ConsumerWidget {
  const DataHealthDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final healthAsync = ref.watch(dataHealthProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('数据健康仪表盘'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(dataHealthProvider),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showSettings(context),
          ),
        ],
      ),
      body: healthAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('加载失败: $err')),
        data: (metrics) => _buildContent(context, metrics),
      ),
    );
  }

  Widget _buildContent(BuildContext context, DataHealthMetrics metrics) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOverallScore(context, metrics),
          const SizedBox(height: 16),
          _buildMetricsGrid(context, metrics),
          const SizedBox(height: 16),
          _buildHealthIssues(context, metrics),
          const SizedBox(height: 16),
          _buildRecommendations(context, metrics),
        ],
      ),
    );
  }

  Widget _buildOverallScore(BuildContext context, DataHealthMetrics metrics) {
    final score = metrics.dataCompleteness;
    final color = score >= 80
        ? Colors.green
        : score >= 60
            ? Colors.orange
            : Colors.red;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              '数据健康评分',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 150,
                  height: 150,
                  child: CircularProgressIndicator(
                    value: score / 100,
                    strokeWidth: 12,
                    backgroundColor: Colors.grey.withOpacity(0.2),
                    color: color,
                  ),
                ),
                Column(
                  children: [
                    Text(
                      '${score.toInt()}',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    Text(
                      _getScoreLabel(score),
                      style: TextStyle(color: color),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _getScoreDescription(score),
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.outline),
            ),
          ],
        ),
      ),
    );
  }

  String _getScoreLabel(double score) {
    if (score >= 80) return '优秀';
    if (score >= 60) return '良好';
    if (score >= 40) return '一般';
    return '需改进';
  }

  String _getScoreDescription(double score) {
    if (score >= 80) return '数据质量很好，继续保持！';
    if (score >= 60) return '数据质量不错，可进一步优化';
    if (score >= 40) return '建议增加更多详细信息';
    return '需要改善数据质量';
  }

  Widget _buildMetricsGrid(BuildContext context, DataHealthMetrics metrics) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '详细指标',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _buildMetricCard(
              context,
              '总记录数',
              metrics.totalRecords.toString(),
              Icons.note,
              Colors.blue,
            ),
            _buildMetricCard(
              context,
              '带照片',
              metrics.recordsWithPhotos.toString(),
              Icons.photo,
              Colors.green,
            ),
            _buildMetricCard(
              context,
              '带语音',
              metrics.recordsWithAudio.toString(),
              Icons.mic,
              Colors.orange,
            ),
            _buildMetricCard(
              context,
              '带位置',
              metrics.recordsWithLocation.toString(),
              Icons.location_on,
              Colors.purple,
            ),
            _buildMetricCard(
              context,
              '平均字数',
              '${metrics.averageNoteLength.toStringAsFixed(0)}字',
              Icons.text_fields,
              Colors.teal,
            ),
            _buildMetricCard(
              context,
              '上次备份',
              '${metrics.lastBackupDays}天前',
              Icons.backup,
              Colors.red,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    value,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.outline,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthIssues(BuildContext context, DataHealthMetrics metrics) {
    final issues = <Map<String, dynamic>>[];

    if (metrics.orphanedRecords > 0) {
      issues.add({
        'icon': Icons.warning,
        'color': Colors.orange,
        'title': '孤立记录',
        'description': '${metrics.orphanedRecords}条记录没有文字、图片或语音',
      });
    }

    if (metrics.lastBackupDays > 7) {
      issues.add({
        'icon': Icons.backup,
        'color': Colors.red,
        'title': '备份过期',
        'description': '上次备份已超过7天',
      });
    }

    if (metrics.averageNoteLength < 20) {
      issues.add({
        'icon': Icons.text_fields,
        'color': Colors.blue,
        'title': '记录简短',
        'description': '平均记录字数较低，建议添加更多细节',
      });
    }

    if (issues.isEmpty) {
      return Card(
        color: Colors.green.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('没有发现健康问题'),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '发现的问题',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            ...issues.map((issue) {
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  issue['icon'] as IconData,
                  color: issue['color'] as Color,
                ),
                title: Text(issue['title'] as String),
                subtitle: Text(issue['description'] as String),
                trailing: Icon(Icons.chevron_right, color: Colors.grey),
                onTap: () {
                  // Navigate to fix issue
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendations(BuildContext context, DataHealthMetrics metrics) {
    final recommendations = <String>[];

    if (metrics.totalRecords > 0) {
      final photoRate = metrics.recordsWithPhotos / metrics.totalRecords;
      if (photoRate < 0.2) {
        recommendations.add('建议增加图片记录，让回忆更生动');
      }

      final locationRate = metrics.recordsWithLocation / metrics.totalRecords;
      if (locationRate < 0.1) {
        recommendations.add('开启位置记录，便于回顾到过的地方');
      }
    }

    if (recommendations.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '优化建议',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...recommendations.map((rec) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.arrow_right,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    Expanded(child: Text(rec)),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '仪表盘设置',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('自动刷新'),
              subtitle: const Text('打开应用时自动更新数据'),
              value: true,
              onChanged: (value) {},
            ),
            SwitchListTile(
              title: const Text('异常提醒'),
              subtitle: const Text('发现问题时发送通知'),
              value: true,
              onChanged: (value) {},
            ),
          ],
        ),
      ),
    );
  }
}
