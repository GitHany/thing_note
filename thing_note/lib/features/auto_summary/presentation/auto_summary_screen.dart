import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class AutoSummaryService {
  Future<Map<String, dynamic>> generateDailySummary(DateTime date) async {
    // This would normally fetch from database
    // For now, return mock data
    return {
      'title': '${DateFormat('yyyy年MM月dd日').format(date)}总结',
      'highlights': [
        '完成了重要的工作任务',
        '坚持了晨跑习惯',
        '学习了一门新课程',
      ],
      'recordCount': 5,
      'totalDuration': 180,
      'topCategories': ['工作', '健康', '学习'],
      'mood': 'good',
    };
  }

  Future<Map<String, dynamic>> generateWeeklySummary(DateTime weekStart) async {
    return {
      'title': '第${_getWeekNumber(weekStart)}周总结',
      'highlights': [
        '本周共记录 35 条',
        '坚持打卡 6 天',
        '完成月度目标 80%',
      ],
      'recordCount': 35,
      'totalDuration': 1260,
      'dailyAvg': 5,
      'topCategories': ['工作', '学习', '运动'],
      'habitsCompleted': 18,
    };
  }

  Future<Map<String, dynamic>> generateMonthlySummary(DateTime month) async {
    return {
      'title': '${DateFormat('yyyy年MM月').format(month)}总结',
      'highlights': [
        '本月共记录 150 条',
        '活跃天数 28 天',
        '情绪平均分 4.2/5',
      ],
      'recordCount': 150,
      'totalDuration': 5400,
      'dailyAvg': 5.4,
      'topCategories': ['工作', '健康', '社交'],
      'goalsCompleted': 3,
      'habitsCompleted': 25,
    };
  }

  int _getWeekNumber(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final days = date.difference(firstDayOfYear).inDays;
    return (days / 7).ceil();
  }
}

final autoSummaryServiceProvider = Provider<AutoSummaryService>((ref) {
  return AutoSummaryService();
});

class AutoSummaryScreen extends ConsumerStatefulWidget {
  const AutoSummaryScreen({super.key});

  @override
  ConsumerState<AutoSummaryScreen> createState() => _AutoSummaryScreenState();
}

class _AutoSummaryScreenState extends ConsumerState<AutoSummaryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _summaryType = 'daily';
  Map<String, dynamic>? _currentSummary;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _generateSummary();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _generateSummary() async {
    setState(() {
      _isLoading = true;
    });

    final service = ref.read(autoSummaryServiceProvider);
    final now = DateTime.now();

    Map<String, dynamic> summary;
    switch (_summaryType) {
      case 'daily':
        summary = await service.generateDailySummary(now);
        break;
      case 'weekly':
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        summary = await service.generateWeeklySummary(weekStart);
        break;
      case 'monthly':
        summary = await service.generateMonthlySummary(now);
        break;
      default:
        summary = {};
    }

    setState(() {
      _currentSummary = summary;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('自动摘要'),
        bottom: TabBar(
          controller: _tabController,
          onTap: (index) {
            setState(() {
              _summaryType = ['daily', 'weekly', 'monthly'][index];
            });
            _generateSummary();
          },
          tabs: const [
            Tab(text: '日报'),
            Tab(text: '周报'),
            Tab(text: '月报'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _currentSummary == null
              ? const Center(child: Text('暂无摘要'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 40),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _currentSummary!['title'] ?? '',
                                      style: Theme.of(context).textTheme.titleLarge,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _getSubtitle(),
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Stats
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              icon: Icons.list_alt,
                              label: '记录数',
                              value: '${_currentSummary!['recordCount'] ?? 0}',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _StatCard(
                              icon: Icons.timer,
                              label: '总时长',
                              value: _formatDuration(_currentSummary!['totalDuration'] ?? 0),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _StatCard(
                              icon: Icons.trending_up,
                              label: '日均',
                              value: '${_currentSummary!['dailyAvg'] ?? 0}',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Highlights
                      const Text(
                        '亮点',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      if (_currentSummary!['highlights'] != null)
                        ...((_currentSummary!['highlights'] as List).map((h) => Card(
                              child: ListTile(
                                leading: const Icon(Icons.star, color: Colors.amber),
                                title: Text(h.toString()),
                              ),
                            ))),
                      const SizedBox(height: 16),
                      // Categories
                      const Text(
                        '热门分类',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: ((_currentSummary!['topCategories'] ?? []) as List)
                            .map((c) => Chip(label: Text(c.toString())))
                            .toList(),
                      ),
                      const SizedBox(height: 24),
                      // Actions
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.share),
                              label: const Text('分享'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.email),
                              label: const Text('发送邮件'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
    );
  }

  String _getSubtitle() {
    final now = DateTime.now();
    switch (_summaryType) {
      case 'daily':
        return DateFormat('yyyy年MM月dd日 星期w').format(now);
      case 'weekly':
        return '本周概览';
      case 'monthly':
        return DateFormat('yyyy年MM月').format(now);
      default:
        return '';
    }
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) return '$minutes分钟';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return '$hours小时$mins分钟';
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: Colors.blue),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}