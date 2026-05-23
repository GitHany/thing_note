import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/sensory_journal/data/sensory_journal_repository.dart';
import 'package:thing_note/features/sensory_journal/domain/sensory_record.dart';

class SensoryJournalScreen extends ConsumerWidget {
  const SensoryJournalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(sensoryRecordsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('感官日记'),
      ),
      body: recordsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('错误: $e')),
        data: (records) {
          if (records.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.spa, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('暂无记录', style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 8),
                  const Text('记录你的感官体验，了解环境偏好', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _showAddDialog(context, ref),
                    icon: const Icon(Icons.add),
                    label: const Text('记录感官'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: records.length,
            itemBuilder: (context, index) {
              final record = records[index];
              return _SensoryCard(record: record);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final visualController = TextEditingController();
    final auditoryController = TextEditingController();
    final olfactoryController = TextEditingController();
    final noteController = TextEditingController();
    int moodScore = 3;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('记录感官体验'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSenseField('👁️ 视觉环境', visualController),
                _buildSenseField('👂 听觉环境', auditoryController),
                _buildSenseField('👃 嗅觉环境', olfactoryController),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('心情: '),
                    ...List.generate(5, (i) {
                      return GestureDetector(
                        onTap: () => setState(() => moodScore = i + 1),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(['😢', '😕', '😐', '🙂', '😄'][i], style: TextStyle(fontSize: moodScore == i + 1 ? 28 : 20)),
                        ),
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: noteController,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: '备注'),
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
                final record = SensoryRecord(
                  recordedAt: DateTime.now().toIso8601String(),
                  visualEnvironment: visualController.text,
                  auditoryEnvironment: auditoryController.text,
                  olfactoryEnvironment: olfactoryController.text,
                  moodScore: moodScore,
                  note: noteController.text.isEmpty ? null : noteController.text,
                );
                ref.read(sensoryRecordsProvider.notifier).addRecord(record);
                Navigator.pop(context);
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSenseField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
    );
  }
}

class _SensoryCard extends ConsumerWidget {
  final SensoryRecord record;

  const _SensoryCard({required this.record});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  ['😢', '😕', '😐', '🙂', '😄'][record.moodScore - 1],
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  DateTime.parse(record.recordedAt).toString().substring(0, 10),
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (record.visualEnvironment != null)
                  Chip(label: Text('视觉: ${record.visualEnvironment}')),
                if (record.auditoryEnvironment != null)
                  Chip(label: Text('听觉: ${record.auditoryEnvironment}')),
                if (record.olfactoryEnvironment != null)
                  Chip(label: Text('嗅觉: ${record.olfactoryEnvironment}')),
              ],
            ),
            if (record.note != null) ...[
              const SizedBox(height: 8),
              Text(record.note!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ],
        ),
      ),
    );
  }
}