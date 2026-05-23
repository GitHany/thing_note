/// Daily Win model
class DailyWin {
  final int? id;
  final String winDate;
  final String title;
  final String? description;
  final String? category;
  final int points;
  final DateTime createdAt;

  static const categories = ['work', 'health', 'learning', 'social', 'personal', 'creative'];
  static const categoryIcons = {
    'work': '💼',
    'health': '💪',
    'learning': '📚',
    'social': '👥',
    'personal': '🌟',
    'creative': '🎨',
  };

  DailyWin({
    this.id,
    required this.winDate,
    required this.title,
    this.description,
    this.category,
    this.points = 10,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  String get categoryIcon => categoryIcons[category] ?? '⭐';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'win_date': winDate,
      'title': title,
      'description': description,
      'category': category,
      'points': points,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory DailyWin.fromMap(Map<String, dynamic> map) {
    return DailyWin(
      id: map['id'] as int?,
      winDate: map['win_date'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      category: map['category'] as String?,
      points: map['points'] as int? ?? 10,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}