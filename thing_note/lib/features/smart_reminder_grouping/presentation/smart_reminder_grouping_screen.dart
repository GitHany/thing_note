import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';

/// 智能提醒分组服务
final smartReminderGroupingServiceProvider = Provider<SmartReminderGroupingService>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return SmartReminderGroupingService(dbAsync);
});

final reminderGroupsProvider = FutureProvider<List<ReminderGroup>>((ref) async {
  final service = ref.watch(smartReminderGroupingServiceProvider);
  return service.getGroups();
});

class SmartReminderGroupingService {
  final AsyncValue<Database> _dbAsync;

  SmartReminderGroupingService(this._dbAsync);

  Future<Database> get _db async {
    final db = _dbAsync.value;
    if (db == null) throw Exception('Database not initialized');
    return db;
  }

  Future<List<ReminderGroup>> getGroups() async {
    final db = await _db;
    final maps = await db.query('reminder_groups', orderBy: 'sort_order ASC');
    return maps.map((m) => ReminderGroup.fromMap(m)).toList();
  }

  Future<List<GroupedReminder>> getGroupedReminders(int groupId) async {
    final db = await _db;
    final maps = await db.rawQuery('''
      SELECT r.*, gr.id as grouped_id
      FROM episode_records r
      INNER JOIN grouped_reminders gr ON r.id = gr.reminder_id
      WHERE gr.group_id = ?
      ORDER BY r.occurred_at ASC
    ''', [groupId]);

    return maps.map((m) => GroupedReminder.fromMap(m)).toList();
  }

  Future<int> createGroup(String name, String type) async {
    final db = await _db;
    return db.insert('reminder_groups', {
      'name': name,
      'group_type': type,
      'sort_order': 0,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> autoGroupReminders() async {
    final db = await _db;

    // 获取所有有提醒的记录
    final reminders = await db.query(
      'episode_records',
      where: 'has_reminder = 1',
      orderBy: 'occurred_at ASC',
    );

    // 按时间段分组
    final groups = <String, List<Map<String, dynamic>>>{
      'morning': [],
      'afternoon': [],
      'evening': [],
      'night': [],
    };

    for (final reminder in reminders) {
      final time = DateTime.parse(reminder['occurred_at'] as String);
      final hour = time.hour;

      String period;
      if (hour >= 6 && hour < 12) {
        period = 'morning';
      } else if (hour >= 12 && hour < 18) {
        period = 'afternoon';
      } else if (hour >= 18 && hour < 22) {
        period = 'evening';
      } else {
        period = 'night';
      }

      groups[period]!.add(reminder);
    }

    // 创建或更新分组
    for (final entry in groups.entries) {
      if (entry.value.isEmpty) continue;

      final existing = await db.query(
        'reminder_groups',
        where: 'name = ?',
        whereArgs: [entry.key],
      );

      int groupId;
      if (existing.isEmpty) {
        groupId = await createGroup(entry.key, 'time');
      } else {
        groupId = existing.first['id'] as int;
      }

      // 添加到分组
      for (final reminder in entry.value) {
        await db.insert('grouped_reminders', {
          'group_id': groupId,
          'reminder_id': reminder['id'],
          'added_at': DateTime.now().toIso8601String(),
        });
      }
    }
  }
}

class ReminderGroup {
  final int? id;
  final String name;
  final String groupType;
  final int sortOrder;
  final DateTime createdAt;

  ReminderGroup({
    this.id,
    required this.name,
    required this.groupType,
    this.sortOrder = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'group_type': groupType,
      'sort_order': sortOrder,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ReminderGroup.fromMap(Map<String, dynamic> map) {
    return ReminderGroup(
      id: map['id'] as int?,
      name: map['name'] as String,
      groupType: map['group_type'] as String,
      sortOrder: map['sort_order'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  String get displayName {
    switch (groupType) {
      case 'morning':
        return '🌅 早晨提醒';
      case 'afternoon':
        return '☀️ 下午提醒';
      case 'evening':
        return '🌆 傍晚提醒';
      case 'night':
        return '🌙 夜间提醒';
      case 'habit':
        return '🎯 习惯提醒';
      case 'goal':
        return '🏆 目标提醒';
      default:
        return name;
    }
  }
}

class GroupedReminder {
  final int id;
  final String note;
  final DateTime occurredAt;
  final int groupedId;

  GroupedReminder({
    required this.id,
    required this.note,
    required this.occurredAt,
    required this.groupedId,
  });

  factory GroupedReminder.fromMap(Map<String, dynamic> map) {
    return GroupedReminder(
      id: map['id'] as int,
      note: map['note'] as String? ?? '',
      occurredAt: DateTime.parse(map['occurred_at'] as String),
      groupedId: map['grouped_id'] as int,
    );
  }
}

class SmartReminderGroupingScreen extends ConsumerWidget {
  const SmartReminderGroupingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(reminderGroupsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('智能提醒分组'),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome),
            onPressed: () async {
              final service = ref.read(smartReminderGroupingServiceProvider);
              await service.autoGroupReminders();
              ref.invalidate(reminderGroupsProvider);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('智能分组已完成')),
                );
              }
            },
            tooltip: '自动分组',
          ),
        ],
      ),
      body: groupsAsync.when(
        data: (groups) {
          if (groups.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.folder_open, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('暂无提醒分组'),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () async {
                      final service = ref.read(smartReminderGroupingServiceProvider);
                      await service.autoGroupReminders();
                      ref.invalidate(reminderGroupsProvider);
                    },
                    child: const Text('自动分组'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: groups.length,
            itemBuilder: (context, index) => _GroupCard(
              group: groups[index],
              onTap: () => _showGroupDetails(context, groups[index]),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
      ),
    );
  }

  void _showGroupDetails(BuildContext context, ReminderGroup group) {
    final service = ProviderContainer().read(smartReminderGroupingServiceProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(group.displayName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: FutureBuilder<List<GroupedReminder>>(
                future: service.getGroupedReminders(group.id!),
                builder: (context, snapshot) {
                  final reminders = snapshot.data ?? [];
                  if (reminders.isEmpty) {
                    return const Center(child: Text('该分组暂无提醒'));
                  }

                  return ListView.builder(
                    controller: scrollController,
                    itemCount: reminders.length,
                    itemBuilder: (context, index) => ListTile(
                      leading: const Icon(Icons.notifications),
                      title: Text(reminders[index].note, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(_formatDate(reminders[index].occurredAt)),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _GroupCard extends StatelessWidget {
  final ReminderGroup group;
  final VoidCallback onTap;

  const _GroupCard({required this.group, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getGroupColor(group.groupType).withOpacity( 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_getGroupIcon(group.groupType), color: _getGroupColor(group.groupType)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(group.displayName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text('类型: ${group.groupType}', style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getGroupIcon(String type) {
    switch (type) {
      case 'morning':
        return Icons.wb_sunny;
      case 'afternoon':
        return Icons.wb_cloudy;
      case 'evening':
        return Icons.nights_stay;
      case 'night':
        return Icons.dark_mode;
      case 'habit':
        return Icons.flag;
      case 'goal':
        return Icons.emoji_events;
      default:
        return Icons.folder;
    }
  }

  Color _getGroupColor(String type) {
    switch (type) {
      case 'morning':
        return Colors.amber;
      case 'afternoon':
        return Colors.blue;
      case 'evening':
        return Colors.orange;
      case 'night':
        return Colors.purple;
      case 'habit':
        return Colors.green;
      case 'goal':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}