/// Quick Export Config model
class QuickExportConfig {
  final int? id;
  final String name;
  final String format;
  final String? fields;
  final String? filters;
  final int useCount;
  final DateTime createdAt;

  static const formats = ['json', 'csv', 'html', 'pdf'];
  static const formatLabels = {
    'json': 'JSON (完整数据)',
    'csv': 'CSV (表格数据)',
    'html': 'HTML (可读报告)',
    'pdf': 'PDF (正式文档)',
  };

  QuickExportConfig({
    this.id,
    required this.name,
    required this.format,
    this.fields,
    this.filters,
    this.useCount = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  String get formatLabel => formatLabels[format] ?? format;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'format': format,
      'fields': fields,
      'filters': filters,
      'use_count': useCount,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory QuickExportConfig.fromMap(Map<String, dynamic> map) {
    return QuickExportConfig(
      id: map['id'] as int?,
      name: map['name'] as String,
      format: map['format'] as String,
      fields: map['fields'] as String?,
      filters: map['filters'] as String?,
      useCount: map['use_count'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}