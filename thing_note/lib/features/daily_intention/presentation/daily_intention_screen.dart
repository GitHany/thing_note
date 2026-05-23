import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/daily_intention/data/daily_intention_repository.dart';
import 'package:thing_note/features/daily_intention/domain/daily_intention.dart';

class DailyIntentionScreen extends ConsumerWidget {
  const DailyIntentionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final intentionAsync = ref.watch(todayIntentionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('每日意图'),
      ),
      body: intentionAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('错误: $e')),
        data: (intention) => _buildContent(context, ref, intention),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, DailyIntention? intention) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Icon(Icons.center_focus_strong, size: 64, color: Colors.indigo),
          const SizedBox(height: 16),
          const Text(
            '今日最重要的意图是什么？',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          if (intention == null)
            _IntentionInput(onSave: (text, cat, col) async {
              final now = DateTime.now();
              final date = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
              final newInt = DailyIntention(
                intention: text,
                category: cat,
                color: col,
                createdAt: now,
                updatedAt: now,
                date: date,
              );
              await ref.read(dailyIntentionRepositoryProvider).insertIntention(newInt);
              ref.invalidate(todayIntentionProvider);
            })
          else
            _IntentionCard(intention: intention, onRefresh: () => ref.invalidate(todayIntentionProvider)),
        ],
      ),
    );
  }
}

class _IntentionInput extends StatefulWidget {
  final Function(String text, String? cat, int col) onSave;
  const _IntentionInput({required this.onSave});
  @override
  State<_IntentionInput> createState() => _IntentionInputState();
}

class _IntentionInputState extends State<_IntentionInput> {
  final _ctrl = TextEditingController();
  String? _selectedCategory;
  int _selectedColor = 0xFF2196F3;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _ctrl,
          maxLines: 3,
          style: const TextStyle(fontSize: 18),
          decoration: const InputDecoration(
            hintText: '例如：专注完成今天最重要的报告...',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        const Text('选择分类:'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: IntentionCategory.values.map((cat) {
            return ChoiceChip(
              label: Text(cat.label),
              selected: _selectedCategory == cat.label,
              selectedColor: Color(cat.color).withOpacity(0.3),
              onSelected: (_) => setState(() {
                _selectedCategory = cat.label;
                _selectedColor = cat.color;
              }),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _ctrl.text.trim().isEmpty
                ? null
                : () => widget.onSave(_ctrl.text.trim(), _selectedCategory, _selectedColor),
            child: const Text('设置今日意图'),
          ),
        ),
      ],
    );
  }
}

class _IntentionCard extends StatelessWidget {
  final DailyIntention intention;
  final VoidCallback onRefresh;
  const _IntentionCard({required this.intention, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Color(intention.color).withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                intention.category ?? '今日意图',
                style: TextStyle(color: Color(intention.color), fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              intention.intention,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(
                    intention.isCompleted ? Icons.check_circle : Icons.check_circle_outline,
                    color: intention.isCompleted ? Colors.green : Colors.grey,
                    size: 32,
                  ),
                  onPressed: () async {
                    // 标记完成
                  },
                ),
                const SizedBox(width: 16),
                Text(
                  intention.isCompleted ? '已完成 ✓' : '点击标记完成',
                  style: TextStyle(color: intention.isCompleted ? Colors.green : Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
