class FlowState {
  final int? id;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int durationMinutes;
  final int focusRating;
  final int distractionCount;
  final int? linkedRecordId;
  final String? note;
  final DateTime createdAt;

  FlowState({
    this.id,
    required this.startedAt,
    this.endedAt,
    this.durationMinutes = 0,
    this.focusRating = 0,
    this.distractionCount = 0,
    this.linkedRecordId,
    this.note,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'started_at': startedAt.toIso8601String(),
      'ended_at': endedAt?.toIso8601String(),
      'duration_minutes': durationMinutes,
      'focus_rating': focusRating,
      'distraction_count': distractionCount,
      'linked_record_id': linkedRecordId,
      'note': note,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory FlowState.fromMap(Map<String, dynamic> map) {
    return FlowState(
      id: map['id'] as int?,
      startedAt: DateTime.parse(map['started_at'] as String),
      endedAt: map['ended_at'] != null ? DateTime.parse(map['ended_at'] as String) : null,
      durationMinutes: map['duration_minutes'] as int? ?? 0,
      focusRating: map['focus_rating'] as int? ?? 0,
      distractionCount: map['distraction_count'] as int? ?? 0,
      linkedRecordId: map['linked_record_id'] as int?,
      note: map['note'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  FlowState copyWith({
    int? id,
    DateTime? startedAt,
    DateTime? endedAt,
    int? durationMinutes,
    int? focusRating,
    int? distractionCount,
    int? linkedRecordId,
    String? note,
    DateTime? createdAt,
  }) {
    return FlowState(
      id: id ?? this.id,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      focusRating: focusRating ?? this.focusRating,
      distractionCount: distractionCount ?? this.distractionCount,
      linkedRecordId: linkedRecordId ?? this.linkedRecordId,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool get isActive => endedAt == null;

  String get statusLabel {
    if (isActive) return 'Active';
    if (focusRating >= 4) return 'Deep Focus';
    if (focusRating >= 3) return 'Good Focus';
    return 'Normal';
  }
}