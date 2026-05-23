/// Export format types
enum ExportFormat {
  pdf,
  csv,
  json,
  markdown,
  html,
}

/// Export template for custom formatting
class ExportTemplate {
  final int? id;
  final String name;
  final ExportFormat format;
  final List<String> includeFields;
  final Map<String, dynamic>? styling;
  final bool isDefault;
  final DateTime createdAt;

  ExportTemplate({
    this.id,
    required this.name,
    required this.format,
    this.includeFields = const [],
    this.styling,
    this.isDefault = false,
    required this.createdAt,
  });

  ExportTemplate copyWith({
    int? id,
    String? name,
    ExportFormat? format,
    List<String>? includeFields,
    Map<String, dynamic>? styling,
    bool? isDefault,
    DateTime? createdAt,
  }) {
    return ExportTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      format: format ?? this.format,
      includeFields: includeFields ?? this.includeFields,
      styling: styling ?? this.styling,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'format': format.name,
      'include_fields': includeFields.join(','),
      'styling': styling?.toString(),
      'is_default': isDefault ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ExportTemplate.fromMap(Map<String, dynamic> map) {
    return ExportTemplate(
      id: map['id'] as int?,
      name: map['name'] as String,
      format: ExportFormat.values.firstWhere(
        (f) => f.name == map['format'],
        orElse: () => ExportFormat.csv,
      ),
      includeFields: (map['include_fields'] as String?)?.split(',').where((e) => e.isNotEmpty).toList() ?? [],
      styling: null,
      isDefault: (map['is_default'] as int?) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

/// Export configuration
class ExportConfig {
  final DateTime? startDate;
  final DateTime? endDate;
  final List<int>? recordIds;
  final List<int>? thingNameIds;
  final List<int>? tagIds;
  final ExportFormat format;
  final ExportTemplate? template;
  final bool includePhotos;
  final bool includeAudio;
  final bool includeLocation;

  ExportConfig({
    this.startDate,
    this.endDate,
    this.recordIds,
    this.thingNameIds,
    this.tagIds,
    this.format = ExportFormat.csv,
    this.template,
    this.includePhotos = false,
    this.includeAudio = false,
    this.includeLocation = false,
  });
}

/// Export result
class ExportResult {
  final String filePath;
  final int recordCount;
  final int fileSizeBytes;
  final Duration duration;
  final String? errorMessage;

  ExportResult({
    required this.filePath,
    required this.recordCount,
    required this.fileSizeBytes,
    required this.duration,
    this.errorMessage,
  });

  bool get isSuccess => errorMessage == null;
}