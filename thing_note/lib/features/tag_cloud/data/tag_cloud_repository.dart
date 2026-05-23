import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';
import 'package:thing_note/features/tag_cloud/domain/tag_cloud_entry.dart';

final tagCloudRepositoryProvider = Provider<TagCloudRepository>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return TagCloudRepository(dbAsync);
});

class TagCloudRepository {
  final AsyncValue<Database> _dbAsync;

  TagCloudRepository(this._dbAsync);

  Future<Database> get _db async {
    final db = _dbAsync.value;
    if (db == null) throw Exception('Database not initialized');
    return db;
  }

  Future<void> syncFromTags() async {
    final db = await _db;

    final tagUsage = await db.rawQuery('''
      SELECT t.name, COUNT(rt.record_id) as usage_count, MAX(e.occurred_at) as last_used
      FROM tags t
      LEFT JOIN record_tags rt ON t.id = rt.tag_id
      LEFT JOIN episode_records e ON rt.record_id = e.id
      GROUP BY t.id
      ORDER BY usage_count DESC
    ''');

    for (final row in tagUsage) {
      final tagName = row['name'] as String;
      final usageCount = row['usage_count'] as int? ?? 0;
      final lastUsed = row['last_used'] as String?;

      final existing = await db.query(
        'tag_cloud',
        where: 'tag_name = ?',
        whereArgs: [tagName],
      );

      if (existing.isEmpty) {
        await db.insert('tag_cloud', {
          'tag_name': tagName,
          'usage_count': usageCount,
          'last_used': lastUsed,
          'created_at': DateTime.now().toIso8601String(),
        });
      } else {
        await db.update(
          'tag_cloud',
          {'usage_count': usageCount, 'last_used': lastUsed},
          where: 'tag_name = ?',
          whereArgs: [tagName],
        );
      }
    }
  }

  Future<List<TagCloudEntry>> getAll() async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      'tag_cloud',
      orderBy: 'usage_count DESC',
    );
    return maps.map((map) => TagCloudEntry.fromMap(map)).toList();
  }

  Future<List<TagCloudEntry>> getTop(int limit) async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      'tag_cloud',
      orderBy: 'usage_count DESC',
      limit: limit,
    );
    return maps.map((map) => TagCloudEntry.fromMap(map)).toList();
  }

  Future<int> getTotalTags() async {
    final db = await _db;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM tag_cloud');
    return result.first['count'] as int;
  }
}
