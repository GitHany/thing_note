import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/features/quick_search_enhance/domain/search_config.dart';

class QuickSearchRepository {
  final Database db;

  QuickSearchRepository(this.db);

  Future<List<EnhancedSearchResult>> search(String query, {SearchFilter? filter, int limit = 50}) async {
    String whereClause = '1=1';
    final List<dynamic> whereArgs = [];

    if (query.isNotEmpty) {
      whereClause += ' AND (note LIKE ? OR address LIKE ?)';
      whereArgs.add('%$query%');
      whereArgs.add('%$query%');
    }

    if (filter?.startDate != null) {
      whereClause += ' AND occurred_at >= ?';
      whereArgs.add(filter!.startDate!.toIso8601String());
    }

    if (filter?.endDate != null) {
      whereClause += ' AND occurred_at <= ?';
      whereArgs.add(filter!.endDate!.toIso8601String());
    }

    if (filter?.thingNameIds.isNotEmpty ?? false) {
      final placeholders = filter!.thingNameIds.map((_) => '?').join(',');
      whereClause += ' AND thing_name_id IN ($placeholders)';
      whereArgs.addAll(filter.thingNameIds);
    }

    if (filter?.isFavorite == true) {
      whereClause += ' AND is_favorite = 1';
    }

    if (filter?.hasPhotos == true) {
      whereClause += " AND photo_paths != '[]' AND photo_paths != '[\"\" ]'";
    }

    if (filter?.hasAudio == true) {
      whereClause += " AND audio_paths != '[]'";
    }

    if (filter?.hasVideo == true) {
      whereClause += " AND video_paths != '[]'";
    }

    if (filter?.hasLocation == true) {
      whereClause += ' AND latitude IS NOT NULL';
    }

    final maps = await db.rawQuery('''
      SELECT r.*, tn.name as thing_name
      FROM episode_records r
      LEFT JOIN thing_names tn ON r.thing_name_id = tn.id
      WHERE $whereClause
      ORDER BY occurred_at DESC
      LIMIT ?
    ''', [...whereArgs, limit]);

    final results = <EnhancedSearchResult>[];
    for (final row in maps) {
      final tags = await getTagsForRecord(row['id'] as int);

      // Calculate relevance
      double relevance = 1.0;
      if (query.isNotEmpty) {
        final note = (row['note'] as String? ?? '').toLowerCase();
        final address = (row['address'] as String? ?? '').toLowerCase();
        final queryLower = query.toLowerCase();

        if (note.contains(queryLower) || address.contains(queryLower)) {
          relevance = 2.0;
        }
      }

      results.add(EnhancedSearchResult(
        recordId: row['id'] as int,
        note: row['note'] as String? ?? '',
        highlightedNote: _highlightQuery(row['note'] as String? ?? '', query),
        occurredAt: DateTime.parse(row['occurred_at'] as String),
        thingNameId: row['thing_name_id'] as int?,
        thingName: row['thing_name'] as String?,
        tags: tags,
        hasPhotos: _hasPhotos(row['photo_paths'] as String?),
        hasAudio: _hasAudio(row['audio_paths'] as String?),
        hasVideo: _hasVideo(row['video_paths'] as String?),
        hasLocation: row['latitude'] != null,
        isFavorite: (row['is_favorite'] as int?) == 1,
        relevanceScore: relevance,
      ));
    }

    // Filter by tags if specified
    if (filter?.tags.isNotEmpty ?? false) {
      return results.where((r) => filter!.tags.any((t) => r.tags.contains(t))).toList();
    }

    return results;
  }

  Future<List<String>> getTagsForRecord(int recordId) async {
    final maps = await db.rawQuery(
      'SELECT tag_name FROM record_tags WHERE record_id = ?',
      [recordId],
    );
    return maps.map((m) => m['tag_name'] as String).toList();
  }

  bool _hasPhotos(String? paths) {
    if (paths == null || paths == '[]') return false;
    try {
      final list = jsonDecode(paths) as List;
      return list.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  bool _hasAudio(String? paths) {
    if (paths == null || paths == '[]') return false;
    try {
      final list = jsonDecode(paths) as List;
      return list.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  bool _hasVideo(String? paths) {
    if (paths == null || paths == '[]') return false;
    try {
      final list = jsonDecode(paths) as List;
      return list.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  String _highlightQuery(String text, String query) {
    if (query.isEmpty) return text;
    // Simple highlight - in real implementation use proper regex
    return text;
  }

  // Search history
  Future<void> saveSearchHistory(SearchHistoryEntry entry) async {
    await db.insert('search_history', entry.toMap());
  }

  Future<List<SearchHistoryEntry>> getSearchHistory({int limit = 20}) async {
    final maps = await db.query(
      'search_history',
      orderBy: 'searched_at DESC',
      limit: limit,
    );
    return maps.map((m) => SearchHistoryEntry.fromMap(m)).toList();
  }

  Future<void> clearSearchHistory() async {
    await db.delete('search_history');
  }

  // Saved searches
  Future<void> saveSearch(SavedSearch search) async {
    await db.insert('saved_searches', search.toMap());
  }

  Future<List<SavedSearch>> getSavedSearches() async {
    final maps = await db.query(
      'saved_searches',
      orderBy: 'use_count DESC, created_at DESC',
    );
    return maps.map((m) => SavedSearch.fromMap(m)).toList();
  }

  Future<void> deleteSavedSearch(int id) async {
    await db.delete('saved_searches', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> incrementSearchUseCount(int id) async {
    await db.rawUpdate('UPDATE saved_searches SET use_count = use_count + 1 WHERE id = ?', [id]);
  }
}