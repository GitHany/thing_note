import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/meeting_assistant/data/meeting_repository.dart';
import 'package:thing_note/features/meeting_assistant/domain/meeting.dart';

class MeetingAssistantScreen extends ConsumerWidget {
  const MeetingAssistantScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meetingsAsync = ref.watch(meetingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('会议助手'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddMeetingDialog(context, ref),
          ),
        ],
      ),
      body: meetingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('错误: $e')),
        data: (meetings) {
          if (meetings.isEmpty) {
            return _buildEmptyState(context, ref);
          }

          final upcoming = meetings.where((m) => m.date.compareTo(_todayString()) >= 0).toList();
          final past = meetings.where((m) => m.date.compareTo(_todayString()) < 0).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (upcoming.isNotEmpty) ...[
                const Text('即将到来', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ...upcoming.map((m) => _MeetingCard(
                  meeting: m,
                  onTap: () => _showMeetingDetail(context, ref, m),
                  onDelete: () => ref.read(meetingsProvider.notifier).deleteMeeting(m.id!),
                )),
                const SizedBox(height: 24),
              ],
              if (past.isNotEmpty) ...[
                const Text('历史会议', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ...past.map((m) => _MeetingCard(
                  meeting: m,
                  onTap: () => _showMeetingDetail(context, ref, m),
                  onDelete: () => ref.read(meetingsProvider.notifier).deleteMeeting(m.id!),
                )),
              ],
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddMeetingDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  String _todayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.groups, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('暂无会议记录', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () => _showAddMeetingDialog(context, ref),
            icon: const Icon(Icons.add),
            label: const Text('创建会议'),
          ),
        ],
      ),
    );
  }

  void _showAddMeetingDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final dateController = TextEditingController(text: _todayString());
    final participantsController = TextEditingController();
    final agendaController = TextEditingController();
    int duration = 60;
    String? template;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('创建会议'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: '会议标题'),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: template,
                  decoration: const InputDecoration(labelText: '模板（可选）'),
                  items: const [
                    DropdownMenuItem(value: 'weekly', child: Text('周会')),
                    DropdownMenuItem(value: 'project', child: Text('项目会议')),
                    DropdownMenuItem(value: '1on1', child: Text('一对一')),
                  ],
                  onChanged: (v) => setState(() => template = v),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: dateController,
                  decoration: const InputDecoration(labelText: '日期 (YYYY-MM-DD)'),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('时长: '),
                    Expanded(
                      child: Slider(
                        value: duration.toDouble(),
                        min: 15,
                        max: 180,
                        divisions: 11,
                        label: '$duration 分钟',
                        onChanged: (v) => setState(() => duration = v.round()),
                      ),
                    ),
                    Text('$duration 分钟'),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: participantsController,
                  decoration: const InputDecoration(
                    labelText: '参会人（逗号分隔）',
                    hintText: '张三, 李四, 王五',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: agendaController,
                  decoration: const InputDecoration(labelText: '议程'),
                  maxLines: 3,
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
                if (titleController.text.trim().isNotEmpty) {
                  final participants = participantsController.text
                      .split(',')
                      .map((s) => s.trim())
                      .where((s) => s.isNotEmpty)
                      .toList();

                  final meeting = Meeting(
                    title: titleController.text.trim(),
                    template: template,
                    date: dateController.text.trim(),
                    durationMinutes: duration,
                    participants: participants,
                    agenda: agendaController.text.trim().isEmpty ? null : agendaController.text.trim(),
                    createdAt: DateTime.now(),
                  );
                  ref.read(meetingsProvider.notifier).addMeeting(meeting);
                  Navigator.pop(context);
                }
              },
              child: const Text('创建'),
            ),
          ],
        ),
      ),
    );
  }

  void _showMeetingDetail(BuildContext context, WidgetRef ref, Meeting meeting) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: ListView(
            controller: scrollController,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(meeting.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 16),
              _buildInfoRow(Icons.calendar_today, '日期', meeting.date),
              if (meeting.durationMinutes != null)
                _buildInfoRow(Icons.timer, '时长', '${meeting.durationMinutes} 分钟'),
              if (meeting.participants.isNotEmpty)
                _buildInfoRow(Icons.people, '参会人', meeting.participants.join(', ')),
              if (meeting.template != null)
                _buildInfoRow(Icons.description, '模板', meeting.template!),
              if (meeting.agenda != null && meeting.agenda!.isNotEmpty) ...[
                const SizedBox(height: 24),
                const Text('议程', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(meeting.agenda!),
              ],
              if (meeting.notes != null && meeting.notes!.isNotEmpty) ...[
                const SizedBox(height: 24),
                const Text('会议记录', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(meeting.notes!),
              ],
              if (meeting.decisions != null && meeting.decisions!.isNotEmpty) ...[
                const SizedBox(height: 24),
                const Text('决策', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(meeting.decisions!),
              ],
              if (meeting.actionItems != null && meeting.actionItems!.isNotEmpty) ...[
                const SizedBox(height: 24),
                const Text('行动项', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(meeting.actionItems!),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _showEditMeetingDialog(context, ref, meeting);
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('编辑'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        ref.read(meetingsProvider.notifier).deleteMeeting(meeting.id!);
                      },
                      icon: const Icon(Icons.delete),
                      label: const Text('删除'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey),
          const SizedBox(width: 12),
          Text('$label: ', style: const TextStyle(color: Colors.grey)),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  void _showEditMeetingDialog(BuildContext context, WidgetRef ref, Meeting meeting) {
    final titleController = TextEditingController(text: meeting.title);
    final notesController = TextEditingController(text: meeting.notes);
    final decisionsController = TextEditingController(text: meeting.decisions);
    final actionItemsController = TextEditingController(text: meeting.actionItems);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('编辑会议'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: '标题'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(labelText: '会议记录'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: decisionsController,
                decoration: const InputDecoration(labelText: '决策'),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: actionItemsController,
                decoration: const InputDecoration(labelText: '行动项'),
                maxLines: 2,
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
              final updated = meeting.copyWith(
                title: titleController.text.trim(),
                notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                decisions: decisionsController.text.trim().isEmpty ? null : decisionsController.text.trim(),
                actionItems: actionItemsController.text.trim().isEmpty ? null : actionItemsController.text.trim(),
              );
              ref.read(meetingsProvider.notifier).updateMeeting(updated);
              Navigator.pop(context);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }
}

class _MeetingCard extends StatelessWidget {
  final Meeting meeting;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _MeetingCard({required this.meeting, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isUpcoming = meeting.date.compareTo(DateTime.now().toIso8601String().substring(0, 10)) >= 0;

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
                  color: isUpcoming ? Colors.blue.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.groups,
                  color: isUpcoming ? Colors.blue : Colors.grey,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meeting.title,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${meeting.date} ${meeting.durationMinutes ?? 60}分钟',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    if (meeting.participants.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${meeting.participants.length} 人参会',
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'delete', child: Text('删除', style: TextStyle(color: Colors.red))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}