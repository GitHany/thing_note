import 'package:thing_note/features/record/domain/episode_record.dart';

class BackupEntry {
  final String id;
  final String fileName;
  final DateTime createdAt;
  final int fileSize;
  final int recordCount;
  final bool isAutoBackup;
  final BackupType type;

  const BackupEntry({
    required this.id,
    required this.fileName,
    required this.createdAt,
    required this.fileSize,
    required this.recordCount,
    this.isAutoBackup = false,
    this.type = BackupType.full,
  });

  String get formattedSize {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

enum BackupType { full, incremental }

class RestorePreview {
  final List<EpisodeRecord> records;
  final Map<int, int> recordsByThingName;
  final DateTime? earliestDate;
  final DateTime? latestDate;
  final int totalRecords;

  const RestorePreview({
    required this.records,
    required this.recordsByThingName,
    this.earliestDate,
    this.latestDate,
    required this.totalRecords,
  });
}

class BackupConfig {
  final bool autoBackupEnabled;
  final Duration autoBackupInterval;
  final int maxBackupsToKeep;
  final bool compressBackups;

  const BackupConfig({
    this.autoBackupEnabled = false,
    this.autoBackupInterval = const Duration(days: 1),
    this.maxBackupsToKeep = 7,
    this.compressBackups = true,
  });

  BackupConfig copyWith({
    bool? autoBackupEnabled,
    Duration? autoBackupInterval,
    int? maxBackupsToKeep,
    bool? compressBackups,
  }) {
    return BackupConfig(
      autoBackupEnabled: autoBackupEnabled ?? this.autoBackupEnabled,
      autoBackupInterval: autoBackupInterval ?? this.autoBackupInterval,
      maxBackupsToKeep: maxBackupsToKeep ?? this.maxBackupsToKeep,
      compressBackups: compressBackups ?? this.compressBackups,
    );
  }
}