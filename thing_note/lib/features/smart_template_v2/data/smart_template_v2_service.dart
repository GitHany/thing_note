import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';
import '../domain/smart_template_v2_models.dart';

/// 智能模板服务提供者
final smartTemplateServiceProvider = Provider<SmartTemplateService>((ref) {
  return SmartTemplateService(ref.read(databaseProvider.future));
});

/// 智能模板服务
class SmartTemplateService {
  final Future<Database> _db;

  SmartTemplateService(this._db);

  /// 获取模板推荐
  Future<List<TemplateRecommendation>> getRecommendations({
    DateTime? currentTime,
    String? location,
    List<String>? recentTags,
  }) async {
    final db = await _db;

    // 获取最常用的模板
    final templates = await db.query(
      'templates',
      orderBy: 'use_count DESC',
      limit: 20,
    );

    if (templates.isEmpty) {
      return [];
    }

    final recommendations = <TemplateRecommendation>[];

    for (final template in templates) {
      final id = template['id'] as int;
      final name = template['name'] as String;
      final useCount = (template['use_count'] as int?) ?? 0;
      final category = template['category'] as String?;
      final defaultTagsStr = template['default_tags'] as String?;

      // 计算置信度
      double confidence = 0.5;
      String reason = '常用模板';

      // 基于使用频率计算置信度
      if (useCount > 10) {
        confidence += 0.2;
        reason = '高频使用';
      } else if (useCount > 5) {
        confidence += 0.1;
        reason = '经常使用';
      }

      // 基于时间模式
      if (recentTags != null && recentTags.isNotEmpty) {
        if (defaultTagsStr != null) {
          final defaultTags = defaultTagsStr.split(',');
          final hasMatch = recentTags.any((t) =>
            defaultTags.any((dt) => dt.toLowerCase().contains(t.toLowerCase()))
          );
          if (hasMatch) {
            confidence += 0.15;
            reason = '标签匹配';
          }
        }
      }

      // 基于类别
      if (category != null) {
        confidence += 0.05;
      }

      // 建议标签
      List<String> suggestedTags = [];
      if (defaultTagsStr != null && defaultTagsStr.isNotEmpty) {
        suggestedTags = defaultTagsStr.split(',').take(3).toList();
      }

      recommendations.add(TemplateRecommendation(
        templateId: id,
        templateName: name,
        confidence: confidence.clamp(0.0, 1.0),
        reason: reason,
        category: category,
        suggestedTags: suggestedTags,
        useCount: useCount,
      ));
    }

    // 按置信度排序
    recommendations.sort((a, b) => b.confidence.compareTo(a.confidence));

    return recommendations.take(5).toList();
  }

  /// 记录模板使用
  Future<void> recordTemplateUsage(TemplateUsage usage) async {
    final db = await _db;

    // 更新使用计数
    await db.rawUpdate(
      'UPDATE templates SET use_count = use_count + 1 WHERE id = ?',
      [usage.templateId],
    );

    // 记录使用历史
    await db.insert('template_usage_history', {
      'template_id': usage.templateId,
      'template_name': usage.templateName,
      'used_at': usage.usedAt.toIso8601String(),
      'context': usage.context,
    });
  }

  /// 获取使用历史
  Future<List<TemplateUsage>> getUsageHistory({int limit = 50}) async {
    final db = await _db;

    final rows = await db.query(
      'template_usage_history',
      orderBy: 'used_at DESC',
      limit: limit,
    );

    return rows.map((row) => TemplateUsage(
      templateId: row['template_id'] as int,
      templateName: row['template_name'] as String,
      usedAt: DateTime.parse(row['used_at'] as String),
      context: row['context'] as String?,
    )).toList();
  }

  /// 分析使用模式
  Future<UsagePattern?> analyzeUsagePattern() async {
    final db = await _db;
    final now = DateTime.now();

    // 获取最近30天的记录
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));

    final records = await db.query(
      'episode_records',
      where: 'created_at >= ?',
      whereArgs: [thirtyDaysAgo.toIso8601String()],
    );

    if (records.isEmpty) {
      return null;
    }

    // 分析时间分布
    int morningCount = 0;
    int afternoonCount = 0;
    int eveningCount = 0;
    int nightCount = 0;

    final dayCounts = <int, int>{}; // 周几的记录数

    for (final record in records) {
      final createdAt = DateTime.parse(record['created_at'] as String);
      final hour = createdAt.hour;

      if (hour >= 6 && hour < 12) {
        morningCount++;
      } else if (hour >= 12 && hour < 18) {
        afternoonCount++;
      } else if (hour >= 18 && hour < 22) {
        eveningCount++;
      } else {
        nightCount++;
      }

      final weekday = createdAt.weekday;
      dayCounts[weekday] = (dayCounts[weekday] ?? 0) + 1;
    }

    // 找出最活跃的时段
    String timeOfDay = 'evening';
    int maxCount = eveningCount;
    if (morningCount > maxCount) {
      timeOfDay = 'morning';
      maxCount = morningCount;
    }
    if (afternoonCount > maxCount) {
      timeOfDay = 'afternoon';
      maxCount = afternoonCount;
    }
    if (nightCount > maxCount) {
      timeOfDay = 'night';
      maxCount = nightCount;
    }

    // 找出最活跃的星期几
    String dayOfWeek = 'weekday';
    int maxDayCount = 0;
    int weekdayCount = 0;
    int weekendCount = 0;

    for (final entry in dayCounts.entries) {
      if (entry.value > maxDayCount) {
        maxDayCount = entry.value;
        dayOfWeek = _weekdayName(entry.key);
      }
      if (entry.key <= 5) {
        weekdayCount += entry.value;
      } else {
        weekendCount += entry.value;
      }
    }

    // 判断是工作日还是周末更活跃
    if (weekendCount > weekdayCount) {
      dayOfWeek = 'weekend';
    }

    return UsagePattern(
      timeOfDay: timeOfDay,
      dayOfWeek: dayOfWeek,
      commonTags: [],
      commonThingNames: [],
      avgRecordCount: (records.length / 30).round(),
    );
  }

  String _weekdayName(int weekday) {
    const names = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return names[weekday - 1];
  }

  /// 创建模板
  Future<int> createTemplate(TemplateCreateRequest request) async {
    final db = await _db;

    final id = await db.insert('templates', request.toMap());

    return id;
  }

  /// 更新模板
  Future<void> updateTemplate(int id, Map<String, dynamic> data) async {
    final db = await _db;
    await db.update('templates', data, where: 'id = ?', whereArgs: [id]);
  }

  /// 删除模板
  Future<void> deleteTemplate(int id) async {
    final db = await _db;
    await db.delete('templates', where: 'id = ?', whereArgs: [id]);
  }

  /// 获取所有模板
  Future<List<Map<String, dynamic>>> getAllTemplates() async {
    final db = await _db;
    return db.query('templates', orderBy: 'use_count DESC');
  }

  /// 搜索模板
  Future<List<Map<String, dynamic>>> searchTemplates(String query) async {
    final db = await _db;
    return db.query(
      'templates',
      where: 'name LIKE ? OR category LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'use_count DESC',
    );
  }

  /// 获取模板统计
  Future<Map<String, dynamic>> getTemplateStats() async {
    final db = await _db;

    final total = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM templates'),
    ) ?? 0;

    final totalUsage = Sqflite.firstIntValue(
      await db.rawQuery('SELECT SUM(use_count) FROM templates'),
    ) ?? 0;

    final favoriteCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM templates WHERE is_favorite = 1'),
    ) ?? 0;

    return {
      'total_templates': total,
      'total_uses': totalUsage,
      'favorite_count': favoriteCount,
    };
  }
}