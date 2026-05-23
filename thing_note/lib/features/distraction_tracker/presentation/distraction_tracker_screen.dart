import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/distraction_tracker/data/distraction_tracker_repository.dart';
import 'package:thing_note/features/distraction_tracker/domain/distraction_record.dart';

class DistractionTrackerScreen extends ConsumerWidget {
  const DistractionTrackerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(distractionRecordsProvider);
    final statsAsync = ref.watch(distractionStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('分心追踪器'),
      ),
      body: Column(
        children: [
          _buildStatsCard(statsAsync),
          Expanded(
            child: recordsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('错误: $e')),
              data: (records) {
                if (records.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.psychology, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('暂无分心记录', style: TextStyle(fontSize: 18)),
                        SizedBox(height: 8),
                        Text('记录分心事件，了解干扰模式', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: records.length,
                  itemBuilder: (context, index) {
                    final record = records[index];
                    return _DistractionCard(record: record);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showQuickAdd(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatsCard(AsyncValue<Map<String, dynamic>> statsAsync) {
    return statsAsync.when(
      data: (stats) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.orange.shade400, Colors.red.shade400],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem('今日', '${stats['today_count'] ?? 0}', '次'),
            _buildStatItem('本周', '${stats['week_count'] ?? 0}', '次'),
            _buildStatItem('浪费', '${stats['today_minutes'] ?? 0}', '分钟'),
          ],
        ),
      ),
      loading: () => const SizedBox(height: 100),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildStatItem(String label, String value, String unit) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 4),
        Text('$value $unit', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
      ],
    );
  }

  void _showQuickAdd(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('快速记录分心', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: DistractionRecord.distractionTypes.map((type) {
                return ActionChip(
                  avatar: Text(DistractionRecord.typeIcons[type] ?? '❓'),
                  label: Text(DistractionRecord.typeLabels[type] ?? type),
                  onPressed: () {
                    ref.read(distractionRecordsProvider.notifier).quickAdd(type);
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _DistractionCard extends ConsumerWidget {
  final DistractionRecord record;

  const _DistractionCard({required this.record});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.orange.withOpacity(0.2),
          child: Text(
            DistractionRecord.typeIcons[record.distractionType] ?? '❓',
            style: const TextStyle(fontSize: 20),
          ),
        ),
        title: Text(DistractionRecord.typeLabels[record.distractionType] ?? record.distractionType),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (record.source != null) Text('来源: ${record.source}'),
            Text('持续 ${record.durationMinutes} 分钟'),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, size: 20),
          onPressed: () {
            ref.read(distractionRecordsProvider.notifier).deleteRecord(record.id!);
          },
        ),
      ),
    );
  }
}