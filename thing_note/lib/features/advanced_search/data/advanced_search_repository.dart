import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/features/advanced_search/domain/search_filters.dart';
import 'package:thing_note/core/database/database_provider.dart';

final advancedSearchRepositoryProvider = Provider((ref) => AdvancedSearchRepository(ref: ref));

class AdvancedSearchRepository {
  final Ref _ref;

  AdvancedSearchRepository({required Ref ref}) : _ref = ref;

  Future<Database> get _db async {
    final db = await _ref.read(databaseProvider.future);
    return db;
  }

  Future<List<Map<String, dynamic>>> searchRecords(SearchFilters filters, {String? query}) async {
    final db = await _db;
    
    var whereClause = '1=1';
    final whereArgs = <dynamic>[];
    
    // Text search in note
    if (query != null && query.isNotEmpty) {
      whereClause += ' AND note LIKE ?';
      whereArgs.add('%$query%');
    }
    
    // Date range
    if (filters.startDate != null) {
      whereClause += ' AND occurred_at >= ?';
      whereArgs.add(filters.startDate!.toIso8601String());
    }
    if (filters.endDate != null) {
      whereClause += ' AND occurred_at <= ?';
      whereArgs.add(filters.endDate!.toIso8601String());
    }
    
    // Duration filters
    if (filters.minDuration != null) {
      whereClause += ' AND duration_sec >= ?';
      whereArgs.add(filters.minDuration! * 60); // Convert minutes to seconds
    }
    if (filters.maxDuration != null) {
      whereClause += ' AND duration_sec <= ?';
      whereArgs.add(filters.maxDuration! * 60);
    }
    
    // Media filters
    if (filters.hasPhoto == true) {
      whereClause += " AND photo_paths != '[]' AND photo_paths != ''";
    }
    if (filters.hasAudio == true) {
      whereClause += " AND audio_paths != '[]' AND audio_paths != ''";
    }
    if (filters.hasVideo == true) {
      whereClause += " AND video_paths != '[]' AND video_paths != ''";
    }
    if (filters.hasDocument == true) {
      whereClause += " AND document_paths != '[]' AND document_paths != ''";
    }
    
    // Location filter
    if (filters.hasLocation == true) {
      whereClause += ' AND latitude IS NOT NULL AND longitude IS NOT NULL';
    }
    
    // Favorite filter
    if (filters.isFavorite == true) {
      whereClause += ' AND is_favorite = 1';
    }
    
    // Build query
    final sql = '''
      SELECT r.*, tn.name as thing_name
      FROM episode_records r
      LEFT JOIN thing_names tn ON r.thing_name_id = tn.id
      WHERE $whereClause
      ORDER BY r.occurred_at DESC
    ''';
    
    final results = await db.rawQuery(sql, whereArgs);
    
    // Filter by thing name IDs (after join)
    var filteredResults = List<Map<String, dynamic>>.from(results);
    if (filters.thingNameIds.isNotEmpty) {
      filteredResults = filteredResults.where((r) {
        final thingNameId = r['thing_name_id'];
        if (thingNameId == null) return false;
        return filters.thingNameIds.contains(thingNameId as int);
      }).toList();
    }
    
    // Filter by tags
    if (filters.tagIds.isNotEmpty) {
      final recordIds = filteredResults.map((r) => r['id'] as int).toList();
      final taggedRecords = await db.rawQuery('''
        SELECT DISTINCT record_id FROM record_tags
        WHERE record_id IN (${recordIds.map((_) => '?').join(',')})
        AND tag_id IN (${filters.tagIds.map((_) => '?').join(',')})
      ''', [...recordIds, ...filters.tagIds]);
      
      final validIds = taggedRecords.map((r) => r['record_id'] as int).toSet();
      filteredResults = filteredResults.where((r) => validIds.contains(r['id'] as int)).toList();
    }
    
    return filteredResults;
  }

  Future<void> saveSearchHistory(SearchHistoryEntry entry) async {
    final db = await _db;
    await db.insert('search_history', entry.toMap());
  }

  Future<List<SearchHistoryEntry>> getSearchHistory({int limit = 20}) async {
    final db = await _db;
    final results = await db.query(
      'search_history',
      orderBy: 'searched_at DESC',
      limit: limit,
    );
    return results.map((e) => SearchHistoryEntry.fromMap(e)).toList();
  }

  Future<void> clearSearchHistory() async {
    final db = await _db;
    await db.delete('search_history');
  }

  Future<void> deleteSearchHistoryEntry(int id) async {
    final db = await _db;
    await db.delete('search_history', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> saveSavedFilter(SavedFilter filter) async {
    final db = await _db;
    return await db.insert('saved_filters', {
      'name': filter.name,
      'filters_json': jsonEncode(_filtersToMap(filter.filters)),
      'created_at': filter.createdAt.toIso8601String(),
    });
  }

  Future<List<SavedFilter>> getSavedFilters() async {
    final db = await _db;
    final results = await db.query('saved_filters', orderBy: 'created_at DESC');
    return results.map((e) => SavedFilter(
      id: e['id'] as int?,
      name: e['name'] as String,
      filters: _mapToFilters(e['filters_json'] as String),
      createdAt: DateTime.parse(e['created_at'] as String),
    )).toList();
  }

  Future<void> deleteSavedFilter(int id) async {
    final db = await _db;
    await db.delete('saved_filters', where: 'id = ?', whereArgs: [id]);
  }

  Map<String, dynamic> _filtersToMap(SearchFilters filters) {
    return {
      'startDate': filters.startDate?.toIso8601String(),
      'endDate': filters.endDate?.toIso8601String(),
      'thingNameIds': filters.thingNameIds,
      'tagIds': filters.tagIds,
      'minDuration': filters.minDuration,
      'maxDuration': filters.maxDuration,
      'hasPhoto': filters.hasPhoto,
      'hasAudio': filters.hasAudio,
      'hasVideo': filters.hasVideo,
      'hasDocument': filters.hasDocument,
      'hasLocation': filters.hasLocation,
      'isFavorite': filters.isFavorite,
      'keywords': filters.keywords,
    };
  }

  SearchFilters _mapToFilters(String jsonStr) {
    try {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return SearchFilters(
        startDate: map['startDate'] != null ? DateTime.parse(map['startDate'] as String) : null,
        endDate: map['endDate'] != null ? DateTime.parse(map['endDate'] as String) : null,
        thingNameIds: (map['thingNameIds'] as List?)?.cast<int>() ?? [],
        tagIds: (map['tagIds'] as List?)?.cast<int>() ?? [],
        minDuration: map['minDuration'] as int?,
        maxDuration: map['maxDuration'] as int?,
        hasPhoto: map['hasPhoto'] as bool?,
        hasAudio: map['hasAudio'] as bool?,
        hasVideo: map['hasVideo'] as bool?,
        hasDocument: map['hasDocument'] as bool?,
        hasLocation: map['hasLocation'] as bool?,
        isFavorite: map['isFavorite'] as bool?,
        keywords: (map['keywords'] as List?)?.cast<String>() ?? [],
      );
    } catch (e) {
      return SearchFilters();
    }
  }

  /// Get search suggestions based on history
  Future<List<String>> getSuggestions(String query) async {
    final db = await _db;
    final results = await db.rawQuery('''
      SELECT DISTINCT query FROM search_history
      WHERE query LIKE ?
      ORDER BY searched_at DESC
      LIMIT 10
    ''', ['%$query%']);
    return results.map((e) => e['query'] as String).toList();
  }
}