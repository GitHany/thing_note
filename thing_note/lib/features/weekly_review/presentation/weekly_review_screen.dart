import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/weekly_review/data/weekly_review_repository.dart';
import 'package:thing_note/features/weekly_review/domain/weekly_review.dart';

class WeeklyReviewScreen extends ConsumerStatefulWidget {
  const WeeklyReviewScreen({super.key});

  @override
  ConsumerState<WeeklyReviewScreen> createState() => _WeeklyReviewScreenState();
}

class _WeeklyReviewScreenState extends ConsumerState<WeeklyReviewScreen> {
  final _highlightsController = TextEditingController();
  final _reflectionsController = TextEditingController();
  final _accomplishmentsController = TextEditingController();
  final _nextWeekGoalsController = TextEditingController();

  @override
  void dispose() {
    _highlightsController.dispose();
    _reflectionsController.dispose();
    _accomplishmentsController.dispose();
    _nextWeekGoalsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(currentWeekStatsProvider);
    final reviewsAsync = ref.watch(weeklyReviewsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('周回顾'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => _showHistoryDialog(context, reviewsAsync),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatsCard(statsAsync),
            const SizedBox(height: 24),
            _buildSectionTitle('本周亮点'),
            const SizedBox(height: 8),
            TextField(
              controller: _highlightsController,
              decoration: const InputDecoration(
                hintText: '写下本周最让你骄傲的事情...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('反思与成长'),
            const SizedBox(height: 8),
            TextField(
              controller: _reflectionsController,
              decoration: const InputDecoration(
                hintText: '这周学到了什么？有什么可以改进的？',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('成就清单'),
            const SizedBox(height: 8),
            TextField(
              controller: _accomplishmentsController,
              decoration: const InputDecoration(
                hintText: '列出这周完成的所有重要事项...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('下周目标'),
            const SizedBox(height: 8),
            TextField(
              controller: _nextWeekGoalsController,
              decoration: const InputDecoration(
                hintText: '下周想要达成的目标是什么？',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _saveReview(context),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('保存周回顾', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildStatsCard(AsyncValue<WeekStats> statsAsync) {
    return statsAsync.when(
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (e, _) => Card(child: Padding(padding: const EdgeInsets.all(16), child: Text('加载失败: $e'))),
      data: (stats) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '本周数据概览',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatColumn(Icons.edit_note, '${stats.recordCount}', '记录'),
                  _buildStatColumn(Icons.timer, '${stats.totalMinutes}分钟', '时长'),
                  _buildStatColumn(Icons.flag, '${stats.completedGoals}', '目标'),
                  _buildStatColumn(Icons.check_circle, '${stats.completedHabits}', '习惯'),
                ],
              ),
              if (stats.topActivities.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                const Text('热门活动', style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: stats.topActivities.entries.map((e) {
                    return Chip(
                      avatar: const Icon(Icons.trending_up, size: 16),
                      label: Text('${e.key} (${e.value})'),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatColumn(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, size: 28, color: Theme.of(context).primaryColor),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  void _saveReview(BuildContext context) {
    final repository = ref.read(weeklyReviewRepositoryProvider);
    final now = DateTime.now();

    final review = WeeklyReview(
      weekStartDate: repository.getWeekStartDate(now),
      weekEndDate: repository.getWeekEndDate(now),
      highlights: _highlightsController.text.trim(),
      reflections: _reflectionsController.text.trim(),
      accomplishments: _accomplishmentsController.text.trim(),
      nextWeekGoals: _nextWeekGoalsController.text.trim(),
      createdAt: DateTime.now(),
    );

    ref.read(weeklyReviewsProvider.notifier).addReview(review);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('周回顾已保存 ✓')),
    );

    _highlightsController.clear();
    _reflectionsController.clear();
    _accomplishmentsController.clear();
    _nextWeekGoalsController.clear();
  }

  void _showHistoryDialog(BuildContext context, AsyncValue<List<WeeklyReview>> reviewsAsync) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('历史回顾'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: reviewsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('错误: $e')),
            data: (reviews) {
              if (reviews.isEmpty) {
                return const Center(child: Text('暂无周回顾记录'));
              }
              return ListView.builder(
                itemCount: reviews.length,
                itemBuilder: (context, index) {
                  final review = reviews[index];
                  return ExpansionTile(
                    title: Text(review.displayRange),
                    subtitle: Text('创建于 ${_formatDate(review.createdAt)}'),
                    children: [
                      if (review.highlights != null && review.highlights!.isNotEmpty)
                        ListTile(
                          leading: const Icon(Icons.star, color: Colors.amber),
                          title: const Text('亮点'),
                          subtitle: Text(review.highlights!),
                        ),
                      if (review.accomplishments != null && review.accomplishments!.isNotEmpty)
                        ListTile(
                          leading: const Icon(Icons.check_circle, color: Colors.green),
                          title: const Text('成就'),
                          subtitle: Text(review.accomplishments!),
                        ),
                      if (review.nextWeekGoals != null && review.nextWeekGoals!.isNotEmpty)
                        ListTile(
                          leading: const Icon(Icons.flag, color: Colors.blue),
                          title: const Text('下周目标'),
                          subtitle: Text(review.nextWeekGoals!),
                        ),
                    ],
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}