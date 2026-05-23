class AchievementBadge {
  final int? id;
  final String badgeId;
  final String badgeName;
  final String badgeType;
  final String? description;
  final String? icon;
  final String? color;
  final String? requirementType;
  final int? requirementValue;
  final int currentProgress;
  final int isUnlocked;
  final String? unlockedAt;
  final int xpReward;
  final String createdAt;

  AchievementBadge({
    this.id,
    required this.badgeId,
    required this.badgeName,
    required this.badgeType,
    this.description,
    this.icon,
    this.color,
    this.requirementType,
    this.requirementValue,
    this.currentProgress = 0,
    this.isUnlocked = 0,
    this.unlockedAt,
    this.xpReward = 0,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'badge_id': badgeId,
      'badge_name': badgeName,
      'badge_type': badgeType,
      'description': description,
      'icon': icon,
      'color': color,
      'requirement_type': requirementType,
      'requirement_value': requirementValue,
      'current_progress': currentProgress,
      'is_unlocked': isUnlocked,
      'unlocked_at': unlockedAt,
      'xp_reward': xpReward,
      'created_at': createdAt,
    };
  }

  factory AchievementBadge.fromMap(Map<String, dynamic> map) {
    return AchievementBadge(
      id: map['id'] as int?,
      badgeId: map['badge_id'] as String,
      badgeName: map['badge_name'] as String,
      badgeType: map['badge_type'] as String,
      description: map['description'] as String?,
      icon: map['icon'] as String?,
      color: map['color'] as String?,
      requirementType: map['requirement_type'] as String?,
      requirementValue: map['requirement_value'] as int?,
      currentProgress: map['current_progress'] as int? ?? 0,
      isUnlocked: map['is_unlocked'] as int? ?? 0,
      unlockedAt: map['unlocked_at'] as String?,
      xpReward: map['xp_reward'] as int? ?? 0,
      createdAt: map['created_at'] as String,
    );
  }

  double get progressPercent {
    if (requirementValue == null || requirementValue == 0) return 0;
    return (currentProgress / requirementValue!).clamp(0.0, 1.0);
  }

  String get typeLabel {
    switch (badgeType) {
      case 'streak':
        return '连续';
      case 'milestone':
        return '里程碑';
      case 'exploration':
        return '探索';
      case 'special':
        return '特殊';
      default:
        return badgeType;
    }
  }

  String get iconDisplay {
    if (icon != null && icon!.isNotEmpty) return icon!;
    switch (badgeType) {
      case 'streak':
        return '🔥';
      case 'milestone':
        return '🏆';
      case 'exploration':
        return '🗺️';
      case 'special':
        return '⭐';
      default:
        return '🎖️';
    }
  }
}

class BadgeTemplates {
  static List<AchievementBadge> getDefaultBadges() {
    final now = DateTime.now().toIso8601String();
    
    return [
      AchievementBadge(
        badgeId: 'streak_7',
        badgeName: '7天连续',
        badgeType: 'streak',
        description: '连续记录7天',
        icon: '🔥',
        color: '#FF6B35',
        requirementType: 'streak_days',
        requirementValue: 7,
        xpReward: 50,
        createdAt: now,
      ),
      AchievementBadge(
        badgeId: 'streak_30',
        badgeName: '30天连续',
        badgeType: 'streak',
        description: '连续记录30天',
        icon: '🔥',
        color: '#FF4500',
        requirementType: 'streak_days',
        requirementValue: 30,
        xpReward: 200,
        createdAt: now,
      ),
      AchievementBadge(
        badgeId: 'streak_100',
        badgeName: '100天连续',
        badgeType: 'streak',
        description: '连续记录100天',
        icon: '🔥',
        color: '#DC143C',
        requirementType: 'streak_days',
        requirementValue: 100,
        xpReward: 500,
        createdAt: now,
      ),
      AchievementBadge(
        badgeId: 'records_100',
        badgeName: '记录达人',
        badgeType: 'milestone',
        description: '累计记录100条',
        icon: '📝',
        color: '#4CAF50',
        requirementType: 'total_records',
        requirementValue: 100,
        xpReward: 100,
        createdAt: now,
      ),
      AchievementBadge(
        badgeId: 'records_500',
        badgeName: '记录专家',
        badgeType: 'milestone',
        description: '累计记录500条',
        icon: '📝',
        color: '#2196F3',
        requirementType: 'total_records',
        requirementValue: 500,
        xpReward: 300,
        createdAt: now,
      ),
      AchievementBadge(
        badgeId: 'explore_all_features',
        badgeName: '探索者',
        badgeType: 'exploration',
        description: '尝试过所有主要功能',
        icon: '🗺️',
        color: '#9C27B0',
        requirementType: 'features_used',
        requirementValue: 20,
        xpReward: 150,
        createdAt: now,
      ),
      AchievementBadge(
        badgeId: 'custom_tag_10',
        badgeName: '标签达人',
        badgeType: 'milestone',
        description: '创建10个自定义标签',
        icon: '🏷️',
        color: '#00BCD4',
        requirementType: 'custom_tags',
        requirementValue: 10,
        xpReward: 80,
        createdAt: now,
      ),
      AchievementBadge(
        badgeId: 'early_bird',
        badgeName: '早起鸟',
        badgeType: 'special',
        description: '早上6点前记录',
        icon: '🌅',
        color: '#FFC107',
        requirementType: 'early_records',
        requirementValue: 10,
        xpReward: 100,
        createdAt: now,
      ),
    ];
  }
}