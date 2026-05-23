enum SyncStatus { idle, syncing, success, failed }

enum SyncDirection { upload, download }

class SyncResult {
  final SyncStatus status;
  final int recordsUploaded;
  final int recordsDownloaded;
  final String? errorMessage;
  final DateTime? lastSyncTime;

  const SyncResult({
    required this.status,
    this.recordsUploaded = 0,
    this.recordsDownloaded = 0,
    this.errorMessage,
    this.lastSyncTime,
  });
}

class SyncConfig {
  final bool autoSyncEnabled;
  final Duration autoSyncInterval;
  final SyncDirection preferredDirection;

  const SyncConfig({
    this.autoSyncEnabled = false,
    this.autoSyncInterval = const Duration(hours: 1),
    this.preferredDirection = SyncDirection.upload,
  });

  SyncConfig copyWith({
    bool? autoSyncEnabled,
    Duration? autoSyncInterval,
    SyncDirection? preferredDirection,
  }) {
    return SyncConfig(
      autoSyncEnabled: autoSyncEnabled ?? this.autoSyncEnabled,
      autoSyncInterval: autoSyncInterval ?? this.autoSyncInterval,
      preferredDirection: preferredDirection ?? this.preferredDirection,
    );
  }
}