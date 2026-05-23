import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/daily_score/data/daily_score_repository.dart';
import 'package:thing_note/features/daily_score/domain/daily_score.dart';
import 'package:thing_note/l10n/generated/app_localizations.dart';

final dailyScoreProvider = dailyScoreRepositoryProvider;

class DailyScoreScreen extends ConsumerStatefulWidget {
  const DailyScoreScreen({super.key});

  @override
  ConsumerState<DailyScoreScreen> createState() => _DailyScoreScreenState();
}

class _DailyScoreScreenState extends ConsumerState<DailyScoreScreen> {
  DailyScore? _todayScore;
  List<DailyScore> _recentScores = [];
  Map<String, double> _weeklyAverage = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final repo = ref.read(dailyScoreProvider);
    final today = DateTime.now().toIso8601String().split('T')[0];
    _todayScore = await repo.getByDate(today);
    _recentScores = await repo.getRecent(7);
    _weeklyAverage = await repo.getWeeklyAverage();
    setState(() => _isLoading = false);
  }

  Future<void> _calculateTodayScore() async {
    final repo = ref.read(dailyScoreProvider);
    await repo.calculateAndSaveTodayScore();
    _loadData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('今日得分已更新！'),
            ],
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.dailyScore),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _calculateTodayScore,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTodayScoreCard(),
                    const SizedBox(height: 16),
                    _buildScoreBreakdown(),
                    const SizedBox(height: 16),
                    _buildWeeklyAverage(),
                    const SizedBox(height: 16),
                    _buildRecentScores(),
                    if (_todayScore?.achievements != null && _todayScore!.achievements!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildAchievements(),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTodayScoreCard() {
    final score = _todayScore?.overallScore ?? 0;
    final grade = _todayScore?.grade ?? '-';
    final emoji = _todayScore?.gradeEmoji ?? '📊';

    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text('今日得分', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 48)),
                const SizedBox(width: 16),
                Column(
                  children: [
                    Text(
                      '${score.round()}',
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getGradeColor(score),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        grade,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreBreakdown() {
    final productivity = _todayScore?.productivityScore ?? 0;
    final health = _todayScore?.healthScore ?? 0;
    final mood = _todayScore?.moodScore ?? 0;
    final social = _todayScore?.socialScore ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('得分明细', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            _ScoreBar(label: '💼 生产力', value: productivity, icon: Icons.work),
            _ScoreBar(label: '🏃 健康', value: health, icon: Icons.fitness_center),
            _ScoreBar(label: '😊 情绪', value: mood, icon: Icons.mood),
            _ScoreBar(label: '👥 社交', value: social, icon: Icons.people),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyAverage() {
    final productivity = _weeklyAverage['productivity'] ?? 0;
    final health = _weeklyAverage['health'] ?? 0;
    final mood = _weeklyAverage['mood'] ?? 0;
    final social = _weeklyAverage['social'] ?? 0;
    final overall = _weeklyAverage['overall'] ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 20),
                const SizedBox(width: 8),
                Text('本周平均', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _WeeklyStat(label: '生产力', value: productivity, color: Colors.blue),
                _WeeklyStat(label: '健康', value: health, color: Colors.green),
                _WeeklyStat(label: '情绪', value: mood, color: Colors.orange),
                _WeeklyStat(label: '社交', value: social, color: Colors.purple),
                _WeeklyStat(label: '综合', value: overall, color: Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentScores() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('最近7天', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            if (_recentScores.isEmpty)
              const Center(child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('暂无数据'),
              ))
            else
              SizedBox(
                height: 100,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: _recentScores.take(7).toList().reversed.map((score) {
                    final height = score.overallScore * 0.8;
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          width: 30,
                          height: height,
                          decoration: BoxDecoration(
                            color: _getGradeColor(score.overallScore),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          score.date.substring(5),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievements() {
    final achievements = _todayScore?.achievements ?? [];

    return Card(
      color: Colors.amber.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.emoji_events, color: Colors.amber),
                const SizedBox(width: 8),
                Text('今日成就', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: achievements.map((a) => Chip(
                avatar: const Icon(Icons.star, size: 16),
                label: Text(a),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Color _getGradeColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.blue;
    if (score >= 40) return Colors.orange;
    return Colors.red;
  }
}

class _ScoreBar extends StatelessWidget {
  final String label;
  final double value;
  final IconData icon;

  const _ScoreBar({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    final color = value >= 80 ? Colors.green : value >= 60 ? Colors.blue : value >= 40 ? Colors.orange : Colors.red;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
          SizedBox(
            width: 150,
            child: LinearProgressIndicator(
              value: value / 100,
              backgroundColor: Colors.grey.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 40,
            child: Text(
              '${value.round()}',
              textAlign: TextAlign.right,
              style: TextStyle(fontWeight: FontWeight.bold, color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyStat extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _WeeklyStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '${value.round()}',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}