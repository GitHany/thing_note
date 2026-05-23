import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/periodic_review/data/periodic_review_provider.dart';

class PeriodicReviewScreen extends ConsumerStatefulWidget {
  const PeriodicReviewScreen({super.key});

  @override
  ConsumerState<PeriodicReviewScreen> createState() => _PeriodicReviewScreenState();
}

class _PeriodicReviewScreenState extends ConsumerState<PeriodicReviewScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pendingAsync = ref.watch(pendingReviewsProvider);
    final historyAsync = ref.watch(reviewHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('周期回顾'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddScheduleDialog(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '待回顾'),
            Tab(text: '模板'),
            Tab(text: '历史'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Pending Reviews Tab
          pendingAsync.when(
            data: (pending) => _buildPendingReviews(context, pending),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
          // Templates Tab
          _buildTemplatesTab(context),
          // History Tab
          historyAsync.when(
            data: (history) => _buildHistoryTab(context, history),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingReviews(BuildContext context, List<PendingReview> pending) {
    if (pending.isEmpty) {
      return _buildEmptyState(
        context,
        icon: Icons.check_circle,
        title: '暂无待回顾项目',
        subtitle: '所有回顾都已完成',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: pending.length,
      itemBuilder: (context, index) {
        final item = pending[index];
        return _buildPendingReviewCard(context, item);
      },
    );
  }

  Widget _buildPendingReviewCard(BuildContext context, PendingReview pending) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _startReview(context, pending.schedule),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    pending.schedule.icon,
                    color: Colors.orange,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pending.schedule.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          pending.schedule.frequencyLabel,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '逾期${pending.overdueDays}天',
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _startReview(context, pending.schedule),
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('开始回顾'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTemplatesTab(BuildContext context) {
    final templates = [
      ReviewTemplates.dailyReview,
      ReviewTemplates.weeklyReview,
      ReviewTemplates.monthlyReview,
      ReviewTemplates.goalReview,
      ReviewTemplates.habitReview,
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: templates.length,
      itemBuilder: (context, index) {
        final template = templates[index];
        return _buildTemplateCard(context, template);
      },
    );
  }

  Widget _buildTemplateCard(BuildContext context, ReviewTemplate template) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Icon(_getTemplateIcon(template.type)),
        title: Text(template.name),
        subtitle: Text(_getFrequencyLabel(template.frequency)),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '回顾问题',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...template.questions.asMap().entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 10,
                          backgroundColor: Colors.blue.withOpacity(0.1),
                          child: Text(
                            '${entry.key + 1}',
                            style: const TextStyle(fontSize: 10),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(entry.value)),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () => _startQuickReview(context, template),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('开始回顾'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab(BuildContext context, List<ReviewResult> history) {
    if (history.isEmpty) {
      return _buildEmptyState(
        context,
        icon: Icons.history,
        title: '暂无回顾历史',
        subtitle: '完成回顾后会在此显示',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: history.length,
      itemBuilder: (context, index) {
        final result = history[index];
        return _buildHistoryCard(context, result);
      },
    );
  }

  Widget _buildHistoryCard(BuildContext context, ReviewResult result) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  result.scheduleType,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _formatDate(result.reviewedAt),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(result.summary),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildStatChip('完成', result.completedItems, Colors.green),
                const SizedBox(width: 8),
                _buildStatChip('待办', result.pendingItems, Colors.orange),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(color: color, fontSize: 12),
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  IconData _getTemplateIcon(String type) {
    switch (type) {
      case 'goal':
        return Icons.flag;
      case 'habit':
        return Icons.check_circle;
      case 'project':
        return Icons.work;
      case 'mood':
        return Icons.mood;
      default:
        return Icons.rate_review;
    }
  }

  String _getFrequencyLabel(String frequency) {
    switch (frequency) {
      case 'daily':
        return '每日';
      case 'weekly':
        return '每周';
      case 'monthly':
        return '每月';
      default:
        return frequency;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showAddScheduleDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加回顾计划'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const TextField(
              decoration: InputDecoration(
                labelText: '计划名称',
                hintText: '例如：每日目标检视',
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField(
              decoration: const InputDecoration(labelText: '频率'),
              items: const [
                DropdownMenuItem(value: 'daily', child: Text('每日')),
                DropdownMenuItem(value: 'weekly', child: Text('每周')),
                DropdownMenuItem(value: 'monthly', child: Text('每月')),
              ],
              onChanged: (value) {},
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
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('计划已添加')),
              );
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }

  void _startReview(BuildContext context, ReviewSchedule schedule) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReviewSessionScreen(schedule: schedule),
      ),
    );
  }

  void _startQuickReview(BuildContext context, ReviewTemplate template) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuickReviewTemplateScreen(template: template),
      ),
    );
  }
}

class ReviewSessionScreen extends StatelessWidget {
  final ReviewSchedule schedule;

  const ReviewSessionScreen({super.key, required this.schedule});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(schedule.name),
      ),
      body: const Center(
        child: Text('回顾会话'),
      ),
    );
  }
}

class QuickReviewTemplateScreen extends StatelessWidget {
  final ReviewTemplate template;

  const QuickReviewTemplateScreen({super.key, required this.template});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(template.name),
      ),
      body: const Center(
        child: Text('快速回顾'),
      ),
    );
  }
}