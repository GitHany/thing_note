/// 时间追踪记录模型
class TimeTrackingEntry {
  final int? id;
  final int? recordId;
  final String thingName;
  final int durationMinutes;
  final String periodType; // morning, afternoon, evening, night
  final DateTime trackedAt;
  final DateTime createdAt;

  TimeTrackingEntry({
    this.id,
    this.recordId,
    required this.thingName,
    required this.durationMinutes,
    required this.periodType,
    required this.trackedAt,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'record_id': recordId,
      'thing_name': thingName,
      'duration_minutes': durationMinutes,
      'period_type': periodType,
      'tracked_at': trackedAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory TimeTrackingEntry.fromMap(Map<String, dynamic> map) {
    return TimeTrackingEntry(
      id: map['id'] as int?,
      recordId: map['record_id'] as int?,
      thingName: map['thing_name'] as String,
      durationMinutes: map['duration_minutes'] as int,
      periodType: map['period_type'] as String,
      trackedAt: DateTime.parse(map['tracked_at'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  TimeTrackingEntry copyWith({
    int? id,
    int? recordId,
    String? thingName,
    int? durationMinutes,
    String? periodType,
    DateTime? trackedAt,
    DateTime? createdAt,
  }) {
    return TimeTrackingEntry(
      id: id ?? this.id,
      recordId: recordId ?? this.recordId,
      thingName: thingName ?? this.thingName,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      periodType: periodType ?? this.periodType,
      trackedAt: trackedAt ?? this.trackedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// 时间分析数据模型
class TimeAnalytics {
  final int? id;
  final String periodType; // daily, weekly, monthly, yearly
  final DateTime periodStart;
  final DateTime periodEnd;
  final int totalMinutes;
  final List<String> topActivities;
  final double efficiencyScore;
  final DateTime createdAt;

  TimeAnalytics({
    this.id,
    required this.periodType,
    required this.periodStart,
    required this.periodEnd,
    this.totalMinutes = 0,
    this.topActivities = const [],
    this.efficiencyScore = 0.0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  String get formattedDuration {
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (hours > 0) {
      return '$hours小时$minutes分钟';
    }
    return '$minutes分钟';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'period_type': periodType,
      'period_start': periodStart.toIso8601String(),
      'period_end': periodEnd.toIso8601String(),
      'total_minutes': totalMinutes,
      'top_activities': topActivities.join(','),
      'efficiency_score': efficiencyScore,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory TimeAnalytics.fromMap(Map<String, dynamic> map) {
    final topActivitiesStr = map['top_activities'] as String? ?? '';
    return TimeAnalytics(
      id: map['id'] as int?,
      periodType: map['period_type'] as String,
      periodStart: DateTime.parse(map['period_start'] as String),
      periodEnd: DateTime.parse(map['period_end'] as String),
      totalMinutes: map['total_minutes'] as int? ?? 0,
      topActivities: topActivitiesStr.isEmpty ? [] : topActivitiesStr.split(','),
      efficiencyScore: (map['efficiency_score'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

/// 时间段枚举
enum PeriodType {
  morning('morning', '上午', '06:00-12:00'),
  afternoon('afternoon', '下午', '12:00-18:00'),
  evening('evening', '傍晚', '18:00-22:00'),
  night('night', '夜间', '22:00-06:00');

  final String value;
  final String label;
  final String timeRange;

  const PeriodType(this.value, this.label, this.timeRange);

  static PeriodType fromTime(DateTime time) {
    final hour = time.hour;
    if (hour >= 6 && hour < 12) return PeriodType.morning;
    if (hour >= 12 && hour < 18) return PeriodType.afternoon;
    if (hour >= 18 && hour < 22) return PeriodType.evening;
    return PeriodType.night;
  }

  static PeriodType fromValue(String value) {
    return PeriodType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => PeriodType.morning,
    );
  }
}