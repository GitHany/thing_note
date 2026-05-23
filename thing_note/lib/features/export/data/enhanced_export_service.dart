import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:thing_note/features/record/domain/episode_record.dart';

/// 增强导出服务
class EnhancedExportService {
  /// 导出为 JSON 格式
  static Future<File> exportToJson(
    List<EpisodeRecord> records, {
    String? fileName,
  }) async {
    final exportData = {
      'version': '1.0',
      'exportedAt': DateTime.now().toIso8601String(),
      'recordCount': records.length,
      'records': records.map((r) => _recordToJson(r)).toList(),
    };

    final jsonStr = const JsonEncoder.withIndent('  ').convert(exportData);
    final file = await _getExportFile(
      fileName ?? 'thing_note_export_${_dateNowStr()}.json',
    );
    await file.writeAsString(jsonStr);
    return file;
  }

  /// 导出为 CSV 格式（增强版）
  static Future<File> exportToCsv(
    List<EpisodeRecord> records, {
    String? fileName,
    bool includeMediaPaths = true,
  }) async {
    final buffer = StringBuffer();

    // CSV 头部
    final headers = [
      'ID',
      'Occurred At',
      'Duration (sec)',
      'Note',
      'Thing Name ID',
      'Has Reminder',
      'Latitude',
      'Longitude',
      'Address',
      'Is Favorite',
      'Repeat Type',
      'Photo Count',
      'Audio Count',
      'Video Count',
      'Document Count',
      'Created At',
      'Updated At',
    ];

    if (includeMediaPaths) {
      headers.addAll([
        'Photo Paths',
        'Audio Paths',
        'Video Paths',
        'Document Paths',
      ]);
    }

    buffer.writeln(_escapeCsvRow(headers));

    // 数据行
    for (final record in records) {
      final row = [
        record.id?.toString() ?? '',
        record.occurredAt.toIso8601String(),
        record.durationSec.toString(),
        record.note,
        record.thingNameId?.toString() ?? '',
        record.hasReminder ? '1' : '0',
        record.latitude?.toString() ?? '',
        record.longitude?.toString() ?? '',
        record.address ?? '',
        record.isFavorite ? '1' : '0',
        record.repeatType,
        record.photoPaths.length.toString(),
        record.audioPaths.length.toString(),
        record.videoPaths.length.toString(),
        record.documentPaths.length.toString(),
        record.createdAt.toIso8601String(),
        record.updatedAt.toIso8601String(),
      ];

      if (includeMediaPaths) {
        row.addAll([
          record.photoPaths.join('; '),
          record.audioPaths.join('; '),
          record.videoPaths.join('; '),
          record.documentPaths.join('; '),
        ]);
      }

      buffer.writeln(_escapeCsvRow(row));
    }

    final file = await _getExportFile(
      fileName ?? 'thing_note_export_${_dateNowStr()}.csv',
    );
    await file.writeAsString(buffer.toString());
    return file;
  }

  /// 导出为 Markdown 格式
  static Future<File> exportToMarkdown(
    List<EpisodeRecord> records, {
    String? fileName,
  }) async {
    final buffer = StringBuffer();
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

    buffer.writeln('# Thing Note Records Export');
    buffer.writeln();
    buffer.writeln('**Export Date:** ${dateFormat.format(DateTime.now())}');
    buffer.writeln('**Total Records:** ${records.length}');
    buffer.writeln();

    for (final record in records) {
      buffer.writeln('## ${record.id ?? 'New'}');
      buffer.writeln();
      buffer.writeln('- **Date:** ${dateFormat.format(record.occurredAt)}');
      buffer.writeln('- **Duration:** ${_formatDuration(record.durationSec)}');
      if (record.note.isNotEmpty) {
        buffer.writeln('- **Note:** ${record.note}');
      }
      if (record.thingNameId != null) {
        buffer.writeln('- **Thing Name ID:** ${record.thingNameId}');
      }
      buffer.writeln('- **Has Reminder:** ${record.hasReminder ? "Yes" : "No"}');
      if (record.latitude != null && record.longitude != null) {
        buffer.writeln('- **Location:** ${record.latitude}, ${record.longitude}');
      }
      if (record.address != null && record.address!.isNotEmpty) {
        buffer.writeln('- **Address:** ${record.address}');
      }
      buffer.writeln('- **Favorite:** ${record.isFavorite ? "⭐" : ""}');
      buffer.writeln('- **Repeat Type:** ${record.repeatType}');

      if (record.photoPaths.isNotEmpty) {
        buffer.writeln('- **Photos:** ${record.photoPaths.length} file(s)');
      }
      if (record.audioPaths.isNotEmpty) {
        buffer.writeln('- **Audio:** ${record.audioPaths.length} file(s)');
      }
      if (record.videoPaths.isNotEmpty) {
        buffer.writeln('- **Videos:** ${record.videoPaths.length} file(s)');
      }
      if (record.documentPaths.isNotEmpty) {
        buffer.writeln('- **Documents:** ${record.documentPaths.length} file(s)');
      }

      buffer.writeln();
      buffer.writeln('---');
      buffer.writeln();
    }

    final file = await _getExportFile(
      fileName ?? 'thing_note_export_${_dateNowStr()}.md',
    );
    await file.writeAsString(buffer.toString());
    return file;
  }

  /// 导出为 HTML 格式
  static Future<File> exportToHtml(
    List<EpisodeRecord> records, {
    String? fileName,
  }) async {
    final buffer = StringBuffer();
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

    buffer.writeln('''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>Thing Note Export</title>
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; max-width: 900px; margin: 0 auto; padding: 20px; }
    h1 { color: #333; }
    .meta { color: #666; font-size: 14px; }
    .record { border: 1px solid #ddd; border-radius: 8px; padding: 16px; margin: 16px 0; background: #fafafa; }
    .record h2 { margin-top: 0; color: #333; }
    .field { margin: 8px 0; }
    .label { font-weight: bold; color: #555; }
    .badge { display: inline-block; padding: 2px 8px; border-radius: 12px; font-size: 12px; margin-left: 8px; }
    .favorite { background: #ffd700; color: #333; }
    .reminder { background: #4caf50; color: white; }
    .media-count { display: inline-block; margin: 4px; padding: 4px 8px; background: #e0e0e0; border-radius: 4px; font-size: 12px; }
    .media-grid { display: flex; flex-wrap: wrap; gap: 8px; }
    .tag { display: inline-block; padding: 2px 8px; border-radius: 12px; font-size: 12px; background: #2196f3; color: white; margin-right: 4px; }
  </style>
</head>
<body>
  <h1>Thing Note Records Export</h1>
  <p class="meta">Export Date: ${dateFormat.format(DateTime.now())} | Total Records: ${records.length}</p>
''');

    for (final record in records) {
      buffer.writeln('''
  <div class="record">
    <h2>Record #${record.id ?? 'New'}</h2>
    <div class="field"><span class="label">Date:</span> ${dateFormat.format(record.occurredAt)}</div>
    <div class="field"><span class="label">Duration:</span> ${_formatDuration(record.durationSec)}</div>
    ${record.note.isNotEmpty ? '<div class="field"><span class="label">Note:</span> ${_escapeHtml(record.note)}</div>' : ''}
    <div class="field">
      ${record.hasReminder ? '<span class="badge reminder">Reminder</span>' : ''}
      ${record.isFavorite ? '<span class="badge favorite">Favorite</span>' : ''}
    </div>
    ${record.latitude != null ? '<div class="field"><span class="label">Location:</span> ${record.latitude}, ${record.longitude}</div>' : ''}
    ${record.address != null ? '<div class="field"><span class="label">Address:</span> ${_escapeHtml(record.address!)}</div>' : ''}
    ${record.repeatType != 'none' ? '<div class="field"><span class="label">Repeat:</span> ${record.repeatType}</div>' : ''}
    <div class="media-grid">
      ${record.photoPaths.isNotEmpty ? '<span class="media-count">📷 ${record.photoPaths.length}</span>' : ''}
      ${record.audioPaths.isNotEmpty ? '<span class="media-count">🎵 ${record.audioPaths.length}</span>' : ''}
      ${record.videoPaths.isNotEmpty ? '<span class="media-count">🎬 ${record.videoPaths.length}</span>' : ''}
      ${record.documentPaths.isNotEmpty ? '<span class="media-count">📄 ${record.documentPaths.length}</span>' : ''}
    </div>
  </div>
''');
    }

    buffer.writeln('''
</body>
</html>
''');

    final file = await _getExportFile(
      fileName ?? 'thing_note_export_${_dateNowStr()}.html',
    );
    await file.writeAsString(buffer.toString());
    return file;
  }

  /// 导出为 XML 格式
  static Future<File> exportToXml(
    List<EpisodeRecord> records, {
    String? fileName,
  }) async {
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<thing_note_export>');
    buffer.writeln('  <metadata>');
    buffer.writeln('    <exported_at>${DateTime.now().toIso8601String()}</exported_at>');
    buffer.writeln('    <record_count>${records.length}</record_count>');
    buffer.writeln('  </metadata>');
    buffer.writeln('  <records>');

    for (final record in records) {
      buffer.writeln('    <record>');
      buffer.writeln('      <id>${record.id ?? ''}</id>');
      buffer.writeln('      <occurred_at>${_escapeXml(record.occurredAt.toIso8601String())}</occurred_at>');
      buffer.writeln('      <duration_sec>${record.durationSec}</duration_sec>');
      buffer.writeln('      <note>${_escapeXml(record.note)}</note>');
      if (record.thingNameId != null) {
        buffer.writeln('      <thing_name_id>${record.thingNameId}</thing_name_id>');
      }
      buffer.writeln('      <has_reminder>${record.hasReminder ? 1 : 0}</has_reminder>');
      buffer.writeln('      <is_favorite>${record.isFavorite ? 1 : 0}</is_favorite>');
      buffer.writeln('      <repeat_type>${record.repeatType}</repeat_type>');
      if (record.latitude != null) {
        buffer.writeln('      <latitude>${record.latitude}</latitude>');
        buffer.writeln('      <longitude>${record.longitude}</longitude>');
      }
      if (record.address != null) {
        buffer.writeln('      <address>${_escapeXml(record.address!)}</address>');
      }
      buffer.writeln('      <created_at>${_escapeXml(record.createdAt.toIso8601String())}</created_at>');
      buffer.writeln('      <updated_at>${_escapeXml(record.updatedAt.toIso8601String())}</updated_at>');
      buffer.writeln('    </record>');
    }

    buffer.writeln('  </records>');
    buffer.writeln('</thing_note_export>');

    final file = await _getExportFile(
      fileName ?? 'thing_note_export_${_dateNowStr()}.xml',
    );
    await file.writeAsString(buffer.toString());
    return file;
  }

  /// 导出为数据库格式（SQLite）
  static Future<File> exportToSql(
    List<EpisodeRecord> records, {
    String? fileName,
  }) async {
    final buffer = StringBuffer();

    buffer.writeln('-- Thing Note Database Export');
    buffer.writeln('-- Generated: ${DateTime.now().toIso8601String()}');
    buffer.writeln();

    for (final record in records) {
      final photoPaths = jsonEncode(record.photoPaths).replaceAll("'", "''");
      final audioPaths = jsonEncode(record.audioPaths).replaceAll("'", "''");
      final audioDurationsSec = jsonEncode(record.audioDurationsSec).replaceAll("'", "''");
      final videoPaths = jsonEncode(record.videoPaths).replaceAll("'", "''");
      final documentPaths = jsonEncode(record.documentPaths).replaceAll("'", "''");
      final note = record.note.replaceAll("'", "''");
      final address = (record.address ?? '').replaceAll("'", "''");

      buffer.writeln('''
INSERT INTO episode_records (
  occurred_at, duration_sec, note, photo_paths, audio_paths,
  audio_durations_sec, thing_name_id, has_reminder, latitude, longitude,
  address, video_paths, document_paths, is_favorite, repeat_type,
  created_at, updated_at
) VALUES (
  '${record.occurredAt.toIso8601String()}',
  ${record.durationSec},
  '$note',
  '$photoPaths',
  '$audioPaths',
  '$audioDurationsSec',
  ${record.thingNameId ?? 'NULL'},
  ${record.hasReminder ? 1 : 0},
  ${record.latitude ?? 'NULL'},
  ${record.longitude ?? 'NULL'},
  ${address.isEmpty ? 'NULL' : "'$address'"},
  '$videoPaths',
  '$documentPaths',
  ${record.isFavorite ? 1 : 0},
  '${record.repeatType}',
  '${record.createdAt.toIso8601String()}',
  '${record.updatedAt.toIso8601String()}'
);
''');
    }

    final file = await _getExportFile(
      fileName ?? 'thing_note_export_${_dateNowStr()}.sql',
    );
    await file.writeAsString(buffer.toString());
    return file;
  }

  /// 导出统计摘要
  static Future<File> exportSummary(
    List<EpisodeRecord> records, {
    String? fileName,
  }) async {
    final buffer = StringBuffer();
    final dateFormat = DateFormat('yyyy-MM-dd');

    // 统计数据
    final totalRecords = records.length;
    final totalDuration = records.fold<int>(0, (sum, r) => sum + r.durationSec);
    final avgDuration = totalRecords > 0 ? totalDuration / totalRecords : 0;
    final withPhotos = records.where((r) => r.photoPaths.isNotEmpty).length;
    final withAudio = records.where((r) => r.audioPaths.isNotEmpty).length;
    final withVideo = records.where((r) => r.videoPaths.isNotEmpty).length;
    final favorites = records.where((r) => r.isFavorite).length;
    final withReminders = records.where((r) => r.hasReminder).length;

    // 按日期分组
    final byDate = <String, int>{};
    for (final record in records) {
      final dateKey = dateFormat.format(record.occurredAt);
      byDate[dateKey] = (byDate[dateKey] ?? 0) + 1;
    }

    final dateRange = records.isEmpty
        ? 'N/A'
        : '${dateFormat.format(records.last.occurredAt)} - ${dateFormat.format(records.first.occurredAt)}';

    buffer.writeln('# Thing Note - Export Summary');
    buffer.writeln();
    buffer.writeln('**Export Date:** ${dateFormat.format(DateTime.now())}');
    buffer.writeln();
    buffer.writeln('## Overview');
    buffer.writeln('| Metric | Value |');
    buffer.writeln('|--------|-------|');
    buffer.writeln('| Total Records | $totalRecords |');
    buffer.writeln('| Date Range | $dateRange |');
    buffer.writeln('| Total Duration | ${_formatDuration(totalDuration)} |');
    buffer.writeln('| Average Duration | ${_formatDuration(avgDuration.round())} |');
    buffer.writeln();
    buffer.writeln('## Media Breakdown');
    buffer.writeln('| Type | Count | Percentage |');
    buffer.writeln('|------|-------|------------|');
    buffer.writeln('| Photos | $withPhotos | ${((withPhotos / totalRecords) * 100).toStringAsFixed(1)}% |');
    buffer.writeln('| Audio | $withAudio | ${((withAudio / totalRecords) * 100).toStringAsFixed(1)}% |');
    buffer.writeln('| Video | $withVideo | ${((withVideo / totalRecords) * 100).toStringAsFixed(1)}% |');
    buffer.writeln();
    buffer.writeln('## Features');
    buffer.writeln('| Feature | Count | Percentage |');
    buffer.writeln('|---------|-------|------------|');
    buffer.writeln('| Favorites | $favorites | ${((favorites / totalRecords) * 100).toStringAsFixed(1)}% |');
    buffer.writeln('| With Reminders | $withReminders | ${((withReminders / totalRecords) * 100).toStringAsFixed(1)}% |');
    buffer.writeln();
    buffer.writeln('## Daily Breakdown');
    for (final entry in byDate.entries) {
      buffer.writeln('- ${entry.key}: ${entry.value} records');
    }

    final file = await _getExportFile(
      fileName ?? 'thing_note_summary_${_dateNowStr()}.md',
    );
    await file.writeAsString(buffer.toString());
    return file;
  }

  // 辅助方法
  static Future<Directory> _getExportDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final exportDir = Directory('${dir.path}/exports');
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }
    return exportDir;
  }

  static Future<File> _getExportFile(String fileName) async {
    final dir = await _getExportDir();
    final file = File('${dir.path}/$fileName');
    return file;
  }

  static String _dateNowStr() {
    return DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
  }

  static String _formatDuration(int seconds) {
    if (seconds < 60) return '${seconds}s';
    if (seconds < 3600) return '${(seconds / 60).round()}m';
    final hours = seconds ~/ 3600;
    final mins = (seconds % 3600) ~/ 60;
    return '${hours}h ${mins}m';
  }

  static String _escapeCsvRow(List<String> row) {
    return row.map((cell) {
      if (cell.contains(',') || cell.contains('"') || cell.contains('\n')) {
        return '"${cell.replaceAll('"', '""')}"';
      }
      return cell;
    }).join(',');
  }

  static String _escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }

  static String _escapeXml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  static Map<String, dynamic> _recordToJson(EpisodeRecord record) {
    return {
      'id': record.id,
      'occurredAt': record.occurredAt.toIso8601String(),
      'durationSec': record.durationSec,
      'note': record.note,
      'photoPaths': record.photoPaths,
      'audioPaths': record.audioPaths,
      'audioDurationsSec': record.audioDurationsSec,
      'thingNameId': record.thingNameId,
      'annotations': record.annotationsJson,
      'hasReminder': record.hasReminder,
      'latitude': record.latitude,
      'longitude': record.longitude,
      'address': record.address,
      'videoPaths': record.videoPaths,
      'documentPaths': record.documentPaths,
      'isFavorite': record.isFavorite,
      'repeatType': record.repeatType,
      'createdAt': record.createdAt.toIso8601String(),
      'updatedAt': record.updatedAt.toIso8601String(),
    };
  }
}