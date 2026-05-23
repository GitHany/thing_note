import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/goal_review/data/goal_review_repository.dart';
import 'package:thing_note/features/goal_review/domain/goal_review.dart';

final goalReviewRepoProvider = Provider((ref) => GoalReviewRepository(ref));

class GoalReviewScreen extends ConsumerStatefulWidget {
  const GoalReviewScreen({super.key});

  @override
  ConsumerState<GoalReviewScreen> createState() => _GoalReviewScreenState();
}

class _GoalReviewScreenState extends ConsumerState<GoalReviewScreen> {
  List<GoalReview> _reviews = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    setState(() => _isLoading = true);
    final repo = ref.read(goalReviewRepoProvider);
    _reviews = await repo.getRecentReviews(limit: 20);
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('目标回顾'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _reviews.isEmpty
              ? _buildEmptyState()
              : _buildReviewList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.rate_review, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('暂无回顾记录', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 8),
          const Text('定期回顾目标，记录你的进展'),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _showAddDialog,
            icon: const Icon(Icons.add),
            label: const Text('添加回顾'),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _reviews.length,
      itemBuilder: (context, index) {
        final review = _reviews[index];
        return _ReviewCard(
          review: review,
          onDelete: () => _deleteReview(review.id!),
        );
      },
    );
  }

  void _showAddDialog() {
    final reflectionController = TextEditingController();
    final nextStepsController = TextEditingController();
    const int goalId = 1; // Would typically show goal selector

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('目标回顾'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Card(
                color: Colors.blue,
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(Icons.info, color: Colors.white),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '选择目标并记录你的进展和反思',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reflectionController,
                decoration: const InputDecoration(
                  labelText: '反思',
                  hintText: '这次回顾你有什么发现？',
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nextStepsController,
                decoration: const InputDecoration(
                  labelText: '下一步计划',
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              final repo = ref.read(goalReviewRepoProvider);
              await repo.insertReview(GoalReview(
                goalId: goalId,
                reviewDate: DateTime.now(),
                progressAfter: 50, // Would get from actual goal data
                reflection: reflectionController.text.trim(),
                nextSteps: nextStepsController.text.trim(),
                createdAt: DateTime.now(),
              ));
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              _loadReviews();
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteReview(int id) async {
    final repo = ref.read(goalReviewRepoProvider);
    await repo.deleteReview(id);
    _loadReviews();
  }
}

class _ReviewCard extends StatelessWidget {
  final GoalReview review;
  final VoidCallback onDelete;

  const _ReviewCard({
    required this.review,
    required this.onDelete,
  });

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final change = review.progressChange;
    final isPositive = change >= 0;

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
                  _formatDate(review.reviewDate),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPositive ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPositive ? Icons.trending_up : Icons.trending_down,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${isPositive ? '+' : ''}$change',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('目标 #${review.goalId}'),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('进展: '),
                Text('${review.progressBefore} → ${review.progressAfter}'),
              ],
            ),
            if (review.reflection != null) ...[
              const SizedBox(height: 8),
              Text(review.reflection!),
            ],
            if (review.nextSteps != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.arrow_forward, size: 16),
                  const SizedBox(width: 4),
                  Text(review.nextSteps!),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}