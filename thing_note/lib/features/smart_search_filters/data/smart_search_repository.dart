import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';

final smartSearchRepositoryProvider = Provider<SmartSearchRepository>((ref) {
  // Pass the FutureProvider directly, not .future
  return SmartSearchRepository(ref.watch(databaseProvider.future));
});

class SmartSearchRepository {
  final Future<Database> _dbFuture;

  SmartSearchRepository(this._dbFuture);

  Future<Database> get _db => _dbFuture;

  Future<List<Map<String, dynamic>>> search(String query, {List<String>? filters}) async {
    final db = await _db;
    String whereClause = "note LIKE ?";
    List<dynamic> whereArgs = ['%$query%'];

    if (filters != null && filters.isNotEmpty) {
      for (final filter in filters) {
        whereClause += " AND $filter";
      }
    }

    return await db.query(
      'episode_records',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'occurred_at DESC',
      limit: 50,
    );
  }

  Future<List<Map<String, dynamic>>> fuzzySearch(String query) async {
    final db = await _db;
    final words = query.split('');

    String whereClause = words.map((w) => 'note LIKE ?').join(' OR ');
    List<dynamic> whereArgs = words.map((w) => '%$w%').toList();

    return await db.query(
      'episode_records',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'occurred_at DESC',
      limit: 50,
    );
  }

  Future<void> saveSearchQuery(String query) async {
    final db = await _db;
    await db.insert('search_history', {
      'query': query,
      'searched_at': DateTime.now().toIso8601String(),
      'result_count': 0,
    });
  }

  Future<List<String>> getRecentSearches() async {
    final db = await _db;
    final results = await db.rawQuery('''
      SELECT DISTINCT query FROM search_history
      ORDER BY searched_at DESC LIMIT 10
    ''');
    return results.map((r) => r['query'] as String).toList();
  }
}