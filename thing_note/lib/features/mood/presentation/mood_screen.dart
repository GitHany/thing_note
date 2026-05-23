import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/mood/data/mood_repository.dart';
import 'package:thing_note/features/mood/domain/mood_entry.dart';

class MoodScreen extends ConsumerStatefulWidget {
  const MoodScreen({super.key});

  @override
  ConsumerState<MoodScreen> createState() => _MoodScreenState();
}

class _MoodScreenState extends ConsumerState<MoodScreen> {
  @override
  Widget build(BuildContext context) {
    final moodsAsync = ref.watch(moodEntriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('情绪记录'),
      ),
      body: moodsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('错误: $e')),
        data: (moods) {
          if (moods.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('😢', style: TextStyle(fontSize: 64)),
                  const SizedBox(height: 16),
                  const Text('暂无情绪记录', style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => _showMoodDialog(context),
                    child: const Text('记录今天的心情'),
                  ),
                ],
              ),
            );
          }
          return Column(
            children: [
              _buildMoodInput(),
              Expanded(
                child: _buildMoodChart(moods),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: moods.length,
                  itemBuilder: (context, index) => _MoodCard(mood: moods[index]),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showMoodDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildMoodInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: MoodLevel.values.map((mood) {
          return GestureDetector(
            onTap: () => _quickAddMood(mood),
            child: Column(
              children: [
                Text(mood.emoji, style: const TextStyle(fontSize: 32)),
                const SizedBox(height: 4),
                Text(mood.displayName, style: const TextStyle(fontSize: 10)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMoodChart(List<MoodEntry> moods) {
    if (moods.length < 2) return const SizedBox();

    final last7Days = <DateTime, MoodLevel>{};
    final now = DateTime.now();

    for (int i = 6; i >= 0; i--) {
      final date = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      last7Days[date] = moods
          .where((m) =>
              m.timestamp.year == date.year &&
              m.timestamp.month == date.month &&
              m.timestamp.day == date.day)
          .map((m) => m.mood)
          .fold(MoodLevel.neutral, (prev, curr) => curr);
    }

    return Container(
      height: 120,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: last7Days.entries.map((entry) {
          final height = entry.value.value * 20.0;
          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                width: 30,
                height: height,
                decoration: BoxDecoration(
                  color: _getMoodColor(entry.value),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${entry.key.month}/${entry.key.day}',
                style: const TextStyle(fontSize: 10),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Color _getMoodColor(MoodLevel mood) {
    switch (mood) {
      case MoodLevel.veryBad:
        return Colors.red[300]!;
      case MoodLevel.bad:
        return Colors.orange[300]!;
      case MoodLevel.neutral:
        return Colors.yellow[300]!;
      case MoodLevel.good:
        return Colors.lightGreen[300]!;
      case MoodLevel.veryGood:
        return Colors.green[300]!;
    }
  }

  void _quickAddMood(MoodLevel mood) {
    final moodEntry = MoodEntry(
      timestamp: DateTime.now(),
      mood: mood,
      createdAt: DateTime.now(),
    );
    ref.read(moodEntriesProvider.notifier).addMood(moodEntry);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已记录: ${mood.displayName} ${mood.emoji}')),
    );
  }

  void _showMoodDialog(BuildContext context) {
    MoodLevel selectedMood = MoodLevel.neutral;
    final noteController = TextEditingController();
    final selectedTriggers = <String>[];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('今天心情如何？', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: MoodLevel.values.map((mood) {
                  final isSelected = mood == selectedMood;
                  return GestureDetector(
                    onTap: () => setState(() => selectedMood = mood),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected ? _getMoodColor(mood).withOpacity(0.3) : null,
                        border: isSelected ? Border.all(color: _getMoodColor(mood), width: 2) : null,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(mood.emoji, style: const TextStyle(fontSize: 36)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              const Text('是什么影响了你的心情？'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: MoodTrigger.commonTriggers.map((trigger) {
                  final isSelected = selectedTriggers.contains(trigger);
                  return FilterChip(
                    label: Text(trigger),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          selectedTriggers.add(trigger);
                        } else {
                          selectedTriggers.remove(trigger);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(
                  labelText: '备注（可选）',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final moodEntry = MoodEntry(
                      timestamp: DateTime.now(),
                      mood: selectedMood,
                      note: noteController.text.trim().isEmpty ? null : noteController.text.trim(),
                      triggers: selectedTriggers,
                      createdAt: DateTime.now(),
                    );
                    ref.read(moodEntriesProvider.notifier).addMood(moodEntry);
                    Navigator.pop(context);
                  },
                  child: const Text('保存'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoodCard extends StatelessWidget {
  final MoodEntry mood;

  const _MoodCard({required this.mood});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Text(mood.mood.emoji, style: const TextStyle(fontSize: 40)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mood.mood.displayName,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    _formatDateTime(mood.timestamp),
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  if (mood.note != null && mood.note!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(mood.note!),
                  ],
                  if (mood.triggers.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 4,
                      children: mood.triggers.map((t) => Chip(
                        label: Text(t, style: const TextStyle(fontSize: 10)),
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      )).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}