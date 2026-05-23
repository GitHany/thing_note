/// Backup schedule configuration
class BackupSchedule {
  final int? id;
  final String name;
  final String frequency; // daily, weekly, monthly
  final String? timeOfDay; // HH:mm format
  final String? dayOfWeek; // for weekly: 0-6
  final String? dayOfMonth; // for monthly: 1-31
  final bool isEnabled;
  final DateTime? lastRunAt;
  final int? maxBackups; // keep only N backups

  BackupSchedule({
    this.id,
    required this.name,
    this.frequency = 'daily',
    this.timeOfDay,
    this.dayOfWeek,
    this.dayOfMonth,
    this.isEnabled = true,
    this.lastRunAt,
    this.maxBackups = 10,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'frequency': frequency,
      'time_of_day': timeOfDay,
      'day_of_week': dayOfWeek,
      'day_of_month': dayOfMonth,
      'is_enabled': isEnabled ? 1 : 0,
      'last_run_at': lastRunAt?.toIso8601String(),
      'max_backups': maxBackups,
    };
  }

  factory BackupSchedule.fromMap(Map<String, dynamic> map) {
    return BackupSchedule(
      id: map['id'] as int?,
      name: map['name'] as String,
      frequency: map['frequency'] as String? ?? 'daily',
      timeOfDay: map['time_of_day'] as String?,
      dayOfWeek: map['day_of_week'] as String?,
      dayOfMonth: map['day_of_month'] as String?,
      isEnabled: (map['is_enabled'] as int?) == 1,
      lastRunAt: map['last_run_at'] != null ? DateTime.parse(map['last_run_at'] as String) : null,
      maxBackups: map['max_backups'] as int? ?? 10,
    );
  }
}

/// Enhanced backup entry with metadata
class EnhancedBackupEntry {
  final int? id;
  final String name;
  final String filePath;
  final String backupType; // full, incremental, database, media
  final int fileSizeBytes;
  final int recordCount;
  final int mediaCount;
  final DateTime createdAt;
  final bool isCompressed;
  final bool isEncrypted;
  final String? checksum;

  EnhancedBackupEntry({
    this.id,
    required this.name,
    required this.filePath,
    this.backupType = 'full',
    this.fileSizeBytes = 0,
    this.recordCount = 0,
    this.mediaCount = 0,
    required this.createdAt,
    this.isCompressed = false,
    this.isEncrypted = false,
    this.checksum,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'file_path': filePath,
      'backup_type': backupType,
      'file_size_bytes': fileSizeBytes,
      'record_count': recordCount,
      'media_count': mediaCount,
      'created_at': createdAt.toIso8601String(),
      'is_compressed': isCompressed ? 1 : 0,
      'is_encrypted': isEncrypted ? 1 : 0,
      'checksum': checksum,
    };
  }

  factory EnhancedBackupEntry.fromMap(Map<String, dynamic> map) {
    return EnhancedBackupEntry(
      id: map['id'] as int?,
      name: map['name'] as String,
      filePath: map['file_path'] as String,
      backupType: map['backup_type'] as String? ?? 'full',
      fileSizeBytes: map['file_size_bytes'] as int? ?? 0,
      recordCount: map['record_count'] as int? ?? 0,
      mediaCount: map['media_count'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
      isCompressed: (map['is_compressed'] as int?) == 1,
      isEncrypted: (map['is_encrypted'] as int?) == 1,
      checksum: map['checksum'] as String?,
    );
  }

  String get formattedSize {
    if (fileSizeBytes < 1024) return '${fileSizeBytes}B';
    if (fileSizeBytes < 1024 * 1024) return '${(fileSizeBytes / 1024).toStringAsFixed(1)}KB';
    if (fileSizeBytes < 1024 * 1024 * 1024) return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(fileSizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }
}

/// Backup statistics
class BackupStats {
  final int totalBackups;
  final int totalSizeBytes;
  final int lastBackupDays;
  final double avgBackupSize;

  BackupStats({
    this.totalBackups = 0,
    this.totalSizeBytes = 0,
    this.lastBackupDays = 0,
    this.avgBackupSize = 0,
  });

  String get formattedTotalSize {
    if (totalSizeBytes < 1024 * 1024) return '${(totalSizeBytes / 1024).toStringAsFixed(1)}KB';
    if (totalSizeBytes < 1024 * 1024 * 1024) return '${(totalSizeBytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(totalSizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }
}