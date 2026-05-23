import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:thing_note/core/database/database_provider.dart';
import 'package:thing_note/features/data_export/domain/data_export.dart';

class DataExportRepository {
  final Ref _ref;

  DataExportRepository(this._ref);

  Future<ExportResult> exportRecords({
    required String format,
    required DateTime startDate,
    required DateTime endDate,
    bool includeMedia = true,
  }) async {
    try {
      final db = await _ref.read(databaseProvider.future);
      final records = await db.rawQuery('''
        SELECT * FROM episode_records
        WHERE occurred_at >= ? AND occurred_at <= ?
        ORDER BY occurred_at DESC
      ''', [startDate.toIso8601String(), endDate.toIso8601String()]);

      if (records.isEmpty) {
        return ExportResult(
          success: false,
          errorMessage: '没有找到指定日期范围内的记录',
        );
      }

      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'thing_note_export_$timestamp.$format';
      final filePath = '${dir.path}/$fileName';

      switch (format) {
        case 'json':
          await _exportJson(records, filePath);
          break;
        case 'csv':
          await _exportCsv(records, filePath);
          break;
        default:
          return ExportResult(
            success: false,
            errorMessage: '不支持的导出格式',
          );
      }

      final file = File(filePath);
      final fileSize = await file.length();

      return ExportResult(
        success: true,
        filePath: filePath,
        recordCount: records.length,
        fileSizeBytes: fileSize,
      );
    } catch (e) {
      return ExportResult(
        success: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> _exportJson(List<Map<String, dynamic>> records, String filePath) async {
    final file = File(filePath);
    final jsonData = jsonEncode(records);
    await file.writeAsString(jsonData);
  }

  Future<void> _exportCsv(List<Map<String, dynamic>> records, String filePath) async {
    final file = File(filePath);
    final buffer = StringBuffer();

    if (records.isNotEmpty) {
      // Header
      buffer.writeln(records.first.keys.join(','));

      // Data rows
      for (final record in records) {
        final values = record.values.map((v) {
          if (v == null) return '';
          final str = v.toString();
          if (str.contains(',') || str.contains('"') || str.contains('\n')) {
            return '"${str.replaceAll('"', '""')}"';
          }
          return str;
        });
        buffer.writeln(values.join(','));
      }
    }

    await file.writeAsString(buffer.toString());
  }

  Future<Map<String, dynamic>> getExportPreview({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final db = await _ref.read(databaseProvider.future);
    final records = await db.rawQuery('''
      SELECT COUNT(*) as count,
             SUM(duration_sec) as total_duration,
             COUNT(DISTINCT thing_name_id) as unique_things
      FROM episode_records
      WHERE occurred_at >= ? AND occurred_at <= ?
    ''', [startDate.toIso8601String(), endDate.toIso8601String()]);

    return records.first;
  }
}