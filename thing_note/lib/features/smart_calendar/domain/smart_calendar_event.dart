class SmartCalendarEvent {
  final int? id;
  final String title;
  final String? description;
  final DateTime startTime;
  final DateTime? endTime;
  final bool isAllDay;
  final bool isRecurring;
  final String? recurrenceRule;
  final String color;
  final int? linkedRecordId;
  final DateTime createdAt;

  SmartCalendarEvent({
    this.id,
    required this.title,
    this.description,
    required this.startTime,
    this.endTime,
    this.isAllDay = false,
    this.isRecurring = false,
    this.recurrenceRule,
    this.color = '#2196F3',
    this.linkedRecordId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'description': description,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'all_day': isAllDay ? 1 : 0,
      'is_recurring': isRecurring ? 1 : 0,
      'recurrence_rule': recurrenceRule,
      'color': color,
      'linked_record_id': linkedRecordId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory SmartCalendarEvent.fromMap(Map<String, dynamic> map) {
    return SmartCalendarEvent(
      id: map['id'] as int?,
      title: map['title'] as String,
      description: map['description'] as String?,
      startTime: DateTime.parse(map['start_time'] as String),
      endTime: map['end_time'] != null ? DateTime.parse(map['end_time'] as String) : null,
      isAllDay: (map['all_day'] as int?) == 1,
      isRecurring: (map['is_recurring'] as int?) == 1,
      recurrenceRule: map['recurrence_rule'] as String?,
      color: map['color'] as String? ?? '#2196F3',
      linkedRecordId: map['linked_record_id'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  SmartCalendarEvent copyWith({
    int? id,
    String? title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    bool? isAllDay,
    bool? isRecurring,
    String? recurrenceRule,
    String? color,
    int? linkedRecordId,
    DateTime? createdAt,
  }) {
    return SmartCalendarEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isAllDay: isAllDay ?? this.isAllDay,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrenceRule: recurrenceRule ?? this.recurrenceRule,
      color: color ?? this.color,
      linkedRecordId: linkedRecordId ?? this.linkedRecordId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}