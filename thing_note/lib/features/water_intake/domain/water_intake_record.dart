/// 饮水追踪数据模型
class WaterIntakeRecord {
  final int? id;
  final String date;
  final int glasses;
  final int totalMl;
  final int goalMl;
  final bool reminderEnabled;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;

  const WaterIntakeRecord({
    this.id,
    required this.date,
    this.glasses = 0,
    this.totalMl = 0,
    this.goalMl = 2000,
    this.reminderEnabled = true,
    this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  double get progressPercent =>
      goalMl > 0 ? (totalMl / goalMl).clamp(0.0, 1.0) : 0.0;

  bool get goalReached => totalMl >= goalMl;

  int get remainingMl => (goalMl - totalMl).clamp(0, goalMl);

  int get remainingGlasses => ((goalMl - totalMl) / 250).ceil().clamp(0, 100);

  WaterIntakeRecord copyWith({
    int? id,
    String? date,
    int? glasses,
    int? totalMl,
    int? goalMl,
    bool? reminderEnabled,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WaterIntakeRecord(
      id: id ?? this.id,
      date: date ?? this.date,
      glasses: glasses ?? this.glasses,
      totalMl: totalMl ?? this.totalMl,
      goalMl: goalMl ?? this.goalMl,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'date': date,
      'glasses': glasses,
      'total_ml': totalMl,
      'goal_ml': goalMl,
      'reminder_enabled': reminderEnabled ? 1 : 0,
      'note': note,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory WaterIntakeRecord.fromMap(Map<String, dynamic> map) {
    return WaterIntakeRecord(
      id: map['id'] as int?,
      date: map['date'] as String,
      glasses: map['glasses'] as int? ?? 0,
      totalMl: map['total_ml'] as int? ?? 0,
      goalMl: map['goal_ml'] as int? ?? 2000,
      reminderEnabled: (map['reminder_enabled'] as int? ?? 1) == 1,
      note: map['note'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}
