import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/enhanced_reminder/data/enhanced_reminder_provider.dart';

class EnhancedReminderScreen extends ConsumerWidget {
  const EnhancedReminderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remindersAsync = ref.watch(enhancedReminderNotifierProvider);
    final statsAsync = ref.watch(reminderStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Enhanced Reminders'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(enhancedReminderNotifierProvider.notifier).loadReminders(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats header
          statsAsync.when(
            data: (stats) {
              return Container(
                padding: const EdgeInsets.all(16),
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem('Total', stats.totalReminders.toString(), Icons.notifications),
                    _buildStatItem('Triggered', stats.triggeredReminders.toString(), Icons.check_circle),
                    _buildStatItem('Snoozed', stats.snoozedReminders.toString(), Icons.snooze),
                    _buildStatItem('Missed', stats.missedReminders.toString(), Icons.warning),
                  ],
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // Reminders list
          Expanded(
            child: remindersAsync.when(
              data: (reminders) {
                if (reminders.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_off, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No reminders set', style: TextStyle(fontSize: 16, color: Colors.grey)),
                      ],
                    ),
                  );
                }

                final now = DateTime.now();
                final upcoming = reminders.where((r) => r.remindAt.isAfter(now)).toList();
                final past = reminders.where((r) => !r.remindAt.isAfter(now) && !r.isTriggered).toList();

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (upcoming.isNotEmpty) ...[
                      const Text(
                        'Upcoming',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ...upcoming.map((reminder) => _buildReminderCard(context, ref, reminder)),
                    ],
                    if (past.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Past (Not Triggered)',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ...past.map((reminder) => _buildReminderCard(context, ref, reminder)),
                    ],
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error: $error')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 24),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildReminderCard(BuildContext context, WidgetRef ref, dynamic reminder) {
    final isRecurring = reminder.isRecurring;
    final isPast = reminder.remindAt.isBefore(DateTime.now());

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isPast ? Colors.orange : Colors.blue,
          child: Icon(
            isRecurring ? Icons.repeat : Icons.notifications,
            color: Colors.white,
          ),
        ),
        title: Text('Record #${reminder.recordId}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_formatDateTime(reminder.remindAt)),
            if (isRecurring)
              Text(
                'Repeats: ${reminder.reminderType}',
                style: const TextStyle(fontSize: 12),
              ),
            if (reminder.snoozeCount > 0)
              Text(
                'Snoozed ${reminder.snoozeCount} times',
                style: const TextStyle(fontSize: 12, color: Colors.orange),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(reminder.isEnabled ? Icons.notifications_active : Icons.notifications_off),
              onPressed: () {
                ref.read(enhancedReminderNotifierProvider.notifier).toggleEnabled(
                  reminder.id!,
                  !reminder.isEnabled,
                );
              },
            ),
            PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'snooze', child: Text('Snooze 5 min')),
                const PopupMenuItem(value: 'snooze10', child: Text('Snooze 10 min')),
                const PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
              onSelected: (value) {
                if (value == 'snooze') {
                  ref.read(enhancedReminderNotifierProvider.notifier).snooze(reminder.id!, 5);
                } else if (value == 'snooze10') {
                  ref.read(enhancedReminderNotifierProvider.notifier).snooze(reminder.id!, 10);
                } else if (value == 'delete') {
                  ref.read(enhancedReminderNotifierProvider.notifier).deleteReminder(reminder.id!);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime date) {
    final now = DateTime.now();
    final diff = date.difference(now);

    final String timeStr = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

    if (diff.isNegative) {
      return 'Past: $timeStr';
    } else if (diff.inDays == 0) {
      return 'Today $timeStr';
    } else if (diff.inDays == 1) {
      return 'Tomorrow $timeStr';
    } else {
      return '${date.month}/${date.day} $timeStr';
    }
  }
}