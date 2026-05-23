class DeviceSyncState {
  final int id;
  final String deviceId;
  final DateTime lastSyncTime;
  final int syncVersion;
  final int pendingChanges;
  final String status;

  DeviceSyncState({
    required this.id,
    required this.deviceId,
    required this.lastSyncTime,
    required this.syncVersion,
    this.pendingChanges = 0,
    this.status = 'active',
  });

  factory DeviceSyncState.fromMap(Map<String, dynamic> map) {
    return DeviceSyncState(
      id: map['id'] as int,
      deviceId: map['device_id'] as String,
      lastSyncTime: DateTime.parse(map['last_sync_time'] as String),
      syncVersion: map['sync_version'] as int? ?? 0,
      pendingChanges: map['pending_changes'] as int? ?? 0,
      status: map['status'] as String? ?? 'active',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'device_id': deviceId,
      'last_sync_time': lastSyncTime.toIso8601String(),
      'sync_version': syncVersion,
      'pending_changes': pendingChanges,
      'status': status,
    };
  }
}

class SyncRecord {
  final int id;
  final String entityType;
  final int entityId;
  final String action;
  final String data;
  final DateTime createdAt;
  final bool synced;

  SyncRecord({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.action,
    required this.data,
    required this.createdAt,
    this.synced = false,
  });

  factory SyncRecord.fromMap(Map<String, dynamic> map) {
    return SyncRecord(
      id: map['id'] as int,
      entityType: map['entity_type'] as String,
      entityId: map['entity_id'] as int,
      action: map['action'] as String,
      data: map['data'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      synced: (map['synced'] as int?) == 1,
    );
  }
}

class SyncStats {
  final int totalDevices;
  final int activeDevices;
  final DateTime? lastSyncTime;
  final int pendingChanges;
  final double syncSuccessRate;

  SyncStats({
    required this.totalDevices,
    required this.activeDevices,
    this.lastSyncTime,
    required this.pendingChanges,
    required this.syncSuccessRate,
  });
}