import 'package:sqflite/sqflite.dart';
import 'package:thing_note/features/tag/domain/tag.dart';
import 'package:thing_note/features/tag/domain/tag_repository.dart';

class TagRepositoryImpl implements TagRepository {
  final Database db;

  TagRepositoryImpl(this.db);

  @override
  Future<List<Tag>> getAllTags() async {
    final rows = await db.query('tags', orderBy: 'name ASC');
    return rows.map((row) => Tag.fromMap(row)).toList();
  }

  @override
  Future<Tag?> getTagById(int id) async {
    final rows = await db.query('tags', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Tag.fromMap(rows.first);
  }

  @override
  Future<int> createTag(Tag tag) async {
    return await db.insert('tags', tag.toMap());
  }

  @override
  Future<void> updateTag(Tag tag) async {
    await db.update(
      'tags',
      tag.toMap(),
      where: 'id = ?',
      whereArgs: [tag.id],
    );
  }

  @override
  Future<void> deleteTag(int id) async {
    await db.delete('tags', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<List<Tag>> getTagsForRecord(int recordId) async {
    final rows = await db.rawQuery('''
      SELECT t.* FROM tags t
      INNER JOIN record_tags rt ON t.id = rt.tag_id
      WHERE rt.record_id = ?
      ORDER BY t.name ASC
    ''', [recordId]);
    return rows.map((row) => Tag.fromMap(row)).toList();
  }

  @override
  Future<void> setTagsForRecord(int recordId, List<int> tagIds) async {
    await db.delete('record_tags', where: 'record_id = ?', whereArgs: [recordId]);
    if (tagIds.isEmpty) return;
    final batch = db.batch();
    for (final tagId in tagIds) {
      batch.insert('record_tags', {
        'record_id': recordId,
        'tag_id': tagId,
      });
    }
    await batch.commit(noResult: true);
  }

  @override
  Future<void> addTagToRecord(int recordId, int tagId) async {
    await db.insert(
      'record_tags',
      {'record_id': recordId, 'tag_id': tagId},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  @override
  Future<void> removeTagFromRecord(int recordId, int tagId) async {
    await db.delete(
      'record_tags',
      where: 'record_id = ? AND tag_id = ?',
      whereArgs: [recordId, tagId],
    );
  }

  @override
  Future<Map<int, List<Tag>>> getTagsForRecords(List<int> recordIds) async {
    if (recordIds.isEmpty) return {};
    
    // Use SQL GROUP_CONCAT for efficient batch retrieval
    final rows = await db.rawQuery('''
      SELECT rt.record_id, t.* FROM tags t
      INNER JOIN record_tags rt ON t.id = rt.tag_id
      WHERE rt.record_id IN (${recordIds.map((_) => '?').join(',')})
      ORDER BY rt.record_id, t.name ASC
    ''', recordIds);
    
    final result = <int, List<Tag>>{};
    for (final row in rows) {
      final recordId = row['record_id'] as int;
      result.putIfAbsent(recordId, () => []);
      result[recordId]!.add(Tag.fromMap(row));
    }
    return result;
  }
}