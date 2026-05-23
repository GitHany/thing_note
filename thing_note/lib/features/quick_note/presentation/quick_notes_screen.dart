import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/quick_note/data/quick_note_repository.dart';
import 'package:thing_note/features/quick_note/domain/quick_note.dart';

class QuickNotesScreen extends ConsumerStatefulWidget {
  const QuickNotesScreen({super.key});

  @override
  ConsumerState<QuickNotesScreen> createState() => _QuickNotesScreenState();
}

class _QuickNotesScreenState extends ConsumerState<QuickNotesScreen> {
  @override
  Widget build(BuildContext context) {
    final notesAsync = ref.watch(quickNotesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('快捷便签'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddNoteDialog(context),
          ),
        ],
      ),
      body: notesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('错误: $e')),
        data: (notes) {
          if (notes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.sticky_note_2_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('暂无便签', style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => _showAddNoteDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('创建便签'),
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: notes.length,
            itemBuilder: (context, index) => _NoteCard(note: notes[index]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddNoteDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddNoteDialog(BuildContext context) {
    final contentController = TextEditingController();
    int selectedColor = QuickNoteColors.presets[0];

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
              const Text('创建便签', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: contentController,
                decoration: const InputDecoration(
                  hintText: '输入便签内容...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 16),
              const Text('选择颜色'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: QuickNoteColors.presets.map((color) {
                  final isSelected = color == selectedColor;
                  return GestureDetector(
                    onTap: () => setState(() => selectedColor = color),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Color(color),
                        borderRadius: BorderRadius.circular(8),
                        border: isSelected ? Border.all(color: Colors.black, width: 2) : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (contentController.text.trim().isNotEmpty) {
                      final now = DateTime.now();
                      final note = QuickNote(
                        content: contentController.text.trim(),
                        color: selectedColor,
                        createdAt: now,
                        updatedAt: now,
                      );
                      ref.read(quickNotesProvider.notifier).addNote(note);
                      Navigator.pop(context);
                    }
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

class _NoteCard extends ConsumerWidget {
  final QuickNote note;

  const _NoteCard({required this.note});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => _showEditDialog(context, ref),
      onLongPress: () => _showOptions(context, ref),
      child: Container(
        decoration: BoxDecoration(
          color: Color(note.color),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      note.content,
                      style: const TextStyle(fontSize: 14),
                      maxLines: 8,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatTime(note.updatedAt),
                    style: TextStyle(color: Colors.grey[600], fontSize: 10),
                  ),
                ],
              ),
            ),
            if (note.isPinned)
              Positioned(
                top: 8,
                right: 8,
                child: Icon(Icons.push_pin, size: 16, color: Colors.grey[600]),
              ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inHours < 1) return '${diff.inMinutes}分钟前';
    if (diff.inDays < 1) return '${diff.inHours}小时前';
    return '${time.month}/${time.day}';
  }

  void _showEditDialog(BuildContext context, WidgetRef ref) {
    final contentController = TextEditingController(text: note.content);
    int selectedColor = note.color;

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
              const Text('编辑便签', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: contentController,
                decoration: const InputDecoration(
                  hintText: '输入便签内容...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 16),
              const Text('选择颜色'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: QuickNoteColors.presets.map((color) {
                  final isSelected = color == selectedColor;
                  return GestureDetector(
                    onTap: () => setState(() => selectedColor = color),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Color(color),
                        borderRadius: BorderRadius.circular(8),
                        border: isSelected ? Border.all(color: Colors.black, width: 2) : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (contentController.text.trim().isNotEmpty) {
                      final updated = note.copyWith(
                        content: contentController.text.trim(),
                        color: selectedColor,
                        updatedAt: DateTime.now(),
                      );
                      ref.read(quickNotesProvider.notifier).updateNote(updated);
                      Navigator.pop(context);
                    }
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

  void _showOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(note.isPinned ? Icons.push_pin_outlined : Icons.push_pin),
              title: Text(note.isPinned ? '取消置顶' : '置顶'),
              onTap: () {
                ref.read(quickNotesProvider.notifier).togglePin(note.id!);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('删除', style: TextStyle(color: Colors.red)),
              onTap: () {
                ref.read(quickNotesProvider.notifier).deleteNote(note.id!);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}