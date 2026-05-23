class TimeAnalysisRecord {
  final int? id;
  final String date;
  final int morningRecords;
  final int afternoonRecords;
  final int eveningRecords;
  final int nightRecords;
  final int weekdayRecords;
  final int weekendRecords;
  final double? averageDuration;
  final DateTime createdAt;

  TimeAnalysisRecord({
    this.id,
    required this.date,
    this.morningRecords = 0,
    this.afternoonRecords = 0,
    this.eveningRecords = 0,
    this.nightRecords = 0,
    this.weekdayRecords = 0,
    this.weekendRecords = 0,
    this.averageDuration,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  int get totalRecords => morningRecords + afternoonRecords + eveningRecords + nightRecords;

  String get peakTime {
    final counts = {
      '上午': morningRecords,
      '下午': afternoonRecords,
      '晚上': eveningRecords,
      '深夜': nightRecords,
    };
    return counts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'date': date,
      'morning_records': morningRecords,
      'afternoon_records': afternoonRecords,
      'evening_records': eveningRecords,
      'night_records': nightRecords,
      'weekday_records': weekdayRecords,
      'weekend_records': weekendRecords,
      'average_duration': averageDuration,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory TimeAnalysisRecord.fromMap(Map<String, dynamic> map) {
    return TimeAnalysisRecord(
      id: map['id'] as int?,
      date: map['date'] as String,
      morningRecords: map['morning_records'] as int? ?? 0,
      afternoonRecords: map['afternoon_records'] as int? ?? 0,
      eveningRecords: map['evening_records'] as int? ?? 0,
      nightRecords: map['night_records'] as int? ?? 0,
      weekdayRecords: map['weekday_records'] as int? ?? 0,
      weekendRecords: map['weekend_records'] as int? ?? 0,
      averageDuration: map['average_duration'] as double?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}