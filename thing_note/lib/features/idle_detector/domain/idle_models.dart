class IdleTimeRecord {
  final int? id;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int durationMinutes;
  final String idleType;
  final String? reason;
  final bool isProductive;
  final int? linkedRecordId;
  final DateTime createdAt;

  IdleTimeRecord({
    this.id,
    required this.startedAt,
    this.endedAt,
    this.durationMinutes = 0,
    this.idleType = 'unplanned',
    this.reason,
    this.isProductive = false,
    this.linkedRecordId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'started_at': startedAt.toIso8601String(),
      'ended_at': endedAt?.toIso8601String(),
      'duration_minutes': durationMinutes,
      'idle_type': idleType,
      'reason': reason,
      'is_productive': isProductive ? 1 : 0,
      'linked_record_id': linkedRecordId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory IdleTimeRecord.fromMap(Map<String, dynamic> map) {
    return IdleTimeRecord(
      id: map['id'] as int?,
      startedAt: DateTime.parse(map['started_at'] as String),
      endedAt: map['ended_at'] != null ? DateTime.parse(map['ended_at'] as String) : null,
      durationMinutes: map['duration_minutes'] as int? ?? 0,
      idleType: map['idle_type'] as String? ?? 'unplanned',
      reason: map['reason'] as String?,
      isProductive: (map['is_productive'] as int?) == 1,
      linkedRecordId: map['linked_record_id'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  IdleTimeRecord copyWith({
    int? id,
    DateTime? startedAt,
    DateTime? endedAt,
    int? durationMinutes,
    String? idleType,
    String? reason,
    bool? isProductive,
    int? linkedRecordId,
    DateTime? createdAt,
  }) {
    return IdleTimeRecord(
      id: id ?? this.id,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      idleType: idleType ?? this.idleType,
      reason: reason ?? this.reason,
      isProductive: isProductive ?? this.isProductive,
      linkedRecordId: linkedRecordId ?? this.linkedRecordId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}