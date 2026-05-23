import 'dart:io';
import 'package:flutter/material.dart';
import 'package:thing_note/features/record/domain/episode_record.dart';
import 'package:thing_note/core/utils/date_formatter.dart';
import 'package:thing_note/core/utils/duration_formatter.dart';
import 'package:thing_note/features/tag/domain/tag.dart';

/// Record PDF exporter - generates shareable PDF documents from records
class RecordPdfExporter {
  /// Export a single record to PDF
  static Future<File> exportRecord({
    required EpisodeRecord record,
    String? thingName,
    List<Tag> tags = const [],
    required String outputPath,
  }) async {
    // Generate HTML content for the PDF
    final htmlContent = _generateRecordHtml(
      record: record,
      thingName: thingName,
      tags: tags,
    );

    // For simplicity, save as HTML that can be converted to PDF
    // In production, you'd use a proper PDF generation library
    final file = File(outputPath);
    await file.writeAsString(htmlContent);
    return file;
  }

  /// Export multiple records to a single PDF
  static Future<File> exportMultipleRecords({
    required List<EpisodeRecord> records,
    required Map<int?, String> thingNameMap,
    required Map<int, List<Tag>> tagsMap,
    required String outputPath,
    String? title,
  }) async {
    final htmlContent = _generateMultipleRecordsHtml(
      records: records,
      thingNameMap: thingNameMap,
      tagsMap: tagsMap,
      title: title ?? '事件记录报告',
    );

    final file = File(outputPath);
    await file.writeAsString(htmlContent);
    return file;
  }

  static String _generateRecordHtml({
    required EpisodeRecord record,
    String? thingName,
    List<Tag> tags = const [],
  }) {
    final buffer = StringBuffer();
    buffer.writeln('<!DOCTYPE html>');
    buffer.writeln('<html><head>');
    buffer.writeln('<meta charset="UTF-8">');
    buffer.writeln('<meta name="viewport" content="width=device-width, initial-scale=1.0">');
    buffer.writeln('<title>事件记录 - ${DateFormatter.formatDate(record.occurredAt)}</title>');
    buffer.writeln('<style>');
    buffer.writeln('''
      body {
        font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
        max-width: 600px;
        margin: 0 auto;
        padding: 20px;
        color: #333;
      }
      .header {
        border-bottom: 2px solid #4A90D9;
        padding-bottom: 16px;
        margin-bottom: 20px;
      }
      .title {
        font-size: 24px;
        font-weight: bold;
        color: #4A90D9;
        margin: 0;
      }
      .date {
        color: #666;
        font-size: 14px;
        margin-top: 4px;
      }
      .section {
        margin-bottom: 20px;
        padding: 16px;
        background: #f8f9fa;
        border-radius: 8px;
      }
      .section-title {
        font-size: 14px;
        font-weight: 600;
        color: #4A90D9;
        margin-bottom: 8px;
        text-transform: uppercase;
      }
      .section-content {
        font-size: 16px;
        line-height: 1.6;
      }
      .tags {
        display: flex;
        flex-wrap: wrap;
        gap: 8px;
      }
      .tag {
        background: #e3f2fd;
        color: #1565c0;
        padding: 4px 12px;
        border-radius: 16px;
        font-size: 12px;
      }
      .media-info {
        color: #666;
        font-size: 14px;
      }
      .icon-row {
        display: flex;
        gap: 16px;
        margin-top: 8px;
      }
      .icon-item {
        display: flex;
        align-items: center;
        gap: 4px;
        color: #666;
      }
      .location {
        color: #666;
        font-size: 14px;
      }
      .note-text {
        white-space: pre-wrap;
        word-break: break-word;
      }
      .footer {
        border-top: 1px solid #eee;
        padding-top: 16px;
        margin-top: 24px;
        color: #999;
        font-size: 12px;
        text-align: center;
      }
    ''');
    buffer.writeln('</style>');
    buffer.writeln('</head><body>');

    // Header
    buffer.writeln('<div class="header">');
    buffer.writeln('<h1 class="title">${thingName ?? '事件记录'}</h1>');
    buffer.writeln('<div class="date">${DateFormatter.formatDateTime(record.occurredAt)}</div>');
    buffer.writeln('</div>');

    // Duration
    buffer.writeln('<div class="section">');
    buffer.writeln('<div class="section-title">时长</div>');
    buffer.writeln('<div class="section-content">${DurationFormatter.formatShort(record.duration)}</div>');
    buffer.writeln('</div>');

    // Tags
    if (tags.isNotEmpty) {
      buffer.writeln('<div class="section">');
      buffer.writeln('<div class="section-title">标签</div>');
      buffer.writeln('<div class="tags">');
      for (final tag in tags) {
        buffer.writeln('<span class="tag">${tag.name}</span>');
      }
      buffer.writeln('</div>');
      buffer.writeln('</div>');
    }

    // Location
    if (record.hasLocation && record.address != null) {
      buffer.writeln('<div class="section">');
      buffer.writeln('<div class="section-title">位置</div>');
      buffer.writeln('<div class="location">${record.address}</div>');
      if (record.latitude != null && record.longitude != null) {
        buffer.writeln('<div class="location">${record.latitude!.toStringAsFixed(6)}, ${record.longitude!.toStringAsFixed(6)}</div>');
      }
      buffer.writeln('</div>');
    }

    // Note
    if (record.note.isNotEmpty) {
      buffer.writeln('<div class="section">');
      buffer.writeln('<div class="section-title">备注</div>');
      buffer.writeln('<div class="section-content note-text">${_escapeHtml(record.note)}</div>');
      buffer.writeln('</div>');
    }

    // Media summary
    buffer.writeln('<div class="section">');
    buffer.writeln('<div class="section-title">附件</div>');
    buffer.writeln('<div class="media-info">');
    buffer.writeln('<div class="icon-row">');
    if (record.hasPhotos) {
      buffer.writeln('<div class="icon-item">📷 ${record.photoPaths.length} 张照片</div>');
    }
    if (record.hasAudio) {
      buffer.writeln('<div class="icon-item">🎤 ${record.audioPaths.length} 条录音</div>');
    }
    if (record.hasVideos) {
      buffer.writeln('<div class="icon-item">🎬 ${record.videoPaths.length} 个视频</div>');
    }
    if (record.hasDocuments) {
      buffer.writeln('<div class="icon-item">📄 ${record.documentPaths.length} 个文档</div>');
    }
    buffer.writeln('</div>');
    buffer.writeln('</div>');
    buffer.writeln('</div>');

    // Reminder status
    if (record.hasReminder) {
      buffer.writeln('<div class="section">');
      buffer.writeln('<div class="section-content">🔔 已设置提醒${record.isRecurring ? ' (${_getRepeatLabel(record.repeatType)})' : ''}</div>');
      buffer.writeln('</div>');
    }

    // Footer
    buffer.writeln('<div class="footer">');
    buffer.writeln('由 ThingNote 生成 · ${DateFormatter.formatDateTime(DateTime.now())}');
    buffer.writeln('</div>');

    buffer.writeln('</body></html>');
    return buffer.toString();
  }

  static String _generateMultipleRecordsHtml({
    required List<EpisodeRecord> records,
    required Map<int?, String> thingNameMap,
    required Map<int, List<Tag>> tagsMap,
    required String title,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('<!DOCTYPE html>');
    buffer.writeln('<html><head>');
    buffer.writeln('<meta charset="UTF-8">');
    buffer.writeln('<meta name="viewport" content="width=device-width, initial-scale=1.0">');
    buffer.writeln('<title>$title</title>');
    buffer.writeln('<style>');
    buffer.writeln('''
      body {
        font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
        max-width: 800px;
        margin: 0 auto;
        padding: 20px;
        color: #333;
      }
      .header {
        border-bottom: 2px solid #4A90D9;
        padding-bottom: 16px;
        margin-bottom: 24px;
      }
      .title {
        font-size: 28px;
        font-weight: bold;
        color: #4A90D9;
        margin: 0;
      }
      .subtitle {
        color: #666;
        font-size: 14px;
        margin-top: 4px;
      }
      .record-card {
        border: 1px solid #e0e0e0;
        border-radius: 12px;
        padding: 16px;
        margin-bottom: 16px;
        page-break-inside: avoid;
      }
      .record-header {
        display: flex;
        justify-content: space-between;
        align-items: flex-start;
        margin-bottom: 12px;
      }
      .record-title {
        font-size: 16px;
        font-weight: 600;
        color: #333;
      }
      .record-date {
        color: #999;
        font-size: 12px;
      }
      .record-meta {
        display: flex;
        flex-wrap: wrap;
        gap: 12px;
        color: #666;
        font-size: 13px;
        margin-bottom: 12px;
      }
      .record-note {
        color: #555;
        font-size: 14px;
        line-height: 1.6;
        white-space: pre-wrap;
      }
      .tags {
        display: flex;
        flex-wrap: wrap;
        gap: 6px;
        margin-top: 8px;
      }
      .tag {
        background: #e3f2fd;
        color: #1565c0;
        padding: 2px 8px;
        border-radius: 12px;
        font-size: 11px;
      }
      .stats {
        display: flex;
        justify-content: space-around;
        background: #f8f9fa;
        padding: 16px;
        border-radius: 8px;
        margin-bottom: 24px;
      }
      .stat-item {
        text-align: center;
      }
      .stat-value {
        font-size: 24px;
        font-weight: bold;
        color: #4A90D9;
      }
      .stat-label {
        font-size: 12px;
        color: #666;
      }
      .footer {
        border-top: 1px solid #eee;
        padding-top: 16px;
        margin-top: 24px;
        color: #999;
        font-size: 12px;
        text-align: center;
      }
    ''');
    buffer.writeln('</style>');
    buffer.writeln('</head><body>');

    // Header
    buffer.writeln('<div class="header">');
    buffer.writeln('<h1 class="title">$title</h1>');
    buffer.writeln('<div class="subtitle">生成时间: ${DateFormatter.formatDateTime(DateTime.now())}</div>');
    buffer.writeln('</div>');

    // Stats summary
    buffer.writeln('<div class="stats">');
    final photoCount = records.fold(0, (sum, r) => sum + r.photoPaths.length);
    final audioCount = records.fold(0, (sum, r) => sum + r.audioPaths.length);
    final videoCount = records.fold(0, (sum, r) => sum + r.videoPaths.length);
    buffer.writeln('<div class="stat-item"><div class="stat-value">$photoCount</div><div class="stat-label">照片</div></div>');
    buffer.writeln('<div class="stat-item"><div class="stat-value">$audioCount</div><div class="stat-label">录音</div></div>');
    buffer.writeln('<div class="stat-item"><div class="stat-value">$videoCount</div><div class="stat-label">视频</div></div>');
    buffer.writeln('</div>');

    // Records
    for (final record in records) {
      final thingName = thingNameMap[record.thingNameId] ?? '默认';
      final tags = tagsMap[record.id] ?? [];

      buffer.writeln('<div class="record-card">');
      buffer.writeln('<div class="record-header">');
      buffer.writeln('<div class="record-title">${_escapeHtml(thingName)}</div>');
      buffer.writeln('<div class="record-date">${DateFormatter.formatDateTime(record.occurredAt)}</div>');
      buffer.writeln('</div>');

      // Meta info
      buffer.writeln('<div class="record-meta">');
      if (record.durationSec > 0) {
        buffer.writeln('<span>⏱️ ${DurationFormatter.formatShort(record.duration)}</span>');
      }
      if (record.hasPhotos) buffer.writeln('<span>📷 ${record.photoPaths.length}</span>');
      if (record.hasAudio) buffer.writeln('<span>🎤 ${record.audioPaths.length}</span>');
      if (record.hasVideos) buffer.writeln('<span>🎬 ${record.videoPaths.length}</span>');
      if (record.hasLocation && record.address != null) {
        buffer.writeln('<span>📍 ${_escapeHtml(record.address!)}</span>');
      }
      if (record.hasReminder) buffer.writeln('<span>🔔</span>');
      buffer.writeln('</div>');

      // Note
      if (record.note.isNotEmpty) {
        buffer.writeln('<div class="record-note">${_escapeHtml(record.note)}</div>');
      }

      // Tags
      if (tags.isNotEmpty) {
        buffer.writeln('<div class="tags">');
        for (final tag in tags) {
          buffer.writeln('<span class="tag">${_escapeHtml(tag.name)}</span>');
        }
        buffer.writeln('</div>');
      }

      buffer.writeln('</div>');
    }

    // Footer
    buffer.writeln('<div class="footer">');
    buffer.writeln('由 ThingNote 生成 · ${DateFormatter.formatDateTime(DateTime.now())}');
    buffer.writeln('</div>');

    buffer.writeln('</body></html>');
    return buffer.toString();
  }

  static String _escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }

  static String _getRepeatLabel(String repeatType) {
    switch (repeatType) {
      case 'daily': return '每天';
      case 'weekly': return '每周';
      case 'monthly': return '每月';
      case 'yearly': return '每年';
      default: return repeatType;
    }
  }
}

/// Export record dialog
class ExportRecordDialog extends StatelessWidget {
  final EpisodeRecord record;
  final String? thingName;
  final List<Tag> tags;

  const ExportRecordDialog({
    super.key,
    required this.record,
    this.thingName,
    this.tags = const [],
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('导出记录'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '将生成包含以下内容的文档：',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          _buildInfoRow(context, '事件名称', thingName ?? '默认'),
          _buildInfoRow(context, '时间', DateFormatter.formatDateTime(record.occurredAt)),
          if (record.durationSec > 0)
            _buildInfoRow(context, '时长', DurationFormatter.formatShort(record.duration)),
          if (tags.isNotEmpty)
            _buildInfoRow(context, '标签', tags.map((t) => t.name).join(', ')),
          if (record.hasLocation && record.address != null)
            _buildInfoRow(context, '位置', record.address!),
          _buildInfoRow(context, '附件', _getMediaSummary()),
          if (record.hasReminder)
            _buildInfoRow(context, '提醒', '已设置${record.isRecurring ? ' (重复)' : ''}'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton.icon(
          icon: const Icon(Icons.picture_as_pdf),
          label: const Text('导出为 PDF'),
          onPressed: () => _exportPdf(context),
        ),
      ],
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  String _getMediaSummary() {
    final parts = <String>[];
    if (record.hasPhotos) parts.add('${record.photoPaths.length}张照片');
    if (record.hasAudio) parts.add('${record.audioPaths.length}条录音');
    if (record.hasVideos) parts.add('${record.videoPaths.length}个视频');
    if (record.hasDocuments) parts.add('${record.documentPaths.length}个文档');
    return parts.isEmpty ? '无' : parts.join(', ');
  }

  Future<void> _exportPdf(BuildContext context) async {
    // In production, this would use a PDF generation library
    // For now, show a placeholder message
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('PDF 导出功能正在开发中，请使用分享功能分享记录'),
        duration: Duration(seconds: 3),
      ),
    );
  }
}

/// Show export dialog for a record
Future<void> showExportRecordDialog(
  BuildContext context, {
  required EpisodeRecord record,
  String? thingName,
  List<Tag> tags = const [],
}) {
  return showDialog(
    context: context,
    builder: (_) => ExportRecordDialog(
      record: record,
      thingName: thingName,
      tags: tags,
    ),
  );
}