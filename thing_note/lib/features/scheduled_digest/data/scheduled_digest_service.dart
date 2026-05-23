import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';
import '../domain/scheduled_digest_models.dart';

/// 定时摘要服务提供者
final scheduledDigestServiceProvider = Provider<ScheduledDigestService>((ref) {
  return ScheduledDigestService(ref.read(databaseProvider.future));
});

/// 定时摘要服务
class ScheduledDigestService {
  final Future<Database> _db;

  ScheduledDigestService(this._db);

  /// 生成摘要
  Future<DigestData> generateDigest(DigestFrequency frequency) async {
    final db = await _db;
    final now = DateTime.now();

    // 确定时间范围
    DateTime startDate;
    final DateTime endDate = now;

    switch (frequency) {
      case DigestFrequency.daily:
        startDate = DateTime(now.year, now.month, now.day);
        break;
      case DigestFrequency.weekly:
        final weekday = now.weekday;
        startDate = now.subtract(Duration(days: weekday - 1));
        startDate = DateTime(startDate.year, startDate.month, startDate.day);
        break;
      case DigestFrequency.monthly:
        startDate = DateTime(now.year, now.month, 1);
        break;
    }

    // 获取记录
    final records = await db.query(
      'episode_records',
      where: 'created_at >= ? AND created_at <= ?',
      whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
    );

    // 计算统计数据
    int totalMinutes = 0;
    final activeDaysSet = <String>{};

    for (final record in records) {
      totalMinutes += ((record['duration_sec'] as int?) ?? 0) ~/ 60;
      final createdAt = DateTime.parse(record['created_at'] as String);
      activeDaysSet.add('${createdAt.year}-${createdAt.month}-${createdAt.day}');
    }

    // 获取标签统计
    final tagCounts = <String, int>{};
    final tagRecords = await db.rawQuery('''
      SELECT rt.tag_name, COUNT(*) as count
      FROM record_tags rt
      JOIN episode_records r ON rt.record_id = r.id
      WHERE r.created_at >= ? AND r.created_at <= ?
      GROUP BY rt.tag_name
      ORDER BY count DESC
      LIMIT 5
    ''', [startDate.toIso8601String(), endDate.toIso8601String()]);

    for (final row in tagRecords) {
      tagCounts[row['tag_name'] as String] = row['count'] as int;
    }

    // 获取事情名称统计
    final thingCounts = <String, int>{};
    final thingRecords = await db.rawQuery('''
      SELECT tn.name, COUNT(*) as count
      FROM episode_records r
      JOIN thing_names tn ON r.thing_name_id = tn.id
      WHERE r.created_at >= ? AND r.created_at <= ?
      GROUP BY tn.name
      ORDER BY count DESC
      LIMIT 5
    ''', [startDate.toIso8601String(), endDate.toIso8601String()]);

    for (final row in thingRecords) {
      thingCounts[row['name'] as String] = row['count'] as int;
    }

    // 获取情绪平均值
    double? averageMood;
    final moodRecords = await db.query(
      'mood_entries',
      where: 'created_at >= ? AND created_at <= ?',
      whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
    );

    if (moodRecords.isNotEmpty) {
      int totalMood = 0;
      for (final record in moodRecords) {
        totalMood += record['mood_level'] as int;
      }
      averageMood = totalMood / moodRecords.length;
    }

    // 生成高亮记录
    final highlights = <Map<String, dynamic>>[];
    for (final record in records.take(3)) {
      if (record['photo_paths'] != null && (record['photo_paths'] as String).length > 2) {
        highlights.add({
          'note': record['note'] as String? ?? '',
          'photo_count': (record['photo_paths'] as String).split(',').length,
          'duration': record['duration_sec'] as int? ?? 0,
        });
      }
    }

    // 生成 AI 洞察
    String? aiInsight;
    if (records.isNotEmpty) {
      aiInsight = _generateBasicInsight(
        frequency,
        records.length,
        totalMinutes,
        activeDaysSet.length,
        tagCounts.keys.toList(),
      );
    }

    return DigestData(
      generatedAt: now,
      periodStart: startDate,
      periodEnd: endDate,
      frequency: frequency,
      totalRecords: records.length,
      totalMinutes: totalMinutes,
      activeDays: activeDaysSet.length,
      topTags: tagCounts.keys.toList(),
      topThings: thingCounts.keys.toList(),
      averageMood: averageMood,
      highlights: highlights,
      aiInsight: aiInsight,
    );
  }

  String _generateBasicInsight(
    DigestFrequency frequency,
    int recordCount,
    int totalMinutes,
    int activeDays,
    List<String> topTags,
  ) {
    final periodName = frequency == DigestFrequency.daily ? '今天' : 
                       frequency == DigestFrequency.weekly ? '本周' : '本月';

    final insights = <String>[];

    // 记录数洞察
    if (recordCount > 10) {
      insights.add('📝 $periodName 你记录了 $recordCount 条事件，非常活跃！');
    } else if (recordCount > 5) {
      insights.add('📝 $periodName 你记录了 $recordCount 条事件，保持良好习惯。');
    }

    // 时间洞察
    if (totalMinutes > 120) {
      insights.add('⏱️ 总计 $totalMinutes 分钟，度过了一段充实的时光。');
    }

    // 活跃度洞察
    if (frequency == DigestFrequency.weekly && activeDays >= 5) {
      insights.add('🔥 你保持了 $activeDays 天的活跃记录，太棒了！');
    }

    // 标签洞察
    if (topTags.isNotEmpty) {
      insights.add('🏷️ 最常用的标签是：${topTags.take(3).join("、")}');
    }

    // 生成总结
    if (insights.isEmpty) {
      return '$periodName 的记录还不错，继续保持！';
    }

    return insights.join('\n');
  }

  /// 保存摘要
  Future<void> saveDigest(DigestData digest) async {
    final db = await _db;

    await db.insert('digest_history', {
      'frequency': digest.frequency.name,
      'period_start': digest.periodStart.toIso8601String(),
      'period_end': digest.periodEnd.toIso8601String(),
      'total_records': digest.totalRecords,
      'total_minutes': digest.totalMinutes,
      'active_days': digest.activeDays,
      'top_tags': digest.topTags.join(','),
      'top_things': digest.topThings.join(','),
      'average_mood': digest.averageMood,
      'ai_insight': digest.aiInsight,
      'highlights_json': digest.highlights.toString(),
      'generated_at': digest.generatedAt.toIso8601String(),
    });
  }

  /// 获取摘要历史
  Future<List<Map<String, dynamic>>> getDigestHistory({int limit = 10}) async {
    final db = await _db;
    return db.query(
      'digest_history',
      orderBy: 'generated_at DESC',
      limit: limit,
    );
  }

  /// 获取配置
  Future<DigestConfig> getConfig() async {
    final db = await _db;
    final rows = await db.query('digest_config', limit: 1);

    if (rows.isEmpty) {
      return DigestConfig();
    }

    final row = rows.first;
    final contentTypesStr = row['content_types'] as String? ?? '';

    return DigestConfig(
      enabled: (row['enabled'] as int?) == 1,
      frequency: DigestFrequency.values.firstWhere(
        (f) => f.name == (row['frequency'] as String? ?? 'daily'),
        orElse: () => DigestFrequency.daily,
      ),
      defaultTime: DigestTime.values.firstWhere(
        (t) => t.name == (row['default_time'] as String? ?? 'evening'),
        orElse: () => DigestTime.evening,
      ),
      contentTypes: contentTypesStr.isEmpty
          ? [DigestContentType.summary, DigestContentType.stats]
          : contentTypesStr.split(',').map((s) {
              return DigestContentType.values.firstWhere(
                (t) => t.name == s,
                orElse: () => DigestContentType.summary,
              );
            }).toList(),
      autoSend: (row['auto_send'] as int?) == 1,
    );
  }

  /// 保存配置
  Future<void> saveConfig(DigestConfig config) async {
    final db = await _db;

    await db.delete('digest_config');
    await db.insert('digest_config', {
      'enabled': config.enabled ? 1 : 0,
      'frequency': config.frequency.name,
      'default_time': config.defaultTime.name,
      'content_types': config.contentTypes.map((t) => t.name).join(','),
      'auto_send': config.autoSend ? 1 : 0,
      'notification_channel': config.notificationChannel,
    });
  }
}