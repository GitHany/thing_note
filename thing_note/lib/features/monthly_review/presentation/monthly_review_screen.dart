import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/monthly_review/data/monthly_review_repository.dart';
import 'package:thing_note/features/monthly_review/domain/monthly_review_models.dart';

class MonthlyReviewScreen extends ConsumerStatefulWidget {
  const MonthlyReviewScreen({super.key});

  @override
  ConsumerState<MonthlyReviewScreen> createState() => _MonthlyReviewScreenState();
}

class _MonthlyReviewScreenState extends ConsumerState<MonthlyReviewScreen> {
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;

  @override
  Widget build(BuildContext context) {
    final reviewsAsync = ref.watch(monthlyReviewsProvider);
    final statsAsync = ref.watch(_monthlyStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('月度回顾'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () => _selectMonth(context),
          ),
        ],
      ),
      body: reviewsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('错误: $e')),
        data: (reviews) {
          final currentReview = reviews.where(
            (r) => r.year == _selectedYear && r.month == _selectedMonth
          ).firstOrNull;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMonthHeader(),
                const SizedBox(height: 16),
                _buildStatsCard(statsAsync),
                const SizedBox(height: 16),
                if (currentReview != null)
                  _buildReviewCard(currentReview)
                else
                  _buildCreateReviewPrompt(),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showReviewEditor(context, null),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildMonthHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple, Colors.blue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_view_month, color: Colors.white, size: 32),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$_selectedYear年$_selectedMonth月回顾',
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(
                _getMonthSummary(),
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getMonthSummary() {
    final now = DateTime.now();
    if (_selectedYear == now.year && _selectedMonth == now.month) {
      return '本月';
    } else if (_selectedYear < now.year || 
        (_selectedYear == now.year && _selectedMonth < now.month)) {
      return '已完成';
    }
    return '规划中';
  }

  Widget _buildStatsCard(AsyncValue<Map<String, dynamic>> statsAsync) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('本月数据', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            statsAsync.when(
              data: (stats) => Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatItem(
                    label: '记录数',
                    value: '${stats['record_count'] ?? 0}',
                    icon: Icons.note,
                  ),
                  _StatItem(
                    label: '习惯打卡',
                    value: '${stats['habit_count'] ?? 0}',
                    icon: Icons.check_circle,
                  ),
                ],
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('错误: $e'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewCard(MonthlyReview review) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('月度回顾', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _showReviewEditor(context, review),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteReview(review.id!),
                    ),
                  ],
                ),
              ],
            ),
            if (review.overallScore != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('综合评分: '),
                  ...List.generate(5, (i) => Icon(
                    i < (review.overallScore! / 2).round() ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 20,
                  )),
                  Text(' ${review.overallScore!.toStringAsFixed(1)}'),
                ],
              ),
            ],
            const SizedBox(height: 16),
            if (review.highlights != null && review.highlights!.isNotEmpty)
              _SectionContent(title: '✨ 本月亮点', content: review.highlights!),
            if (review.achievements != null && review.achievements!.isNotEmpty)
              _SectionContent(title: '🏆 成就', content: review.achievements!),
            if (review.improvements != null && review.improvements!.isNotEmpty)
              _SectionContent(title: '📈 待改进', content: review.improvements!),
            if (review.reflection != null && review.reflection!.isNotEmpty)
              _SectionContent(title: '💭 反思', content: review.reflection!),
            if (review.nextMonthGoals != null && review.nextMonthGoals!.isNotEmpty)
              _SectionContent(title: '🎯 下月目标', content: review.nextMonthGoals!),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateReviewPrompt() {
    return Card(
      child: InkWell(
        onTap: () => _showReviewEditor(context, null),
        borderRadius: BorderRadius.circular(12),
        child: const Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(Icons.rate_review, size: 48, color: Colors.grey),
              SizedBox(height: 16),
              Text('创建本月回顾', style: TextStyle(fontSize: 16)),
              SizedBox(height: 8),
              Text('记录你的成长和收获', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  void _selectMonth(BuildContext context) async {
    final result = await showDatePicker(
      context: context,
      initialDate: DateTime(_selectedYear, _selectedMonth),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );
    if (result != null) {
      setState(() {
        _selectedYear = result.year;
        _selectedMonth = result.month;
      });
    }
  }

  void _showReviewEditor(BuildContext context, MonthlyReview? existing) {
    final highlightsController = TextEditingController(text: existing?.highlights);
    final achievementsController = TextEditingController(text: existing?.achievements);
    final improvementsController = TextEditingController(text: existing?.improvements);
    final reflectionController = TextEditingController(text: existing?.reflection);
    final goalsController = TextEditingController(text: existing?.nextMonthGoals);
    double score = existing?.overallScore ?? 3.0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      existing != null ? '编辑回顾' : '创建回顾',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('综合评分'),
                Row(
                  children: [
                    Expanded(
                      child: Slider(
                        value: score,
                        min: 1,
                        max: 5,
                        divisions: 8,
                        label: score.toStringAsFixed(1),
                        onChanged: (v) => setState(() => score = v),
                      ),
                    ),
                    Text(score.toStringAsFixed(1)),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: highlightsController,
                  decoration: const InputDecoration(
                    labelText: '本月亮点',
                    hintText: '记录本月最值得骄傲的事情...',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: achievementsController,
                  decoration: const InputDecoration(
                    labelText: '成就',
                    hintText: '本月完成了哪些目标...',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: improvementsController,
                  decoration: const InputDecoration(
                    labelText: '待改进',
                    hintText: '需要提升的方面...',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: reflectionController,
                  decoration: const InputDecoration(
                    labelText: '反思',
                    hintText: '对过去一个月的思考...',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: goalsController,
                  decoration: const InputDecoration(
                    labelText: '下月目标',
                    hintText: '下个月想要达成的目标...',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      final review = MonthlyReview(
                        id: existing?.id,
                        year: _selectedYear,
                        month: _selectedMonth,
                        highlights: highlightsController.text,
                        achievements: achievementsController.text,
                        improvements: improvementsController.text,
                        reflection: reflectionController.text,
                        nextMonthGoals: goalsController.text,
                        overallScore: score,
                        createdAt: DateTime.now(),
                      );
                      if (existing != null) {
                        ref.read(monthlyReviewsProvider.notifier).updateReview(review);
                      } else {
                        ref.read(monthlyReviewsProvider.notifier).addReview(review);
                      }
                      Navigator.pop(context);
                    },
                    child: const Text('保存'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _deleteReview(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除回顾'),
        content: const Text('确定要删除这个月度回顾吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              ref.read(monthlyReviewsProvider.notifier).deleteReview(id);
              Navigator.pop(context);
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  final _monthlyStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
    final now = DateTime.now();
    final repository = ref.watch(monthlyReviewRepositoryProvider);
    return repository.getMonthlyStats(now.year, now.month);
  });
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatItem({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 28, color: Colors.grey[600]),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      ],
    );
  }
}

class _SectionContent extends StatelessWidget {
  final String title;
  final String content;

  const _SectionContent({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(content, style: TextStyle(color: Colors.grey[700])),
        ],
      ),
    );
  }
}