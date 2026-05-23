import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final smartReminderV3Provider = StateNotifierProvider<SmartReminderV3Notifier, List<Map<String, dynamic>>>((ref) {
  return SmartReminderV3Notifier();
});

class SmartReminderV3Notifier extends StateNotifier<List<Map<String, dynamic>>> {
  SmartReminderV3Notifier() : super([
    {'id': 1, 'title': '喝水提醒', 'time': '09:00', 'success_rate': 85, 'enabled': true},
    {'id': 2, 'title': '站立休息', 'time': '10:30', 'success_rate': 72, 'enabled': true},
    {'id': 3, 'title': '眼保健操', 'time': '14:00', 'success_rate': 90, 'enabled': true},
  ]);

  void toggleReminder(int id) {}
  void deleteReminder(int id) {}
}

class SmartReminderV3Screen extends ConsumerWidget {
  const SmartReminderV3Screen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reminders = ref.watch(smartReminderV3Provider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('智能提醒 V3'),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome),
            onPressed: () => _showOptimizer(context),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildOptimizationCard(context),
          Expanded(
            child: reminders.isEmpty
                ? _buildEmptyState(context)
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: reminders.length,
                    itemBuilder: (context, index) {
                      final reminder = reminders[index];
                      return _ReminderCard(
                        reminder: reminder,
                        onToggle: () => ref.read(smartReminderV3Provider.notifier).toggleReminder(reminder['id'] as int),
                        onDelete: () => ref.read(smartReminderV3Provider.notifier).deleteReminder(reminder['id'] as int),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addReminder(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildOptimizationCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.blue, Colors.purple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: Colors.white),
              SizedBox(width: 8),
              Text('智能优化', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          SizedBox(height: 12),
          Text(
            '基于你的习惯，最佳提醒时间：',
            style: TextStyle(color: Colors.white70),
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _TimeChip(label: '09:00', confidence: '高'),
              _TimeChip(label: '11:30', confidence: '中'),
              _TimeChip(label: '15:00', confidence: '高'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('暂无提醒', style: TextStyle(fontSize: 18)),
          SizedBox(height: 8),
          Text('创建智能提醒，优化你的日程', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  void _showOptimizer(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('智能优化建议', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Text('💡 基于你的行为模式，我们建议：'),
            const SizedBox(height: 8),
            const Text('• 喝水提醒从 09:00 调整到 09:30'),
            const Text('• 添加 12:00 午休提醒'),
            const Text('• 晚间提醒从 21:00 调整到 21:30'),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('忽略'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('应用'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _addReminder(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加提醒'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(labelText: '提醒名称'),
            ),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(labelText: '时间'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  final String label;
  final String confidence;

  const _TimeChip({required this.label, required this.confidence});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          Text(confidence, style: const TextStyle(color: Colors.white70, fontSize: 10)),
        ],
      ),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  final Map<String, dynamic> reminder;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _ReminderCard({
    required this.reminder,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final title = reminder['title'] as String;
    final time = reminder['time'] as String;
    final successRate = reminder['success_rate'] as int;
    final enabled = reminder['enabled'] as bool;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _getSuccessColor(successRate).withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Icon(Icons.notifications, color: _getSuccessColor(successRate)),
          ),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(time),
            const SizedBox(height: 4),
            Row(
              children: [
                const Text('成功率: ', style: TextStyle(fontSize: 12)),
                Text(
                  '$successRate%',
                  style: TextStyle(
                    fontSize: 12,
                    color: _getSuccessColor(successRate),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: enabled,
              onChanged: (value) => onToggle(),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }

  Color _getSuccessColor(int rate) {
    if (rate >= 80) return Colors.green;
    if (rate >= 60) return Colors.orange;
    return Colors.red;
  }
}