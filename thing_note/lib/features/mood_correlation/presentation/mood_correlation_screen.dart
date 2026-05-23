import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/mood_correlation/data/mood_correlation_provider.dart';

class MoodCorrelationScreen extends ConsumerWidget {
  const MoodCorrelationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final correlationAsync = ref.watch(moodCorrelationProvider);
    final bestActivitiesAsync = ref.watch(bestActivitiesProvider);
    final activitiesToAvoidAsync = ref.watch(activitiesToAvoidProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('情绪关联分析'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Best Activities
            bestActivitiesAsync.when(
              data: (activities) => _buildActivitiesSection(
                context,
                '🌟 有益活动',
                activities,
                Colors.green,
                Icons.thumb_up,
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
            ),
            const SizedBox(height: 16),
            
            // Activities to Avoid
            activitiesToAvoidAsync.when(
              data: (activities) => _buildActivitiesSection(
                context,
                '⚠️ 需注意活动',
                activities,
                Colors.orange,
                Icons.warning_amber,
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
            ),
            const SizedBox(height: 24),
            
            // Full Correlation List
            Text(
              '活动情绪分布',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            correlationAsync.when(
              data: (correlations) {
                if (correlations.isEmpty) {
                  return _buildEmptyState(context);
                }
                
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: correlations.length,
                  itemBuilder: (context, index) {
                    final correlation = correlations[index];
                    return _buildCorrelationCard(context, correlation);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.insights,
              size: 64,
              color: Colors.grey.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              '数据不足',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '记录更多带情绪的日常活动，\n以获取更准确的关联分析',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivitiesSection(
    BuildContext context,
    String title,
    List<ActivityInsight> activities,
    Color color,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (activities.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '暂无数据',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
          )
        else
          ...activities.map((activity) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: color.withOpacity(0.1),
                child: Icon(icon, color: color),
              ),
              title: Text(activity.name),
              subtitle: Text(activity.reason),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${(activity.moodBoost * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${activity.sampleCount}次',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          )),
      ],
    );
  }

  Widget _buildCorrelationCard(BuildContext context, MoodCorrelation correlation) {
    final impactColor = _getImpactColor(correlation.impactScore);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    correlation.activityName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: impactColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    correlation.trend,
                    style: TextStyle(color: impactColor, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildStatItem(
                  '平均情绪',
                  correlation.avgMoodLevel.toStringAsFixed(1),
                  _getMoodColor(correlation.avgMoodLevel),
                ),
                const SizedBox(width: 24),
                _buildStatItem(
                  '样本数',
                  '${correlation.sampleCount}次',
                  Colors.blue,
                ),
                const SizedBox(width: 24),
                _buildStatItem(
                  '影响度',
                  '${(correlation.impactScore * 100).toStringAsFixed(0)}%',
                  impactColor,
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: correlation.avgMoodLevel / 5,
              backgroundColor: Colors.grey.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(_getMoodColor(correlation.avgMoodLevel)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Color _getImpactColor(double impact) {
    if (impact > 0.3) return Colors.green;
    if (impact > 0) return Colors.lightGreen;
    if (impact > -0.3) return Colors.orange;
    return Colors.red;
  }

  Color _getMoodColor(double mood) {
    if (mood >= 4) return Colors.green;
    if (mood >= 3) return Colors.blue;
    if (mood >= 2) return Colors.orange;
    return Colors.red;
  }
}