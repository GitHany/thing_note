import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/smart_summary_assistant/data/smart_summary_provider.dart';
import 'package:thing_note/features/smart_summary_assistant/domain/smart_summary.dart';

class SmartSummaryScreen extends ConsumerWidget {
  const SmartSummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summariesAsync = ref.watch(smartSummaryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('智能摘要'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) => _generateSummary(context, ref, value),
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 'daily', child: Text('生成日报')),
              const PopupMenuItem(value: 'weekly', child: Text('生成周报')),
            ],
          ),
        ],
      ),
      body: summariesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
        data: (summaries) {
          if (summaries.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.summarize, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('暂无摘要', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _generateSummary(context, ref, 'daily'),
                    icon: const Icon(Icons.add),
                    label: const Text('生成日报'),
                  ),
                ],
              ),
            );
          }

          final dailySummaries = summaries.where((s) => s.summaryType == 'daily').toList();
          final weeklySummaries = summaries.where((s) => s.summaryType == 'weekly').toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (weeklySummaries.isNotEmpty) ...[
                const Text('周报', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...weeklySummaries.map((s) => _buildSummaryCard(context, ref, s)),
                const SizedBox(height: 24),
              ],
              const Text('日报', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...dailySummaries.take(10).map((s) => _buildSummaryCard(context, ref, s)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, WidgetRef ref, SmartSummary summary) {
    final isRead = summary.isRead == 1;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          if (!isRead) {
            ref.read(smartSummaryProvider.notifier).markAsRead(summary.id!);
          }
          _showSummaryDetail(context, summary);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: summary.summaryType == 'daily' 
                          ? Colors.blue.withOpacity(0.1) 
                          : Colors.purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      summary.typeLabel,
                      style: TextStyle(
                        color: summary.summaryType == 'daily' ? Colors.blue : Colors.purple,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      summary.title ?? '',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                  if (!isRead)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                summary.content,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.article, size: 16, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text('${summary.recordCount} 条记录', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                  const Spacer(),
                  Icon(Icons.access_time, size: 16, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(summary.createdAt),
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String dateStr) {
    final date = DateTime.parse(dateStr);
    return '${date.month}/${date.day} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _generateSummary(BuildContext context, WidgetRef ref, String type) async {
    try {
      if (type == 'daily') {
        await ref.read(smartSummaryProvider.notifier).generateDailySummary();
      } else {
        await ref.read(smartSummaryProvider.notifier).generateWeeklySummary();
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('摘要生成成功')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('生成失败: $e')),
        );
      }
    }
  }

  void _showSummaryDetail(BuildContext context, SmartSummary summary) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (ctx, scrollController) => Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: summary.summaryType == 'daily' 
                          ? Colors.blue.withOpacity(0.1) 
                          : Colors.purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      summary.typeLabel,
                      style: TextStyle(
                        color: summary.summaryType == 'daily' ? Colors.blue : Colors.purple,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      summary.title ?? '',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                child: Text(
                  summary.content,
                  style: const TextStyle(fontSize: 16, height: 1.6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}