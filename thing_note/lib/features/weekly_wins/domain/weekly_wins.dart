/// Weekly Wins 数据模型
class WeeklyWin {
  final int? id;
  final int weekNumber;
  final int year;
  final String title;
  final String? description;
  final String? category;
  final DateTime? achievedAt;
  final DateTime createdAt;

  const WeeklyWin({
    this.id,
    required this.weekNumber,
    required this.year,
    required this.title,
    this.description,
    this.category,
    this.achievedAt,
    required this.createdAt,
  });

  WeeklyWin copyWith({
    int? id,
    int? weekNumber,
    int? year,
    String? title,
    String? description,
    String? category,
    DateTime? achievedAt,
    DateTime? createdAt,
  }) {
    return WeeklyWin(
      id: id ?? this.id,
      weekNumber: weekNumber ?? this.weekNumber,
      year: year ?? this.year,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      achievedAt: achievedAt ?? this.achievedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'week_number': weekNumber,
      'year': year,
      'title': title,
      'description': description,
      'category': category,
      'achieved_at': achievedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory WeeklyWin.fromMap(Map<String, dynamic> map) {
    return WeeklyWin(
      id: map['id'] as int?,
      weekNumber: map['week_number'] as int,
      year: map['year'] as int,
      title: map['title'] as String,
      description: map['description'] as String?,
      category: map['category'] as String?,
      achievedAt: map['achieved_at'] != null
          ? DateTime.parse(map['achieved_at'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

/// 周成就总结
class WeeklySummary {
  final int weekNumber;
  final int year;
  final int totalWins;
  final List<String> categories;
  final String? reflection;
  final DateTime createdAt;

  const WeeklySummary({
    required this.weekNumber,
    required this.year,
    this.totalWins = 0,
    this.categories = const [],
    this.reflection,
    required this.createdAt,
  });
}