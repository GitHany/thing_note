/// 记录快照 - Record Snapshot
/// 快速保存和恢复记录状态
library;

/// 快照模型
class RecordSnapshot {
  final int id;
  final int recordId;
  final String snapshotData;
  final String? note;
  final DateTime createdAt;
  final DateTime? expiresAt;

  RecordSnapshot({
    required this.id,
    required this.recordId,
    required this.snapshotData,
    this.note,
    required this.createdAt,
    this.expiresAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'record_id': recordId,
      'snapshot_data': snapshotData,
      'note': note,
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
    };
  }

  factory RecordSnapshot.fromMap(Map<String, dynamic> map) {
    return RecordSnapshot(
      id: map['id'] as int,
      recordId: map['record_id'] as int,
      snapshotData: map['snapshot_data'] as String,
      note: map['note'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      expiresAt: map['expires_at'] != null
          ? DateTime.parse(map['expires_at'] as String)
          : null,
    );
  }

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }
}

/// 快照配置
class SnapshotConfig {
  final bool autoSnapshot;
  final int maxSnapshots;
  final bool autoDeleteExpired;

  SnapshotConfig({
    this.autoSnapshot = true,
    this.maxSnapshots = 10,
    this.autoDeleteExpired = true,
  });
}