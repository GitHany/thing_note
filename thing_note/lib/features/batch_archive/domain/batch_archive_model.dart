/// Archive Config model
class ArchiveConfig {
  final int? id;
  final bool autoArchiveEnabled;
  final int autoArchiveDays;
  final List<String> excludeCategories;
  final int batchSize;
  final bool compressMedia;
  final int compressionQuality;

  ArchiveConfig({
    this.id,
    this.autoArchiveEnabled = false,
    this.autoArchiveDays = 365,
    this.excludeCategories = const [],
    this.batchSize = 100,
    this.compressMedia = true,
    this.compressionQuality = 70,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'auto_archive_enabled': autoArchiveEnabled ? 1 : 0,
      'auto_archive_days': autoArchiveDays,
      'exclude_categories': excludeCategories.join(','),
      'batch_size': batchSize,
      'compress_media': compressMedia ? 1 : 0,
      'compression_quality': compressionQuality,
    };
  }

  factory ArchiveConfig.fromMap(Map<String, dynamic> map) {
    final categoriesStr = map['exclude_categories'] as String?;
    return ArchiveConfig(
      id: map['id'] as int?,
      autoArchiveEnabled: (map['auto_archive_enabled'] as int?) == 1,
      autoArchiveDays: map['auto_archive_days'] as int? ?? 365,
      excludeCategories: categoriesStr != null && categoriesStr.isNotEmpty 
          ? categoriesStr.split(',') 
          : [],
      batchSize: map['batch_size'] as int? ?? 100,
      compressMedia: (map['compress_media'] as int?) == 1,
      compressionQuality: map['compression_quality'] as int? ?? 70,
    );
  }
}

/// Archive Job model
class ArchiveJob {
  final int? id;
  final String name;
  final String type; // manual, auto, scheduled
  final DateTime createdAt;
  final DateTime? completedAt;
  final int recordsAffected;
  final int storageFreed;
  final String status; // pending, running, completed, failed
  final String? error;

  ArchiveJob({
    this.id,
    required this.name,
    required this.type,
    required this.createdAt,
    this.completedAt,
    this.recordsAffected = 0,
    this.storageFreed = 0,
    this.status = 'pending',
    this.error,
  });

  Duration? get duration => completedAt?.difference(createdAt);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'created_at': createdAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'records_affected': recordsAffected,
      'storage_freed': storageFreed,
      'status': status,
      'error': error,
    };
  }

  factory ArchiveJob.fromMap(Map<String, dynamic> map) {
    return ArchiveJob(
      id: map['id'] as int?,
      name: map['name'] as String,
      type: map['type'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      completedAt: map['completed_at'] != null 
          ? DateTime.parse(map['completed_at'] as String) 
          : null,
      recordsAffected: map['records_affected'] as int? ?? 0,
      storageFreed: map['storage_freed'] as int? ?? 0,
      status: map['status'] as String? ?? 'pending',
      error: map['error'] as String?,
    );
  }
}