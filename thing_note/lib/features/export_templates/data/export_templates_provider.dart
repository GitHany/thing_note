// Export Templates feature
// Version: 1.0
// Description: 导出模板系统，支持自定义导出格式和预设模板

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/core/database/database_provider.dart';

// Export Templates Provider
final exportTemplatesProvider = FutureProvider<List<ExportTemplate>>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  
  final List<Map<String, dynamic>> maps = await db.query(
    'export_templates',
    orderBy: 'use_count DESC, name ASC',
  );
  
  return maps.map((map) => ExportTemplate.fromMap(map)).toList();
});

final exportHistoryProvider = FutureProvider<List<ExportHistory>>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  
  final List<Map<String, dynamic>> maps = await db.query(
    'export_history',
    orderBy: 'created_at DESC',
    limit: 20,
  );
  
  return maps.map((map) => ExportHistory.fromMap(map)).toList();
});

class ExportTemplate {
  final int? id;
  final String name;
  final String format;
  final bool includePhotos;
  final bool includeAudio;
  final bool includeVideo;
  final bool includeLocation;
  final bool includeTags;
  final bool includeNotes;
  final String? customFields;
  final String? filterConfig;
  final int useCount;
  final DateTime createdAt;

  ExportTemplate({
    this.id,
    required this.name,
    required this.format,
    this.includePhotos = false,
    this.includeAudio = false,
    this.includeVideo = false,
    this.includeLocation = true,
    this.includeTags = true,
    this.includeNotes = true,
    this.customFields,
    this.filterConfig,
    this.useCount = 0,
    required this.createdAt,
  });

  factory ExportTemplate.fromMap(Map<String, dynamic> map) {
    return ExportTemplate(
      id: map['id'] as int?,
      name: map['name'] as String,
      format: map['format'] as String,
      includePhotos: (map['include_photos'] as int?) == 1,
      includeAudio: (map['include_audio'] as int?) == 1,
      includeVideo: (map['include_video'] as int?) == 1,
      includeLocation: (map['include_location'] as int?) == 1,
      includeTags: (map['include_tags'] as int?) == 1,
      includeNotes: (map['include_notes'] as int?) == 1,
      customFields: map['custom_fields'] as String?,
      filterConfig: map['filter_config'] as String?,
      useCount: map['use_count'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'format': format,
      'include_photos': includePhotos ? 1 : 0,
      'include_audio': includeAudio ? 1 : 0,
      'include_video': includeVideo ? 1 : 0,
      'include_location': includeLocation ? 1 : 0,
      'include_tags': includeTags ? 1 : 0,
      'include_notes': includeNotes ? 1 : 0,
      'custom_fields': customFields,
      'filter_config': filterConfig,
      'use_count': useCount,
      'created_at': createdAt.toIso8601String(),
    };
  }

  IconData get icon {
    switch (format) {
      case 'csv':
        return Icons.table_chart;
      case 'json':
        return Icons.data_object;
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'html':
        return Icons.web;
      case 'markdown':
        return Icons.description;
      default:
        return Icons.file_download;
    }
  }

  Color get formatColor {
    switch (format) {
      case 'csv':
        return Colors.green;
      case 'json':
        return Colors.orange;
      case 'pdf':
        return Colors.red;
      case 'html':
        return Colors.blue;
      case 'markdown':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String get formatLabel {
    switch (format) {
      case 'csv':
        return 'CSV';
      case 'json':
        return 'JSON';
      case 'pdf':
        return 'PDF';
      case 'html':
        return 'HTML';
      case 'markdown':
        return 'MD';
      default:
        return format.toUpperCase();
    }
  }

  List<String> get includedItems {
    final items = <String>[];
    if (includePhotos) items.add('照片');
    if (includeAudio) items.add('音频');
    if (includeVideo) items.add('视频');
    if (includeLocation) items.add('位置');
    if (includeTags) items.add('标签');
    if (includeNotes) items.add('笔记');
    return items;
  }
}

class ExportHistory {
  final int? id;
  final String templateName;
  final String format;
  final int recordCount;
  final int fileSizeBytes;
  final String? filePath;
  final DateTime createdAt;

  ExportHistory({
    this.id,
    required this.templateName,
    required this.format,
    required this.recordCount,
    required this.fileSizeBytes,
    this.filePath,
    required this.createdAt,
  });

  factory ExportHistory.fromMap(Map<String, dynamic> map) {
    return ExportHistory(
      id: map['id'] as int?,
      templateName: map['template_name'] as String? ?? '自定义导出',
      format: map['format'] as String,
      recordCount: map['record_count'] as int? ?? 0,
      fileSizeBytes: map['file_size'] as int? ?? 0,
      filePath: map['file_path'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  String get formattedSize {
    if (fileSizeBytes < 1024) {
      return '${fileSizeBytes}B';
    } else if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(1)}KB';
    } else {
      return '${(fileSizeBytes / 1024 / 1024).toStringAsFixed(1)}MB';
    }
  }
}

// Predefined Templates
class PredefinedTemplates {
  static final simpleCsv = ExportTemplate(
    name: '简易CSV',
    format: 'csv',
    includeTags: true,
    includeNotes: true,
    createdAt: DateTime.now(),
  );

  static final fullBackup = ExportTemplate(
    name: '完整备份',
    format: 'json',
    includePhotos: true,
    includeAudio: true,
    includeVideo: true,
    includeLocation: true,
    includeTags: true,
    includeNotes: true,
    createdAt: DateTime.now(),
  );

  static final summaryReport = ExportTemplate(
    name: '摘要报告',
    format: 'markdown',
    includeTags: true,
    includeNotes: true,
    includeLocation: true,
    createdAt: DateTime.now(),
  );

  static final timelineHtml = ExportTemplate(
    name: '时间线网页',
    format: 'html',
    includePhotos: true,
    includeTags: true,
    includeNotes: true,
    includeLocation: true,
    createdAt: DateTime.now(),
  );

  static final compactPdf = ExportTemplate(
    name: '紧凑PDF',
    format: 'pdf',
    includeNotes: true,
    includeTags: true,
    createdAt: DateTime.now(),
  );
}