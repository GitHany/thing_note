import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/timeline_models.dart';

/// 智能时间线屏幕
class IntelligentTimelineScreen extends ConsumerWidget {
  const IntelligentTimelineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // watch timeline type to trigger rebuild
    ref.watch(timelineTypeProvider);
    final timelineAsync = ref.watch(intelligentTimelineProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('智能时间线'),
        actions: [
          PopupMenuButton<TimelineType>(
            icon: const Icon(Icons.sort),
            onSelected: (type) {
              ref.read(timelineTypeProvider.notifier).state = type;
              ref.read(intelligentTimelineProvider.notifier).loadTimeline(type: type);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: TimelineType.chronological, child: Text('按时间顺序')),
              const PopupMenuItem(value: TimelineType.grouped, child: Text('按时间段分组')),
              const PopupMenuItem(value: TimelineType.activity, child: Text('按活动类型')),
            ],
          ),
        ],
      ),
      body: timelineAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
        data: (nodes) => nodes.isEmpty
            ? const Center(child: Text('暂无时间线数据'))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: nodes.length,
                itemBuilder: (context, index) {
                  final node = nodes[index];
                  final isLast = index == nodes.length - 1;
                  return IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 时间线
                        SizedBox(
                          width: 60,
                          child: Column(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(color: node.color.withOpacity(0.2), shape: BoxShape.circle),
                                child: Icon(node.icon, color: node.color, size: 16),
                              ),
                              if (!isLast) Expanded(child: Container(width: 2, color: node.color.withOpacity(0.3))),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // 内容
                        Expanded(
                          child: Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(_formatTime(node.time), style: Theme.of(context).textTheme.bodySmall),
                                      const Spacer(),
                                      if (node.recordId != null)
                                        IconButton(
                                          icon: const Icon(Icons.open_in_new, size: 16),
                                          onPressed: () {},
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(node.title, style: Theme.of(context).textTheme.titleMedium),
                                  if (node.subtitle != null) ...[
                                    const SizedBox(height: 4),
                                    Text(node.subtitle!, style: Theme.of(context).textTheme.bodySmall),
                                  ],
                                  if (node.tags.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 4,
                                      children: node.tags.map((t) => Chip(label: Text(t, style: const TextStyle(fontSize: 10)), padding: EdgeInsets.zero)).toList(),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}