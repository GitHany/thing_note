/// 导出配置文件模型
class ExportProfile {
  final int? id;
  final String name;
  final String format; // json, csv, pdf, markdown
  final List<String> fields; // 要导出的字段
  final String? filters; // 筛选条件 JSON
  final int useCount;
  final DateTime createdAt;

  ExportProfile({
    this.id,
    required this.name,
    required this.format,
    this.fields = const [],
    this.filters,
    this.useCount = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'format': format,
      'fields': fields.join(','),
      'filters': filters,
      'use_count': useCount,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ExportProfile.fromMap(Map<String, dynamic> map) {
    final fieldsStr = map['fields'] as String? ?? '';
    return ExportProfile(
      id: map['id'] as int?,
      name: map['name'] as String,
      format: map['format'] as String,
      fields: fieldsStr.isEmpty ? [] : fieldsStr.split(','),
      filters: map['filters'] as String?,
      useCount: map['use_count'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

/// 导出计划模型
class ExportSchedule {
  final int? id;
  final String name;
  final String frequency; // daily, weekly, monthly
  final String? timeOfDay;
  final String? dayOfWeek;
  final String? dayOfMonth;
  final int isEnabled;
  final DateTime? lastRunAt;
  final int maxBackups;

  ExportSchedule({
    this.id,
    required this.name,
    this.frequency = 'daily',
    this.timeOfDay,
    this.dayOfWeek,
    this.dayOfMonth,
    this.isEnabled = 1,
    this.lastRunAt,
    this.maxBackups = 10,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'frequency': frequency,
      'time_of_day': timeOfDay,
      'day_of_week': dayOfWeek,
      'day_of_month': dayOfMonth,
      'is_enabled': isEnabled,
      'last_run_at': lastRunAt?.toIso8601String(),
      'max_backups': maxBackups,
    };
  }

  factory ExportSchedule.fromMap(Map<String, dynamic> map) {
    return ExportSchedule(
      id: map['id'] as int?,
      name: map['name'] as String,
      frequency: map['frequency'] as String? ?? 'daily',
      timeOfDay: map['time_of_day'] as String?,
      dayOfWeek: map['day_of_week'] as String?,
      dayOfMonth: map['day_of_month'] as String?,
      isEnabled: map['is_enabled'] as int? ?? 1,
      lastRunAt: map['last_run_at'] != null
          ? DateTime.parse(map['last_run_at'] as String)
          : null,
      maxBackups: map['max_backups'] as int? ?? 10,
    );
  }
}

/// 导出选项模型
class ExportOptions {
  final bool includePhotos;
  final bool includeAudio;
  final bool includeLocation;
  final bool includeTags;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<int>? recordIds; // 指定记录ID列表

  ExportOptions({
    this.includePhotos = true,
    this.includeAudio = true,
    this.includeLocation = true,
    this.includeTags = true,
    this.startDate,
    this.endDate,
    this.recordIds,
  });
}

/// 导出格式枚举
enum ExportFormat {
  json('json', 'JSON'),
  csv('csv', 'CSV'),
  pdf('pdf', 'PDF'),
  markdown('markdown', 'Markdown');

  final String value;
  final String label;

  const ExportFormat(this.value, this.label);

  static ExportFormat fromValue(String value) {
    return ExportFormat.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ExportFormat.csv,
    );
  }
}