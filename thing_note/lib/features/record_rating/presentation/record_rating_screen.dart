import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/record_rating/data/record_rating_service.dart';

class RecordRatingScreen extends ConsumerStatefulWidget {
  const RecordRatingScreen({super.key});

  @override
  ConsumerState<RecordRatingScreen> createState() => _RecordRatingScreenState();
}

class _RecordRatingScreenState extends ConsumerState<RecordRatingScreen> {
  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(ratingStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('记录评分'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context),
            tooltip: '筛选',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 统计概览
            statsAsync.when(
              data: (stats) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          icon: Icons.star,
                          label: '平均重要性',
                          value: stats.avgImportance.toStringAsFixed(1),
                          color: Colors.amber,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.thumb_up,
                          label: '平均满意度',
                          value: stats.avgSatisfaction.toStringAsFixed(1),
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          icon: Icons.analytics,
                          label: '已评分',
                          value: '${stats.totalRatings}',
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.favorite,
                          label: '高价值',
                          value: '${stats.highValueCount}',
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // 评分分布
                  const Text(
                    '评分分布',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [1, 2, 3, 4, 5].map((rating) {
                          final count = stats.distribution[rating] ?? 0;
                          final percentage = stats.totalRatings > 0
                              ? count / stats.totalRatings
                              : 0.0;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Text('$rating星'),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: LinearProgressIndicator(
                                    value: percentage,
                                    backgroundColor: Colors.grey[200],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text('$count'),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('加载失败: $e')),
            ),
            const SizedBox(height: 24),
            // 高价值记录
            const Text(
              '⭐ 高价值记录',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _HighValueRecordsList(),
          ],
        ),
      ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('筛选条件', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Text('评分类型'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                FilterChip(label: const Text('重要性'), selected: true, onSelected: (_) {}),
                FilterChip(label: const Text('满意度'), selected: false, onSelected: (_) {}),
              ],
            ),
            const SizedBox(height: 16),
            const Text('评分范围'),
            const SizedBox(height: 8),
            const Row(
              children: [
                Expanded(child: TextField(decoration: InputDecoration(labelText: '最低分'))),
                SizedBox(width: 16),
                Expanded(child: TextField(decoration: InputDecoration(labelText: '最高分'))),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('应用筛选'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }
}

class _HighValueRecordsList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.watch(recordRatingServiceProvider);

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: service.getHighValueRecords(),
      builder: (context, snapshot) {
        final records = snapshot.data ?? [];

        if (records.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.star_border, size: 48, color: Colors.grey),
                    SizedBox(height: 8),
                    Text('暂无高价值记录'),
                    SizedBox(height: 4),
                    Text('给你的重要记录打分吧', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ),
          );
        }

        return Column(
          children: records.map((record) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Stack(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 32),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${record['importance_rating']}',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
              title: Text(record['note']?.toString() ?? '无内容', maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text('${record['occurred_at']}'),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(5, (i) => Icon(
                      i < (record['importance_rating'] as int? ?? 0) ? Icons.star : Icons.star_border,
                      size: 12,
                      color: Colors.amber,
                    )),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(5, (i) => Icon(
                      i < (record['satisfaction_rating'] as int? ?? 0) ? Icons.thumb_up : Icons.thumb_up_outlined,
                      size: 12,
                      color: Colors.green,
                    )),
                  ),
                ],
              ),
            ),
          )).toList(),
        );
      },
    );
  }
}