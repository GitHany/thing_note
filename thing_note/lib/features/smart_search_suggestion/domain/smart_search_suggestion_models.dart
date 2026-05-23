/// 智能搜索建议 - Smart Search Suggestion
/// 基于上下文的智能搜索建议
library;

/// 搜索建议
class SearchSuggestion {
  final String query;
  final SuggestionType type;
  final double confidence;
  final String? reason;
  final int useCount;
  final DateTime lastUsed;

  SearchSuggestion({
    required this.query,
    required this.type,
    required this.confidence,
    this.reason,
    this.useCount = 0,
    required this.lastUsed,
  });

  Map<String, dynamic> toMap() {
    return {
      'query': query,
      'type': type.name,
      'confidence': confidence,
      'reason': reason,
      'use_count': useCount,
      'last_used': lastUsed.toIso8601String(),
    };
  }

  factory SearchSuggestion.fromMap(Map<String, dynamic> map) {
    return SearchSuggestion(
      query: map['query'] as String,
      type: SuggestionType.values.firstWhere(
        (t) => t.name == (map['type'] as String? ?? 'history'),
        orElse: () => SuggestionType.history,
      ),
      confidence: (map['confidence'] as num?)?.toDouble() ?? 0.5,
      reason: map['reason'] as String?,
      useCount: (map['use_count'] as int?) ?? 0,
      lastUsed: DateTime.parse(map['last_used'] as String),
    );
  }
}

/// 建议类型
enum SuggestionType {
  history, // 搜索历史
  popular, // 热门搜索
  recent, // 最近相关
  smart, // 智能推荐
  tag, // 标签相关
  thing, // 事情相关
}

/// 搜索上下文
class SearchContext {
  final String? currentQuery;
  final DateTime? timeOfDay;
  final List<String> recentTags;
  final List<String> recentThingNames;
  final String? location;

  SearchContext({
    this.currentQuery,
    this.timeOfDay,
    this.recentTags = const [],
    this.recentThingNames = const [],
    this.location,
  });
}

/// 搜索趋势
class SearchTrend {
  final String query;
  final int searchCount;
  final double trendScore; // 上升/下降趋势
  final DateTime lastUpdated;

  SearchTrend({
    required this.query,
    required this.searchCount,
    required this.trendScore,
    required this.lastUpdated,
  });
}