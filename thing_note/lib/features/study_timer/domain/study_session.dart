/// 学习计时器数据模型
class StudySession {
  final int? id;
  final String subject;
  final String? description;
  final int durationMinutes;
  final DateTime startedAt;
  final DateTime? endedAt;
  final SessionStatus status;
  final int? linkedRecordId;
  final DateTime createdAt;

  const StudySession({
    this.id,
    required this.subject,
    this.description,
    required this.durationMinutes,
    required this.startedAt,
    this.endedAt,
    this.status = SessionStatus.inProgress,
    this.linkedRecordId,
    required this.createdAt,
  });

  StudySession copyWith({
    int? id,
    String? subject,
    String? description,
    int? durationMinutes,
    DateTime? startedAt,
    DateTime? endedAt,
    SessionStatus? status,
    int? linkedRecordId,
    DateTime? createdAt,
  }) {
    return StudySession(
      id: id ?? this.id,
      subject: subject ?? this.subject,
      description: description ?? this.description,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      status: status ?? this.status,
      linkedRecordId: linkedRecordId ?? this.linkedRecordId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Duration get actualDuration {
    final end = endedAt ?? DateTime.now();
    return end.difference(startedAt);
  }

  bool get isCompleted => status == SessionStatus.completed;

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'subject': subject,
      'description': description,
      'duration_minutes': durationMinutes,
      'started_at': startedAt.toIso8601String(),
      'ended_at': endedAt?.toIso8601String(),
      'status': status.name,
      'linked_record_id': linkedRecordId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory StudySession.fromMap(Map<String, dynamic> map) {
    return StudySession(
      id: map['id'] as int?,
      subject: map['subject'] as String,
      description: map['description'] as String?,
      durationMinutes: map['duration_minutes'] as int? ?? 0,
      startedAt: DateTime.parse(map['started_at'] as String),
      endedAt: map['ended_at'] != null ? DateTime.parse(map['ended_at'] as String) : null,
      status: SessionStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => SessionStatus.inProgress,
      ),
      linkedRecordId: map['linked_record_id'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

enum SessionStatus { inProgress, completed, cancelled }

extension SessionStatusExtension on SessionStatus {
  String get displayName {
    switch (this) {
      case SessionStatus.inProgress:
        return '进行中';
      case SessionStatus.completed:
        return '已完成';
      case SessionStatus.cancelled:
        return '已取消';
    }
  }
}