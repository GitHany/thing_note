import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/smart_habit_scheduling/data/habit_schedule_provider.dart';
import 'package:thing_note/features/smart_habit_scheduling/domain/habit_schedule_model.dart';

class SmartHabitSchedulingScreen extends ConsumerStatefulWidget {
  const SmartHabitSchedulingScreen({super.key});

  @override
  ConsumerState<SmartHabitSchedulingScreen> createState() =>
      _SmartHabitSchedulingScreenState();
}

class _SmartHabitSchedulingScreenState
    extends ConsumerState<SmartHabitSchedulingScreen> {
  @override
  Widget build(BuildContext context) {
    final schedulesAsync = ref.watch(habitScheduleNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('智能习惯排程'),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome),
            onPressed: () => _showRecommendations(context),
            tooltip: '获取推荐',
          ),
        ],
      ),
      body: schedulesAsync.when(
        data: (schedules) => _buildContent(schedules),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddScheduleDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildContent(List<HabitSchedule> schedules) {
    if (schedules.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.schedule, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              '暂无习惯排程',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              '点击 + 添加智能排程',
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: schedules.length,
      itemBuilder: (context, index) {
        final schedule = schedules[index];
        return _buildScheduleCard(schedule);
      },
    );
  }

  Widget _buildScheduleCard(HabitSchedule schedule) {
    final timeStr = schedule.scheduledHour != null
        ? '${schedule.scheduledHour!.toString().padLeft(2, '0')}:${(schedule.scheduledMinute ?? 0).toString().padLeft(2, '0')}'
        : '未设置';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: schedule.isEnabled
              ? Theme.of(context).primaryColor.withOpacity(0.2)
              : Colors.grey[300],
          child: Icon(
            Icons.schedule,
            color: schedule.isEnabled ? Theme.of(context).primaryColor : Colors.grey,
          ),
        ),
        title: Text('习惯 #${schedule.habitId}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('排程时间: $timeStr'),
            if (schedule.energyLevelNeeded != null)
              Text('所需能量: ${'⭐' * schedule.energyLevelNeeded!}'),
            Text('成功执行: ${schedule.successCount} 次'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: schedule.isEnabled,
              onChanged: (value) {
                ref.read(habitScheduleNotifierProvider.notifier).updateSchedule(
                      schedule.copyWith(isEnabled: value),
                    );
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _confirmDelete(schedule),
            ),
          ],
        ),
        onTap: () => _showEditDialog(context, schedule),
      ),
    );
  }

  void _showAddScheduleDialog(BuildContext context) {
    final habitIdController = TextEditingController();
    int selectedHour = 8;
    int selectedMinute = 0;
    int? selectedEnergy;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('添加习惯排程'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: habitIdController,
                  decoration: const InputDecoration(
                    labelText: '习惯 ID',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('排程时间: '),
                    const SizedBox(width: 8),
                    DropdownButton<int>(
                      value: selectedHour,
                      items: List.generate(24, (i) => i)
                          .map((h) => DropdownMenuItem(value: h, child: Text('$h')))
                          .toList(),
                      onChanged: (v) => setState(() => selectedHour = v!),
                    ),
                    const Text(' : '),
                    DropdownButton<int>(
                      value: selectedMinute,
                      items: [0, 15, 30, 45]
                          .map((m) => DropdownMenuItem(value: m, child: Text('$m')))
                          .toList(),
                      onChanged: (v) => setState(() => selectedMinute = v!),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int?>(
                  value: selectedEnergy,
                  decoration: const InputDecoration(
                    labelText: '所需能量等级',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('不限制')),
                    ...List.generate(10, (i) => i + 1)
                        .map((e) => DropdownMenuItem(value: e, child: Text('Level $e'))),
                  ],
                  onChanged: (v) => setState(() => selectedEnergy = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                final habitId = int.tryParse(habitIdController.text);
                if (habitId != null) {
                  final schedule = HabitSchedule(
                    id: 0,
                    habitId: habitId,
                    scheduledHour: selectedHour,
                    scheduledMinute: selectedMinute,
                    energyLevelNeeded: selectedEnergy,
                    createdAt: DateTime.now(),
                  );
                  ref.read(habitScheduleNotifierProvider.notifier).addSchedule(schedule);
                  Navigator.pop(context);
                }
              },
              child: const Text('添加'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, HabitSchedule schedule) {
    int selectedHour = schedule.scheduledHour ?? 8;
    int selectedMinute = schedule.scheduledMinute ?? 0;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('编辑排程'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Text('排程时间: '),
                  const SizedBox(width: 8),
                  DropdownButton<int>(
                    value: selectedHour,
                    items: List.generate(24, (i) => i)
                        .map((h) => DropdownMenuItem(value: h, child: Text('$h')))
                        .toList(),
                    onChanged: (v) => setState(() => selectedHour = v!),
                  ),
                  const Text(' : '),
                  DropdownButton<int>(
                    value: selectedMinute,
                    items: [0, 15, 30, 45]
                        .map((m) => DropdownMenuItem(value: m, child: Text('$m')))
                        .toList(),
                    onChanged: (v) => setState(() => selectedMinute = v!),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                ref.read(habitScheduleNotifierProvider.notifier).updateSchedule(
                      schedule.copyWith(
                        scheduledHour: selectedHour,
                        scheduledMinute: selectedMinute,
                      ),
                    );
                Navigator.pop(context);
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(HabitSchedule schedule) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这个排程吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(habitScheduleNotifierProvider.notifier).deleteSchedule(schedule.id);
              Navigator.pop(context);
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  void _showRecommendations(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '智能推荐',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            const Text('基于您的能量周期分析，以下是建议的最佳习惯执行时间：'),
            const SizedBox(height: 16),
            _buildRecommendationItem('早晨 6-8点', '适合简单习惯如冥想、拉伸', Colors.orange),
            _buildRecommendationItem('上午 9-11点', '适合需要专注的习惯如学习、写作', Colors.blue),
            _buildRecommendationItem('下午 2-4点', '适合中等难度的习惯如运动', Colors.green),
            _buildRecommendationItem('晚上 8-10点', '适合放松习惯如阅读、复盘', Colors.purple),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('知道了'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationItem(String time, String desc, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(time, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(desc, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}