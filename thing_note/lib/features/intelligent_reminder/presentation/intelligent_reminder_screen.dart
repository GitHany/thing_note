import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/intelligent_reminder/data/intelligent_reminder_repository.dart';
import 'package:thing_note/features/intelligent_reminder/domain/intelligent_reminder.dart';

final intelligentReminderRepoProvider = Provider((ref) => IntelligentReminderRepository(ref));

class IntelligentReminderScreen extends ConsumerStatefulWidget {
  const IntelligentReminderScreen({super.key});

  @override
  ConsumerState<IntelligentReminderScreen> createState() => _IntelligentReminderScreenState();
}

class _IntelligentReminderScreenState extends ConsumerState<IntelligentReminderScreen> {
  List<IntelligentReminder> _reminders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    setState(() => _isLoading = true);
    final repo = ref.read(intelligentReminderRepoProvider);
    _reminders = await repo.getAllReminders();
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('智能提醒'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _reminders.isEmpty
              ? _buildEmptyState()
              : _buildReminderList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.notifications_active, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('暂无智能提醒', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 8),
          const Text('创建基于行为模式的智能提醒'),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _showAddDialog,
            icon: const Icon(Icons.add),
            label: const Text('创建提醒'),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _reminders.length,
      itemBuilder: (context, index) {
        final reminder = _reminders[index];
        return _ReminderCard(
          reminder: reminder,
          onToggle: () => _toggleReminder(reminder),
          onDelete: () => _deleteReminder(reminder.id!),
        );
      },
    );
  }

  void _showAddDialog() {
    final titleController = TextEditingController();
    String triggerType = 'time';
    String actionType = 'notification';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('创建智能提醒'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: '提醒标题'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: triggerType,
                  decoration: const InputDecoration(labelText: '触发类型'),
                  items: const [
                    DropdownMenuItem(value: 'time', child: Text('⏰ 时间')),
                    DropdownMenuItem(value: 'location', child: Text('📍 位置')),
                    DropdownMenuItem(value: 'behavior', child: Text('🎯 行为')),
                    DropdownMenuItem(value: 'mood', child: Text('😊 情绪')),
                  ],
                  onChanged: (v) => setDialogState(() => triggerType = v!),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: actionType,
                  decoration: const InputDecoration(labelText: '动作类型'),
                  items: const [
                    DropdownMenuItem(value: 'notification', child: Text('🔔 通知')),
                    DropdownMenuItem(value: 'record', child: Text('📝 创建记录')),
                    DropdownMenuItem(value: 'habit', child: Text('✅ 习惯打卡')),
                  ],
                  onChanged: (v) => setDialogState(() => actionType = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () async {
                if (titleController.text.trim().isEmpty) return;
                final repo = ref.read(intelligentReminderRepoProvider);
                await repo.insertReminder(IntelligentReminder(
                  title: titleController.text.trim(),
                  triggerType: triggerType,
                  actionType: actionType,
                  createdAt: DateTime.now(),
                ));
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                _loadReminders();
              },
              child: const Text('创建'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleReminder(IntelligentReminder reminder) async {
    final repo = ref.read(intelligentReminderRepoProvider);
    await repo.toggleEnabled(reminder.id!, !reminder.isEnabled);
    _loadReminders();
  }

  Future<void> _deleteReminder(int id) async {
    final repo = ref.read(intelligentReminderRepoProvider);
    await repo.deleteReminder(id);
    _loadReminders();
  }
}

class _ReminderCard extends StatelessWidget {
  final IntelligentReminder reminder;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _ReminderCard({
    required this.reminder,
    required this.onToggle,
    required this.onDelete,
  });

  IconData _getTriggerIcon() {
    switch (reminder.triggerType) {
      case 'time':
        return Icons.schedule;
      case 'location':
        return Icons.location_on;
      case 'behavior':
        return Icons.touch_app;
      case 'mood':
        return Icons.mood;
      default:
        return Icons.notifications;
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveEffectiveness = (reminder.effectivenessScore * 100).toInt();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_getTriggerIcon()),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    reminder.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Switch(
                  value: reminder.isEnabled,
                  onChanged: (_) => onToggle(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Chip(
                  label: Text(reminder.triggerType),
                  avatar: Icon(_getTriggerIcon(), size: 16),
                ),
                const SizedBox(width: 8),
                Chip(
                  label: Text(reminder.actionType),
                  avatar: const Icon(Icons.play_arrow, size: 16),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.bar_chart, size: 16),
                const SizedBox(width: 4),
                Text('触发 $effectiveEffectiveness%'),
                const SizedBox(width: 16),
                const Icon(Icons.repeat, size: 16),
                const SizedBox(width: 4),
                Text('触发 ${reminder.triggeredCount} 次'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: const Text('删除'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}