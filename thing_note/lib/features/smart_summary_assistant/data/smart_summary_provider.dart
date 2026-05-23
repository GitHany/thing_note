import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';
import 'package:thing_note/features/smart_summary_assistant/domain/smart_summary.dart';

final smartSummaryProvider = StateNotifierProvider<SmartSummaryNotifier, AsyncValue<List<SmartSummary>>>((ref) {
  return SmartSummaryNotifier(ref);
});

class SmartSummaryNotifier extends StateNotifier<AsyncValue<List<SmartSummary>>> {
  final Ref ref;

  SmartSummaryNotifier(this.ref) : super(const AsyncValue.loading()) {
    loadSummaries();
  }

  Future<Database> get _db => ref.read(databaseProvider.future);

  Future<void> loadSummaries() async {
    try {
      state = const AsyncValue.loading();
      final db = await _db;
      final maps = await db.query('smart_summaries', orderBy: 'created_at DESC');
      final summaries = maps.map((m) => SmartSummary.fromMap(m)).toList();
      state = AsyncValue.data(summaries);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<int> createSummary(SmartSummary summary) async {
    final db = await _db;
    final id = await db.insert('smart_summaries', summary.toMap()..remove('id'));
    await loadSummaries();
    return id;
  }

  Future<void> markAsRead(int id) async {
    final db = await _db;
    await db.update('smart_summaries', {'is_read': 1}, where: 'id = ?', whereArgs: [id]);
    await loadSummaries();
  }

  Future<SmartSummary?> generateDailySummary() async {
    final db = await _db;
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final records = await db.query(
      'episode_records',
      where: 'occurred_at >= ? AND occurred_at < ?',
      whereArgs: [startOfDay.toIso8601String(), endOfDay.toIso8601String()],
    );

    if (records.isEmpty) return null;

    int totalDuration = 0;
    final thingCounts = <String, int>{};
    final tagCounts = <String, int>{};

    for (final record in records) {
      totalDuration += (record['duration_sec'] as int? ?? 0);
      
      final thingNameId = record['thing_name_id'];
      if (thingNameId != null) {
        final things = await db.query('thing_names', where: 'id = ?', whereArgs: [thingNameId]);
        if (things.isNotEmpty) {
          final name = things.first['name'] as String;
          thingCounts[name] = (thingCounts[name] ?? 0) + 1;
        }
      }

      final note = record['note'] as String? ?? '';
      if (note.isNotEmpty) {
        final tags = note.split(RegExp(r'[,，#]'));
        for (final tag in tags) {
          if (tag.trim().isNotEmpty) {
            tagCounts[tag.trim()] = (tagCounts[tag.trim()] ?? 0) + 1;
          }
        }
      }
    }

    final sortedThings = thingCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final sortedTags = tagCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topThings = sortedThings.take(5).map((e) => e.key).join(', ');
    final topTags = sortedTags.take(5).map((e) => e.key).join(', ');

    final durationMinutes = totalDuration ~/ 60;
    final hours = durationMinutes ~/ 60;
    final mins = durationMinutes % 60;

    final content = '''
今日共记录 ${records.length} 条，总时长 ${hours > 0 ? '${hours}小时' : ''}${mins}分钟。

最常做的事情：
${sortedThings.take(3).map((e) => '• ${e.key} (${e.value}次)').join('\n')}

常用标签：
${sortedTags.take(5).map((e) => '• #${e.key}').join('\n')}

继续保持！💪
''';

    final summary = SmartSummary(
      summaryType: 'daily',
      periodStart: startOfDay.toIso8601String(),
      periodEnd: endOfDay.toIso8601String(),
      title: '${now.month}月${now.day}日日报',
      content: content,
      recordCount: records.length,
      topThings: topThings,
      topTags: topTags,
      highlights: sortedThings.take(3).map((e) => '${e.key}: ${e.value}次').join('; '),
      createdAt: now.toIso8601String(),
    );

    final id = await createSummary(summary);
    return summary.copyWith(id: id);
  }

  Future<SmartSummary?> generateWeeklySummary() async {
    final db = await _db;
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final weekStart = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    final weekEnd = weekStart.add(const Duration(days: 7));

    final records = await db.query(
      'episode_records',
      where: 'occurred_at >= ? AND occurred_at < ?',
      whereArgs: [weekStart.toIso8601String(), weekEnd.toIso8601String()],
    );

    if (records.isEmpty) return null;

    int totalDuration = 0;
    final dailyCounts = <int, int>{};

    for (final record in records) {
      totalDuration += (record['duration_sec'] as int? ?? 0);
      final date = DateTime.parse(record['occurred_at'] as String);
      final dayIndex = date.weekday - 1;
      dailyCounts[dayIndex] = (dailyCounts[dayIndex] ?? 0) + 1;
    }

    final avgDaily = records.length / 7;
    final durationHours = totalDuration / 3600;
    final mostActiveDay = dailyCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    final dayNames = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];

    final content = '''
本周（${weekStart.month}/${weekStart.day} - ${weekEnd.month}/${weekEnd.day}）共记录 ${records.length} 条。

📊 数据概览：
• 平均每日记录：${avgDaily.toStringAsFixed(1)}条
• 总时长：${durationHours.toStringAsFixed(1)}小时
• 最活跃日：${dayNames[mostActiveDay]}

📈 趋势分析：
${durationHours > 10 ? '• 继续保持高活跃度！🎉' : '• 有进步空间，可以尝试设定小目标'}
${avgDaily > 3 ? '• 记录习惯良好，继续保持！' : '• 建议每天至少记录一条'}

下周目标：
• 保持记录连续性
• 尝试新的活动类型
''';

    final summary = SmartSummary(
      summaryType: 'weekly',
      periodStart: weekStart.toIso8601String(),
      periodEnd: weekEnd.toIso8601String(),
      title: '第${((now.difference(DateTime(now.year, 1, 1)).inDays) / 7).ceil()}周周报',
      content: content,
      recordCount: records.length,
      highlights: '平均每天${avgDaily.toStringAsFixed(1)}条',
      insights: '本周最活跃日：${dayNames[mostActiveDay]}',
      createdAt: now.toIso8601String(),
    );

    final id = await createSummary(summary);
    return summary.copyWith(id: id);
  }

  Future<void> deleteSummary(int id) async {
    final db = await _db;
    await db.delete('smart_summaries', where: 'id = ?', whereArgs: [id]);
    await loadSummaries();
  }
}

extension SmartSummaryExtension on SmartSummary {
  SmartSummary copyWith({
    int? id,
    String? summaryType,
    String? periodStart,
    String? periodEnd,
    String? title,
    String? content,
    String? highlights,
    String? insights,
    int? recordCount,
    String? topThings,
    String? topTags,
    double? moodAverage,
    double? energyAverage,
    int? isRead,
    String? createdAt,
  }) {
    return SmartSummary(
      id: id ?? this.id,
      summaryType: summaryType ?? this.summaryType,
      periodStart: periodStart ?? this.periodStart,
      periodEnd: periodEnd ?? this.periodEnd,
      title: title ?? this.title,
      content: content ?? this.content,
      highlights: highlights ?? this.highlights,
      insights: insights ?? this.insights,
      recordCount: recordCount ?? this.recordCount,
      topThings: topThings ?? this.topThings,
      topTags: topTags ?? this.topTags,
      moodAverage: moodAverage ?? this.moodAverage,
      energyAverage: energyAverage ?? this.energyAverage,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}