class FocusAchievement {
  final int id;
  final String achievementType;
  final String title;
  final String? description;
  final int? targetMinutes;
  final String? badgeIcon;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final int shareCount;
  final DateTime createdAt;

  FocusAchievement({
    required this.id,
    required this.achievementType,
    required this.title,
    this.description,
    this.targetMinutes,
    this.badgeIcon,
    this.isUnlocked = false,
    this.unlockedAt,
    this.shareCount = 0,
    required this.createdAt,
  });

  factory FocusAchievement.fromMap(Map<String, dynamic> map) {
    return FocusAchievement(
      id: map['id'] as int,
      achievementType: map['achievement_type'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      targetMinutes: map['target_minutes'] as int?,
      badgeIcon: map['badge_icon'] as String?,
      isUnlocked: (map['is_unlocked'] as int?) == 1,
      unlockedAt: map['unlocked_at'] != null
          ? DateTime.parse(map['unlocked_at'] as String)
          : null,
      shareCount: map['share_count'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'achievement_type': achievementType,
      'title': title,
      'description': description,
      'target_minutes': targetMinutes,
      'badge_icon': badgeIcon,
      'is_unlocked': isUnlocked ? 1 : 0,
      'unlocked_at': unlockedAt?.toIso8601String(),
      'share_count': shareCount,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class ShareCard {
  final String title;
  final String subtitle;
  final int duration;
  final DateTime date;
  final String badgeEmoji;

  ShareCard({
    required this.title,
    required this.subtitle,
    required this.duration,
    required this.date,
    this.badgeEmoji = '🎯',
  });
}