import 'package:sqflite/sqflite.dart';
import 'package:thing_note/features/record_link_enhance/domain/record_link.dart';

class RecordLinkRepository {
  final Database db;

  RecordLinkRepository(this.db);

  Future<int> createLink(EnhancedRecordLink link) async {
    // Prevent duplicate links
    final existing = await db.query(
      'enhanced_record_links',
      where: 'source_record_id = ? AND target_record_id = ?',
      whereArgs: [link.sourceRecordId, link.targetRecordId],
    );
    if (existing.isNotEmpty) return existing.first['id'] as int;

    return await db.insert('enhanced_record_links', link.toMap());
  }

  Future<List<EnhancedRecordLink>> getLinksForRecord(int recordId) async {
    final maps = await db.query(
      'enhanced_record_links',
      where: 'source_record_id = ? OR target_record_id = ?',
      whereArgs: [recordId, recordId],
      orderBy: 'created_at DESC',
    );
    return maps.map((m) => EnhancedRecordLink.fromMap(m)).toList();
  }

  Future<List<EnhancedRecordLink>> getOutgoingLinks(int recordId) async {
    final maps = await db.query(
      'enhanced_record_links',
      where: 'source_record_id = ?',
      whereArgs: [recordId],
      orderBy: 'created_at DESC',
    );
    return maps.map((m) => EnhancedRecordLink.fromMap(m)).toList();
  }

  Future<List<EnhancedRecordLink>> getIncomingLinks(int recordId) async {
    final maps = await db.query(
      'enhanced_record_links',
      where: 'target_record_id = ?',
      whereArgs: [recordId],
      orderBy: 'created_at DESC',
    );
    return maps.map((m) => EnhancedRecordLink.fromMap(m)).toList();
  }

  Future<int> deleteLink(int id) async {
    return await db.delete(
      'enhanced_record_links',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteLinksForRecord(int recordId) async {
    return await db.delete(
      'enhanced_record_links',
      where: 'source_record_id = ? OR target_record_id = ?',
      whereArgs: [recordId, recordId],
    );
  }

  Future<List<LinkSuggestion>> suggestLinks(int recordId, {int limit = 10}) async {
    final records = await db.query(
      'episode_records',
      where: 'id != ?',
      whereArgs: [recordId],
      orderBy: 'occurred_at DESC',
      limit: 100,
    );

    if (records.isEmpty) return [];

    final sourceRecord = await db.query(
      'episode_records',
      where: 'id = ?',
      whereArgs: [recordId],
    );

    if (sourceRecord.isEmpty) return [];

    final source = sourceRecord.first;
    final sourceNote = (source['note'] as String? ?? '').toLowerCase();
    final sourceThingId = source['thing_name_id'];

    final suggestions = <LinkSuggestion>[];

    for (final target in records) {
      final targetNote = (target['note'] as String? ?? '').toLowerCase();
      final targetThingId = target['thing_name_id'];

      double similarity = 0;

      // Same thing name = high similarity
      if (sourceThingId != null && sourceThingId == targetThingId) {
        similarity += 3;
      }

      // Time proximity
      final sourceTime = DateTime.parse(source['occurred_at'] as String);
      final targetTime = DateTime.parse(target['occurred_at'] as String);
      final hourDiff = (sourceTime.difference(targetTime).inHours).abs();
      if (hourDiff < 2) similarity += 2;
      if (hourDiff < 24) similarity += 1;

      // Text similarity
      final words = sourceNote.split(RegExp(r'\s+'));
      for (final word in words) {
        if (word.length > 3 && targetNote.contains(word)) {
          similarity += 0.5;
        }
      }

      if (similarity > 1) {
        suggestions.add(LinkSuggestion(
          sourceRecordId: recordId,
          targetRecordId: target['id'] as int,
          similarityScore: similarity,
          reason: _generateReason(sourceNote, targetNote, sourceThingId == targetThingId),
          sourceNote: source['note'] as String? ?? '',
          targetNote: target['note'] as String? ?? '',
        ));
      }
    }

    suggestions.sort((a, b) => b.similarityScore.compareTo(a.similarityScore));
    return suggestions.take(limit).toList();
  }

  String _generateReason(String source, String target, bool sameThing) {
    if (sameThing) return 'Same event category';
    if (source.contains('meeting') || target.contains('meeting')) return 'Similar meeting content';
    if (source.contains('work') && target.contains('work')) return 'Work-related activity';
    return 'Content similarity';
  }

  Future<LinkStats> getStats() async {
    final total = await db.rawQuery('SELECT COUNT(*) as count FROM enhanced_record_links');
    final reference = await db.rawQuery("SELECT COUNT(*) as count FROM enhanced_record_links WHERE link_type = 'reference'");
    final parentChild = await db.rawQuery("SELECT COUNT(*) as count FROM enhanced_record_links WHERE link_type IN ('parent', 'child')");
    final related = await db.rawQuery("SELECT COUNT(*) as count FROM enhanced_record_links WHERE link_type = 'related'");

    return LinkStats(
      totalLinks: total.first['count'] as int? ?? 0,
      referenceLinks: reference.first['count'] as int? ?? 0,
      parentChildLinks: parentChild.first['count'] as int? ?? 0,
      relatedLinks: related.first['count'] as int? ?? 0,
    );
  }

  Future<Map<String, dynamic>> getRecordDetails(int recordId) async {
    final maps = await db.query(
      'episode_records',
      where: 'id = ?',
      whereArgs: [recordId],
    );
    if (maps.isEmpty) return {};
    return maps.first;
  }
}