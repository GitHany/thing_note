import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/core/database/database_provider.dart';

class HealthDashboardScreen extends ConsumerStatefulWidget {
  const HealthDashboardScreen({super.key});
  @override
  ConsumerState<HealthDashboardScreen> createState() => _HealthDashboardScreenState();
}

class _HealthDashboardScreenState extends ConsumerState<HealthDashboardScreen> {
  Map<String, dynamic>? _healthData;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadHealthData();
  }

  Future<void> _loadHealthData() async {
    final db = await ref.read(databaseProvider.future);
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));

    int recordCount = 0;
    final records = await db.query('episode_records', where: 'occurred_at >= ?', whereArgs: [weekAgo.toIso8601String()]);
    recordCount = records.length;

    int totalDuration = 0;
    for (final r in records) {
      totalDuration += (r['duration_sec'] as int? ?? 0);
    }

    final sleepRecords = await db.query('sleep_records', where: 'record_date >= ?', whereArgs: [weekAgo.toIso8601String().substring(0, 10)]);
    double avgSleepHours = 0;
    if (sleepRecords.isNotEmpty) {
      avgSleepHours = sleepRecords.map((r) => (r['total_hours'] as num?)?.toDouble() ?? 0).reduce((a, b) => a + b) / sleepRecords.length;
    }

    final waterRecords = await db.query('water_intake_records', where: 'date >= ?', whereArgs: [weekAgo.toIso8601String().substring(0, 10)]);
    int totalWater = 0;
    for (final w in waterRecords) {
      totalWater += (w['total_ml'] as int? ?? 0);
    }

    final moodRecords = await db.query('mood_entries', where: 'recorded_at >= ?', whereArgs: [weekAgo.toIso8601String()]);
    double avgMood = 0;
    if (moodRecords.isNotEmpty) {
      avgMood = moodRecords.map((r) => (r['mood_level'] as num?)?.toDouble() ?? 0).reduce((a, b) => a + b) / moodRecords.length;
    }

    setState(() {
      _healthData = {
        'recordCount': recordCount,
        'totalDuration': totalDuration,
        'avgSleepHours': avgSleepHours,
        'totalWater': totalWater,
        'avgMood': avgMood,
        'activeDays': records.map((r) => r['occurred_at'].toString().substring(0, 10)).toSet().length,
      };
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('健康仪表盘'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _loadHealthData)],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadHealthData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildHeroCard(),
                  const SizedBox(height: 16),
                  const Text('健康指标', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildMetricCard('睡眠时长', '${(_healthData!['avgSleepHours'] as double).toStringAsFixed(1)}h', Icons.bedtime, Colors.indigo)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildMetricCard('饮水量', '${((_healthData!['totalWater'] as int) / 1000).toStringAsFixed(1)}L', Icons.water_drop, Colors.blue)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildMetricCard('平均心情', '${(_healthData!['avgMood'] as double).toStringAsFixed(1)}/5', Icons.mood, Colors.green)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildMetricCard('活跃天数', '${_healthData!['activeDays']}/7', Icons.calendar_today, Colors.orange)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text('一周概览', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildWeeklyOverview(),
                ],
              ),
            ),
    );
  }

  Widget _buildHeroCard() {
    final healthScore = _calculateHealthScore();
    return Card(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green.shade400, Colors.green.shade700],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            const Text('健康综合评分', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 8),
            Text(
              '${healthScore.toInt()}',
              style: const TextStyle(fontSize: 64, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const Text('分', style: TextStyle(color: Colors.white70, fontSize: 20)),
            const SizedBox(height: 8),
            Text(
              _getHealthLevel(healthScore),
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }

  int _calculateHealthScore() {
    int score = 50;
    if ((_healthData!['avgSleepHours'] as double) >= 7) {
      score += 15;
    } else if ((_healthData!['avgSleepHours'] as double) >= 6) {
      score += 10;
    } else if ((_healthData!['avgSleepHours'] as double) >= 5) {
      score += 5;
    }

    if ((_healthData!['totalWater'] as int) >= 14000) {
      score += 15;
    } else if ((_healthData!['totalWater'] as int) >= 10000) {
      score += 10;
    } else if ((_healthData!['totalWater'] as int) >= 7000) {
      score += 5;
    }

    if ((_healthData!['avgMood'] as double) >= 4) {
      score += 15;
    } else if ((_healthData!['avgMood'] as double) >= 3) {
      score += 10;
    } else if ((_healthData!['avgMood'] as double) >= 2) {
      score += 5;
    }

    if ((_healthData!['activeDays'] as int) >= 6) {
      score += 10;
    } else if ((_healthData!['activeDays'] as int) >= 4) {
      score += 7;
    } else if ((_healthData!['activeDays'] as int) >= 3) {
      score += 3;
    }

    return score.clamp(0, 100);
  }

  String _getHealthLevel(int score) {
    if (score >= 80) return '🌟 优秀';
    if (score >= 60) return '👍 良好';
    if (score >= 40) return '💪 一般';
    return '📚 需要改善';
  }

  Widget _buildMetricCard(String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text(label, style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyOverview() {
    final dayNames = ['一', '二', '三', '四', '五', '六', '日'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: dayNames.asMap().entries.map((e) {
        final active = (e.key + 1) <= (_healthData!['activeDays'] as int);
        return Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: active ? Colors.green : Colors.grey[300],
                shape: BoxShape.circle,
              ),
              child: Center(child: Text(e.value, style: TextStyle(color: active ? Colors.white : Colors.grey[500]))),
            ),
            const SizedBox(height: 4),
            Text(e.value, style: const TextStyle(fontSize: 10)),
          ],
        );
      }).toList(),
    );
  }
}