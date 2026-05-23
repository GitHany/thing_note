import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/habit_tournament/data/tournament_repository.dart';
import 'package:thing_note/features/habit_tournament/domain/tournament_models.dart';

class MoodJournalScreen extends ConsumerStatefulWidget {
  const MoodJournalScreen({super.key});

  @override
  ConsumerState<MoodJournalScreen> createState() => _MoodJournalScreenState();
}

class _MoodJournalScreenState extends ConsumerState<MoodJournalScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final journalsAsync = ref.watch(moodJournalsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('情绪日记'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _selectDate(context),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildMoodChart(),
          Expanded(
            child: journalsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('错误: $e')),
              data: (journals) => _buildJournalList(journals),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddJournalDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildMoodChart() {
    final journals = ref.watch(moodJournalsProvider).value ?? [];
    final now = DateTime.now();
    final weekJournals = journals.where((j) =>
      j.date.isAfter(now.subtract(const Duration(days: 7)))
    ).toList();

    return Container(
      height: 100,
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(7, (i) {
          final date = now.subtract(Duration(days: 6 - i));
          final journal = weekJournals.where((j) =>
            j.date.year == date.year &&
            j.date.month == date.month &&
            j.date.day == date.day
          ).firstOrNull;

          return Column(
            children: [
              Text(
                ['一', '二', '三', '四', '五', '六', '日'][date.weekday - 1],
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 8),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: journal != null ? _getMoodColor(journal.moodLevel) : Colors.grey[200],
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: journal != null
                      ? Text(_getMoodEmoji(journal.moodLevel), style: const TextStyle(fontSize: 16))
                      : const Icon(Icons.remove, color: Colors.grey, size: 16),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${date.day}',
                style: TextStyle(
                  fontSize: 10,
                  color: _isToday(date) ? Colors.blue : Colors.grey,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildJournalList(List<MoodJournal> journals) {
    if (journals.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.book, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('暂无日记', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text('记录你的情绪和感恩', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: journals.length,
      itemBuilder: (context, index) {
        return _JournalCard(
          journal: journals[index],
          onDelete: () => ref.read(moodJournalsProvider.notifier).deleteJournal(journals[index].id!),
        );
      },
    );
  }

  void _selectDate(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  void _showAddJournalDialog(BuildContext context) {
    int moodLevel = 3;
    final gratitudeController = TextEditingController();
    final noteController = TextEditingController();
    final triggersController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '记录情绪',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('今天的心情'),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(5, (i) {
                    final level = i + 1;
                    final isSelected = moodLevel == level;
                    return GestureDetector(
                      onTap: () => setState(() => moodLevel = level),
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: isSelected ? _getMoodColor(level) : Colors.grey[200],
                          shape: BoxShape.circle,
                          border: isSelected ? Border.all(color: _getMoodColor(level), width: 3) : null,
                        ),
                        child: Center(
                          child: Text(_getMoodEmoji(level), style: const TextStyle(fontSize: 24)),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: gratitudeController,
                  decoration: const InputDecoration(
                    labelText: '感恩事项',
                    hintText: '今天感恩的事情...',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: triggersController,
                  decoration: const InputDecoration(
                    labelText: '触发因素',
                    hintText: '影响情绪的因素...',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteController,
                  decoration: const InputDecoration(
                    labelText: '详细记录',
                    hintText: '记录更多细节...',
                  ),
                  maxLines: 4,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      final journal = MoodJournal(
                        date: _selectedDate,
                        moodLevel: moodLevel,
                        gratitudeItems: gratitudeController.text.isEmpty ? null : gratitudeController.text,
                        triggers: triggersController.text.isEmpty ? null : triggersController.text,
                        detailedNote: noteController.text.isEmpty ? null : noteController.text,
                        createdAt: DateTime.now(),
                      );
                      ref.read(moodJournalsProvider.notifier).addJournal(journal);
                      Navigator.pop(context);
                    },
                    child: const Text('保存'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  Color _getMoodColor(int level) {
    switch (level) {
      case 1:
        return Colors.red.shade300;
      case 2:
        return Colors.orange.shade300;
      case 3:
        return Colors.yellow.shade600;
      case 4:
        return Colors.lightGreen.shade300;
      case 5:
        return Colors.green.shade400;
      default:
        return Colors.grey;
    }
  }

  String _getMoodEmoji(int level) {
    switch (level) {
      case 1:
        return '😢';
      case 2:
        return '😔';
      case 3:
        return '😐';
      case 4:
        return '🙂';
      case 5:
        return '😄';
      default:
        return '😐';
    }
  }
}

class _JournalCard extends StatelessWidget {
  final MoodJournal journal;
  final VoidCallback onDelete;

  const _JournalCard({required this.journal, required this.onDelete});

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
                    color: _getMoodColor(journal.moodLevel).withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(_getMoodEmoji(journal.moodLevel), style: const TextStyle(fontSize: 20)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${journal.date.month}/${journal.date.day}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _getMoodLabel(journal.moodLevel),
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: onDelete,
                ),
              ],
            ),
            if (journal.gratitudeItems != null && journal.gratitudeItems!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                journal.gratitudeItems!,
                style: const TextStyle(fontSize: 14),
              ),
            ],
            if (journal.detailedNote != null && journal.detailedNote!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                journal.detailedNote!,
                style: const TextStyle(fontSize: 13),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getMoodColor(int level) {
    switch (level) {
      case 1:
        return Colors.red.shade300;
      case 2:
        return Colors.orange.shade300;
      case 3:
        return Colors.yellow.shade600;
      case 4:
        return Colors.lightGreen.shade300;
      case 5:
        return Colors.green.shade400;
      default:
        return Colors.grey;
    }
  }

  String _getMoodEmoji(int level) {
    switch (level) {
      case 1:
        return '😢';
      case 2:
        return '😔';
      case 3:
        return '😐';
      case 4:
        return '🙂';
      case 5:
        return '😄';
      default:
        return '😐';
    }
  }

  String _getMoodLabel(int level) {
    switch (level) {
      case 1:
        return '低落';
      case 2:
        return '不太好';
      case 3:
        return '一般';
      case 4:
        return '不错';
      case 5:
        return '很好';
      default:
        return '未知';
    }
  }
}