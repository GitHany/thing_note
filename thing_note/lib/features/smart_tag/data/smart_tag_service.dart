import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/smart_tag/domain/tag_recommendation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';

final smartTagProvider = Provider<SmartTagService>((ref) {
    final dbAsync = ref.watch(databaseProvider);
    return SmartTagService(dbAsync);
});

/// 智能标签推荐服务
class SmartTagService {
  final AsyncValue<Database> _dbAsync;

  SmartTagService(this._dbAsync);

  Future<Database> get _db async {
    final db = _dbAsync.value;
    if (db == null) throw Exception('Database not initialized');
    return db;
  }

  /// 基于记录内容分析推荐标签
  Future<List<TagRecommendation>> getRecommendations({
    required String note,
    String? thingName,
    DateTime? occurredAt,
    List<String>? existingTags,
  }) async {
    final recommendations = <TagRecommendation>[];
    
    // 基于关键词分析
    recommendations.addAll(_analyzeKeywords(note));
    
    // 基于时间模式分析
    if (occurredAt != null) {
      recommendations.addAll(await _analyzeTimePattern(occurredAt));
    }
    
    // 基于事件名称推荐
    if (thingName != null) {
      recommendations.addAll(await _analyzeThingName(thingName));
    }
    
    // 去重并按分数排序
    final seen = <String>{};
    final unique = <TagRecommendation>[];
    for (final rec in recommendations) {
      if (!seen.contains(rec.tagName)) {
        seen.add(rec.tagName);
        // 过滤已存在的标签
        if (existingTags == null || !existingTags.contains(rec.tagName)) {
          unique.add(rec);
        }
      }
    }
    
    unique.sort((a, b) => b.score.compareTo(a.score));
    return unique.take(5).toList();
  }

  List<TagRecommendation> _analyzeKeywords(String note) {
    final recommendations = <TagRecommendation>[];
    final lowerNote = note.toLowerCase();
    
    // 定义关键词到标签的映射
    final keywordMap = {
      '会议': '会议',
      '电话': '沟通',
      '邮件': '沟通',
      '微信': '沟通',
      '跑步': '运动',
      '健身': '运动',
      '游泳': '运动',
      '瑜伽': '运动',
      '阅读': '学习',
      '学习': '学习',
      '读书': '学习',
      '写代码': '工作',
      '编程': '工作',
      '做饭': '生活',
      '吃饭': '生活',
      '睡觉': '生活',
      '早起': '习惯',
      '喝水': '健康',
      '医院': '健康',
      '买': '购物',
      '购物': '购物',
      '消费': '财务',
      '工资': '财务',
      '旅游': '休闲',
      '电影': '休闲',
      '音乐': '休闲',
      '朋友': '社交',
      '聚会': '社交',
      '家人': '家庭',
      '生日': '重要',
      '节日': '重要',
    };
    
    for (final entry in keywordMap.entries) {
      if (lowerNote.contains(entry.key)) {
        recommendations.add(TagRecommendation(
          tagName: entry.value,
          reason: '检测到关键词: ${entry.key}',
          score: 80,
          type: RecommendationType.keyword,
        ));
      }
    }
    
    return recommendations;
  }

  Future<List<TagRecommendation>> _analyzeTimePattern(DateTime occurredAt) async {
    final recommendations = <TagRecommendation>[];
    
    // 检查是否在周末
    if (occurredAt.weekday == DateTime.saturday || occurredAt.weekday == DateTime.sunday) {
      recommendations.add(const TagRecommendation(
        tagName: '周末',
        reason: '周末记录',
        score: 70,
        type: RecommendationType.time,
      ));
    }
    
    // 检查是否在工作日早上
    if (occurredAt.weekday >= DateTime.monday && occurredAt.weekday <= DateTime.friday) {
      if (occurredAt.hour >= 9 && occurredAt.hour < 12) {
        recommendations.add(const TagRecommendation(
          tagName: '工作',
          reason: '工作时间段',
          score: 60,
          type: RecommendationType.time,
        ));
      }
    }
    
    // 检查是否在深夜
    if (occurredAt.hour >= 22 || occurredAt.hour < 6) {
      recommendations.add(const TagRecommendation(
        tagName: '深夜',
        reason: '夜间记录',
        score: 50,
        type: RecommendationType.time,
      ));
    }
    
    return recommendations;
  }

  Future<List<TagRecommendation>> _analyzeThingName(String thingName) async {
    final recommendations = <TagRecommendation>[];
    final lowerName = thingName.toLowerCase();
    
    if (lowerName.contains('工作') || lowerName.contains('任务')) {
      recommendations.add(const TagRecommendation(
        tagName: '工作',
        reason: '事件名称相关',
        score: 90,
        type: RecommendationType.thingName,
      ));
    }
    
    if (lowerName.contains('学习') || lowerName.contains('课程')) {
      recommendations.add(const TagRecommendation(
        tagName: '学习',
        reason: '事件名称相关',
        score: 90,
        type: RecommendationType.thingName,
      ));
    }
    
    return recommendations;
  }

  /// 获取常用标签
  Future<List<String>> getFrequentlyUsedTags({int limit = 10}) async {
    final db = await _db;
    final result = await db.rawQuery('''
      SELECT t.name, COUNT(rt.record_id) as count
      FROM tags t
      LEFT JOIN record_tags rt ON t.id = rt.tag_id
      GROUP BY t.id, t.name
      ORDER BY count DESC
      LIMIT ?
    ''', [limit]);
    
    return result.map((r) => r['name'] as String).toList();
  }

  /// 获取最近使用的标签
  Future<List<String>> getRecentlyUsedTags({int limit = 5, int days = 7}) async {
    final db = await _db;
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    
    final result = await db.rawQuery('''
      SELECT DISTINCT t.name
      FROM tags t
      INNER JOIN record_tags rt ON t.id = rt.tag_id
      INNER JOIN episode_records r ON rt.record_id = r.id
      WHERE r.occurred_at >= ?
      ORDER BY r.occurred_at DESC
      LIMIT ?
    ''', [cutoffDate.toIso8601String(), limit]);
    
    return result.map((r) => r['name'] as String).toList();
  }

  /// 获取标签共现关系（经常一起使用的标签）
  Future<Map<String, List<String>>> getTagCooccurrence({int minCooccurrence = 2}) async {
    final db = await _db;
    
    final result = await db.rawQuery('''
      SELECT rt1.tag_id as tag1, rt2.tag_id as tag2
      FROM record_tags rt1
      INNER JOIN record_tags rt2 ON rt1.record_id = rt2.record_id AND rt1.tag_id < rt2.tag_id
      GROUP BY rt1.tag_id, rt2.tag_id
      HAVING COUNT(*) >= ?
    ''', [minCooccurrence]);
    
    final cooccurrence = <String, List<String>>{};
    
    for (final row in result) {
      final tag1Id = row['tag1'] as int;
      final tag2Id = row['tag2'] as int;
      
      final tag1Name = await _getTagName(tag1Id);
      final tag2Name = await _getTagName(tag2Id);
      
      if (tag1Name != null && tag2Name != null) {
        cooccurrence.putIfAbsent(tag1Name, () => []).add(tag2Name);
        cooccurrence.putIfAbsent(tag2Name, () => []).add(tag1Name);
      }
    }
    
    return cooccurrence;
  }

  Future<String?> _getTagName(int tagId) async {
    final db = await _db;
    final result = await db.query('tags', where: 'id = ?', whereArgs: [tagId], limit: 1);
    if (result.isEmpty) return null;
    return result.first['name'] as String;
  }
}