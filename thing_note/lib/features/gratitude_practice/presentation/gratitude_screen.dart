import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/core/database/database_provider.dart';
import 'package:thing_note/features/gratitude_practice/data/gratitude_provider.dart';
import 'package:thing_note/features/gratitude_practice/domain/gratitude_models.dart';

class GratitudeScreen extends ConsumerStatefulWidget {
  const GratitudeScreen({super.key});

  @override
  ConsumerState<GratitudeScreen> createState() => _GratitudeScreenState();
}

class _GratitudeScreenState extends ConsumerState<GratitudeScreen> {
  final _contentController = TextEditingController();
  final List<String> _gratitudeItems = [];
  int _moodLevel = 3;
  
  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(gratitudeStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('每日感恩'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => _showHistory(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats Card
            statsAsync.when(
              data: (stats) => _buildStatsCard(stats),
              loading: () => const SizedBox(),
              error: (_, __) => const SizedBox(),
            ),
            const SizedBox(height: 24),
            
            // Daily Prompt
            _buildPromptCard(),
            const SizedBox(height: 24),
            
            // Gratitude Items
            _buildGratitudeItems(),
            const SizedBox(height: 24),
            
            // Content Input
            _buildContentInput(),
            const SizedBox(height: 24),
            
            // Mood Level
            _buildMoodSelector(),
            const SizedBox(height: 24),
            
            // Save Button
            Center(
              child: FilledButton.icon(
                onPressed: () => _saveEntry(),
                icon: const Icon(Icons.save),
                label: const Text('保存感恩'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard(GratitudeStats stats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(
              Icons.local_fire_department,
              '${stats.streak}',
              '连续天数',
              Colors.orange,
            ),
            _buildStatItem(
              Icons.edit_note,
              '${stats.totalEntries}',
              '本月记录',
              Colors.blue,
            ),
            _buildStatItem(
              Icons.mood,
              stats.avgMood > 0 ? stats.avgMood.toStringAsFixed(1) : '-',
              '平均心情',
              Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildPromptCard() {
    final prompt = GratitudePrompt.defaultPrompts[
      Random().nextInt(GratitudePrompt.defaultPrompts.length)
    ];
    
    return Card(
      color: Colors.amber.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.amber.shade700),
                const SizedBox(width: 8),
                Text(
                  '今日提示',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              prompt.prompt,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGratitudeItems() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.favorite, color: Colors.red),
                const SizedBox(width: 8),
                const Text(
                  '感恩事项',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _showAddItemDialog(),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('添加'),
                ),
              ],
            ),
            if (_gratitudeItems.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.favorite_border, size: 48, color: Colors.grey.shade300),
                      const SizedBox(height: 8),
                      const Text(
                        '添加你感恩的事情',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _gratitudeItems.asMap().entries.map((entry) {
                  return Chip(
                    label: Text(entry.value),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () {
                      setState(() => _gratitudeItems.removeAt(entry.key));
                    },
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentInput() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.edit, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  '今日感想',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(
                hintText: '写下今天让你感恩的事情...',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.mood, color: Colors.purple),
                SizedBox(width: 8),
                Text(
                  '此刻心情',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(5, (i) {
                final level = i + 1;
                final isSelected = _moodLevel == level;
                return GestureDetector(
                  onTap: () => setState(() => _moodLevel = level),
                  child: Column(
                    children: [
                      Icon(
                        _getMoodIcon(level),
                        size: 36,
                        color: isSelected ? _getMoodColor(level) : Colors.grey,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getMoodLabel(level),
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected ? _getMoodColor(level) : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getMoodIcon(int level) {
    switch (level) {
      case 1: return Icons.sentiment_very_dissatisfied;
      case 2: return Icons.sentiment_dissatisfied;
      case 3: return Icons.sentiment_neutral;
      case 4: return Icons.sentiment_satisfied;
      case 5: return Icons.sentiment_very_satisfied;
      default: return Icons.sentiment_neutral;
    }
  }

  Color _getMoodColor(int level) {
    switch (level) {
      case 1: return Colors.red;
      case 2: return Colors.orange;
      case 3: return Colors.yellow.shade700;
      case 4: return Colors.lightGreen;
      case 5: return Colors.green;
      default: return Colors.grey;
    }
  }

  String _getMoodLabel(int level) {
    switch (level) {
      case 1: return '很差';
      case 2: return '较差';
      case 3: return '一般';
      case 4: return '不错';
      case 5: return '很棒';
      default: return '';
    }
  }

  void _showAddItemDialog() {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加感恩事项'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: '例如：家人的支持',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                setState(() => _gratitudeItems.add(controller.text));
              }
              Navigator.pop(context);
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveEntry() async {
    if (_contentController.text.isEmpty && _gratitudeItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请至少填写感想或感恩事项')),
      );
      return;
    }
    
    final db = await ref.read(databaseProvider.future);
    final today = DateTime.now().toIso8601String().substring(0, 10);
    
    final entry = GratitudeEntry(
      date: today,
      content: _contentController.text,
      gratitudeItems: _gratitudeItems,
      moodLevel: _moodLevel,
    );
    
    await db.insert('gratitude_entries', entry.toMap());
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('保存成功')),
      );
      ref.invalidate(todayGratitudeProvider);
      ref.invalidate(gratitudeStatsProvider);
    }
  }

  void _showHistory(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.history),
                    SizedBox(width: 8),
                    Text(
                      '感恩历史',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const Divider(),
                Expanded(
                  child: ref.watch(monthlyGratitudeProvider).when(
                    data: (entries) {
                      if (entries.isEmpty) {
                        return const Center(child: Text('暂无记录'));
                      }
                      return ListView.builder(
                        controller: scrollController,
                        itemCount: entries.length,
                        itemBuilder: (context, index) {
                          final entry = entries[index];
                          final date = DateTime.parse(entry.date);
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                child: Text('${entry.moodLevel ?? 3}'),
                              ),
                              title: Text(
                                entry.content.isNotEmpty
                                    ? entry.content
                                    : '感恩 ${entry.gratitudeItems.length} 件事',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                '${date.month}/${date.day} ${_getMoodLabel(entry.moodLevel ?? 3)}',
                              ),
                            ),
                          );
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Error: $e')),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}