import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';
import '../domain/smart_search_suggestion_models.dart';

/// 智能搜索建议服务提供者
final smartSearchSuggestionServiceProvider = Provider<SmartSearchSuggestionService>((ref) {
  return SmartSearchSuggestionService(ref.read(databaseProvider.future));
});

/// 智能搜索建议服务
class SmartSearchSuggestionService {
  final Future<Database> _db;

  SmartSearchSuggestionService(this._db);

  /// 获取搜索建议
  Future<List<SearchSuggestion>> getSuggestions({
    String? currentQuery,
    int limit = 10,
  }) async {
    final suggestions = <SearchSuggestion>[];

    // 1. 获取搜索历史
    final historySuggestions = await _getHistorySuggestions(limit: 5);
    suggestions.addAll(historySuggestions);

    // 2. 获取热门搜索
    final popularSuggestions = await _getPopularSuggestions(limit: 3);
    suggestions.addAll(popularSuggestions);

    // 3. 基于上下文的智能推荐
    if (currentQuery != null && currentQuery.isNotEmpty) {
      final contextSuggestions = await _getContextSuggestions(currentQuery, limit: 5);
      suggestions.addAll(contextSuggestions);
    }

    // 4. 标签相关建议
    final tagSuggestions = await _getTagSuggestions(limit: 3);
    suggestions.addAll(tagSuggestions);

    // 去重并按置信度排序
    final uniqueSuggestions = _deduplicateSuggestions(suggestions);
    uniqueSuggestions.sort((a, b) => b.confidence.compareTo(a.confidence));

    return uniqueSuggestions.take(limit).toList();
  }

  Future<List<SearchSuggestion>> _getHistorySuggestions({int limit = 5}) async {
    final db = await _db;

    final rows = await db.query(
      'search_history',
      orderBy: 'searched_at DESC',
      limit: limit,
    );

    if (rows.isEmpty) return [];

    return rows.map((row) {
      final useCount = row['result_count'] as int? ?? 0;
      return SearchSuggestion(
        query: row['query'] as String,
        type: SuggestionType.history,
        confidence: 0.8 + (useCount.clamp(0, 10) / 50),
        reason: '您之前搜索过',
        useCount: useCount,
        lastUsed: DateTime.parse(row['searched_at'] as String),
      );
    }).toList();
  }

  Future<List<SearchSuggestion>> _getPopularSuggestions({int limit = 3}) async {
    final db = await _db;

    final rows = await db.rawQuery('''
      SELECT query, COUNT(*) as count, MAX(searched_at) as last_used
      FROM search_history
      WHERE searched_at >= datetime('now', '-30 days')
      GROUP BY query
      ORDER BY count DESC
      LIMIT ?
    ''', [limit]);

    if (rows.isEmpty) return [];

    return rows.map((row) {
      final count = row['count'] as int;
      return SearchSuggestion(
        query: row['query'] as String,
        type: SuggestionType.popular,
        confidence: 0.7 + (count.clamp(0, 20) / 50),
        reason: '近期热门搜索',
        useCount: count,
        lastUsed: DateTime.parse(row['last_used'] as String),
      );
    }).toList();
  }

  Future<List<SearchSuggestion>> _getContextSuggestions(
    String currentQuery,
    {int limit = 5}
  ) async {
    final db = await _db;
    final suggestions = <SearchSuggestion>[];

    // 基于当前查询查找相似的记录关键词
    final records = await db.query(
      'episode_records',
      where: 'note LIKE ?',
      whereArgs: ['%$currentQuery%'],
      orderBy: 'created_at DESC',
      limit: 20,
    );

    // 提取关键词
    final keywords = <String, int>{};
    for (final record in records) {
      final note = record['note'] as String? ?? '';
      final words = note.split(RegExp(r'[\s,，。.!?]+'));
      for (final word in words) {
        if (word.length >= 2 && !word.contains(currentQuery)) {
          keywords[word] = (keywords[word] ?? 0) + 1;
        }
      }
    }

    // 排序并生成建议
    final sortedKeywords = keywords.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    for (final entry in sortedKeywords.take(limit)) {
      suggestions.add(SearchSuggestion(
        query: entry.key,
        type: SuggestionType.smart,
        confidence: 0.5 + (entry.value / 10 * 0.3),
        reason: '与 "$currentQuery" 相关',
        lastUsed: DateTime.now(),
      ));
    }

    return suggestions;
  }

  Future<List<SearchSuggestion>> _getTagSuggestions({int limit = 3}) async {
    final db = await _db;

    final rows = await db.rawQuery('''
      SELECT tag_name, COUNT(*) as count, MAX(added_at) as last_used
      FROM record_tags
      WHERE added_at >= datetime('now', '-7 days')
      GROUP BY tag_name
      ORDER BY count DESC
      LIMIT ?
    ''', [limit]);

    if (rows.isEmpty) return [];

    return rows.map((row) {
      return SearchSuggestion(
        query: row['tag_name'] as String,
        type: SuggestionType.tag,
        confidence: 0.6,
        reason: '最近常用的标签',
        useCount: row['count'] as int,
        lastUsed: DateTime.parse(row['last_used'] as String),
      );
    }).toList();
  }

  List<SearchSuggestion> _deduplicateSuggestions(List<SearchSuggestion> suggestions) {
    final unique = <String, SearchSuggestion>{};

    for (final suggestion in suggestions) {
      if (!unique.containsKey(suggestion.query) ||
          unique[suggestion.query]!.confidence < suggestion.confidence) {
        unique[suggestion.query] = suggestion;
      }
    }

    return unique.values.toList();
  }

  /// 记录搜索
  Future<void> recordSearch(String query, int resultCount) async {
    final db = await _db;

    // 更新或插入搜索历史
    final existing = await db.query(
      'search_history',
      where: 'query = ?',
      whereArgs: [query],
    );

    if (existing.isNotEmpty) {
      await db.update(
        'search_history',
        {
          'searched_at': DateTime.now().toIso8601String(),
          'result_count': resultCount,
        },
        where: 'query = ?',
        whereArgs: [query],
      );
    } else {
      await db.insert('search_history', {
        'query': query,
        'searched_at': DateTime.now().toIso8601String(),
        'result_count': resultCount,
      });
    }

    // 清理旧记录（保留最近100条）
    await db.rawDelete('''
      DELETE FROM search_history
      WHERE id NOT IN (
        SELECT id FROM search_history
        ORDER BY searched_at DESC
        LIMIT 100
      )
    ''');
  }

  /// 获取搜索趋势
  Future<List<SearchTrend>> getTrends({int days = 7}) async {
    final db = await _db;

    final rows = await db.rawQuery('''
      SELECT 
        query,
        COUNT(*) as count,
        MAX(searched_at) as last_updated
      FROM search_history
      WHERE searched_at >= datetime('now', '-$days days')
      GROUP BY query
      ORDER BY count DESC
      LIMIT 10
    ''');

    return rows.map((row) {
      return SearchTrend(
        query: row['query'] as String,
        searchCount: row['count'] as int,
        trendScore: 0, // 简化实现
        lastUpdated: DateTime.parse(row['last_updated'] as String),
      );
    }).toList();
  }

  /// 清除搜索历史
  Future<void> clearHistory() async {
    final db = await _db;
    await db.delete('search_history');
  }

  /// 获取保存的搜索
  Future<List<Map<String, dynamic>>> getSavedSearches() async {
    final db = await _db;
    return db.query('saved_searches', orderBy: 'use_count DESC');
  }

  /// 保存搜索
  Future<void> saveSearch(String name, String query) async {
    final db = await _db;

    // 检查是否已存在
    final existing = await db.query(
      'saved_searches',
      where: 'query = ?',
      whereArgs: [query],
    );

    if (existing.isNotEmpty) {
      await db.update(
        'saved_searches',
        {'use_count': (existing.first['use_count'] as int) + 1},
        where: 'query = ?',
        whereArgs: [query],
      );
    } else {
      await db.insert('saved_searches', {
        'name': name,
        'query': query,
        'created_at': DateTime.now().toIso8601String(),
      });
    }
  }
}