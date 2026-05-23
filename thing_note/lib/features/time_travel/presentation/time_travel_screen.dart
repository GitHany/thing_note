import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';
import 'dart:convert';

class TimeTravelSnapshot {
  final int? id;
  final String snapshotDate;
  final String snapshotType;
  final int recordCount;
  final int? moodScore;
  final int? energyScore;
  final String? topActivities;
  final String? highlights;
  final String snapshotData;
  final String createdAt;

  TimeTravelSnapshot({
    this.id,
    required this.snapshotDate,
    required this.snapshotType,
    this.recordCount = 0,
    this.moodScore,
    this.energyScore,
    this.topActivities,
    this.highlights,
    required this.snapshotData,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id, 'snapshot_date': snapshotDate, 'snapshot_type': snapshotType,
    'record_count': recordCount, 'mood_score': moodScore, 'energy_score': energyScore,
    'top_activities': topActivities, 'highlights': highlights, 'snapshot_data': snapshotData,
    'created_at': createdAt,
  };

  factory TimeTravelSnapshot.fromMap(Map<String, dynamic> m) => TimeTravelSnapshot(
    id: m['id'] as int?, snapshotDate: m['snapshot_date'] as String,
    snapshotType: m['snapshot_type'] as String, recordCount: m['record_count'] as int? ?? 0,
    moodScore: m['mood_score'] as int?, energyScore: m['energy_score'] as int?,
    topActivities: m['top_activities'] as String?, highlights: m['highlights'] as String?,
    snapshotData: m['snapshot_data'] as String, createdAt: m['created_at'] as String,
  );
}

final timeTravelProvider = StateNotifierProvider<TimeTravelNotifier, List<TimeTravelSnapshot>>((ref) {
  return TimeTravelNotifier(ref);
});

class TimeTravelNotifier extends StateNotifier<List<TimeTravelSnapshot>> {
  final Ref ref;
  TimeTravelNotifier(this.ref) : super([]) { loadSnapshots(); }

  Future<Database> get _db => ref.read(databaseProvider.future);

  Future<void> loadSnapshots() async {
    final db = await _db;
    final maps = await db.query('time_travel_snapshots', orderBy: 'snapshot_date DESC');
    state = maps.map((m) => TimeTravelSnapshot.fromMap(m)).toList();
  }

  Future<void> createSnapshot(String date) async {
    final db = await _db;
    final targetDate = DateTime.parse(date);
    final dayStart = DateTime(targetDate.year, targetDate.month, targetDate.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    final records = await db.query(
      'episode_records',
      where: 'occurred_at >= ? AND occurred_at < ?',
      whereArgs: [dayStart.toIso8601String(), dayEnd.toIso8601String()],
    );

    if (records.isEmpty) return;

    int totalDuration = 0;
    final thingCounts = <int, int>{};
    for (final r in records) {
      totalDuration += (r['duration_sec'] as int? ?? 0);
      final tid = r['thing_name_id'];
      if (tid != null) thingCounts[tid as int] = (thingCounts[tid as int] ?? 0) + 1;
    }

    final sortedThings = thingCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final topActivity = sortedThings.isNotEmpty ? sortedThings.first.key : 0;

    String topName = '';
    if (topActivity > 0) {
      final things = await db.query('thing_names', where: 'id = ?', whereArgs: [topActivity]);
      if (things.isNotEmpty) topName = things.first['name'] as String;
    }

    final snapshot = TimeTravelSnapshot(
      snapshotDate: date,
      snapshotType: 'daily',
      recordCount: records.length,
      topActivities: topName,
      snapshotData: jsonEncode({'records': records.length, 'duration': totalDuration}),
      createdAt: DateTime.now().toIso8601String(),
    );

    await db.insert('time_travel_snapshots', snapshot.toMap()..remove('id'));
    await loadSnapshots();
  }
}

class TimeTravelScreen extends ConsumerStatefulWidget {
  const TimeTravelScreen({super.key});
  @override
  ConsumerState<TimeTravelScreen> createState() => _TimeTravelScreenState();
}

class _TimeTravelScreenState extends ConsumerState<TimeTravelScreen> {
  DateTime _selectedDate = DateTime.now();
  Map<String, dynamic>? _dayData;

  @override
  void initState() {
    super.initState();
    _loadDayData();
  }

  Future<void> _loadDayData() async {
    final db = await ref.read(databaseProvider.future);
    final dayStart = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    final records = await db.query(
      'episode_records',
      where: 'occurred_at >= ? AND occurred_at < ?',
      whereArgs: [dayStart.toIso8601String(), dayEnd.toIso8601String()],
    );

    int totalDuration = 0;
    for (final r in records) {
      totalDuration += (r['duration_sec'] as int? ?? 0);
    }

    setState(() {
      _dayData = {
        'recordCount': records.length,
        'totalDuration': totalDuration,
        'records': records,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('时间旅行')),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    setState(() {
                      _selectedDate = _selectedDate.subtract(const Duration(days: 1));
                      _loadDayData();
                    });
                  },
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() {
                          _selectedDate = picked;
                          _loadDayData();
                        });
                      }
                    },
                    child: Text(
                      '${_selectedDate.year}年${_selectedDate.month}月${_selectedDate.day}日',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    if (_selectedDate.isBefore(DateTime.now().subtract(const Duration(days: 1)))) {
                      setState(() {
                        _selectedDate = _selectedDate.add(const Duration(days: 1));
                        _loadDayData();
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          if (_dayData != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _buildDayStat('记录', '${_dayData!['recordCount']}', Icons.article),
                  const SizedBox(width: 16),
                  _buildDayStat('时长', _formatDuration(_dayData!['totalDuration']), Icons.timer),
                ],
              ),
            ),
          if (_dayData != null && (_dayData!['records'] as List).isNotEmpty)
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: (_dayData!['records'] as List).length,
                itemBuilder: (ctx, i) {
                  final r = (_dayData!['records'] as List)[i];
                  final time = DateTime.parse(r['occurred_at'] as String);
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(child: Text('${time.hour}:${time.minute.toString().padLeft(2, '0')}')),
                      title: Text(r['note'] as String? ?? '无标题'),
                      subtitle: Text(_formatDuration(r['duration_sec'] as int? ?? 0)),
                    ),
                  );
                },
              ),
            )
          else
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.history, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('这一天没有记录', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await ref.read(timeTravelProvider.notifier).createSnapshot(_selectedDate.toIso8601String().substring(0, 10));
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已保存快照')));
        },
        child: const Icon(Icons.save),
      ),
    );
  }

  Widget _buildDayStat(String label, String value, IconData icon) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: Colors.blue),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(color: Colors.grey[600])),
                  Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    if (h > 0) return '${h}h${m}m';
    return '${m}m';
  }
}