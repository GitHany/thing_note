import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/interrupt_tracker/data/interrupt_tracker_provider.dart';
import 'package:thing_note/features/interrupt_tracker/domain/interrupt_tracker.dart';

class InterruptTrackerScreen extends ConsumerStatefulWidget {
  const InterruptTrackerScreen({super.key});

  @override
  ConsumerState<InterruptTrackerScreen> createState() => _InterruptTrackerScreenState();
}

class _InterruptTrackerScreenState extends ConsumerState<InterruptTrackerScreen> {
  @override
  Widget build(BuildContext context) {
    final activeInterrupt = ref.watch(activeInterruptProvider);
    final statsAsync = ref.watch(interruptStatsProvider);
    final interruptsAsync = ref.watch(todayInterruptsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('中断追踪'),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () => _showAnalytics(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Quick Record Button
          if (activeInterrupt == null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton.icon(
                  onPressed: () => _showRecordDialog(context),
                  icon: const Icon(Icons.add),
                  label: const Text('记录中断'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            )
          else
            _buildActiveInterruptCard(activeInterrupt),

          // Stats
          statsAsync.when(
            data: (stats) => _buildStatsCard(stats),
            loading: () => const SizedBox(height: 100),
            error: (_, __) => const SizedBox(height: 100),
          ),

          // Interrupt List
          Expanded(
            child: interruptsAsync.when(
              data: (interrupts) => _buildInterruptList(interrupts),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveInterruptCard(Interrupt interrupt) {
    final duration = DateTime.now().difference(interrupt.startedAt);
    final minutes = duration.inMinutes;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning, color: Colors.red, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '进行中的中断',
                  style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                ),
                Text(
                  interrupt.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '$minutes分钟',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _endInterrupt(interrupt),
            child: const Text('结束'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(InterruptStats stats) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('今日中断', '${stats.todayTotal}', Icons.notifications),
          _buildStatItem('生产性', '${stats.todayProductive}', Icons.check_circle),
          _buildStatItem('耗时', '${stats.todayMinutes}分钟', Icons.timer),
          _buildStatItem('生产率', '${(stats.productivityRate * 100).toInt()}%', Icons.trending_up),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.red.shade400, size: 20),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  Widget _buildInterruptList(List<Interrupt> interrupts) {
    if (interrupts.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
            SizedBox(height: 16),
            Text('今天还没有中断！'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: interrupts.length,
      itemBuilder: (context, index) {
        final interrupt = interrupts[index];
        final duration = interrupt.durationSeconds ~/ 60;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: interrupt.isProductive ? Colors.green : Colors.red,
              child: Icon(
                interrupt.isProductive ? Icons.check : Icons.close,
                color: Colors.white,
              ),
            ),
            title: Text(interrupt.title),
            subtitle: Text('$interrupt.type.displayName • $duration分钟'),
            trailing: Text(
              '${interrupt.startedAt.hour}:${interrupt.startedAt.minute.toString().padLeft(2, '0')}',
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        );
      },
    );
  }

  void _showRecordDialog(BuildContext context) {
    final titleController = TextEditingController();
    InterruptType selectedType = InterruptType.notification;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('记录中断'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: '中断内容',
                  hintText: '例如：手机通知',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              const Text('类型'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: InterruptType.values.map((type) {
                  return ChoiceChip(
                    label: Text(type.displayName),
                    selected: selectedType == type,
                    onSelected: (selected) {
                      setState(() => selectedType = type);
                    },
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.isNotEmpty) {
                  final interrupt = Interrupt(
                    title: titleController.text,
                    type: selectedType,
                    startedAt: DateTime.now(),
                  );
                  ref.read(activeInterruptProvider.notifier).state = interrupt;
                  Navigator.pop(context);
                }
              },
              child: const Text('开始追踪'),
            ),
          ],
        ),
      ),
    );
  }

  void _endInterrupt(Interrupt interrupt) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          bool isProductive = false;
          return AlertDialog(
            title: const Text('结束中断'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('中断时长: ${interrupt.durationSeconds ~/ 60}分钟'),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('生产性中断？'),
                  value: isProductive,
                  onChanged: (value) => setState(() => isProductive = value),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消'),
              ),
              ElevatedButton(
                onPressed: () {
                  ref.read(activeInterruptProvider.notifier).state = null;
                  Navigator.pop(context);
                },
                child: const Text('确认结束'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAnalytics(BuildContext context) {
    // TODO: Navigate to analytics screen
  }
}