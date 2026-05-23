import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/grateful_notes/data/grateful_notes_provider.dart';
import 'package:thing_note/features/grateful_notes/domain/grateful_notes.dart';

class GratefulNotesScreen extends ConsumerStatefulWidget {
  const GratefulNotesScreen({super.key});

  @override
  ConsumerState<GratefulNotesScreen> createState() => _GratefulNotesScreenState();
}

class _GratefulNotesScreenState extends ConsumerState<GratefulNotesScreen> {
  @override
  Widget build(BuildContext context) {
    final notesAsync = ref.watch(gratefulNotesProvider);
    final statsAsync = ref.watch(gratefulStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('感恩日志'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _showCalendar(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats Card
          statsAsync.when(
            data: (stats) => _buildStatsCard(stats),
            loading: () => const SizedBox(height: 100),
            error: (_, __) => const SizedBox(height: 100),
          ),

          // Notes List
          Expanded(
            child: notesAsync.when(
              data: (notes) => _buildNotesList(notes),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddNoteDialog(context),
        icon: const Icon(Icons.favorite),
        label: const Text('记录感恩'),
        backgroundColor: Colors.pink,
      ),
    );
  }

  Widget _buildStatsCard(GratefulStats stats) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.pink, Colors.red],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(Icons.note, '${stats.totalNotes}', '记录'),
          _buildStatItem(Icons.local_fire_department, '${stats.streakDays}', '连续'),
          _buildStatItem(Icons.mood, stats.avgMoodLevel.toStringAsFixed(1), '平均心情'),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
      ],
    );
  }

  Widget _buildNotesList(List<GratefulNote> notes) {
    if (notes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border, size: 64, color: Colors.pink.shade200),
            const SizedBox(height: 16),
            const Text('今天有什么想感恩的吗？'),
            const SizedBox(height: 8),
            const Text('记录感恩可以提升幸福感', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final note = notes[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.favorite, color: Colors.pink.shade300, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      '${note.date.month}/${note.date.day}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const Spacer(),
                    _buildMoodIndicator(note.moodLevel),
                  ],
                ),
                const SizedBox(height: 8),
                Text(note.content),
                if (note.category != null) ...[
                  const SizedBox(height: 8),
                  Chip(
                    label: Text(note.category!),
                    backgroundColor: Colors.pink.withOpacity(0.1),
                    labelStyle: TextStyle(color: Colors.pink.shade700, fontSize: 10),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMoodIndicator(int level) {
    final icons = ['😢', '😕', '😐', '🙂', '😊'];
    return Text(icons[level - 1], style: const TextStyle(fontSize: 16));
  }

  void _showAddNoteDialog(BuildContext context) {
    final contentController = TextEditingController();
    String selectedCategory = 'people';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('记录感恩'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('今天想感恩的是什么？'),
                const SizedBox(height: 16),
                TextField(
                  controller: contentController,
                  decoration: const InputDecoration(
                    hintText: '例如：感谢家人的支持',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                const Text('分类'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    _buildCategoryChip('people', '人', setState, selectedCategory, (v) { selectedCategory = v; }),
                    _buildCategoryChip('health', '健康', setState, selectedCategory, (v) { selectedCategory = v; }),
                    _buildCategoryChip('work', '工作', setState, selectedCategory, (v) { selectedCategory = v; }),
                    _buildCategoryChip('life', '生活', setState, selectedCategory, (v) { selectedCategory = v; }),
                    _buildCategoryChip('learning', '学习', setState, selectedCategory, (v) { selectedCategory = v; }),
                  ],
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
                if (contentController.text.isNotEmpty) {
                  final note = GratefulNote(
                    date: DateTime.now(),
                    content: contentController.text,
                    category: selectedCategory,
                    moodLevel: 4,
                    createdAt: DateTime.now(),
                  );
                  ref.read(addGratefulNoteProvider).addNote(note);
                  Navigator.pop(context);
                }
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String value, String label, StateSetter setState, String selected, void Function(String) onSelected) {
    return ChoiceChip(
      label: Text(label),
      selected: selected == value,
      onSelected: (isSelected) {
        onSelected(value);
        setState(() {});
      },
    );
  }

  void _showCalendar(BuildContext context) {
    // TODO: Navigate to calendar view
  }
}