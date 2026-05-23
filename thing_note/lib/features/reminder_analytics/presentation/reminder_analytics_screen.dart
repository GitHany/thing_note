import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/reminder_analytics/data/reminder_analytics_repository.dart';
import 'package:thing_note/l10n/generated/app_localizations.dart';

final reminderAnalyticsProvider = Provider((ref) => ref.watch(reminderAnalyticsRepositoryProvider));

class ReminderAnalyticsScreen extends ConsumerStatefulWidget {
  const ReminderAnalyticsScreen({super.key});

  @override
  ConsumerState<ReminderAnalyticsScreen> createState() => _ReminderAnalyticsScreenState();
}

class _ReminderAnalyticsScreenState extends ConsumerState<ReminderAnalyticsScreen> {
  Map<String, dynamic> _overview = {};
  List<Map<String, dynamic>> _effectivenessByReminder = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final repo = ref.read(reminderAnalyticsProvider);
    _overview = await repo.getOverview();
    _effectivenessByReminder = await repo.getEffectivenessByReminder();
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.reminderAnalytics),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildOverviewCard(),
                    const SizedBox(height: 16),
                    _buildEffectivenessChart(),
                    const SizedBox(height: 16),
                    _buildTopReminders(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildOverviewCard() {
    final totalReminders = _overview['totalReminders'] ?? 0;
    final actionTaken = _overview['actionTakenCount'] ?? 0;
    final snoozed = _overview['snoozedCount'] ?? 0;
    final avgEffectiveness = (_overview['avgEffectiveness'] ?? 0.0) as double;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.analytics, color: Colors.blue),
                const SizedBox(width: 8),
                Text('提醒效果概览', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _StatCard(
                  icon: Icons.notifications,
                  value: '$totalReminders',
                  label: '总提醒数',
                  color: Colors.blue,
                )),
                const SizedBox(width: 12),
                Expanded(child: _StatCard(
                  icon: Icons.check_circle,
                  value: '$actionTaken',
                  label: '已执行',
                  color: Colors.green,
                )),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _StatCard(
                  icon: Icons.snooze,
                  value: '$snoozed',
                  label: '被延迟',
                  color: Colors.orange,
                )),
                const SizedBox(width: 12),
                Expanded(child: _StatCard(
                  icon: Icons.trending_up,
                  value: '${(avgEffectiveness * 100).round()}%',
                  label: '平均效果',
                  color: Colors.purple,
                )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEffectivenessChart() {
    final avgEffectiveness = (_overview['avgEffectiveness'] ?? 0.0) as double;
    final color = avgEffectiveness >= 0.7
        ? Colors.green
        : avgEffectiveness >= 0.4
            ? Colors.orange
            : Colors.red;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text('整体提醒效果', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 24),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: CircularProgressIndicator(
                    value: avgEffectiveness,
                    strokeWidth: 12,
                    backgroundColor: Colors.grey.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
                Column(
                  children: [
                    Text(
                      '${(avgEffectiveness * 100).round()}%',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                    ),
                    Text(
                      _getEffectivenessLabel(avgEffectiveness),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _getEffectivenessHint(avgEffectiveness),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  String _getEffectivenessLabel(double score) {
    if (score >= 0.8) return '优秀';
    if (score >= 0.6) return '良好';
    if (score >= 0.4) return '一般';
    return '待改进';
  }

  String _getEffectivenessHint(double score) {
    if (score >= 0.8) return '🎉 你的提醒设置非常有效！';
    if (score >= 0.6) return '👍 提醒效果不错，继续保持！';
    if (score >= 0.4) return '💡 可以调整提醒时间提高效果';
    return '📈 建议重新评估提醒策略';
  }

  Widget _buildTopReminders() {
    if (_effectivenessByReminder.isEmpty) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.notifications_off, size: 48, color: Colors.grey),
            SizedBox(height: 8),
            Text('暂无提醒数据'),
            SizedBox(height: 8),
            Text('创建提醒后会显示效果分析'),
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
            Text('各提醒效果排名', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _effectivenessByReminder.length,
              itemBuilder: (context, index) {
                final item = _effectivenessByReminder[index];
                final total = item['total'] as int? ?? 0;
                final actions = item['actions'] as int? ?? 0;
                final effectiveness = (item['effectiveness'] as num?)?.toDouble() ?? 0;
                final rate = total > 0 ? (actions / total * 100).round() : 0;

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: effectiveness >= 0.7
                        ? Colors.green.withOpacity(0.2)
                        : effectiveness >= 0.4
                            ? Colors.orange.withOpacity(0.2)
                            : Colors.red.withOpacity(0.2),
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: effectiveness >= 0.7
                            ? Colors.green
                            : effectiveness >= 0.4
                                ? Colors.orange
                                : Colors.red,
                      ),
                    ),
                  ),
                  title: Text('提醒 #${item['reminder_id']}'),
                  subtitle: Text('执行率: $rate% ($actions/$total)'),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: effectiveness >= 0.7
                          ? Colors.green.withOpacity(0.2)
                          : effectiveness >= 0.4
                              ? Colors.orange.withOpacity(0.2)
                              : Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${(effectiveness * 100).round()}%',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: effectiveness >= 0.7
                            ? Colors.green
                            : effectiveness >= 0.4
                                ? Colors.orange
                                : Colors.red,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}