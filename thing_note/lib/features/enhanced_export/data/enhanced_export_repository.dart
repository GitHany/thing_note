import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/features/enhanced_export/domain/export_models.dart';
import 'package:thing_note/core/database/database_provider.dart';

final enhancedExportRepositoryProvider = Provider((ref) => EnhancedExportRepository(ref));

class EnhancedExportRepository {
  final Ref _ref;

  EnhancedExportRepository(this._ref);

  Future<Database> get _db async {
    final db = await _ref.read(databaseProvider.future);
    return db;
  }

  Future<List<ExportTemplate>> getTemplates() async {
    final db = await _db;
    final results = await db.query('export_templates', orderBy: 'is_default DESC, created_at DESC');
    return results.map((e) => ExportTemplate.fromMap(e)).toList();
  }

  Future<int> saveTemplate(ExportTemplate template) async {
    final db = await _db;
    return await db.insert('export_templates', template.toMap());
  }

  Future<void> deleteTemplate(int id) async {
    final db = await _db;
    await db.delete('export_templates', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> setDefaultTemplate(int id) async {
    final db = await _db;
    await db.rawUpdate('UPDATE export_templates SET is_default = 0');
    await db.update('export_templates', {'is_default': 1}, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getRecordsForExport(ExportConfig config) async {
    final db = await _db;
    
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
      whereClause += ' AND id IN (${config.recordIds!.map((_) => '?').join(',')})';
      whereArgs.addAll(config.recordIds!);
    }
    
    return await db.rawQuery('''
      SELECT r.*, tn.name as thing_name
      FROM episode_records r
      LEFT JOIN thing_names tn ON r.thing_name_id = tn.id
      WHERE $whereClause
      ORDER BY r.occurred_at DESC
    ''', whereArgs);
  }

  Future<String> exportToCSV(List<Map<String, dynamic>> records, {String? fileName}) async {
    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${dir.path}/export_$timestamp.csv');
    
    final buffer = StringBuffer();
    
    // Header
    buffer.writeln('日期,时间,事件名称,时长(分钟),备注,标签,位置');
    
    // Data rows
    for (final record in records) {
      final occurredAt = DateTime.parse(record['occurred_at'] as String);
      final date = '${occurredAt.year}-${occurredAt.month.toString().padLeft(2, '0')}-${occurredAt.day.toString().padLeft(2, '0')}';
      final time = '${occurredAt.hour}:${occurredAt.minute.toString().padLeft(2, '0')}';
      final thingName = record['thing_name'] ?? '';
      final duration = (record['duration_sec'] as int? ?? 0) ~/ 60;
      final note = (record['note'] as String? ?? '').replaceAll(',', ';').replaceAll('\n', ' ');
      final location = record['address'] ?? '';
      
      buffer.writeln('$date,$time,$thingName,$duration,"$note",,$location');
    }
    
    await file.writeAsString(buffer.toString());
    return file.path;
  }

  Future<String> exportToJSON(List<Map<String, dynamic>> records, {String? fileName}) async {
    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${dir.path}/export_$timestamp.json');
    
    final exportData = records.map((r) {
      final occurredAt = DateTime.parse(r['occurred_at'] as String);
      return {
        'id': r['id'],
        'date': '${occurredAt.year}-${occurredAt.month.toString().padLeft(2, '0')}-${occurredAt.day.toString().padLeft(2, '0')}',
        'time': '${occurredAt.hour}:${occurredAt.minute.toString().padLeft(2, '0')}',
        'thingName': r['thing_name'] ?? '',
        'durationMinutes': (r['duration_sec'] as int? ?? 0) ~/ 60,
        'note': r['note'] ?? '',
        'address': r['address'] ?? '',
        'createdAt': r['created_at'],
      };
    }).toList();
    
    final jsonStr = '''
{
  "exportDate": "${DateTime.now().toIso8601String()}",
  "recordCount": ${records.length},
  "records": ${exportData.map((e) => e.toString()).join(',')}
}
''';
    
    await file.writeAsString(jsonStr);
    return file.path;
  }

  Future<String> exportToMarkdown(List<Map<String, dynamic>> records, {String? fileName}) async {
    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${dir.path}/export_$timestamp.md');
    
    final buffer = StringBuffer();
    buffer.writeln('# 活动记录导出');
    buffer.writeln('');
    buffer.writeln('**导出时间**: ${DateTime.now().toIso8601String()}');
    buffer.writeln('**记录数量**: ${records.length}');
    buffer.writeln('');
    buffer.writeln('---');
    buffer.writeln('');
    
    for (final record in records) {
      final occurredAt = DateTime.parse(record['occurred_at'] as String);
      final date = '${occurredAt.year}-${occurredAt.month.toString().padLeft(2, '0')}-${occurredAt.day.toString().padLeft(2, '0')}';
      final time = '${occurredAt.hour}:${occurredAt.minute.toString().padLeft(2, '0')}';
      final thingName = record['thing_name'] ?? '默认';
      final duration = (record['duration_sec'] as int? ?? 0) ~/ 60;
      final note = record['note'] ?? '';
      final address = record['address'] ?? '';
      
      buffer.writeln('## $date $time');
      buffer.writeln('');
      buffer.writeln('**事件**: $thingName');
      buffer.writeln('');
      buffer.writeln('**时长**: $duration 分钟');
      if (note.isNotEmpty) {
        buffer.writeln('');
        buffer.writeln('**备注**: $note');
      }
      if (address.isNotEmpty) {
        buffer.writeln('');
        buffer.writeln('**位置**: $address');
      }
      buffer.writeln('');
      buffer.writeln('---');
      buffer.writeln('');
    }
    
    await file.writeAsString(buffer.toString());
    return file.path;
  }

  Future<ExportResult> export(ExportConfig config) async {
    final startTime = DateTime.now();
    
    try {
      final records = await getRecordsForExport(config);
      
      String filePath;
      switch (config.format) {
        case ExportFormat.csv:
          filePath = await exportToCSV(records);
          break;
        case ExportFormat.json:
          filePath = await exportToJSON(records);
          break;
        case ExportFormat.markdown:
          filePath = await exportToMarkdown(records);
          break;
        default:
          filePath = await exportToCSV(records);
      }
      
      final file = File(filePath);
      final fileSize = await file.length();
      
      return ExportResult(
        filePath: filePath,
        recordCount: records.length,
        fileSizeBytes: fileSize,
        duration: DateTime.now().difference(startTime),
      );
    } catch (e) {
      return ExportResult(
        filePath: '',
        recordCount: 0,
        fileSizeBytes: 0,
        duration: DateTime.now().difference(startTime),
        errorMessage: e.toString(),
      );
    }
  }
}