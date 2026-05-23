import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/daily_briefing_widget/data/briefing_provider.dart';
import 'package:thing_note/features/daily_briefing_widget/domain/briefing_model.dart';

class DailyBriefingWidgetScreen extends ConsumerWidget {
  const DailyBriefingWidgetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final briefingAsync = ref.watch(dailyBriefingProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('每日简报小组件'),
        actions: [
          IconButton(
            icon: const Icon(Icons.widgets),
            onPressed: () => _showWidgetSelector(context),
            tooltip: '组件配置',
          ),
        ],
      ),
      body: briefingAsync.when(
        data: (briefing) => _buildBriefingView(context, briefing),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  void _showWidgetSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('选择小组件', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.check_circle),
              title: const Text('今日完成'),
              onTap: () => Navigator.pop(ctx),
            ),
            ListTile(
              leading: const Icon(Icons.trending_up),
              title: const Text('能量趋势'),
              onTap: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBriefingView(BuildContext context, DailyBriefing briefing) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildWeatherCard(briefing),
        const SizedBox(height: 16),
        _buildHabitProgress(briefing),
        const SizedBox(height: 16),
        _buildTodoList(briefing),
      ],
    );
  }

  Widget _buildWeatherCard(DailyBriefing briefing) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              _getWeatherIcon(briefing.weather),
              size: 48,
              color: Colors.blue,
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(briefing.weather, style: const TextStyle(fontSize: 20)),
                Text('${briefing.temperature}°C', style: const TextStyle(fontSize: 16)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHabitProgress(DailyBriefing briefing) {
    final progress = briefing.habitCount > 0 
        ? briefing.completedHabits / briefing.habitCount 
        : 0.0;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('习惯进度', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: progress),
            Text('${briefing.completedHabits}/${briefing.habitCount}'),
          ],
        ),
      ),
    );
  }

  Widget _buildTodoList(DailyBriefing briefing) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('今日待办', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...briefing.todoItems.map((item) => ListTile(
              leading: const Icon(Icons.circle_outlined, size: 20),
              title: Text(item),
              contentPadding: EdgeInsets.zero,
            )),
          ],
        ),
      ),
    );
  }

  IconData _getWeatherIcon(String weather) {
    switch (weather) {
      case '晴':
        return Icons.wb_sunny;
      case '多云':
        return Icons.cloud;
      case '阴':
        return Icons.cloud_queue;
      case '小雨':
        return Icons.grain;
      default:
        return Icons.wb_cloudy;
    }
  }
}