/// Time Audit Entry model
class TimeAuditEntry {
  final int? id;
  final DateTime date;
  final String activity;
  final int startHour;
  final int endHour;
  final int durationMinutes;
  final String category;
  final int productivity;
  final String? note;
  final DateTime createdAt;

  TimeAuditEntry({
    this.id,
    required this.date,
    required this.activity,
    required this.startHour,
    required this.endHour,
    this.durationMinutes = 0,
    required this.category,
    this.productivity = 3,
    this.note,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String().substring(0, 10),
      'activity': activity,
      'start_hour': startHour,
      'end_hour': endHour,
      'duration_minutes': durationMinutes,
      'category': category,
      'productivity': productivity,
      'note': note,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory TimeAuditEntry.fromMap(Map<String, dynamic> map) {
    return TimeAuditEntry(
      id: map['id'] as int?,
      date: DateTime.parse(map['date'] as String),
      activity: map['activity'] as String,
      startHour: map['start_hour'] as int,
      endHour: map['end_hour'] as int,
      durationMinutes: map['duration_minutes'] as int? ?? 0,
      category: map['category'] as String,
      productivity: map['productivity'] as int? ?? 3,
      note: map['note'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

/// Time Distribution model
class TimeDistribution {
  final String category;
  final int totalMinutes;
  final double percentage;
  final int entryCount;

  TimeDistribution({
    required this.category,
    required this.totalMinutes,
    required this.percentage,
    required this.entryCount,
  });
}

/// Peak Productivity Hour model
class PeakProductivityHour {
  final int hour;
  final double avgProductivity;
  final int sessionCount;

  PeakProductivityHour({
    required this.hour,
    required this.avgProductivity,
    required this.sessionCount,
  });

  String get formattedHour {
    final h = hour % 24;
    final amPm = h >= 12 ? 'PM' : 'AM';
    final displayHour = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    return '$displayHour $amPm';
  }
}

/// Time Audit Statistics
class TimeAuditStats {
  final int totalMinutes;
  final int totalEntries;
  final int productiveMinutes;
  final double avgProductivity;
  final String mostProductiveTime;
  final String leastProductiveTime;
  final List<TimeDistribution> categoryDistribution;
  final List<PeakProductivityHour> peakHours;

  TimeAuditStats({
    required this.totalMinutes,
    required this.totalEntries,
    required this.productiveMinutes,
    required this.avgProductivity,
    required this.mostProductiveTime,
    required this.leastProductiveTime,
    required this.categoryDistribution,
    required this.peakHours,
  });

  double get productivityRatio => totalMinutes > 0 
      ? productiveMinutes / totalMinutes * 100 
      : 0;

  factory TimeAuditStats.empty() {
    return TimeAuditStats(
      totalMinutes: 0,
      totalEntries: 0,
      productiveMinutes: 0,
      avgProductivity: 0,
      mostProductiveTime: '',
      leastProductiveTime: '',
      categoryDistribution: [],
      peakHours: [],
    );
  }
}