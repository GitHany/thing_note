/// 同步状态模型
class SyncStatus {
  final bool isConnected;
  final bool isSyncing;
  final DateTime? lastSyncTime;
  final int pendingCount;
  final String? errorMessage;

  SyncStatus({
    this.isConnected = false,
    this.isSyncing = false,
    this.lastSyncTime,
    this.pendingCount = 0,
    this.errorMessage,
  });
}

/// 同步冲突模型
class SyncConflict {
  final int? id;
  final int recordId;
  final String localVersion;
  final String remoteVersion;
  final String conflictType; // field_conflict, deleted_remotely
  final DateTime detectedAt;
  final String? resolution; // local, remote, merged

  SyncConflict({
    this.id,
    required this.recordId,
    required this.localVersion,
    required this.remoteVersion,
    required this.conflictType,
    required this.detectedAt,
    this.resolution,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'record_id': recordId,
      'local_version': localVersion,
      'remote_version': remoteVersion,
      'conflict_type': conflictType,
      'detected_at': detectedAt.toIso8601String(),
      'resolution': resolution,
    };
  }

  factory SyncConflict.fromMap(Map<String, dynamic> map) {
    return SyncConflict(
      id: map['id'] as int?,
      recordId: map['record_id'] as int,
      localVersion: map['local_version'] as String,
      remoteVersion: map['remote_version'] as String,
      conflictType: map['conflict_type'] as String,
      detectedAt: DateTime.parse(map['detected_at'] as String),
      resolution: map['resolution'] as String?,
    );
  }
}

/// 同步队列项
class SyncQueueItem {
  final int? id;
  final int recordId;
  final String action; // create, update, delete
  final String status; // pending, syncing, synced, failed
  final String? payload;
  final int retryCount;
  final DateTime createdAt;
  final DateTime? lastAttemptAt;

  SyncQueueItem({
    this.id,
    required this.recordId,
    required this.action,
    this.status = 'pending',
    this.payload,
    this.retryCount = 0,
    DateTime? createdAt,
    this.lastAttemptAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'record_id': recordId,
      'action': action,
      'status': status,
      'payload': payload,
      'retry_count': retryCount,
      'created_at': createdAt.toIso8601String(),
      'last_attempt_at': lastAttemptAt?.toIso8601String(),
    };
  }

  factory SyncQueueItem.fromMap(Map<String, dynamic> map) {
    return SyncQueueItem(
      id: map['id'] as int?,
      recordId: map['record_id'] as int,
      action: map['action'] as String,
      status: map['status'] as String,
      payload: map['payload'] as String?,
      retryCount: map['retry_count'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
      lastAttemptAt: map['last_attempt_at'] != null
          ? DateTime.parse(map['last_attempt_at'] as String)
          : null,
    );
  }
}

/// 同步历史记录
class SyncHistoryItem {
  final DateTime syncedAt;
  final String action;
  final int recordCount;
  final bool success;
  final String? error;

  SyncHistoryItem({
    required this.syncedAt,
    required this.action,
    required this.recordCount,
    required this.success,
    this.error,
  });
}