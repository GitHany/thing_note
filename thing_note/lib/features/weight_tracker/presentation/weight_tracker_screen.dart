import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/weight_tracker/data/weight_repository.dart';
import 'package:thing_note/features/weight_tracker/domain/weight_record.dart';

class WeightTrackerScreen extends ConsumerStatefulWidget {
  const WeightTrackerScreen({super.key});

  @override
  ConsumerState<WeightTrackerScreen> createState() => _WeightTrackerScreenState();
}

class _WeightTrackerScreenState extends ConsumerState<WeightTrackerScreen> {
  @override
  Widget build(BuildContext context) {
    final recordsAsync = ref.watch(weightRecordsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('体重追踪'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddWeightDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Today's summary
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            child: ref.watch(latestWeightProvider).when(
              data: (record) => record != null
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${record.weight}',
                          style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        Text('${record.unit}', style: const TextStyle(fontSize: 18)),
                      ],
                    )
                  : const Text('今日未记录', style: TextStyle(fontSize: 18)),
              loading: () => const CircularProgressIndicator(),
              error: (e, st) => Text('错误: $e'),
            ),
          ),
          // Records list
          Expanded(
            child: recordsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('错误: $e')),
              data: (records) {
                if (records.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.monitor_weight, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text('暂无体重记录', style: TextStyle(fontSize: 18)),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () => _showAddWeightDialog(context),
                          child: const Text('添加记录'),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: records.length,
                  itemBuilder: (context, index) => _WeightRecordCard(record: records[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAddWeightDialog(BuildContext context) {
    final weightController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加体重记录'),
        content: TextField(
          controller: weightController,
          decoration: const InputDecoration(labelText: '体重 (kg)', hintText: '例如: 70.5'),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              final weight = double.tryParse(weightController.text);
              if (weight != null && weight > 0) {
                final now = DateTime.now();
                final record = WeightRecord(
                  weight: weight,
                  recordedAt: now,
                  createdAt: now,
                );
                ref.read(weightRecordsProvider.notifier).addWeightRecord(record);
                Navigator.pop(context);
              }
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }
}

class _WeightRecordCard extends ConsumerWidget {
  final WeightRecord record;

  const _WeightRecordCard({required this.record});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
          child: Text(record.weight.toStringAsFixed(1), style: const TextStyle(fontSize: 12)),
        ),
        title: Text('${record.weight} ${record.unit}'),
        subtitle: Text(_formatDate(record.recordedAt)),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: () => ref.read(weightRecordsProvider.notifier).deleteWeightRecord(record.id!),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}