import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:thing_note/features/annual_review/data/annual_review_service.dart';
import 'package:thing_note/features/annual_review/domain/annual_review_models.dart';

class AnnualReviewScreen extends ConsumerStatefulWidget {
  const AnnualReviewScreen({super.key});

  @override
  ConsumerState<AnnualReviewScreen> createState() => _AnnualReviewScreenState();
}

class _AnnualReviewScreenState extends ConsumerState<AnnualReviewScreen> {
  late int _selectedYear;
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _selectedYear = DateTime.now().year;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('年度回顾'),
        actions: [
          PopupMenuButton<int>(
            onSelected: (year) {
              setState(() {
                _selectedYear = year;
                _currentPage = 0;
                _pageController.jumpToPage(0);
              });
            },
            itemBuilder: (context) {
              final currentYear = DateTime.now().year;
              return List.generate(5, (index) {
                final year = currentYear - index;
                return PopupMenuItem(
                  value: year,
                  child: Text('$year 年${year == _selectedYear ? ' ✓' : ''}'),
                );
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    '$_selectedYear 年',
                    style: const TextStyle(fontSize: 18),
                  ),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareReview,
            tooltip: '分享年度报告',
          ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentPage = index;
          });
        },
        children: [
          _OverviewPage(year: _selectedYear),
          _AchievementsPage(year: _selectedYear),
          _TrendsPage(year: _selectedYear),
          _GoalsPage(year: _selectedYear),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentPage,
        onTap: (index) {
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: '概览'),
          BottomNavigationBarItem(icon: Icon(Icons.emoji_events), label: '成就'),
          BottomNavigationBarItem(icon: Icon(Icons.trending_up), label: '趋势'),
          BottomNavigationBarItem(icon: Icon(Icons.flag), label: '目标'),
        ],
      ),
    );
  }

  void _shareReview() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('年度报告已生成，可以分享')),
    );
  }
}

/// 概览页面
class _OverviewPage extends ConsumerWidget {
  final int year;

  const _OverviewPage({required this.year});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(annualStatisticsProvider(year));

    return statsAsync.when(
      data: (stats) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 年度标题
            Center(
              child: Column(
                children: [
                  const Text(
                    '📊',
                    style: TextStyle(fontSize: 64),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$year 年度回顾',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // 核心数据卡片
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _StatRow(
                      icon: Icons.note,
                      label: '记录总数',
                      value: '${stats.totalRecords}',
                      color: Colors.blue,
                    ),
                    const Divider(),
                    _StatRow(
                      icon: Icons.timer,
                      label: '总时长',
                      value: stats.formattedDuration,
                      color: Colors.green,
                    ),
                    const Divider(),
                    _StatRow(
                      icon: Icons.calendar_today,
                      label: '活跃天数',
                      value: '${stats.activeDays} 天',
                      color: Colors.orange,
                    ),
                    const Divider(),
                    _StatRow(
                      icon: Icons.emoji_events,
                      label: '最长连续',
                      value: '${stats.streakDays} 天',
                      color: Colors.purple,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // 习惯和目标
            Row(
              children: [
                Expanded(
                  child: _MiniCard(
                    title: '习惯完成率',
                    value: '${stats.habitCompletionRate.toStringAsFixed(0)}%',
                    icon: Icons.check_circle,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MiniCard(
                    title: '目标完成',
                    value: '${stats.goalsCompleted}/${stats.goalsTotal}',
                    icon: Icons.flag,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _MiniCard(
                    title: '平均情绪',
                    value: stats.avgMoodScore.toStringAsFixed(1),
                    icon: Icons.mood,
                    color: Colors.pink,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MiniCard(
                    title: '活动类型',
                    value: '${stats.topActivities.length}',
                    icon: Icons.category,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Top 活动
            if (stats.topActivities.isNotEmpty) ...[
              const Text(
                '🏆 Top 活动',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Card(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: stats.topActivities.take(5).length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final activity = stats.topActivities[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.amber.withOpacity(0.2),
                        child: Text('${index + 1}'),
                      ),
                      title: Text(activity.name),
                      subtitle: Text('${activity.count} 条记录'),
                      trailing: Text(
                        _formatMinutes(activity.minutes),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('加载失败: $e')),
    );
  }

  String _formatMinutes(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours > 0) {
      return '${hours}h ${mins}m';
    }
    return '${mins}m';
  }
}

/// 成就页面
class _AchievementsPage extends ConsumerWidget {
  final int year;

  const _AchievementsPage({required this.year});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(annualStatisticsProvider(year));

    return statsAsync.when(
      data: (stats) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🎖️ 年度成就',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // 里程碑卡片
            _AchievementCard(
              icon: '📝',
              title: '记录达人',
              description: '全年共记录 ${stats.totalRecords} 条事件',
              isUnlocked: stats.totalRecords >= 100,
            ),
            _AchievementCard(
              icon: '⏱️',
              title: '时间管理者',
              description: '累计记录 ${stats.formattedDuration}',
              isUnlocked: stats.totalMinutes >= 10000,
            ),
            _AchievementCard(
              icon: '🔥',
              title: '坚持不懈',
              description: '最长连续记录 ${stats.streakDays} 天',
              isUnlocked: stats.streakDays >= 30,
            ),
            _AchievementCard(
              icon: '😊',
              title: '情绪稳定',
              description: '平均情绪评分 ${stats.avgMoodScore.toStringAsFixed(1)}/5',
              isUnlocked: stats.avgMoodScore >= 4.0,
            ),
            _AchievementCard(
              icon: '✅',
              title: '目标达成',
              description: '完成 ${stats.goalsCompleted} 个目标',
              isUnlocked: stats.goalsCompleted >= 5,
            ),
            _AchievementCard(
              icon: '🌟',
              title: '活跃玩家',
              description: '全年活跃 ${stats.activeDays} 天',
              isUnlocked: stats.activeDays >= 300,
            ),
          ],
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('加载失败: $e')),
    );
  }
}

/// 趋势页面
class _TrendsPage extends ConsumerWidget {
  final int year;

  const _TrendsPage({required this.year});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(annualStatisticsProvider(year));

    return statsAsync.when(
      data: (stats) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📈 趋势分析',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // 月度记录趋势
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '月度记录数量',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 200,
                      child: BarChart(
                        BarChartData(
                          barGroups: List.generate(12, (index) {
                            final monthData = stats.monthlyData.firstWhere(
                              (m) => m.month == index + 1,
                              orElse: () => MonthlyData(
                                month: index + 1,
                                recordCount: 0,
                                minutes: 0,
                              ),
                            );
                            return BarChartGroupData(
                              x: index,
                              barRods: [
                                BarChartRodData(
                                  toY: monthData.recordCount.toDouble(),
                                  color: Colors.blue,
                                  width: 16,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ],
                            );
                          }),
                          titlesData: FlTitlesData(
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  return Text(
                                    '${(value.toInt() + 1)}月',
                                    style: const TextStyle(fontSize: 10),
                                  );
                                },
                              ),
                            ),
                          ),
                          gridData: const FlGridData(show: true),
                          borderData: FlBorderData(show: false),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // 统计摘要
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '📊 统计摘要',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _MiniStat(
                            label: '月均记录',
                            value: (stats.totalRecords / 12).toStringAsFixed(0),
                          ),
                        ),
                        Expanded(
                          child: _MiniStat(
                            label: '日均时长',
                            value: '${(stats.totalMinutes / (stats.activeDays > 0 ? stats.activeDays : 1)).toStringAsFixed(0)}m',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _MiniStat(
                            label: '最多活动',
                            value: stats.topActivities.isNotEmpty ? stats.topActivities.first.name : '-',
                          ),
                        ),
                        Expanded(
                          child: _MiniStat(
                            label: '活动多样性',
                            value: '${stats.topActivities.length} 种',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('加载失败: $e')),
    );
  }
}

/// 目标页面
class _GoalsPage extends ConsumerWidget {
  final int year;

  const _GoalsPage({required this.year});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(yearlyGoalsProvider(year));

    return goalsAsync.when(
      data: (goals) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '🎯 年度目标',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showAddGoalDialog(context, ref),
                  icon: const Icon(Icons.add),
                  label: const Text('添加目标'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (goals.isEmpty)
              const Center(
                child: Column(
                  children: [
                    SizedBox(height: 48),
                    Icon(Icons.flag_outlined, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('还没有年度目标'),
                    SizedBox(height: 8),
                    Text(
                      '设定目标，让新的一年更有方向',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              )
            else
              ...goals.map((goal) => _GoalCard(goal: goal)),
          ],
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('加载失败: $e')),
    );
  }

  void _showAddGoalDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加年度目标'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: '目标内容',
            hintText: '例如：读完10本书',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                final service = ref.read(annualReviewServiceProvider);
                service.addYearlyGoal(YearlyGoal(
                  year: year,
                  title: controller.text,
                ));
                ref.invalidate(yearlyGoalsProvider(year));
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

/// 统计行
class _StatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 16))),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// 迷你卡片
class _MiniCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _MiniCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

/// 成就卡片
class _AchievementCard extends StatelessWidget {
  final String icon;
  final String title;
  final String description;
  final bool isUnlocked;

  const _AchievementCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.isUnlocked,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isUnlocked ? Colors.amber.withOpacity(0.1) : null,
      child: ListTile(
        leading: Text(icon, style: TextStyle(fontSize: 32, color: isUnlocked ? null : Colors.grey)),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isUnlocked ? null : Colors.grey,
          ),
        ),
        subtitle: Text(
          description,
          style: TextStyle(color: isUnlocked ? Colors.grey[600] : Colors.grey),
        ),
        trailing: isUnlocked
            ? const Icon(Icons.check_circle, color: Colors.green)
            : const Icon(Icons.lock_outline, color: Colors.grey),
      ),
    );
  }
}

/// 迷你统计
class _MiniStat extends StatelessWidget {
  final String label;
  final String value;

  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        Text(
          value.length > 10 ? '${value.substring(0, 10)}...' : value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

/// 目标卡片
class _GoalCard extends StatelessWidget {
  final YearlyGoal goal;

  const _GoalCard({required this.goal});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          goal.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
          color: goal.isCompleted ? Colors.green : Colors.grey,
        ),
        title: Text(
          goal.title,
          style: TextStyle(
            decoration: goal.isCompleted ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: goal.targetValue != null
            ? LinearProgressIndicator(
                value: goal.progress,
                backgroundColor: Colors.grey[200],
              )
            : null,
        trailing: goal.isCompleted ? null : IconButton(
          icon: const Icon(Icons.check),
          onPressed: () {
            // 标记完成
          },
        ),
      ),
    );
  }
}