// Daily Inspiration Models
// 每日灵感生成功能 - 基于你的数据生成个性化的每日灵感

class DailyInspiration {
  final int? id;
  final String date;
  final String content;
  final String category; // 'motivation', 'tip', 'quote', 'challenge'
  final List<String> relatedActions;
  final bool isViewed;
  final DateTime createdAt;

  DailyInspiration({
    this.id,
    required this.date,
    required this.content,
    required this.category,
    required this.relatedActions,
    this.isViewed = false,
    required this.createdAt,
  });

  String get categoryEmoji {
    switch (category) {
      case 'motivation':
        return '🔥';
      case 'tip':
        return '💡';
      case 'quote':
        return '📜';
      case 'challenge':
        return '🎯';
      default:
        return '✨';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'content': content,
      'category': category,
      'related_actions': relatedActions.join('|||'),
      'is_viewed': isViewed ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory DailyInspiration.fromMap(Map<String, dynamic> map) {
    final actionsStr = map['related_actions'] as String? ?? '';
    return DailyInspiration(
      id: map['id'] as int?,
      date: map['date'] as String,
      content: map['content'] as String,
      category: map['category'] as String? ?? 'tip',
      relatedActions: actionsStr.isEmpty ? [] : actionsStr.split('|||'),
      isViewed: (map['is_viewed'] as int?) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

class InspirationTemplate {
  final int? id;
  final String category;
  final String template;
  final Map<String, String> variables;
  final int usageCount;
  final double rating;

  InspirationTemplate({
    this.id,
    required this.category,
    required this.template,
    required this.variables,
    this.usageCount = 0,
    this.rating = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category,
      'template': template,
      'variables': variables.entries.map((e) => '${e.key}:${e.value}').join(','),
      'usage_count': usageCount,
      'rating': rating,
    };
  }

  factory InspirationTemplate.fromMap(Map<String, dynamic> map) {
    return InspirationTemplate(
      id: map['id'] as int?,
      category: map['category'] as String,
      template: map['template'] as String,
      variables: {},
      usageCount: map['usage_count'] as int? ?? 0,
      rating: (map['rating'] as num?)?.toDouble() ?? 0,
    );
  }
}

class Challenge {
  final int? id;
  final String title;
  final String description;
  final int durationDays;
  final String difficulty; // 'easy', 'medium', 'hard'
  final int xpReward;
  final int currentProgress;
  final bool isCompleted;
  final DateTime startedAt;
  final DateTime? completedAt;

  Challenge({
    this.id,
    required this.title,
    required this.description,
    required this.durationDays,
    required this.difficulty,
    required this.xpReward,
    this.currentProgress = 0,
    this.isCompleted = false,
    required this.startedAt,
    this.completedAt,
  });

  double get progressPercent => 
    durationDays > 0 ? (currentProgress / durationDays * 100).clamp(0, 100) : 0;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'duration_days': durationDays,
      'difficulty': difficulty,
      'xp_reward': xpReward,
      'current_progress': currentProgress,
      'is_completed': isCompleted ? 1 : 0,
      'started_at': startedAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  factory Challenge.fromMap(Map<String, dynamic> map) {
    return Challenge(
      id: map['id'] as int?,
      title: map['title'] as String,
      description: map['description'] as String,
      durationDays: map['duration_days'] as int,
      difficulty: map['difficulty'] as String? ?? 'medium',
      xpReward: map['xp_reward'] as int? ?? 10,
      currentProgress: map['current_progress'] as int? ?? 0,
      isCompleted: (map['is_completed'] as int?) == 1,
      startedAt: DateTime.parse(map['started_at'] as String),
      completedAt: map['completed_at'] != null
          ? DateTime.parse(map['completed_at'] as String)
          : null,
    );
  }
}