/// Backup destination types
enum BackupDestination {
  local,
  googleDrive,
  oneDrive,
  dropbox,
  custom,
}

/// Backup status
enum BackupStatus {
  idle,
  inProgress,
  completed,
  failed,
}

/// Backup entry model
class BackupEntry {
  final int? id;
  final String name;
  final DateTime createdAt;
  final int sizeBytes;
  final int recordCount;
  final String destination;
  final bool isAutoBackup;
  final DateTime? lastRestoredAt;

  BackupEntry({
    this.id,
    required this.name,
    required this.createdAt,
    this.sizeBytes = 0,
    this.recordCount = 0,
    required this.destination,
    this.isAutoBackup = false,
    this.lastRestoredAt,
  });

  BackupEntry copyWith({
    int? id,
    String? name,
    DateTime? createdAt,
    int? sizeBytes,
    int? recordCount,
    String? destination,
    bool? isAutoBackup,
    DateTime? lastRestoredAt,
  }) {
    return BackupEntry(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      recordCount: recordCount ?? this.recordCount,
      destination: destination ?? this.destination,
      isAutoBackup: isAutoBackup ?? this.isAutoBackup,
      lastRestoredAt: lastRestoredAt ?? this.lastRestoredAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'created_at': createdAt.toIso8601String(),
      'size_bytes': sizeBytes,
      'record_count': recordCount,
      'destination': destination,
      'is_auto_backup': isAutoBackup ? 1 : 0,
      'last_restored_at': lastRestoredAt?.toIso8601String(),
    };
  }

  factory BackupEntry.fromMap(Map<String, dynamic> map) {
    return BackupEntry(
      id: map['id'] as int?,
      name: map['name'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      sizeBytes: map['size_bytes'] as int? ?? 0,
      recordCount: map['record_count'] as int? ?? 0,
      destination: map['destination'] as String? ?? 'local',
      isAutoBackup: (map['is_auto_backup'] as int?) == 1,
      lastRestoredAt: map['last_restored_at'] != null
          ? DateTime.parse(map['last_restored_at'] as String)
          : null,
    );
  }

  String get formattedSize {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    if (sizeBytes < 1024 * 1024 * 1024) {
      return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(sizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

/// Backup configuration
class BackupConfig {
  final bool enableAutoBackup;
  final String autoBackupTime; // HH:mm
  final int retentionDays;
  final List<BackupDestination> destinations;
  final bool compressBackup;
  final bool encryptBackup;

  BackupConfig({
    this.enableAutoBackup = false,
    this.autoBackupTime = '02:00',
    this.retentionDays = 30,
    this.destinations = const [BackupDestination.local],
    this.compressBackup = true,
    this.encryptBackup = false,
  });
}

/// Backup progress info
class BackupProgress {
  final int currentStep;
  final int totalSteps;
  final String currentAction;
  final double progress;
  final String? errorMessage;

  BackupProgress({
    this.currentStep = 0,
    this.totalSteps = 0,
    this.currentAction = '',
    this.progress = 0.0,
    this.errorMessage,
  });
}