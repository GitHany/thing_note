import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/weekly_wins/data/weekly_wins_provider.dart';
import 'package:thing_note/features/weekly_wins/domain/weekly_wins.dart';

class WeeklyWinsScreen extends ConsumerStatefulWidget {
  const WeeklyWinsScreen({super.key});

  @override
  ConsumerState<WeeklyWinsScreen> createState() => _WeeklyWinsScreenState();
}

class _WeeklyWinsScreenState extends ConsumerState<WeeklyWinsScreen> {
  @override
  Widget build(BuildContext context) {
    final winsAsync = ref.watch(weeklyWinsProvider);
    final summaryAsync = ref.watch(weeklySummaryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('每周成就'),
        actions: [
          IconButton(
            icon: const Icon(Icons.emoji_events),
            onPressed: () => _showAchievements(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Summary Card
          summaryAsync.when(
            data: (summary) => _buildSummaryCard(summary),
            loading: () => const SizedBox(height: 120),
            error: (_, __) => const SizedBox(height: 120),
          ),
          const SizedBox(height: 16),

          // Wins List
          Expanded(
            child: winsAsync.when(
              data: (wins) => _buildWinsList(wins),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddWinDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('记录成就'),
        backgroundColor: Colors.amber,
      ),
    );
  }

  Widget _buildSummaryCard(WeeklySummary summary) {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.amber, Colors.orange],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '第${summary.weekNumber}周',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${weekStart.month}/${weekStart.day} - ${weekEnd.month}/${weekEnd.day}',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem(Icons.emoji_events, '${summary.totalWins}', '成就'),
              _buildSummaryItem(Icons.category, '${summary.categories.length}', '分类'),
              _buildSummaryItem(Icons.star, '90%', '达成率'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
      ],
    );
  }

  Widget _buildWinsList(List<WeeklyWin> wins) {
    if (wins.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emoji_events_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text('本周还没有记录成就'),
            const SizedBox(height: 8),
            const Text('点击右下角记录你的第一个成就！', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: wins.length,
      itemBuilder: (context, index) {
        final win = wins[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () => _showWinDetail(context, win),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getCategoryIcon(win.category),
                      color: Colors.amber,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          win.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        if (win.description != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            win.description!,
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Colors.grey.shade400),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  IconData _getCategoryIcon(String? category) {
    switch (category) {
      case 'work':
        return Icons.work;
      case 'health':
        return Icons.fitness_center;
      case 'learning':
        return Icons.school;
      case 'social':
        return Icons.people;
      case 'personal':
        return Icons.person;
      default:
        return Icons.emoji_events;
    }
  }

  void _showAddWinDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    String selectedCategory = 'personal';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('记录成就'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: '成就名称',
                    hintText: '例如：完成了重要项目',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: '描述（可选）',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                const Text('分类'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    _buildCategoryChip('personal', '个人', setState, selectedCategory, (v) { selectedCategory = v; }),
                    _buildCategoryChip('work', '工作', setState, selectedCategory, (v) { selectedCategory = v; }),
                    _buildCategoryChip('health', '健康', setState, selectedCategory, (v) { selectedCategory = v; }),
                    _buildCategoryChip('learning', '学习', setState, selectedCategory, (v) { selectedCategory = v; }),
                    _buildCategoryChip('social', '社交', setState, selectedCategory, (v) { selectedCategory = v; }),
                  ],
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
                if (titleController.text.isNotEmpty) {
                  final now = DateTime.now();
                  final win = WeeklyWin(
                    weekNumber: _getWeekNumber(now),
                    year: now.year,
                    title: titleController.text,
                    description: descController.text.isEmpty ? null : descController.text,
                    category: selectedCategory,
                    createdAt: now,
                  );
                  ref.read(addWinProvider).addWin(win);
                  Navigator.pop(context);
                }
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String value, String label, StateSetter setState, String selected, void Function(String) onSelected) {
    return ChoiceChip(
      label: Text(label),
      selected: selected == value,
      onSelected: (isSelected) {
        onSelected(value);
        setState(() {});
      },
    );
  }

  void _showWinDetail(BuildContext context, WeeklyWin win) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(win.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (win.description != null) ...[
              const Text('描述:'),
              Text(win.description!),
              const SizedBox(height: 16),
            ],
            if (win.category != null) ...[
              const Text('分类:'),
              Chip(label: Text(win.category!)),
            ],
          ],
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

  void _showAchievements(BuildContext context) {
    // TODO: Navigate to achievements screen
  }

  int _getWeekNumber(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final days = date.difference(firstDayOfYear).inDays;
    return ((days + firstDayOfYear.weekday - 1) / 7).ceil();
  }
}