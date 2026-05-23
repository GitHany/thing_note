import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/core/database/database_provider.dart';

class QuickRecallScreen extends ConsumerStatefulWidget {
  const QuickRecallScreen({super.key});
  @override
  ConsumerState<QuickRecallScreen> createState() => _QuickRecallScreenState();
}

class _QuickRecallScreenState extends ConsumerState<QuickRecallScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _recentRecords = [];
  List<Map<String, dynamic>> _starredRecords = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    final db = await ref.read(databaseProvider.future);
    final weekAgo = DateTime.now().subtract(const Duration(days: 7)).toIso8601String();

    _recentRecords = await db.query(
      'episode_records',
      where: 'occurred_at >= ?',
      whereArgs: [weekAgo],
      orderBy: 'occurred_at DESC',
      limit: 50,
    );

    final starred = await db.query(
      'quick_recall_entries',
      where: 'is_starred = 1',
      orderBy: 'created_at DESC',
    );
    final starredIds = starred.map((s) => s['record_id']).toList();
    if (starredIds.isNotEmpty) {
      _starredRecords = await db.query(
        'episode_records',
        where: 'id IN (${starredIds.join(",")})',
      );
    }

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('快速回顾'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '最近7天'),
            Tab(text: '收藏'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildRecentList(),
                _buildStarredList(),
              ],
            ),
    );
  }

  Widget _buildRecentList() {
    if (_recentRecords.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('最近7天没有记录', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final r in _recentRecords) {
      final date = r['occurred_at'].toString().substring(0, 10);
      grouped[date] = (grouped[date] ?? [])..add(r);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: grouped.entries.map((e) {
        final date = DateTime.parse(e.key);
        final label = _isToday(date) ? '今天' : _isYesterday(date) ? '昨天' : '${date.month}/${date.day}';
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            ...e.value.map((r) => _buildRecordItem(r)),
            const SizedBox(height: 8),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildStarredList() {
    if (_starredRecords.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.star_border, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('暂无收藏记录', style: TextStyle(color: Colors.grey)),
            SizedBox(height: 8),
            Text('长按记录可以收藏', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _starredRecords.length,
      itemBuilder: (ctx, i) => _buildRecordItem(_starredRecords[i], starred: true),
    );
  }

  Widget _buildRecordItem(Map<String, dynamic> record, {bool starred = false}) {
    final time = DateTime.parse(record['occurred_at'] as String);
    final duration = record['duration_sec'] as int? ?? 0;
    final note = record['note'] as String? ?? '';
    final photos = record['photo_paths'] as String? ?? '[]';
    final hasPhotos = photos != '[]' && photos.isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onLongPress: () => _toggleStar(record['id'] as int),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 50,
                decoration: BoxDecoration(
                  color: _getColorForHour(time.hour),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${time.hour}:${time.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    if (note.isNotEmpty)
                      Text(note, maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(_formatDuration(duration), style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (hasPhotos) const Icon(Icons.photo, size: 16, color: Colors.grey),
                      if (starred) const Icon(Icons.star, size: 16, color: Colors.amber),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _toggleStar(int recordId) async {
    final db = await ref.read(databaseProvider.future);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final existing = await db.query(
      'quick_recall_entries',
      where: 'record_id = ?',
      whereArgs: [recordId],
    );

    if (existing.isNotEmpty) {
      await db.delete('quick_recall_entries', where: 'record_id = ?', whereArgs: [recordId]);
    } else {
      await db.insert('quick_recall_entries', {
        'record_id': recordId,
        'importance_score': 0,
        'is_starred': 1,
        'created_at': DateTime.now().toIso8601String(),
      });
    }

    if (!mounted) return;
    scaffoldMessenger.showSnackBar(
      const SnackBar(content: Text('已更新收藏状态')),
    );

    _loadData();
  }

  bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  bool _isYesterday(DateTime d) {
    final y = DateTime.now().subtract(const Duration(days: 1));
    return d.year == y.year && d.month == y.month && d.day == y.day;
  }

  Color _getColorForHour(int hour) {
    if (hour < 6) return Colors.indigo;
    if (hour < 12) return Colors.orange;
    if (hour < 18) return Colors.blue;
    return Colors.purple;
  }

  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    if (h > 0) return '${h}h${m}m';
    return '${m}m';
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}