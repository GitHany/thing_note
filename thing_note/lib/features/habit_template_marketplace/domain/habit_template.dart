class HabitTemplate {
  final int? id;
  final String templateName;
  final String category;
  final String? description;
  final String? habitConfig;
  final int useCount;
  final double rating;
  final bool isPublished;
  final DateTime createdAt;

  HabitTemplate({
    this.id,
    required this.templateName,
    required this.category,
    this.description,
    this.habitConfig,
    this.useCount = 0,
    this.rating = 0,
    this.isPublished = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'template_name': templateName,
      'category': category,
      'description': description,
      'habit_config': habitConfig,
      'use_count': useCount,
      'rating': rating,
      'is_published': isPublished ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory HabitTemplate.fromMap(Map<String, dynamic> map) {
    return HabitTemplate(
      id: map['id'] as int?,
      templateName: map['template_name'] as String,
      category: map['category'] as String,
      description: map['description'] as String?,
      habitConfig: map['habit_config'] as String?,
      useCount: map['use_count'] as int? ?? 0,
      rating: (map['rating'] as num?)?.toDouble() ?? 0,
      isPublished: (map['is_published'] as int?) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  List<String> get categories => ['健康', '学习', '工作', '生活', '运动', '冥想', '阅读', '其他'];
}