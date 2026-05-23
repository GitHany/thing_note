class DailyChallenge {
  final int id;
  final String challengeDate;
  final String challengeType;
  final String title;
  final String? description;
  final int? targetValue;
  final int currentValue;
  final int xpReward;
  final bool isCompleted;
  final DateTime createdAt;

  DailyChallenge({
    required this.id,
    required this.challengeDate,
    required this.challengeType,
    required this.title,
    this.description,
    this.targetValue,
    this.currentValue = 0,
    this.xpReward = 10,
    this.isCompleted = false,
    required this.createdAt,
  });

  factory DailyChallenge.fromMap(Map<String, dynamic> map) {
    return DailyChallenge(
      id: map['id'] as int,
      challengeDate: map['challenge_date'] as String,
      challengeType: map['challenge_type'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      targetValue: map['target_value'] as int?,
      currentValue: map['current_value'] as int? ?? 0,
      xpReward: map['xp_reward'] as int? ?? 10,
      isCompleted: (map['is_completed'] as int?) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'challenge_date': challengeDate,
      'challenge_type': challengeType,
      'title': title,
      'description': description,
      'target_value': targetValue,
      'current_value': currentValue,
      'xp_reward': xpReward,
      'is_completed': isCompleted ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  double get progress => targetValue != null && targetValue! > 0
      ? (currentValue / targetValue!).clamp(0.0, 1.0)
      : 0.0;
}

class Achievement {
  final String name;
  final String emoji;
  final bool unlocked;
  final DateTime? unlockedAt;
  final String rarity;

  Achievement({
    required this.name,
    required this.emoji,
    this.unlocked = false,
    this.unlockedAt,
    this.rarity = 'common',
  });
}