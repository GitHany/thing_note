import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/water_intake/data/water_intake_repository.dart';
import 'package:thing_note/features/water_intake/domain/water_intake_record.dart';

class WaterIntakeScreen extends ConsumerWidget {
  const WaterIntakeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayAsync = ref.watch(waterIntakeTodayProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('饮水追踪'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showSettingsDialog(context, ref),
          ),
        ],
      ),
      body: todayAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('错误: $e')),
        data: (record) => _buildContent(context, ref, record),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, WaterIntakeRecord? record) {
    final record_ = record ?? _defaultRecord();
    final progress = record_.progressPercent;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 进度圆环
          Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade200, width: 12),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.water_drop, size: 32, color: Colors.blue),
                  const SizedBox(height: 8),
                  Text(
                    '${record_.totalMl} ml',
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${record_.glasses} 杯',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // 进度条
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation(progress >= 1.0 ? Colors.green : Colors.blue),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            progress >= 1.0
                ? '今日目标达成！🎉'
                : '还差 ${record_.remainingMl} ml (${record_.remainingGlasses} 杯)',
            style: TextStyle(
              color: progress >= 1.0 ? Colors.green : Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          // 快速添加按钮
          const Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _GlassButton(label: '+1杯', ml: 250, icon: Icons.local_drink),
              _GlassButton(label: '+2杯', ml: 500, icon: Icons.local_cafe),
              _GlassButton(label: '+3杯', ml: 750, icon: Icons.water),
              _GlassButton(label: '自定义', ml: 0, icon: Icons.add, isCustom: true),
            ],
          ),
          const SizedBox(height: 24),
          // 周统计
          _WeeklyWaterChart(),
        ],
      ),
    );
  }

  WaterIntakeRecord _defaultRecord() {
    final now = DateTime.now();
    return WaterIntakeRecord(
      date: '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
      createdAt: now,
      updatedAt: now,
    );
  }

  void _showSettingsDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController(text: '2000');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('每日饮水目标'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: '目标 (ml)',
            hintText: '例如: 2000',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              final goal = int.tryParse(controller.text) ?? 2000;
              final now = DateTime.now();
              final date = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
              ref.read(waterIntakeRepositoryProvider).setGoalMl(date, goal);
              ref.invalidate(waterIntakeTodayProvider);
              Navigator.pop(context);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }
}

class _GlassButton extends ConsumerWidget {
  final String label;
  final int ml;
  final IconData icon;
  final bool isCustom;

  const _GlassButton({
    required this.label,
    required this.ml,
    required this.icon,
    this.isCustom = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton.icon(
      onPressed: () async {
        if (isCustom) {
          final result = await showDialog<int>(
            context: context,
            builder: (ctx) => _CustomMlDialog(),
          );
          if (result != null && result > 0) {
            await ref.read(waterIntakeRepositoryProvider).addGlass(_todayDate);
            ref.invalidate(waterIntakeTodayProvider);
          }
        } else {
          final now = DateTime.now();
          final date = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
          for (int i = 0; i < (ml ~/ 250); i++) {
            await ref.read(waterIntakeRepositoryProvider).addGlass(date);
          }
          ref.invalidate(waterIntakeTodayProvider);
        }
      },
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue.shade50,
        foregroundColor: Colors.blue.shade700,
      ),
    );
  }

  String get _todayDate {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}

class _CustomMlDialog extends StatefulWidget {
  @override
  State<_CustomMlDialog> createState() => _CustomMlDialogState();
}

class _CustomMlDialogState extends State<_CustomMlDialog> {
  final _ctrl = TextEditingController(text: '250');
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('自定义饮水量'),
      content: TextField(
        controller: _ctrl,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(labelText: 'ml'),
        autofocus: true,
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
        TextButton(
          onPressed: () => Navigator.pop(context, int.tryParse(_ctrl.text)),
          child: const Text('确定'),
        ),
      ],
    );
  }
}

class _WeeklyWaterChart extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weeklyAsync = ref.watch(waterIntakeWeeklyProvider);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('本周饮水', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            weeklyAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (e, st) => Text('加载失败: $e'),
              data: (records) {
                final days = ['一', '二', '三', '四', '五', '六', '日'];
                final now = DateTime.now();
                final weekStart = now.subtract(Duration(days: now.weekday - 1));
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(7, (i) {
                    final day = weekStart.add(Duration(days: i));
                    final dateStr = '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
                    final record = records.where((r) => r.date == dateStr).firstOrNull;
                    final ml = record?.totalMl ?? 0;
                    final height = (ml / 2000 * 80).clamp(4.0, 80.0);
                    return Column(
                      children: [
                        Container(
                          width: 28,
                          height: height,
                          decoration: BoxDecoration(
                            color: ml >= 2000 ? Colors.blue : Colors.blue.shade200,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(days[i], style: const TextStyle(fontSize: 12)),
                        Text('${(ml / 1000).toStringAsFixed(1)}L', style: const TextStyle(fontSize: 10)),
                      ],
                    );
                  }),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
