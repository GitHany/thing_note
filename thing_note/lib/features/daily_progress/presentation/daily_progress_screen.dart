import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/daily_progress/data/daily_progress_provider.dart';
import 'package:thing_note/features/daily_progress/domain/daily_progress.dart';

class DailyProgressScreen extends ConsumerWidget {
  const DailyProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(dailyProgressProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('每日进度'),
      ),
      body: progressAsync.when(
        data: (progress) => _buildProgressView(context, ref, progress),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddItemDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildProgressView(BuildContext context, WidgetRef ref, DailyProgress progress) {
    return Column(
      children: [
        // Progress Summary
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text(
                '${(progress.completionRate * 100).toInt()}%',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const Text('今日完成'),
              const SizedBox(height: 8),
              LinearProgressIndicator(value: progress.completionRate),
              const SizedBox(height: 8),
              Text(
                '${progress.completedCount}/${progress.totalCount} 项',
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),

        // Items List
        Expanded(
          child: progress.items.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.checklist, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('暂无进度项'),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: progress.items.length,
                  itemBuilder: (context, index) {
                    final item = progress.items[index];
                    return Card(
                      child: CheckboxListTile(
                        value: item.isCompleted,
                        title: Text(item.title),
                        subtitle: item.targetValue != null
                            ? Text('${item.currentValue}/${item.targetValue} ${item.unit ?? ''}')
                            : null,
                        onChanged: (value) {
                          ref.read(updateProgressProvider).update(
                            item.id,
                            isCompleted: value,
                          );
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showAddItemDialog(BuildContext context) {
    final titleController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加进度项'),
        content: TextField(
          controller: titleController,
          decoration: const InputDecoration(
            labelText: '进度项名称',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }
}