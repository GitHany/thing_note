/// Weekly Planner Item model
class WeeklyPlannerItem {
  final int? id;
  final String title;
  final String? description;
  final int dayOfWeek;
  final String? startTime;
  final int durationMinutes;
  final String priority;
  final String status;
  final int? linkedRecordId;
  final DateTime createdAt;

  static const dayNames = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];

  WeeklyPlannerItem({
    this.id,
    required this.title,
    this.description,
    required this.dayOfWeek,
    this.startTime,
    this.durationMinutes = 60,
    this.priority = 'normal',
    this.status = 'pending',
    this.linkedRecordId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  String get dayName => dayNames[dayOfWeek - 1];

  bool get isCompleted => status == 'completed';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'day_of_week': dayOfWeek,
      'start_time': startTime,
      'duration_minutes': durationMinutes,
      'priority': priority,
      'status': status,
      'linked_record_id': linkedRecordId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory WeeklyPlannerItem.fromMap(Map<String, dynamic> map) {
    return WeeklyPlannerItem(
      id: map['id'] as int?,
      title: map['title'] as String,
      description: map['description'] as String?,
      dayOfWeek: map['day_of_week'] as int,
      startTime: map['start_time'] as String?,
      durationMinutes: map['duration_minutes'] as int? ?? 60,
      priority: map['priority'] as String? ?? 'normal',
      status: map['status'] as String? ?? 'pending',
      linkedRecordId: map['linked_record_id'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  WeeklyPlannerItem copyWith({
    int? id,
    String? title,
    String? description,
    int? dayOfWeek,
    String? startTime,
    int? durationMinutes,
    String? priority,
    String? status,
    int? linkedRecordId,
    DateTime? createdAt,
  }) {
    return WeeklyPlannerItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startTime: startTime ?? this.startTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      linkedRecordId: linkedRecordId ?? this.linkedRecordId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}