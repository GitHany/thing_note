class ExportFormat {
  final int? id;
  final String formatType;
  final String formatName;
  final String fileExtension;
  final String? configJson;
  final int useCount;
  final bool isFavorite;
  final DateTime createdAt;

  ExportFormat({
    this.id,
    required this.formatType,
    required this.formatName,
    required this.fileExtension,
    this.configJson,
    this.useCount = 0,
    this.isFavorite = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  static const formatTypes = [
    {
      'value': 'notion',
      'name': 'Notion',
      'extension': 'json',
      'icon': '📓',
      'description': '导出为 Notion 兼容的 JSON 格式',
    },
    {
      'value': 'obsidian',
      'name': 'Obsidian',
      'extension': 'md',
      'icon': '💎',
      'description': '导出为 Obsidian Markdown 格式',
    },
    {
      'value': 'calendar',
      'name': '日历',
      'extension': 'ics',
      'icon': '📅',
      'description': '导出为 iCalendar 格式',
    },
    {
      'value': 'json',
      'name': 'JSON',
      'extension': 'json',
      'icon': '{ }',
      'description': '导出为标准 JSON 格式',
    },
    {
      'value': 'csv',
      'name': 'CSV',
      'extension': 'csv',
      'icon': '📊',
      'description': '导出为 CSV 表格格式',
    },
    {
      'value': 'html',
      'name': 'HTML',
      'extension': 'html',
      'icon': '🌐',
      'description': '导出为可浏览的 HTML 页面',
    },
    {
      'value': 'pdf',
      'name': 'PDF',
      'extension': 'pdf',
      'icon': '📄',
      'description': '导出为 PDF 文档',
    },
  ];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'format_type': formatType,
      'format_name': formatName,
      'file_extension': fileExtension,
      'config_json': configJson,
      'use_count': useCount,
      'is_favorite': isFavorite ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ExportFormat.fromMap(Map<String, dynamic> map) {
    return ExportFormat(
      id: map['id'] as int?,
      formatType: map['format_type'] as String,
      formatName: map['format_name'] as String,
      fileExtension: map['file_extension'] as String,
      configJson: map['config_json'] as String?,
      useCount: map['use_count'] as int? ?? 0,
      isFavorite: (map['is_favorite'] as int?) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
