import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/core/database/database_provider.dart';

class DeepStatsPanel extends ConsumerStatefulWidget {
  const DeepStatsPanel({super.key});
  @override
  ConsumerState<DeepStatsPanel> createState() => _DeepStatsPanelState();
}

class _DeepStatsPanelState extends ConsumerState<DeepStatsPanel> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedPeriod = 'week';
  Map<String, dynamic>? _statsData;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadStats();
  }

  Future<void> _loadStats() async {
    final db = await ref.read(databaseProvider.future);
    final now = DateTime.now();
    DateTime start;
    
    switch (_selectedPeriod) {
      case 'month':
        start = DateTime(now.year, now.month - 1, now.day);
        break;
      case 'year':
        start = DateTime(now.year - 1, now.month, now.day);
        break;
      default:
        start = now.subtract(Duration(days: now.weekday - 1));
    }

    final records = await db.query(
      'episode_records',
      where: 'occurred_at >= ?',
      whereArgs: [start.toIso8601String()],
    );

    int totalDuration = 0;
    final thingCounts = <String, int>{};
    final hourlyDist = <int, int>{};
    final dailyDist = <int, int>{};

    for (final r in records) {
      totalDuration += (r['duration_sec'] as int? ?? 0);
      final dt = DateTime.parse(r['occurred_at'] as String);
      hourlyDist[dt.hour] = (hourlyDist[dt.hour] ?? 0) + 1;
      dailyDist[dt.weekday] = (dailyDist[dt.weekday] ?? 0) + 1;
      
      final tid = r['thing_name_id'];
      if (tid != null) {
        final things = await db.query('thing_names', where: 'id = ?', whereArgs: [tid]);
        if (things.isNotEmpty) {
          final name = things.first['name'] as String;
          thingCounts[name] = (thingCounts[name] ?? 0) + 1;
        }
      }
    }

    final sortedThings = thingCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    setState(() {
      _statsData = {
        'recordCount': records.length,
        'totalDuration': totalDuration,
        'avgDuration': records.isNotEmpty ? totalDuration ~/ records.length : 0,
        'topThings': sortedThings.take(5).toList(),
        'hourlyDist': hourlyDist,
        'dailyDist': dailyDist,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('深度统计'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '概览'),
            Tab(text: '时间'),
            Tab(text: '分类'),
            Tab(text: '趋势'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'week', label: Text('本周')),
                ButtonSegment(value: 'month', label: Text('本月')),
                ButtonSegment(value: 'year', label: Text('本年')),
              ],
              selected: {_selectedPeriod},
              onSelectionChanged: (v) {
                setState(() => _selectedPeriod = v.first);
                _loadStats();
              },
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildTimeTab(),
                _buildCategoryTab(),
                _buildTrendTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    if (_statsData == null) return const Center(child: CircularProgressIndicator());
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildStatCard('记录总数', '${_statsData!['recordCount']}', Icons.article, Colors.blue),
        const SizedBox(height: 12),
        _buildStatCard(
          '总时长',
          _formatDuration(_statsData!['totalDuration']),
          Icons.timer,
          Colors.green,
        ),
        const SizedBox(height: 12),
        _buildStatCard(
          '平均时长',
          _formatDuration(_statsData!['avgDuration']),
          Icons.speed,
          Colors.orange,
        ),
        const SizedBox(height: 24),
        const Text('TOP 5 活动', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...(_statsData!['topThings'] as List).asMap().entries.map((e) {
          return ListTile(
            leading: CircleAvatar(child: Text('${e.key + 1}')),
            title: Text(e.value.key),
            trailing: Text('${e.value.value}次', style: const TextStyle(fontWeight: FontWeight.bold)),
          );
        }),
      ],
    );
  }

  Widget _buildTimeTab() {
    if (_statsData == null) return const Center(child: CircularProgressIndicator());
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('每小时分布', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        SizedBox(
          height: 150,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(24, (hour) {
              final count = _statsData!['hourlyDist'][hour] ?? 0;
              final max = _statsData!['hourlyDist'].values.fold(0, (a, b) => a > b ? a : b);
              final height = max > 0 ? (count / max * 120) : 0.0;
              
              return Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      height: height.toDouble(),
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('$hour', style: const TextStyle(fontSize: 8)),
                  ],
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 24),
        const Text('每周分布', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: ['一', '二', '三', '四', '五', '六', '日'].asMap().entries.map((e) {
            final count = _statsData!['dailyDist'][e.key + 1] ?? 0;
            return Column(
              children: [
                Text('$count', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Container(
                  width: 30,
                  height: count.toDouble() * 2 + 10,
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Text(e.value),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCategoryTab() {
    if (_statsData == null) return const Center(child: CircularProgressIndicator());
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('分类统计', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        ...(_statsData!['topThings'] as List).map((e) {
          final total = _statsData!['recordCount'];
          final percent = total > 0 ? (e.value / total * 100) : 0.0;
          
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(e.key, style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text('${e.value}次 (${percent.toStringAsFixed(1)}%)'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(value: percent / 100, backgroundColor: Colors.grey[200]),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildTrendTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.trending_up, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('趋势分析', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('记录足够数据后自动生成趋势图表', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: Colors.grey[600])),
                Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    if (h > 0) return '${h}小时${m}分钟';
    return '${m}分钟';
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}