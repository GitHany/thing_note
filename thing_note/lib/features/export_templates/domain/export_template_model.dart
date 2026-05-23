/// Export Template model
class ExportTemplate {
  final int? id;
  final String name;
  final String format; // csv, json, pdf, html, markdown
  final bool includePhotos;
  final bool includeAudio;
  final bool includeLocation;
  final bool includeTags;
  final bool includeDuration;
  final bool includeAnnotations;
  final List<String> customFields;
  final String? filterConfig;
  final DateTime createdAt;

  ExportTemplate({
    this.id,
    required this.name,
    required this.format,
    this.includePhotos = false,
    this.includeAudio = false,
    this.includeLocation = true,
    this.includeTags = true,
    this.includeDuration = true,
    this.includeAnnotations = true,
    this.customFields = const [],
    this.filterConfig,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'format': format,
      'include_photos': includePhotos ? 1 : 0,
      'include_audio': includeAudio ? 1 : 0,
      'include_location': includeLocation ? 1 : 0,
      'include_tags': includeTags ? 1 : 0,
      'include_duration': includeDuration ? 1 : 0,
      'include_annotations': includeAnnotations ? 1 : 0,
      'custom_fields': customFields.join(','),
      'filter_config': filterConfig,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ExportTemplate.fromMap(Map<String, dynamic> map) {
    final fieldsStr = map['custom_fields'] as String?;
    return ExportTemplate(
      id: map['id'] as int?,
      name: map['name'] as String,
      format: map['format'] as String,
      includePhotos: (map['include_photos'] as int?) == 1,
      includeAudio: (map['include_audio'] as int?) == 1,
      includeLocation: (map['include_location'] as int?) == 1,
      includeTags: (map['include_tags'] as int?) == 1,
      includeDuration: (map['include_duration'] as int?) == 1,
      includeAnnotations: (map['include_annotations'] as int?) == 1,
      customFields: fieldsStr != null && fieldsStr.isNotEmpty 
          ? fieldsStr.split(',') 
          : [],
      filterConfig: map['filter_config'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  ExportTemplate copyWith({
    int? id,
    String? name,
    String? format,
    bool? includePhotos,
    bool? includeAudio,
    bool? includeLocation,
    bool? includeTags,
    bool? includeDuration,
    bool? includeAnnotations,
    List<String>? customFields,
    String? filterConfig,
    DateTime? createdAt,
  }) {
    return ExportTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      format: format ?? this.format,
      includePhotos: includePhotos ?? this.includePhotos,
      includeAudio: includeAudio ?? this.includeAudio,
      includeLocation: includeLocation ?? this.includeLocation,
      includeTags: includeTags ?? this.includeTags,
      includeDuration: includeDuration ?? this.includeDuration,
      includeAnnotations: includeAnnotations ?? this.includeAnnotations,
      customFields: customFields ?? this.customFields,
      filterConfig: filterConfig ?? this.filterConfig,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Export History model
class ExportHistory {
  final int? id;
  final String format;
  final int recordCount;
  final String? filePath;
  final DateTime createdAt;

  ExportHistory({
    this.id,
    required this.format,
    required this.recordCount,
    this.filePath,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'format': format,
      'record_count': recordCount,
      'file_path': filePath,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ExportHistory.fromMap(Map<String, dynamic> map) {
    return ExportHistory(
      id: map['id'] as int?,
      format: map['format'] as String,
      recordCount: map['record_count'] as int? ?? 0,
      filePath: map['file_path'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}