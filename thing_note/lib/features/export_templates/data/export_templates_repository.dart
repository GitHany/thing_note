import 'package:sqflite/sqflite.dart';
import 'package:thing_note/features/export_templates/domain/export_template_model.dart';

/// Repository for Export Templates data operations
class ExportTemplatesRepository {
  final Database db;

  ExportTemplatesRepository(this.db);

  /// Create an export template
  Future<int> createTemplate(ExportTemplate template) async {
    return await db.insert('export_templates', template.toMap());
  }

  /// Update an export template
  Future<int> updateTemplate(ExportTemplate template) async {
    return await db.update(
      'export_templates',
      template.toMap(),
      where: 'id = ?',
      whereArgs: [template.id],
    );
  }

  /// Delete an export template
  Future<int> deleteTemplate(int id) async {
    return await db.delete(
      'export_templates',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Get all templates
  Future<List<ExportTemplate>> getAllTemplates() async {
    final List<Map<String, dynamic>> maps = await db.query(
      'export_templates',
      orderBy: 'name ASC',
    );
    return maps.map((map) => ExportTemplate.fromMap(map)).toList();
  }

  /// Get template by ID
  Future<ExportTemplate?> getTemplateById(int id) async {
    final List<Map<String, dynamic>> maps = await db.query(
      'export_templates',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return ExportTemplate.fromMap(maps.first);
  }

  /// Get templates by format
  Future<List<ExportTemplate>> getTemplatesByFormat(String format) async {
    final List<Map<String, dynamic>> maps = await db.query(
      'export_templates',
      where: 'format = ?',
      whereArgs: [format],
      orderBy: 'name ASC',
    );
    return maps.map((map) => ExportTemplate.fromMap(map)).toList();
  }

  /// Create default templates if none exist
  Future<void> createDefaultTemplates() async {
    final existing = await getAllTemplates();
    if (existing.isNotEmpty) return;

    final defaults = [
      ExportTemplate(
        name: '完整导出',
        format: 'json',
        includePhotos: true,
        includeAudio: true,
        includeLocation: true,
        includeTags: true,
        includeDuration: true,
        includeAnnotations: true,
      ),
      ExportTemplate(
        name: '简洁 CSV',
        format: 'csv',
        includePhotos: false,
        includeAudio: false,
        includeLocation: true,
        includeTags: true,
        includeDuration: true,
        includeAnnotations: false,
      ),
      ExportTemplate(
        name: 'Markdown 笔记',
        format: 'markdown',
        includePhotos: false,
        includeAudio: false,
        includeLocation: true,
        includeTags: true,
        includeDuration: false,
        includeAnnotations: true,
      ),
    ];

    for (final template in defaults) {
      await createTemplate(template);
    }
  }

  // ========== Export History Operations ==========

  /// Create export history entry
  Future<int> createHistoryEntry(ExportHistory history) async {
    return await db.insert('export_history', history.toMap());
  }

  /// Get export history
  Future<List<ExportHistory>> getHistory({int limit = 20}) async {
    final List<Map<String, dynamic>> maps = await db.query(
      'export_history',
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return maps.map((map) => ExportHistory.fromMap(map)).toList();
  }

  /// Get history by format
  Future<List<ExportHistory>> getHistoryByFormat(String format, {int limit = 10}) async {
    final List<Map<String, dynamic>> maps = await db.query(
      'export_history',
      where: 'format = ?',
      whereArgs: [format],
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return maps.map((map) => ExportHistory.fromMap(map)).toList();
  }

  /// Delete old history entries
  Future<int> deleteOldHistory({int daysOld = 90}) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
    return await db.delete(
      'export_history',
      where: 'created_at < ?',
      whereArgs: [cutoffDate.toIso8601String()],
    );
  }

  /// Get export statistics
  Future<Map<String, dynamic>> getStatistics() async {
    final totalExports = await db.rawQuery('SELECT COUNT(*) as count FROM export_history');
    final totalRecords = await db.rawQuery(
      'SELECT SUM(record_count) as total FROM export_history'
    );
    final byFormat = await db.rawQuery('''
      SELECT format, COUNT(*) as count 
      FROM export_history 
      GROUP BY format
    ''');

    return {
      'total_exports': (totalExports.first['count'] as int?) ?? 0,
      'total_records_exported': (totalRecords.first['total'] as int?) ?? 0,
      'by_format': byFormat,
    };
  }
}