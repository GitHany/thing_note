import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/sleep_tracker/data/sleep_repository.dart';
import 'package:thing_note/features/sleep_tracker/domain/sleep_record.dart';

class SleepTrackerScreen extends ConsumerStatefulWidget {
  const SleepTrackerScreen({super.key});

  @override
  ConsumerState<SleepTrackerScreen> createState() => _SleepTrackerScreenState();
}

class _SleepTrackerScreenState extends ConsumerState<SleepTrackerScreen> {
  @override
  Widget build(BuildContext context) {
    final recordsAsync = ref.watch(sleepRecordsProvider);
    final statsAsync = ref.watch(sleepStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('睡眠追踪'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddSleepDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStatsCard(statsAsync),
          Expanded(
            child: recordsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('错误: $e')),
              data: (records) {
                if (records.isEmpty) {
                  return _buildEmptyState();
                }
                return _buildRecordsList(records);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSleepDialog(context),
        child: const Icon(Icons.bedtime),
      ),
    );
  }

  Widget _buildStatsCard(AsyncValue<SleepStats> statsAsync) {
    return statsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (stats) => Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.indigo.shade400, Colors.purple.shade400],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem('平均时长', '${stats.avgDuration.round()}分钟', Icons.timer),
            _buildStatItem('平均质量', '${stats.avgQuality.toStringAsFixed(1)}星', Icons.star),
            _buildStatItem('好睡眠', '${stats.goodNights}晚', Icons.nightlight),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 24),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.nightlight_round, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('暂无睡眠记录', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 8),
          const Text('开始记录你的睡眠吧', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _showAddSleepDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('添加记录'),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordsList(List<SleepRecord> records) {
    final last7Days = records.take(7).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('最近睡眠', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        ...last7Days.map((record) => _buildSleepCard(record)),
      ],
    );
  }

  Widget _buildSleepCard(SleepRecord record) {
    final qualityStars = record.quality ?? 0;
    
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
                  record.date,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      index < qualityStars ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 20,
                    );
                  }),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildTimeChip(Icons.bedtime, record.bedtime, '入睡'),
                const SizedBox(width: 8),
                _buildTimeChip(Icons.wb_sunny, record.wakeTime, '起床'),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.indigo.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    record.formattedDuration,
                    style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            if (record.note != null && record.note!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(record.note!, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimeChip(IconData icon, String time, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 4),
          Text(time, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _showAddSleepDialog(BuildContext context) {
    TimeOfDay bedtime = const TimeOfDay(hour: 23, minute: 0);
    TimeOfDay wakeTime = const TimeOfDay(hour: 7, minute: 0);
    int quality = 3;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('记录睡眠'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: const Text('入睡时间'),
                  subtitle: Text(bedtime.format(context)),
                  trailing: const Icon(Icons.bedtime),
                  onTap: () async {
                    final time = await showTimePicker(context: context, initialTime: bedtime);
                    if (time != null) setState(() => bedtime = time);
                  },
                ),
                ListTile(
                  title: const Text('起床时间'),
                  subtitle: Text(wakeTime.format(context)),
                  trailing: const Icon(Icons.wb_sunny),
                  onTap: () async {
                    final time = await showTimePicker(context: context, initialTime: wakeTime);
                    if (time != null) setState(() => wakeTime = time);
                  },
                ),
                const SizedBox(height: 16),
                const Text('睡眠质量'),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      icon: Icon(
                        index < quality ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 32,
                      ),
                      onPressed: () => setState(() => quality = index + 1),
                    );
                  }),
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
                final now = DateTime.now();
                final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
                
                final bedtimeMinutes = bedtime.hour * 60 + bedtime.minute;
                final wakeTimeMinutes = wakeTime.hour * 60 + wakeTime.minute;
                final duration = wakeTimeMinutes > bedtimeMinutes 
                    ? wakeTimeMinutes - bedtimeMinutes 
                    : (24 * 60 - bedtimeMinutes) + wakeTimeMinutes;

                final record = SleepRecord(
                  date: dateStr,
                  bedtime: '${bedtime.hour.toString().padLeft(2, '0')}:${bedtime.minute.toString().padLeft(2, '0')}',
                  wakeTime: '${wakeTime.hour.toString().padLeft(2, '0')}:${wakeTime.minute.toString().padLeft(2, '0')}',
                  durationMinutes: duration,
                  quality: quality,
                  createdAt: now,
                );
                ref.read(sleepRecordsProvider.notifier).addRecord(record);
                Navigator.pop(context);
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }
}