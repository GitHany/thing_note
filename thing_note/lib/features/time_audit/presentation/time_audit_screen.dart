import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/mood_correlation/data/mood_correlation_provider.dart';

class TimeAuditScreen extends ConsumerWidget {
  const TimeAuditScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auditAsync = ref.watch(timeAuditProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('时间审计'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(timeAuditProvider),
          ),
        ],
      ),
      body: auditAsync.when(
        data: (audit) => _buildAuditContent(context, audit),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildAuditContent(BuildContext context, TimeAudit audit) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Cards
          _buildSummarySection(context, audit),
          const SizedBox(height: 24),
          
          // Peak Hours
          _buildPeakHoursSection(context, audit),
          const SizedBox(height: 24),
          
          // Day Distribution
          _buildDayDistributionSection(context, audit),
          const SizedBox(height: 24),
          
          // Top Activities
          _buildTopActivitiesSection(context, audit),
          const SizedBox(height: 24),
          
          // Insights
          _buildInsightsSection(context, audit),
        ],
      ),
    );
  }

  Widget _buildSummarySection(BuildContext context, TimeAudit audit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '本周概览',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                context,
                '总时长',
                '${audit.totalHours.toStringAsFixed(1)}小时',
                Icons.timer,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                context,
                '记录数',
                '${audit.recordCount}条',
                Icons.list_alt,
                Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                context,
                '日均时长',
                '${(audit.averagePerDay / 60).toStringAsFixed(1)}小时',
                Icons.calendar_today,
                Colors.purple,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                context,
                '最佳日',
                audit.bestDay,
                Icons.star,
                Colors.orange,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(title, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeakHoursSection(BuildContext context, TimeAudit audit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.access_time, size: 20),
            const SizedBox(width: 8),
            Text(
              '高效时段',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          '本周你最活跃的时间段',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: audit.peakHours.map((hour) {
            return Chip(
              avatar: const Icon(Icons.schedule, size: 16),
              label: Text(hour),
              backgroundColor: Colors.blue.withOpacity(0.1),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDayDistributionSection(BuildContext context, TimeAudit audit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.calendar_view_week, size: 20),
            const SizedBox(width: 8),
            Text(
              '周分布',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(7, (index) {
                final day = index + 1;
                final minutes = audit.dayDistribution[day] ?? 0;
                final maxMinutes = audit.dayDistribution.values.isEmpty 
                    ? 1 
                    : audit.dayDistribution.values.reduce((a, b) => a > b ? a : b);
                final height = maxMinutes > 0 ? (minutes / maxMinutes * 60).clamp(20.0, 80.0) : 20.0;
                
                return Column(
                  children: [
                    Container(
                      width: 30,
                      height: height,
                      decoration: BoxDecoration(
                        color: minutes > 0 ? Colors.blue : Colors.grey.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getDayShortName(day),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopActivitiesSection(BuildContext context, TimeAudit audit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.category, size: 20),
            const SizedBox(width: 8),
            Text(
              '耗时排行',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (audit.topActivities.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Text(
                  '暂无数据',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
            ),
          )
        else
          ...audit.topActivities.asMap().entries.map((entry) {
            final index = entry.key;
            final activity = entry.value;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getRankColor(index).withOpacity(0.1),
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: _getRankColor(index),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(activity.name),
                subtitle: LinearProgressIndicator(
                  value: activity.minutes / (audit.totalMinutes > 0 ? audit.totalMinutes : 1),
                  backgroundColor: Colors.grey.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(_getRankColor(index)),
                ),
                trailing: Text(
                  '${activity.minutes}分钟',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildInsightsSection(BuildContext context, TimeAudit audit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.lightbulb, size: 20, color: Colors.amber),
            const SizedBox(width: 8),
            Text(
              '智能洞察',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          color: Colors.amber.withOpacity(0.1),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ..._generateInsights(audit),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _generateInsights(TimeAudit audit) {
    final insights = <Widget>[];
    
    // Check if morning person
    final morningMinutes = audit.hourDistribution.entries
        .where((e) => e.key >= 6 && e.key < 12)
        .fold(0, (sum, e) => sum + e.value);
    final eveningMinutes = audit.hourDistribution.entries
        .where((e) => e.key >= 18 && e.key < 24)
        .fold(0, (sum, e) => sum + e.value);
    
    if (morningMinutes > eveningMinutes * 1.5) {
      insights.add(_buildInsightItem('🌅 你是个早起型的人，早晨效率最高'));
    } else if (eveningMinutes > morningMinutes * 1.5) {
      insights.add(_buildInsightItem('🌙 你是个夜猫子，晚上工作状态更好'));
    }
    
    // Check consistency
    if (audit.dayDistribution.values.every((v) => v > 0)) {
      insights.add(_buildInsightItem('📅 你的时间分配非常均衡，每天都有记录'));
    }
    
    // Best day recommendation
    insights.add(_buildInsightItem('💡 ${audit.bestDay}是你最活跃的日子，适合安排重要任务'));
    
    // Peak hours recommendation
    if (audit.peakHours.isNotEmpty) {
      insights.add(_buildInsightItem('⏰ 建议在 ${audit.peakHours.first} 左右处理复杂任务'));
    }
    
    return insights;
  }

  Widget _buildInsightItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  String _getDayShortName(int day) {
    const names = ['一', '二', '三', '四', '五', '六', '日'];
    return names[day - 1];
  }

  Color _getRankColor(int index) {
    const colors = [Colors.amber, Colors.grey, Colors.orange];
    return colors[index.clamp(0, 2)];
  }
}