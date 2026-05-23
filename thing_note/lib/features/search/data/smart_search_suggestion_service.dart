import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thing_note/features/record/domain/episode_record.dart';

/// 搜索建议类型
enum SuggestionType {
  recentSearch,    // 最近搜索
  thingName,      // 事情名称
  tag,            // 标签
  note,           // 笔记关键词
  dateRange,      // 日期范围
}

/// 搜索建议数据模型
class SearchSuggestion {
  final String text;
  final SuggestionType type;
  final String? subtitle;
  final int? count; // 相关记录数量
  final DateTime? lastUsed;

  SearchSuggestion({
    required this.text,
    required this.type,
    this.subtitle,
    this.count,
    this.lastUsed,
  });

  Map<String, dynamic> toJson() => {
        'text': text,
        'type': type.index,
        'subtitle': subtitle,
        'count': count,
        'lastUsed': lastUsed?.toIso8601String(),
      };

  factory SearchSuggestion.fromJson(Map<String, dynamic> json) {
    return SearchSuggestion(
      text: json['text'] as String,
      type: SuggestionType.values[json['type'] as int],
      subtitle: json['subtitle'] as String?,
      count: json['count'] as int?,
      lastUsed: json['lastUsed'] != null
          ? DateTime.parse(json['lastUsed'] as String)
          : null,
    );
  }
}

/// 智能搜索建议服务
class SmartSearchSuggestionService {
  static const _keyRecentSearches = 'recent_searches';
  static const _maxRecentSearches = 20;

  final SharedPreferences _prefs;

  SmartSearchSuggestionService(this._prefs);

  /// 保存搜索记录
  Future<void> saveSearch(String query) async {
    if (query.trim().isEmpty) return;

    final history = await getRecentSearches();
    history.removeWhere((h) => h.toLowerCase() == query.toLowerCase());
    history.insert(0, query);
    if (history.length > _maxRecentSearches) {
      history.removeRange(_maxRecentSearches, history.length);
    }
    await _prefs.setString(_keyRecentSearches, jsonEncode(history));
  }

  /// 获取最近搜索
  Future<List<String>> getRecentSearches() async {
    final jsonStr = _prefs.getString(_keyRecentSearches);
    if (jsonStr == null) return [];
    try {
      final list = jsonDecode(jsonStr) as List;
      return list.cast<String>();
    } catch (_) {
      return [];
    }
  }

  /// 清除搜索历史
  Future<void> clearSearchHistory() async {
    await _prefs.remove(_keyRecentSearches);
  }

  /// 获取搜索历史（带时间戳）
  Future<List<SearchSuggestion>> getSearchHistoryWithTime() async {
    final searches = await getRecentSearches();
    final now = DateTime.now();

    return searches.asMap().entries.map((entry) {
      // 假设每条搜索间隔5分钟，用于估算时间
      final estimatedTime = now.subtract(Duration(minutes: (entry.key + 1) * 5));
      return SearchSuggestion(
        text: entry.value,
        type: SuggestionType.recentSearch,
        lastUsed: estimatedTime,
      );
    }).toList();
  }

  /// 从记录中提取建议
  Future<List<SearchSuggestion>> generateSuggestionsFromRecords(
    List<EpisodeRecord> records, {
    int limit = 10,
  }) async {
    final suggestions = <SearchSuggestion>[];

    // 提取常用 thingName
    final thingNameCounts = <int?, int>{};
    for (final record in records) {
      thingNameCounts[record.thingNameId] = (thingNameCounts[record.thingNameId] ?? 0) + 1;
    }

    final sortedThingNames = thingNameCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    for (final entry in sortedThingNames.take(5)) {
      if (entry.key != null) {
        suggestions.add(SearchSuggestion(
          text: 'thing:${entry.key}',
          type: SuggestionType.thingName,
          count: entry.value,
          subtitle: '${entry.value} records',
        ));
      }
    }

    // 提取常用关键词
    final wordCounts = <String, int>{};
    final stopWords = {'的', '了', '在', '是', '我', '有', '和', '就', '不', '人', '都', '一', '一个', '上', '也', '很', '到', '说', '要', '去', '你', '会', '着', '没有', '看', '好', '自己', '这', 'the', 'a', 'an', 'is', 'it', 'and', 'or', 'but'};

    for (final record in records) {
      if (record.note.isNotEmpty) {
        final words = record.note.split(RegExp(r'[\s,，.。!！?？]+'));
        for (final word in words) {
          final trimmed = word.trim();
          if (trimmed.length >= 2 && !stopWords.contains(trimmed.toLowerCase())) {
            wordCounts[trimmed] = (wordCounts[trimmed] ?? 0) + 1;
          }
        }
      }
    }

    final sortedWords = wordCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    for (final entry in sortedWords.take(5)) {
      suggestions.add(SearchSuggestion(
        text: entry.key,
        type: SuggestionType.note,
        count: entry.value,
        subtitle: '${entry.value} times',
      ));
    }

    return suggestions.take(limit).toList();
  }

  /// 获取智能建议（合并最近搜索和建议）
  Future<List<SearchSuggestion>> getSmartSuggestions(
    List<EpisodeRecord> records, {
    int limit = 10,
  }) async {
    final suggestions = <SearchSuggestion>[];

    // 添加最近搜索
    final recentSearches = await getSearchHistoryWithTime();
    suggestions.addAll(recentSearches.take(5));

    // 添加从记录生成的建议
    final recordSuggestions = await generateSuggestionsFromRecords(records, limit: limit);
    for (final suggestion in recordSuggestions) {
      // 避免重复
      if (!suggestions.any((s) => s.text.toLowerCase() == suggestion.text.toLowerCase())) {
        suggestions.add(suggestion);
      }
    }

    // 添加日期快捷方式
    suggestions.addAll([
      SearchSuggestion(
        text: 'today',
        type: SuggestionType.dateRange,
        subtitle: 'Records from today',
      ),
      SearchSuggestion(
        text: 'yesterday',
        type: SuggestionType.dateRange,
        subtitle: 'Records from yesterday',
      ),
      SearchSuggestion(
        text: 'this week',
        type: SuggestionType.dateRange,
        subtitle: 'Records from this week',
      ),
      SearchSuggestion(
        text: 'this month',
        type: SuggestionType.dateRange,
        subtitle: 'Records from this month',
      ),
    ]);

    return suggestions.take(limit).toList();
  }

  /// 解析搜索查询中的特殊语法
  SearchQuery parseQuery(String query) {
    final parsed = SearchQuery(query: query);

    // 检查 thingName 语法
    final thingNameMatch = RegExp(r'thing:(\d+)').firstMatch(query);
    if (thingNameMatch != null) {
      parsed.thingNameId = int.tryParse(thingNameMatch.group(1)!);
      parsed.query = query.replaceFirst(thingNameMatch.group(0)!, '').trim();
    }

    // 检查 tag 语法
    final tagMatch = RegExp(r'tag:(\w+)').firstMatch(query);
    if (tagMatch != null) {
      parsed.tagName = tagMatch.group(1);
      parsed.query = query.replaceFirst(tagMatch.group(0)!, '').trim();
    }

    // 检查日期语法
    final dateMatch = RegExp(r'from:(\d{4}-\d{2}-\d{2})').firstMatch(query);
    if (dateMatch != null) {
      parsed.dateFrom = DateTime.tryParse(dateMatch.group(1)!);
      parsed.query = query.replaceFirst(dateMatch.group(0)!, '').trim();
    }

    final dateToMatch = RegExp(r'to:(\d{4}-\d{2}-\d{2})').firstMatch(query);
    if (dateToMatch != null) {
      parsed.dateTo = DateTime.tryParse(dateToMatch.group(1)!);
      parsed.query = query.replaceFirst(dateToMatch.group(0)!, '').trim();
    }

    // 检查快捷日期
    if (query.contains('today')) {
      final now = DateTime.now();
      parsed.dateFrom = DateTime(now.year, now.month, now.day);
      parsed.dateTo = now;
      parsed.query = query.replaceAll('today', '').trim();
    } else if (query.contains('yesterday')) {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      parsed.dateFrom = DateTime(yesterday.year, yesterday.month, yesterday.day);
      parsed.dateTo = DateTime(yesterday.year, yesterday.month, yesterday.day, 23, 59, 59);
      parsed.query = query.replaceAll('yesterday', '').trim();
    } else if (query.contains('this week')) {
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      parsed.dateFrom = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
      parsed.dateTo = now;
      parsed.query = query.replaceAll('this week', '').trim();
    } else if (query.contains('this month')) {
      final now = DateTime.now();
      parsed.dateFrom = DateTime(now.year, now.month, 1);
      parsed.dateTo = now;
      parsed.query = query.replaceAll('this month', '').trim();
    }

    // 检查收藏筛选
    parsed.hasFavorite = query.contains('star:yes') || query.contains('favorite:true');
    parsed.query = parsed.query.replaceAll(RegExp(r'star:(yes|no)'), '').trim();
    parsed.query = parsed.query.replaceAll(RegExp(r'favorite:(true|false)'), '').trim();

    // 检查提醒筛选
    parsed.hasReminder = query.contains('reminder:yes');
    parsed.query = parsed.query.replaceAll('reminder:yes', '').trim();

    // 检查媒体筛选
    if (query.contains('has:photo')) {
      parsed.hasMedia = true;
      parsed.mediaType = 'photo';
      parsed.query = query.replaceAll('has:photo', '').trim();
    } else if (query.contains('has:audio')) {
      parsed.hasMedia = true;
      parsed.mediaType = 'audio';
      parsed.query = query.replaceAll('has:audio', '').trim();
    } else if (query.contains('has:video')) {
      parsed.hasMedia = true;
      parsed.mediaType = 'video';
      parsed.query = query.replaceAll('has:video', '').trim();
    }

    return parsed;
  }
}

/// 解析后的搜索查询
class SearchQuery {
  String query;
  int? thingNameId;
  String? tagName;
  DateTime? dateFrom;
  DateTime? dateTo;
  bool? hasFavorite;
  bool? hasReminder;
  bool? hasMedia;
  String? mediaType;

  SearchQuery({
    required this.query,
    this.thingNameId,
    this.tagName,
    this.dateFrom,
    this.dateTo,
    this.hasFavorite,
    this.hasReminder,
    this.hasMedia,
    this.mediaType,
  });
}