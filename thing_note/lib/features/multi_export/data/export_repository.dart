import 'package:sqflite/sqflite.dart';
import 'package:thing_note/features/multi_export/domain/export_config.dart';

class ExportRepository {
  final Database db;

  ExportRepository(this.db);

  Future<List<ExportTemplate>> getAllTemplates() async {
    final maps = await db.query(
      'export_templates',
      orderBy: 'created_at DESC',
    );
    return maps.map((m) => ExportTemplate.fromMap(m)).toList();
  }

  Future<int> saveTemplate(ExportTemplate template) async {
    return await db.insert('export_templates', template.toMap());
  }

  Future<int> deleteTemplate(int id) async {
    return await db.delete(
      'export_templates',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> getRecordsForExport(ExportConfig config) async {
    String whereClause = '1=1';
    final List<dynamic> whereArgs = [];

    if (config.startDate != null) {
      whereClause += ' AND occurred_at >= ?';
      whereArgs.add(config.startDate!.toIso8601String());
    }

    if (config.endDate != null) {
      whereClause += ' AND occurred_at <= ?';
      whereArgs.add(config.endDate!.toIso8601String());
    }

    if (config.recordIds != null && config.recordIds!.isNotEmpty) {
      final placeholders = config.recordIds!.map((_) => '?').join(',');
      whereClause += ' AND id IN ($placeholders)';
      whereArgs.addAll(config.recordIds!);
    }

    return await db.query(
      'episode_records',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'occurred_at DESC',
    );
  }

  Future<Map<String, dynamic>> getRecordTags(int recordId) async {
    final maps = await db.rawQuery('''
      SELECT GROUP_CONCAT(tag_name) as tags
      FROM record_tags
      WHERE record_id = ?
    ''', [recordId]);

    return {
      'record_id': recordId,
      'tags': maps.isNotEmpty ? (maps.first['tags'] as String?)?.split(',') ?? [] : [],
    };
  }

  Future<List<Map<String, dynamic>>> getAllTags() async {
    return await db.rawQuery('SELECT DISTINCT tag_name FROM record_tags ORDER BY tag_name');
  }
}