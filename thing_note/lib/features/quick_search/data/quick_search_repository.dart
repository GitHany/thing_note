import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';
import 'package:thing_note/features/quick_search/domain/quick_search_entry.dart';

final quickSearchRepositoryProvider = Provider<QuickSearchRepository>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return QuickSearchRepository(dbAsync);
});

class QuickSearchRepository {
  final AsyncValue<Database> _dbAsync;

  QuickSearchRepository(this._dbAsync);

  Future<Database> get _db async {
    final db = _dbAsync.value;
    if (db == null) throw Exception('Database not initialized');
    return db;
  }

  Future<int> saveSearch(String query, int resultCount) async {
    final db = await _db;
    final entry = QuickSearchEntry(
      query: query,
      resultCount: resultCount,
      searchedAt: DateTime.now(),
    );
    return await db.insert('quick_search_history', entry.toMap());
  }

  Future<List<QuickSearchEntry>> getRecentSearches(int limit) async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      'quick_search_history',
      orderBy: 'searched_at DESC',
      limit: limit,
    );
    return maps.map((map) => QuickSearchEntry.fromMap(map)).toList();
  }

  Future<List<String>> getSearchSuggestions(String prefix) async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT DISTINCT query FROM quick_search_history
      WHERE query LIKE ?
      ORDER BY searched_at DESC
      LIMIT 10
    ''', ['%$prefix%']);

    return maps.map((map) => map['query'] as String).toList();
  }

  Future<List<Map<String, dynamic>>> searchRecords(String query) async {
    final db = await _db;

    final records = await db.rawQuery('''
      SELECT 'record' as type, id, note as title, occurred_at as date
      FROM episode_records
      WHERE note LIKE ?
      LIMIT 50
    ''', ['%$query%']);

    final thingNames = await db.rawQuery('''
      SELECT 'thing' as type, id, name as title, created_at as date
      FROM thing_names
      WHERE name LIKE ?
      LIMIT 20
    ''', ['%$query%']);

    final tags = await db.rawQuery('''
      SELECT 'tag' as type, id, name as title, created_at as date
      FROM tags
      WHERE name LIKE ?
      LIMIT 20
    ''', ['%$query%']);

    final results = [...records, ...thingNames, ...tags];
    results.sort((a, b) => (b['date'] as String).compareTo(a['date'] as String));

    return results.take(50).toList();
  }

  Future<int> deleteSearch(int id) async {
    final db = await _db;
    return await db.delete(
      'quick_search_history',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> clearHistory() async {
    final db = await _db;
    return await db.delete('quick_search_history');
  }
}
