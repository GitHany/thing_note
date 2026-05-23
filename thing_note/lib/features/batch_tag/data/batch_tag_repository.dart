import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';
import 'package:thing_note/features/batch_tag/domain/batch_tag.dart';

final batchTagRepositoryProvider = Provider<BatchTagRepository>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return BatchTagRepository(dbAsync);
});

class BatchTagRepository {
  final AsyncValue<Database> _dbAsync;

  BatchTagRepository(this._dbAsync);

  Future<Database> get _db async {
    final db = _dbAsync.value;
    if (db == null) throw Exception('Database not initialized');
    return db;
  }

  Future<Map<int, List<String>>> getRecordTags(List<int> recordIds) async {
    final db = await _db;
    final Map<int, List<String>> result = {};
    if (recordIds.isEmpty) return result;

    final placeholders = recordIds.map((_) => '?').join(',');
    final maps = await db.rawQuery(
      '''
      SELECT record_id, GROUP_CONCAT(tag_name, ',') as tags
      FROM record_tags
      WHERE record_id IN ($placeholders)
      GROUP BY record_id
      ''',
      recordIds,
    );

    for (final row in maps) {
      final recordId = row['record_id'] as int;
      final tagsStr = row['tags'] as String?;
      result[recordId] = tagsStr != null && tagsStr.isNotEmpty
          ? tagsStr.split(',')
          : [];
    }

    for (final id in recordIds) {
      result.putIfAbsent(id, () => []);
    }

    return result;
  }

  Future<void> addTagsToRecords(List<int> recordIds, List<String> tags) async {
    final db = await _db;
    final batch = db.batch();
    final now = DateTime.now().toIso8601String();

    for (final recordId in recordIds) {
      for (final tag in tags) {
        batch.insert(
          'record_tags',
          {
            'record_id': recordId,
            'tag_name': tag,
            'added_at': now,
          },
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
    }
    await batch.commit(noResult: true);
  }

  Future<void> removeTagsFromRecords(List<int> recordIds, List<String> tags) async {
    final db = await _db;
    if (recordIds.isEmpty || tags.isEmpty) return;

    final recordPlaceholders = recordIds.map((_) => '?').join(',');
    final tagPlaceholders = tags.map((_) => '?').join(',');

    await db.delete(
      'record_tags',
      where: 'record_id IN ($recordPlaceholders) AND tag_name IN ($tagPlaceholders)',
      whereArgs: [...recordIds, ...tags],
    );
  }

  Future<void> replaceTagsForRecords(List<int> recordIds, List<String> newTags) async {
    final db = await _db;
    await db.transaction((txn) async {
      final recordPlaceholders = recordIds.map((_) => '?').join(',');
      await txn.delete(
        'record_tags',
        where: 'record_id IN ($recordPlaceholders)',
        whereArgs: recordIds,
      );

      final now = DateTime.now().toIso8601String();
      final batch = txn.batch();
      for (final recordId in recordIds) {
        for (final tag in newTags) {
          batch.insert(
            'record_tags',
            {
              'record_id': recordId,
              'tag_name': tag,
              'added_at': now,
            },
          );
        }
      }
      await batch.commit(noResult: true);
    });
  }

  Future<void> saveOperation(BatchTagOperation operation) async {
    final db = await _db;
    await db.insert('batch_tag_operations', operation.toMap());
  }

  Future<List<BatchTagOperation>> getRecentOperations({int limit = 20}) async {
    final db = await _db;
    final maps = await db.query(
      'batch_tag_operations',
      orderBy: 'performed_at DESC',
      limit: limit,
    );
    return maps.map((m) => BatchTagOperation.fromMap(m)).toList();
  }

  Future<List<TagStatistics>> getTagStatistics() async {
    final db = await _db;
    final maps = await db.rawQuery('''
      SELECT tag_name, COUNT(*) as usage_count, MAX(added_at) as last_used
      FROM record_tags
      GROUP BY tag_name
      ORDER BY usage_count DESC
    ''');

    return maps.map((m) => TagStatistics(
      tagName: m['tag_name'] as String,
      usageCount: m['usage_count'] as int? ?? 0,
      lastUsed: m['last_used'] != null ? DateTime.parse(m['last_used'] as String) : null,
    )).toList();
  }

  Future<List<String>> getSuggestedTags(String query, {int limit = 10}) async {
    final db = await _db;
    final maps = await db.rawQuery('''
      SELECT DISTINCT tag_name FROM record_tags
      WHERE tag_name LIKE ?
      ORDER BY tag_name
      LIMIT ?
    ''', ['%$query%', limit]);

    return maps.map((m) => m['tag_name'] as String).toList();
  }
}
