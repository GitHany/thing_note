import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/travel_log/data/travel_log_repository.dart';
import 'package:thing_note/features/travel_log/domain/travel_log.dart';

class TravelLogScreen extends ConsumerStatefulWidget {
  const TravelLogScreen({super.key});

  @override
  ConsumerState<TravelLogScreen> createState() => _TravelLogScreenState();
}

class _TravelLogScreenState extends ConsumerState<TravelLogScreen> {
  @override
  Widget build(BuildContext context) {
    final logsAsync = ref.watch(travelLogsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('旅行日志'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddTravelLogDialog(context),
          ),
        ],
      ),
      body: logsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('错误: $e')),
        data: (logs) {
          if (logs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.flight_takeoff, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('暂无旅行记录', style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => _showAddTravelLogDialog(context),
                    child: const Text('添加旅行'),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: logs.length,
            itemBuilder: (context, index) => _TravelLogCard(log: logs[index]),
          );
        },
      ),
    );
  }

  void _showAddTravelLogDialog(BuildContext context) {
    final titleController = TextEditingController();
    final destinationController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加旅行'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: '旅行标题'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: destinationController,
                decoration: const InputDecoration(labelText: '目的地'),
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
              if (titleController.text.trim().isNotEmpty) {
                final now = DateTime.now();
                final log = TravelLog(
                  title: titleController.text.trim(),
                  destination: destinationController.text.trim(),
                  startDate: now,
                  createdAt: now,
                  updatedAt: now,
                );
                ref.read(travelLogsProvider.notifier).addTravelLog(log);
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

class _TravelLogCard extends ConsumerWidget {
  final TravelLog log;

  const _TravelLogCard({required this.log});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showLogDetail(context, ref),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      log.title,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      log.isFavorite ? Icons.star : Icons.star_border,
                      color: log.isFavorite ? Colors.amber : null,
                    ),
                    onPressed: () => ref.read(travelLogsProvider.notifier)
                        .toggleFavorite(log.id!, !log.isFavorite),
                  ),
                ],
              ),
              if (log.destination != null && log.destination!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(log.destination!, style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Text(
                '${log.startDate.year}-${log.startDate.month.toString().padLeft(2, '0')}-${log.startDate.day.toString().padLeft(2, '0')}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              if (log.photos.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.photo, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text('${log.photos.length} 张照片', style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showLogDetail(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(log.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('目的地: ${log.destination ?? '未设置'}'),
            const SizedBox(height: 8),
            Text('时长: ${log.durationDays} 天'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      ref.read(travelLogsProvider.notifier).deleteTravelLog(log.id!);
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('删除'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}