import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/event_reminder/domain/event_trigger.dart';

final eventTriggersProvider = StateNotifierProvider<EventTriggersNotifier, List<EventTrigger>>((ref) {
  return EventTriggersNotifier();
});

class EventTriggersNotifier extends StateNotifier<List<EventTrigger>> {
  EventTriggersNotifier() : super(_defaultTriggers);
  
  static final List<EventTrigger> _defaultTriggers = [
    EventTrigger(
      id: 1,
      name: '每日提醒',
      triggerType: TriggerType.time,
      triggerConfig: '{"time": "09:00", "repeat": "daily"}',
      actionType: ActionType.notification,
      actionConfig: '{"title": "开始新的一天！", "body": "查看今日任务"}',
      createdAt: DateTime.now(),
    ),
    EventTrigger(
      id: 2,
      name: '周回顾提醒',
      triggerType: TriggerType.time,
      triggerConfig: '{"day": "sunday", "time": "20:00"}',
      actionType: ActionType.reminder,
      actionConfig: '{"title": "周回顾时间到了"}',
      createdAt: DateTime.now(),
    ),
    EventTrigger(
      id: 3,
      name: '记录创建提醒',
      triggerType: TriggerType.record,
      triggerConfig: '{"action": "create", "tag": "重要"}',
      actionType: ActionType.autoRecord,
      actionConfig: '{"message": "已为您自动标记为重要"}',
      createdAt: DateTime.now(),
    ),
  ];

  void addTrigger(EventTrigger trigger) {
    state = [...state, trigger];
  }

  void updateTrigger(EventTrigger trigger) {
    state = state.map((t) => t.id == trigger.id ? trigger : t).toList();
  }

  void deleteTrigger(int id) {
    state = state.where((t) => t.id != id).toList();
  }

  void toggleEnabled(int id) {
    state = state.map((t) {
      if (t.id == id) {
        return t.copyWith(isEnabled: !t.isEnabled);
      }
      return t;
    }).toList();
  }
}

class EventReminderScreen extends ConsumerWidget {
  const EventReminderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final triggers = ref.watch(eventTriggersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('事件提醒'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddTriggerDialog(context, ref),
          ),
        ],
      ),
      body: triggers.isEmpty
          ? _buildEmptyState(context, ref)
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: triggers.length,
              itemBuilder: (context, index) {
                return _TriggerCard(
                  trigger: triggers[index],
                  onToggle: () => ref.read(eventTriggersProvider.notifier).toggleEnabled(triggers[index].id!),
                  onDelete: () => ref.read(eventTriggersProvider.notifier).deleteTrigger(triggers[index].id!),
                );
              },
            ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.notifications_active, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('暂无事件触发器', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 8),
          const Text('创建自动化事件提醒', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _showAddTriggerDialog(context, ref),
            icon: const Icon(Icons.add),
            label: const Text('添加触发器'),
          ),
        ],
      ),
    );
  }

  void _showAddTriggerDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    String triggerType = TriggerType.time;
    String actionType = ActionType.notification;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('添加触发器'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: '触发器名称'),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: triggerType,
                  decoration: const InputDecoration(labelText: '触发类型'),
                  items: ['time', 'location', 'record', 'manual'].map((t) {
                    return DropdownMenuItem(
                      value: t,
                      child: Row(
                        children: [
                          Icon(TriggerType.getIcon(t), size: 20),
                          const SizedBox(width: 8),
                          Text(TriggerType.getTitle(t)),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => triggerType = v!),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: actionType,
                  decoration: const InputDecoration(labelText: '动作类型'),
                  items: ['reminder', 'notification', 'auto_record'].map((t) {
                    return DropdownMenuItem(
                      value: t,
                      child: Row(
                        children: [
                          Icon(ActionType.getIcon(t), size: 20),
                          const SizedBox(width: 8),
                          Text(ActionType.getTitle(t)),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => actionType = v!),
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
                if (nameController.text.trim().isNotEmpty) {
                  final trigger = EventTrigger(
                    name: nameController.text.trim(),
                    triggerType: triggerType,
                    triggerConfig: '{}',
                    actionType: actionType,
                    actionConfig: '{}',
                    createdAt: DateTime.now(),
                  );
                  ref.read(eventTriggersProvider.notifier).addTrigger(trigger);
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
}

class _TriggerCard extends StatelessWidget {
  final EventTrigger trigger;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _TriggerCard({
    required this.trigger,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
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
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: (trigger.isEnabled ? Colors.green : Colors.grey).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    TriggerType.getIcon(trigger.triggerType),
                    color: trigger.isEnabled ? Colors.green : Colors.grey,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trigger.name,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${TriggerType.getTitle(trigger.triggerType)} → ${ActionType.getTitle(trigger.actionType)}',
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: trigger.isEnabled,
                  onChanged: (_) => onToggle(),
                ),
              ],
            ),
            if (trigger.lastTriggered != null) ...[
              const SizedBox(height: 8),
              Text(
                '上次触发: ${_formatDate(trigger.lastTriggered!)}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('编辑'),
                ),
                TextButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                  label: const Text('删除', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}