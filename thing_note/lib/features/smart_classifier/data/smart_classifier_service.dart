import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';
import '../domain/smart_classifier_models.dart';

/// 智能分类服务提供者
final smartClassifierServiceProvider = Provider<SmartClassifierService>((ref) {
  return SmartClassifierService(ref.read(databaseProvider.future));
});

/// 智能分类服务
class SmartClassifierService {
  final Future<Database> _db;

  SmartClassifierService(this._db);

  /// 分析内容特征
  Future<ContentFeature> analyzeContent(String content) async {
    final keywords = <String>[];
    final entities = <String>[];

    // 简单关键词提取
    final words = content.split(RegExp(r'[\s,，。.!?]+'));
    for (final word in words) {
      if (word.length >= 2 && word.length <= 10) {
        keywords.add(word);
      }
    }

    // 提取时间提及
    final timePatterns = [
      RegExp(r'\d+分钟'),
      RegExp(r'\d+小时'),
      RegExp(r'上午|下午|晚上|早晨'),
      RegExp(r'今天|昨天|明天'),
    ];

    String? timeMention;
    for (final pattern in timePatterns) {
      final match = pattern.firstMatch(content);
      if (match != null) {
        timeMention = match.group(0);
        break;
      }
    }

    // 提取位置提及
    final locationPatterns = [
      RegExp(r'在(.+?)[做去到]'),
      RegExp(r'去了(.+?)做'),
    ];

    String? locationMention;
    for (final pattern in locationPatterns) {
      final match = pattern.firstMatch(content);
      if (match != null) {
        locationMention = match.group(1);
        break;
      }
    }

    // 估算持续时间
    int estimatedDuration = 30; // 默认 30 分钟
    final durationMatch = RegExp(r'(\d+)\s*分钟').firstMatch(content);
    if (durationMatch != null) {
      estimatedDuration = int.tryParse(durationMatch.group(1)!) ?? 30;
    }

    return ContentFeature(
      keywords: keywords.take(20).toList(),
      entities: entities,
      timeMention: timeMention,
      locationMention: locationMention,
      estimatedDuration: estimatedDuration,
    );
  }

  /// 获取分类建议
  Future<List<ClassificationSuggestion>> getSuggestions(int recordId, String content) async {
    final suggestions = <ClassificationSuggestion>[];

    // 1. 基于规则匹配
    final ruleSuggestions = await _matchRules(recordId, content);
    suggestions.addAll(ruleSuggestions);

    // 2. 基于历史分析
    final historySuggestions = await _analyzeHistory(recordId, content);
    suggestions.addAll(historySuggestions);

    // 3. 基于关键词
    final keywordSuggestions = await _matchKeywords(recordId, content);
    suggestions.addAll(keywordSuggestions);

    // 去重并按置信度排序
    final uniqueSuggestions = _deduplicateSuggestions(suggestions);
    uniqueSuggestions.sort((a, b) => b.confidence.compareTo(a.confidence));

    return uniqueSuggestions.take(5).toList();
  }

  Future<List<ClassificationSuggestion>> _matchRules(int recordId, String content) async {
    final db = await _db;
    final suggestions = <ClassificationSuggestion>[];

    final rules = await db.query(
      'classification_rules',
      where: 'is_enabled = 1',
    );

    for (final ruleMap in rules) {
      final rule = ClassificationRule.fromMap(ruleMap);
      final pattern = RegExp(rule.pattern, caseSensitive: false);

      if (pattern.hasMatch(content)) {
        // 更新匹配计数
        await db.rawUpdate(
          'UPDATE classification_rules SET match_count = match_count + 1 WHERE id = ?',
          [rule.id],
        );

        suggestions.add(ClassificationSuggestion(
          recordId: recordId,
          suggestedThingName: rule.assignedThingName,
          suggestedTags: rule.assignedTags,
          confidence: 0.95,
          reason: '匹配规则: ${rule.name}',
          type: ClassificationType.both,
        ));
      }
    }

    return suggestions;
  }

  Future<List<ClassificationSuggestion>> _analyzeHistory(int recordId, String content) async {
    final db = await _db;
    final suggestions = <ClassificationSuggestion>[];

    // 查找相似内容的记录
    final words = content.split(RegExp(r'[\s,，。.!?]+')).take(5);
    final conditions = words.map((w) => "note LIKE '%$w%'").join(' OR ');

    if (conditions.isEmpty) return suggestions;

    final similarRecords = await db.rawQuery(
      'SELECT * FROM episode_records WHERE $conditions ORDER BY created_at DESC LIMIT 10',
    );

    if (similarRecords.isEmpty) return suggestions;

    // 分析相似记录的分类
    final tagCounts = <String, int>{};
    final thingNameCounts = <String, int>{};

    for (final record in similarRecords) {
      // 统计标签（从 record_tags 表）
      final tags = await db.query(
        'record_tags',
        where: 'record_id = ?',
        whereArgs: [record['id']],
      );
      for (final tag in tags) {
        final tagName = tag['tag_name'] as String;
        tagCounts[tagName] = (tagCounts[tagName] ?? 0) + 1;
      }

      // 统计事情名称
      final thingNameId = record['thing_name_id'] as int?;
      if (thingNameId != null) {
        final thingNames = await db.query(
          'thing_names',
          where: 'id = ?',
          whereArgs: [thingNameId],
        );
        if (thingNames.isNotEmpty) {
          final name = thingNames.first['name'] as String;
          thingNameCounts[name] = (thingNameCounts[name] ?? 0) + 1;
        }
      }
    }

    // 找出最常见的标签
    if (tagCounts.isNotEmpty) {
      final sortedTags = tagCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final topTag = sortedTags.first.key;
      final confidence = sortedTags.first.value / similarRecords.length;

      suggestions.add(ClassificationSuggestion(
        recordId: recordId,
        suggestedTags: [topTag],
        confidence: confidence,
        reason: '基于 ${similarRecords.length} 条相似记录',
        type: ClassificationType.tag,
      ));
    }

    // 找出最常见的事情名称
    if (thingNameCounts.isNotEmpty) {
      final sortedThings = thingNameCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final topThing = sortedThings.first.key;
      final confidence = sortedThings.first.value / similarRecords.length;

      suggestions.add(ClassificationSuggestion(
        recordId: recordId,
        suggestedThingName: topThing,
        confidence: confidence,
        reason: '基于 ${similarRecords.length} 条相似记录',
        type: ClassificationType.thingName,
      ));
    }

    return suggestions;
  }

  Future<List<ClassificationSuggestion>> _matchKeywords(int recordId, String content) async {
    final suggestions = <ClassificationSuggestion>[];

    // 预设关键词映射
    final keywordMappings = {
      'work': ['工作', '上班', '开会', '任务', '项目'],
      'study': ['学习', '读书', '课程', '复习', '考试'],
      'exercise': ['运动', '跑步', '健身', '瑜伽', '锻炼'],
      'meal': ['吃饭', '午餐', '晚餐', '早餐', '烹饪'],
      'rest': ['休息', '睡觉', '午休', '小憩', '放松'],
      'social': ['聚会', '见面', '约会', '聊天', '社交'],
    };

    for (final entry in keywordMappings.entries) {
      final category = entry.key;
      final keywords = entry.value;

      for (final keyword in keywords) {
        if (content.contains(keyword)) {
          final tag = _getTagForCategory(category);
          suggestions.add(ClassificationSuggestion(
            recordId: recordId,
            suggestedTags: [tag],
            confidence: 0.6,
            reason: '关键词匹配: $keyword',
            type: ClassificationType.tag,
          ));
          break;
        }
      }
    }

    return suggestions;
  }

  String _getTagForCategory(String category) {
    const mapping = {
      'work': '工作',
      'study': '学习',
      'exercise': '运动',
      'meal': '餐饮',
      'rest': '休息',
      'social': '社交',
    };
    return mapping[category] ?? category;
  }

  List<ClassificationSuggestion> _deduplicateSuggestions(
    List<ClassificationSuggestion> suggestions,
  ) {
    final unique = <String, ClassificationSuggestion>{};

    for (final suggestion in suggestions) {
      final key = '${suggestion.suggestedThingName}_${suggestion.suggestedTags.join('_')}';
      if (!unique.containsKey(key) || unique[key]!.confidence < suggestion.confidence) {
        unique[key] = suggestion;
      }
    }

    return unique.values.toList();
  }

  /// 应用分类建议
  Future<void> applySuggestion(ClassificationSuggestion suggestion) async {
    final db = await _db;

    // 更新记录的事情名称
    if (suggestion.suggestedThingName != null) {
      // 查找或创建事情名称
      final thingNames = await db.query(
        'thing_names',
        where: 'name = ?',
        whereArgs: [suggestion.suggestedThingName],
      );

      int thingNameId;
      if (thingNames.isEmpty) {
        thingNameId = await db.insert('thing_names', {
          'name': suggestion.suggestedThingName,
          'created_at': DateTime.now().toIso8601String(),
        });
      } else {
        thingNameId = thingNames.first['id'] as int;
      }

      await db.update(
        'episode_records',
        {'thing_name_id': thingNameId},
        where: 'id = ?',
        whereArgs: [suggestion.recordId],
      );
    }

    // 添加标签
    for (final tag in suggestion.suggestedTags) {
      await db.insert('record_tags', {
        'record_id': suggestion.recordId,
        'tag_name': tag,
        'added_at': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }

    // 记录分类历史
    await db.insert('classification_history', {
      'record_id': suggestion.recordId,
      'suggested_thing_name': suggestion.suggestedThingName,
      'suggested_tags': suggestion.suggestedTags.join(','),
      'confidence': suggestion.confidence,
      'applied_at': DateTime.now().toIso8601String(),
    });
  }

  /// 获取分类规则
  Future<List<ClassificationRule>> getRules() async {
    final db = await _db;
    final rows = await db.query('classification_rules');
    return rows.map((r) => ClassificationRule.fromMap(r)).toList();
  }

  /// 添加分类规则
  Future<void> addRule(ClassificationRule rule) async {
    final db = await _db;
    await db.insert('classification_rules', rule.toMap());
  }

  /// 更新分类规则
  Future<void> updateRule(int id, ClassificationRule rule) async {
    final db = await _db;
    await db.update(
      'classification_rules',
      rule.toMap(),
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 删除分类规则
  Future<void> deleteRule(int id) async {
    final db = await _db;
    await db.delete('classification_rules', where: 'id = ?', whereArgs: [id]);
  }
}