class TimeAllocation {
  final int? id;
  final String date;
  final String category;
  final int totalMinutes;
  final int recordCount;
  final double percentage;
  final double efficiencyScore;
  final DateTime createdAt;

  TimeAllocation({
    this.id,
    required this.date,
    required this.category,
    this.totalMinutes = 0,
    this.recordCount = 0,
    this.percentage = 0,
    this.efficiencyScore = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'category': category,
      'total_minutes': totalMinutes,
      'record_count': recordCount,
      'percentage': percentage,
      'efficiency_score': efficiencyScore,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory TimeAllocation.fromMap(Map<String, dynamic> map) {
    return TimeAllocation(
      id: map['id'],
      date: map['date'],
      category: map['category'],
      totalMinutes: map['total_minutes'] ?? 0,
      recordCount: map['record_count'] ?? 0,
      percentage: (map['percentage'] ?? 0).toDouble(),
      efficiencyScore: (map['efficiency_score'] ?? 0).toDouble(),
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  TimeAllocation copyWith({
    int? id,
    String? date,
    String? category,
    int? totalMinutes,
    int? recordCount,
    double? percentage,
    double? efficiencyScore,
    DateTime? createdAt,
  }) {
    return TimeAllocation(
      id: id ?? this.id,
      date: date ?? this.date,
      category: category ?? this.category,
      totalMinutes: totalMinutes ?? this.totalMinutes,
      recordCount: recordCount ?? this.recordCount,
      percentage: percentage ?? this.percentage,
      efficiencyScore: efficiencyScore ?? this.efficiencyScore,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}