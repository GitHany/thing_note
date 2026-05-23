/// Export format types
enum ExportFormat {
  json,
  csv,
  pdf,
  html,
  markdown,
}

class ExportConfig {
  final ExportFormat format;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<int>? recordIds;
  final bool includePhotos;
  final bool includeAudio;
  final bool includeLocation;
  final bool includeTags;
  final String? fileName;

  ExportConfig({
    this.format = ExportFormat.json,
    this.startDate,
    this.endDate,
    this.recordIds,
    this.includePhotos = false,
    this.includeAudio = false,
    this.includeLocation = true,
    this.includeTags = true,
    this.fileName,
  });

  Map<String, dynamic> toMap() {
    return {
      'format': format.name,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'record_ids': recordIds,
      'include_photos': includePhotos,
      'include_audio': includeAudio,
      'include_location': includeLocation,
      'include_tags': includeTags,
      'file_name': fileName,
    };
  }
}

class ExportResult {
  final String filePath;
  final ExportFormat format;
  final int recordCount;
  final int fileSizeBytes;
  final DateTime exportedAt;

  ExportResult({
    required this.filePath,
    required this.format,
    required this.recordCount,
    required this.fileSizeBytes,
    required this.exportedAt,
  });

  String get formattedSize {
    if (fileSizeBytes < 1024) return '${fileSizeBytes}B';
    if (fileSizeBytes < 1024 * 1024) return '${(fileSizeBytes / 1024).toStringAsFixed(1)}KB';
    return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
}

class ExportTemplate {
  final int? id;
  final String name;
  final ExportFormat format;
  final bool includePhotos;
  final bool includeAudio;
  final bool includeLocation;
  final bool includeTags;
  final DateTime createdAt;

  ExportTemplate({
    this.id,
    required this.name,
    required this.format,
    this.includePhotos = false,
    this.includeAudio = false,
    this.includeLocation = true,
    this.includeTags = true,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'format': format.name,
      'include_photos': includePhotos ? 1 : 0,
      'include_audio': includeAudio ? 1 : 0,
      'include_location': includeLocation ? 1 : 0,
      'include_tags': includeTags ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ExportTemplate.fromMap(Map<String, dynamic> map) {
    return ExportTemplate(
      id: map['id'] as int?,
      name: map['name'] as String,
      format: ExportFormat.values.firstWhere(
        (f) => f.name == map['format'],
        orElse: () => ExportFormat.json,
      ),
      includePhotos: (map['include_photos'] as int?) == 1,
      includeAudio: (map['include_audio'] as int?) == 1,
      includeLocation: (map['include_location'] as int?) == 1,
      includeTags: (map['include_tags'] as int?) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  ExportConfig toConfig() {
    return ExportConfig(
      format: format,
      includePhotos: includePhotos,
      includeAudio: includeAudio,
      includeLocation: includeLocation,
      includeTags: includeTags,
      fileName: name,
    );
  }
}