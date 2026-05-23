/// Idle time type classification
enum IdleType {
  unplanned,
  breakTime,
  waiting,
  distracted,
  rest;

  String get displayName {
    switch (this) {
      case IdleType.unplanned:
        return 'Unplanned';
      case IdleType.breakTime:
        return 'Break';
      case IdleType.waiting:
        return 'Waiting';
      case IdleType.distracted:
        return 'Distracted';
      case IdleType.rest:
        return 'Rest';
    }
  }

  String get icon {
    switch (this) {
      case IdleType.unplanned:
        return '📋';
      case IdleType.breakTime:
        return '☕';
      case IdleType.waiting:
        return '⏳';
      case IdleType.distracted:
        return '📱';
      case IdleType.rest:
        return '😴';
    }
  }

  bool get isProductiveDefault {
    switch (this) {
      case IdleType.breakTime:
      case IdleType.rest:
        return true;
      default:
        return false;
    }
  }

  static IdleType fromString(String value) {
    switch (value) {
      case 'break':
        return IdleType.breakTime;
      case 'waiting':
        return IdleType.waiting;
      case 'distracted':
        return IdleType.distracted;
      case 'rest':
        return IdleType.rest;
      default:
        return IdleType.unplanned;
    }
  }

  String toDbString() {
    switch (this) {
      case IdleType.breakTime:
        return 'break';
      default:
        return name;
    }
  }
}

/// Idle time record model
class IdleTimeRecord {
  final int? id;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int durationMinutes;
  final IdleType idleType;
  final String? reason;
  final bool isProductive;
  final int? linkedRecordId;
  final DateTime createdAt;

  IdleTimeRecord({
    this.id,
    required this.startedAt,
    this.endedAt,
    this.durationMinutes = 0,
    this.idleType = IdleType.unplanned,
    this.reason,
    this.isProductive = false,
    this.linkedRecordId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Create a copy with updated fields
  IdleTimeRecord copyWith({
    int? id,
    DateTime? startedAt,
    DateTime? endedAt,
    int? durationMinutes,
    IdleType? idleType,
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

  /// Complete the idle record with end time
  IdleTimeRecord complete({DateTime? endTime}) {
    final end = endTime ?? DateTime.now();
    final duration = end.difference(startedAt).inMinutes;
    return copyWith(
      endedAt: end,
      durationMinutes: duration,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'started_at': startedAt.toIso8601String(),
      'ended_at': endedAt?.toIso8601String(),
      'duration_minutes': durationMinutes,
      'idle_type': idleType.toDbString(),
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
      idleType: IdleType.fromString(map['idle_type'] as String? ?? 'unplanned'),
      reason: map['reason'] as String?,
      isProductive: (map['is_productive'] as int? ?? 0) == 1,
      linkedRecordId: map['linked_record_id'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

/// Statistics for idle time records
class IdleTimeStats {
  final int totalRecords;
  final int totalMinutes;
  final double averageMinutes;
  final double productiveRatio;
  final Map<IdleType, int> minutesByType;
  final Map<IdleType, int> countByType;

  IdleTimeStats({
    this.totalRecords = 0,
    this.totalMinutes = 0,
    this.averageMinutes = 0,
    this.productiveRatio = 0,
    this.minutesByType = const {},
    this.countByType = const {},
  });

  factory IdleTimeStats.fromRecords(List<IdleTimeRecord> records) {
    if (records.isEmpty) {
      return IdleTimeStats();
    }

    final totalRecords = records.length;
    final totalMinutes = records.fold<int>(
      0,
      (sum, r) => sum + r.durationMinutes,
    );
    final averageMinutes = totalMinutes / totalRecords;
    final productiveCount = records.where((r) => r.isProductive).length;
    final productiveRatio = productiveCount / totalRecords;

    final minutesByType = <IdleType, int>{};
    final countByType = <IdleType, int>{};

    for (final type in IdleType.values) {
      final typeRecords = records.where((r) => r.idleType == type).toList();
      minutesByType[type] = typeRecords.fold(0, (sum, r) => sum + r.durationMinutes);
      countByType[type] = typeRecords.length;
    }

    return IdleTimeStats(
      totalRecords: totalRecords,
      totalMinutes: totalMinutes,
      averageMinutes: averageMinutes,
      productiveRatio: productiveRatio,
      minutesByType: minutesByType,
      countByType: countByType,
    );
  }
}