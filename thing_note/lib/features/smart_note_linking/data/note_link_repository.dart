import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';
import 'package:thing_note/features/smart_note_linking/domain/note_link.dart';

final noteLinkRepositoryProvider = Provider<NoteLinkRepository>((ref) {
  return NoteLinkRepository(ref.watch(databaseProvider.future));
});

class NoteLinkRepository {
  final Future<Database> _dbFuture;

  NoteLinkRepository(this._dbFuture);

  Future<Database> get _db => _dbFuture;

  Future<List<NoteLink>> getAllLinks() async {
    final db = await _db;
    final results = await db.query('smart_note_links', orderBy: 'created_at DESC');
    return results.map((e) => NoteLink.fromMap(e)).toList();
  }

  Future<List<NoteLink>> getLinksForRecord(int recordId) async {
    final db = await _db;
    final results = await db.query(
      'smart_note_links',
      where: 'source_note_id = ? OR target_record_id = ?',
      whereArgs: [recordId, recordId],
      orderBy: 'strength_score DESC',
    );
    return results.map((e) => NoteLink.fromMap(e)).toList();
  }

  Future<int> insertLink(NoteLink link) async {
    final db = await _db;
    return await db.insert('smart_note_links', link.toMap()..remove('id'));
  }

  Future<int> deleteLink(int id) async {
    final db = await _db;
    return await db.delete('smart_note_links', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<NoteLink>> findSuggestedLinks(int recordId, Map<String, dynamic> recordData) async {
    final db = await _db;
    final suggestions = <NoteLink>[];

    final recordDate = DateTime.tryParse(recordData['occurred_at'] ?? '');
    final recordTags = recordData['annotations'] ?? '';
    final recordLocation = recordData['address'] ?? '';

    if (recordDate != null) {
      final startOfDay = recordDate.subtract(const Duration(hours: 2));
      final endOfDay = recordDate.add(const Duration(hours: 2));

      final timeMatches = await db.query(
        'episode_records',
        where: 'occurred_at BETWEEN ? AND ? AND id != ?',
        whereArgs: [startOfDay.toIso8601String(), endOfDay.toIso8601String(), recordId],
        limit: 5,
      );

      for (final match in timeMatches) {
        suggestions.add(NoteLink(
          sourceNoteId: recordId,
          targetRecordId: match['id'] as int,
          linkType: 'time',
          strengthScore: 0.8,
          linkBasis: '相近时间记录',
        ));
      }
    }

    if (recordTags.isNotEmpty) {
      final tagMatches = await db.query(
        'episode_records',
        where: 'annotations LIKE ? AND id != ?',
        whereArgs: ['%$recordTags%', recordId],
        limit: 3,
      );

      for (final match in tagMatches) {
        suggestions.add(NoteLink(
          sourceNoteId: recordId,
          targetRecordId: match['id'] as int,
          linkType: 'tag',
          strengthScore: 0.6,
          linkBasis: '共享标签',
        ));
      }
    }

    if (recordLocation.isNotEmpty) {
      final locationMatches = await db.query(
        'episode_records',
        where: 'address LIKE ? AND id != ?',
        whereArgs: ['%$recordLocation%', recordId],
        limit: 3,
      );

      for (final match in locationMatches) {
        suggestions.add(NoteLink(
          sourceNoteId: recordId,
          targetRecordId: match['id'] as int,
          linkType: 'location',
          strengthScore: 0.7,
          linkBasis: '相同位置',
        ));
      }
    }

    return suggestions;
  }

  Future<Map<int, double>> getLinkStatistics() async {
    final db = await _db;
    final results = await db.rawQuery('''
      SELECT target_record_id, COUNT(*) as link_count, AVG(strength_score) as avg_score
      FROM smart_note_links
      GROUP BY target_record_id
      ORDER BY link_count DESC
      LIMIT 10
    ''');

    return {
      for (final row in results)
        row['target_record_id'] as int: row['avg_score'] as double
    };
  }
}