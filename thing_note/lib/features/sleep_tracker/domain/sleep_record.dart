/// 睡眠记录数据模型
class SleepRecord {
  final int? id;
  final String date;
  final String bedtime;
  final String wakeTime;
  final int durationMinutes;
  final int? quality;
  final String? note;
  final DateTime createdAt;

  const SleepRecord({
    this.id,
    required this.date,
    required this.bedtime,
    required this.wakeTime,
    required this.durationMinutes,
    this.quality,
    this.note,
    required this.createdAt,
  });

  SleepRecord copyWith({
    int? id,
    String? date,
    String? bedtime,
    String? wakeTime,
    int? durationMinutes,
    int? quality,
    String? note,
    DateTime? createdAt,
  }) {
    return SleepRecord(
      id: id ?? this.id,
      date: date ?? this.date,
      bedtime: bedtime ?? this.bedtime,
      wakeTime: wakeTime ?? this.wakeTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      quality: quality ?? this.quality,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'date': date,
      'bedtime': bedtime,
      'wake_time': wakeTime,
      'duration_minutes': durationMinutes,
      'quality': quality,
      'note': note,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory SleepRecord.fromMap(Map<String, dynamic> map) {
    return SleepRecord(
      id: map['id'] as int?,
      date: map['date'] as String,
      bedtime: map['bedtime'] as String,
      wakeTime: map['wake_time'] as String,
      durationMinutes: map['duration_minutes'] as int,
      quality: map['quality'] as int?,
      note: map['note'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  String get formattedDuration {
    final hours = durationMinutes ~/ 60;
    final minutes = durationMinutes % 60;
    return '$hours小时$minutes分钟';
  }
}

/// 睡眠统计
class SleepStats {
  final double avgDuration;
  final double avgQuality;
  final int totalNights;
  final int goodNights;

  const SleepStats({
    this.avgDuration = 0,
    this.avgQuality = 0,
    this.totalNights = 0,
    this.goodNights = 0,
  });
}