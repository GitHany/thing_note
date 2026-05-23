import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/energy_mood_correlation/data/correlation_provider.dart';
import 'package:thing_note/features/energy_mood_correlation/domain/correlation_model.dart';

class EnergyMoodCorrelationScreen extends ConsumerWidget {
  const EnergyMoodCorrelationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(energyMoodStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('能量情绪关联'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Stats Overview
            statsAsync.when(
              data: (stats) => _buildStatsOverview(context, stats),
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const SizedBox(),
            ),
            
            // Insights Section
            statsAsync.when(
              data: (stats) => _buildInsightsSection(context, stats),
              loading: () => const SizedBox(),
              error: (_, __) => const SizedBox(),
            ),
            
            // Record New
            _buildRecordSection(context, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsOverview(BuildContext context, EnergyMoodStats stats) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple, Colors.purple.shade300],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Text(
            '关联分析',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('平均能量', stats.averageEnergy.toStringAsFixed(1), Icons.bolt),
              _buildStatItem('平均情绪', stats.averageMood.toStringAsFixed(1), Icons.mood),
              _buildStatItem('关联度', '${(stats.correlation * 100).toInt()}%', Icons.link),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTimeItem('最佳能量时段', stats.peakEnergyTime),
              _buildTimeItem('最佳情绪时段', stats.bestMoodTime),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 4),
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

  Widget _buildTimeItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildInsightsSection(BuildContext context, EnergyMoodStats stats) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb, color: Colors.amber),
              const SizedBox(width: 8),
              Text(
                '洞察分析',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...stats.insights.map((insight) => _buildInsightCard(context, insight)),
        ],
      ),
    );
  }

  Widget _buildInsightCard(BuildContext context, CorrelationInsight insight) {
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    insight.factor,
                    style: const TextStyle(
                      color: Colors.purple,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '置信度: ${(insight.confidence * 100).toInt()}%',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(insight.insight),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: insight.recommendations.map((rec) => Chip(
                label: Text(rec, style: const TextStyle(fontSize: 12)),
                backgroundColor: Colors.green.withOpacity(0.1),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordSection(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '记录当前状态',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    const Text('能量'),
                    Slider(
                      value: 5,
                      min: 1,
                      max: 10,
                      divisions: 9,
                      label: '5',
                      onChanged: (value) {},
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    const Text('情绪'),
                    Slider(
                      value: 5,
                      min: 1,
                      max: 10,
                      divisions: 9,
                      label: '5',
                      onChanged: (value) {},
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Center(
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('状态已记录')),
                );
              },
              child: const Text('保存记录'),
            ),
          ),
        ],
      ),
    );
  }
}