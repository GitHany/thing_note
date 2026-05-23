import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/mood_journal/data/mood_journal_repository.dart';

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
    final trendAsync = ref.watch(moodJournalTrendProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('心情日记'),
        actions: [
          IconButton(
            icon: const Icon(Icons.trending_up),
            onPressed: () => _showTrend(context, trendAsync),
          ),
        ],
      ),
      body: journalsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('错误: $e')),
        data: (journals) => _buildContent(journals),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddJournalDialog(context),
        child: const Icon(Icons.edit),
      ),
    );
  }

  Widget _buildContent(List<MoodJournal> journals) {
    final todayJournal = journals.where((j) => j.date == _formatDate(_selectedDate)).toList();
    final journal = todayJournal.isNotEmpty ? todayJournal.first : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDateSelector(),
          const SizedBox(height: 24),
          _buildMoodSelector(journal),
          const SizedBox(height: 24),
          if (journal != null) ...[
            _buildGratitudeSection(journal),
            const SizedBox(height: 24),
            _buildTriggersSection(journal),
            const SizedBox(height: 24),
            _buildNoteSection(journal),
          ] else ...[
            _buildEmptyState(),
          ],
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              setState(() {
                _selectedDate = _selectedDate.subtract(const Duration(days: 1));
              });
            },
          ),
          GestureDetector(
            onTap: () => _selectDate(context),
            child: Column(
              children: [
                Text(
                  _isToday(_selectedDate) ? '今天' : _formatDate(_selectedDate),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  _getWeekday(_selectedDate),
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              setState(() {
                _selectedDate = _selectedDate.add(const Duration(days: 1));
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMoodSelector(MoodJournal? journal) {
    final currentLevel = journal?.moodLevel ?? 2;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('今日心情', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(5, (index) {
              final level = index + 1;
              final isSelected = level == currentLevel;
              return GestureDetector(
                onTap: () => _updateMoodLevel(level),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? _getMoodColor(level).withOpacity(0.2)
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                    border: isSelected
                        ? Border.all(color: _getMoodColor(level), width: 2)
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        moodLevelEmojis[index],
                        style: const TextStyle(fontSize: 24),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        moodLevelLabels[index],
                        style: TextStyle(
                          fontSize: 10,
                          color: isSelected ? _getMoodColor(level) : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildGratitudeSection(MoodJournal journal) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('🙏', style: TextStyle(fontSize: 20)),
              SizedBox(width: 8),
              Text('感恩事项', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          if (journal.gratitudeItems != null && journal.gratitudeItems!.isNotEmpty)
            Text(journal.gratitudeItems!, style: const TextStyle(fontSize: 14))
          else
            Text('点击添加感恩事项', style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildTriggersSection(MoodJournal journal) {
    final triggers = journal.triggers?.split(',') ?? [];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('触发因素', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: commonTriggers.map((t) {
              final isSelected = triggers.contains(t);
              return FilterChip(
                label: Text(t),
                selected: isSelected,
                onSelected: (selected) => _toggleTrigger(t, selected),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteSection(MoodJournal journal) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('详细记录', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (journal.detailedNote != null && journal.detailedNote!.isNotEmpty)
            Text(journal.detailedNote!, style: const TextStyle(fontSize: 14))
          else
            Text('点击添加详细记录', style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text('📝', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          const Text('今天还没有写日记', style: TextStyle(fontSize: 16)),
          const SizedBox(height: 8),
          Text('点击右下角按钮开始记录', style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }

  void _showTrend(BuildContext context, AsyncValue<List<Map<String, dynamic>>> trendAsync) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('心情趋势', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            trendAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Text('错误: $e'),
              data: (data) {
                if (data.isEmpty) {
                  return const Text('暂无数据');
                }
                return SizedBox(
                  height: 100,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: data.map((d) {
                      final level = d['level'] as int;
                      return Column(
                        children: [
                          Text(moodLevelEmojis[level - 1], style: const TextStyle(fontSize: 24)),
                          const SizedBox(height: 4),
                          Text(d['date'] as String, style: const TextStyle(fontSize: 10)),
                        ],
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddJournalDialog(BuildContext context) {
    final noteController = TextEditingController();
    final gratitudeController = TextEditingController();
    int selectedMood = 3;
    final selectedTriggers = <String>[];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('写日记'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('心情'),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(5, (index) {
                    return GestureDetector(
                      onTap: () => setState(() => selectedMood = index + 1),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: selectedMood == index + 1
                              ? _getMoodColor(index + 1).withOpacity(0.2)
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(moodLevelEmojis[index], style: const TextStyle(fontSize: 24)),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 16),
                const Text('触发因素'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: commonTriggers.map((t) {
                    return FilterChip(
                      label: Text(t),
                      selected: selectedTriggers.contains(t),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            selectedTriggers.add(t);
                          } else {
                            selectedTriggers.remove(t);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: gratitudeController,
                  decoration: const InputDecoration(labelText: '感恩事项'),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: noteController,
                  decoration: const InputDecoration(labelText: '详细记录'),
                  maxLines: 4,
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
                final journal = MoodJournal(
                  date: _formatDate(_selectedDate),
                  moodLevel: selectedMood,
                  gratitudeItems: gratitudeController.text,
                  triggers: selectedTriggers.join(','),
                  detailedNote: noteController.text,
                  createdAt: DateTime.now(),
                );
                ref.read(moodJournalsProvider.notifier).addMoodJournal(journal);
                Navigator.pop(context);
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
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

  void _updateMoodLevel(int level) {
    // Update mood level in database
    final journal = MoodJournal(
      date: _formatDate(_selectedDate),
      moodLevel: level,
      createdAt: DateTime.now(),
    );
    ref.read(moodJournalsProvider.notifier).addMoodJournal(journal);
  }

  void _toggleTrigger(String trigger, bool selected) {
    // Update trigger in database
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _getWeekday(DateTime date) {
    const weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return weekdays[date.weekday - 1];
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  Color _getMoodColor(int level) {
    switch (level) {
      case 1: return Colors.red;
      case 2: return Colors.orange;
      case 3: return Colors.yellow;
      case 4: return Colors.lightGreen;
      case 5: return Colors.green;
      default: return Colors.grey;
    }
  }
}