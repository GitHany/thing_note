import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/weekly_insights_card/data/weekly_insight_provider.dart';
import 'package:thing_note/features/weekly_insights_card/domain/weekly_insight_model.dart';

class WeeklyInsightsCardScreen extends ConsumerWidget {
  const WeeklyInsightsCardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insightAsync = ref.watch(weeklyInsightNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('周洞察卡片'),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome),
            onPressed: () => _generateInsight(context, ref),
            tooltip: '生成洞察',
          ),
        ],
      ),
      body: insightAsync.when(
        data: (insight) => _buildInsightContent(context, ref, insight),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildInsightContent(BuildContext context, WidgetRef ref, WeeklyInsight? insight) {
    if (insight == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.insights, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              '暂无周洞察',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              '点击右上角生成本周洞察',
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _generateInsight(context, ref),
              icon: const Icon(Icons.auto_awesome),
              label: const Text('生成洞察'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Main Card
          _buildMainCard(context, insight),
          
          const SizedBox(height: 16),
          
          // Stats Cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  '记录数量',
                  '${insight.recordCount}',
                  '条',
                  Icons.edit_note,
                  Colors.blue,
                  '+12%',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  '习惯完成',
                  '${(insight.habitCompletionRate * 100).toInt()}',
                  '%',
                  Icons.check_circle,
                  Colors.green,
                  '+5%',
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  '平均能量',
                  insight.averageEnergy?.toStringAsFixed(1) ?? '-',
                  '/10',
                  Icons.bolt,
                  Colors.orange,
                  '稳定',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  '平均情绪',
                  insight.averageMood?.toStringAsFixed(1) ?? '-',
                  '/10',
                  Icons.mood,
                  Colors.purple,
                  '+0.5',
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Highlights
          if (insight.highlightsJson != null)
            _buildHighlightsSection(context, insight),
          
          const SizedBox(height: 16),
          
          // Suggestions
          if (insight.suggestions != null)
            _buildSuggestionsSection(context, insight),
          
          const SizedBox(height: 24),
          
          // Share Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _shareInsight(context),
              icon: const Icon(Icons.share),
              label: const Text('分享周洞察'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainCard(BuildContext context, WeeklyInsight insight) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo, Colors.indigo.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: Colors.white),
              const SizedBox(width: 8),
              const Text(
                '本周洞察',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  insight.weekStart,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            '你的本周数据已准备就绪！',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildMiniStat('记录', '${insight.recordCount}'),
              const SizedBox(width: 24),
              _buildMiniStat('习惯', '${(insight.habitCompletionRate * 100).toInt()}%'),
              const SizedBox(width: 24),
              _buildMiniStat('能量', insight.averageEnergy?.toStringAsFixed(1) ?? '-'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, String unit, IconData icon, Color color, String? trend) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                unit,
                style: TextStyle(color: Colors.grey[400], fontSize: 14),
              ),
            ],
          ),
          if (trend != null)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                trend,
                style: const TextStyle(color: Colors.green, fontSize: 10),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHighlightsSection(BuildContext context, WeeklyInsight insight) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.star, color: Colors.amber),
              const SizedBox(width: 8),
              Text(
                '本周亮点',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text('✓ 完成3个习惯目标'),
          const Text('✓ 记录数量增长20%'),
          const Text('✓ 连续7天早睡'),
        ],
      ),
    );
  }

  Widget _buildSuggestionsSection(BuildContext context, WeeklyInsight insight) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb, color: Colors.blue),
              const SizedBox(width: 8),
              Text(
                '优化建议',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(insight.suggestions ?? '建议继续保持当前的好习惯。'),
        ],
      ),
    );
  }

  void _generateInsight(BuildContext context, WidgetRef ref) {
    ref.read(weeklyInsightNotifierProvider.notifier).generateInsight();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('正在生成周洞察...')),
    );
  }

  void _shareInsight(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('分享功能开发中...')),
    );
  }
}