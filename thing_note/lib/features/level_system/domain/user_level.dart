import 'package:flutter/material.dart';

class UserLevel {
  final int? id;
  final int level;
  final int xpRequired;
  final String title;
  final String? badgeIcon;
  final String createdAt;

  UserLevel({
    this.id,
    required this.level,
    required this.xpRequired,
    required this.title,
    this.badgeIcon,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'level': level,
      'xp_required': xpRequired,
      'title': title,
      'badge_icon': badgeIcon,
      'created_at': createdAt,
    };
  }

  factory UserLevel.fromMap(Map<String, dynamic> map) {
    return UserLevel(
      id: map['id'] as int?,
      level: map['level'] as int,
      xpRequired: map['xp_required'] as int,
      title: map['title'] as String,
      badgeIcon: map['badge_icon'] as String?,
      createdAt: map['created_at'] as String,
    );
  }

  static List<UserLevel> get defaultLevels {
    final now = DateTime.now().toIso8601String();
    return [
      UserLevel(level: 1, xpRequired: 0, title: '新手记录者', badgeIcon: '🌱', createdAt: now),
      UserLevel(level: 2, xpRequired: 100, title: '初露头角', badgeIcon: '🌿', createdAt: now),
      UserLevel(level: 3, xpRequired: 250, title: '稳步前行', badgeIcon: '🌾', createdAt: now),
      UserLevel(level: 4, xpRequired: 500, title: '小有成就', badgeIcon: '🌻', createdAt: now),
      UserLevel(level: 5, xpRequired: 800, title: '记录达人', badgeIcon: '🌺', createdAt: now),
      UserLevel(level: 6, xpRequired: 1200, title: '习惯养成者', badgeIcon: '🌸', createdAt: now),
      UserLevel(level: 7, xpRequired: 1600, title: '生活记录师', badgeIcon: '🌷', createdAt: now),
      UserLevel(level: 8, xpRequired: 2100, title: '时间管理者', badgeIcon: '⏰', createdAt: now),
      UserLevel(level: 9, xpRequired: 2700, title: '目标追求者', badgeIcon: '🎯', createdAt: now),
      UserLevel(level: 10, xpRequired: 3400, title: '自律达人', badgeIcon: '💪', createdAt: now),
      UserLevel(level: 11, xpRequired: 4200, title: '成长探索者', badgeIcon: '🚀', createdAt: now),
      UserLevel(level: 12, xpRequired: 5100, title: '高效记录者', badgeIcon: '⚡', createdAt: now),
      UserLevel(level: 13, xpRequired: 6100, title: '数据洞察者', badgeIcon: '🔍', createdAt: now),
      UserLevel(level: 14, xpRequired: 7200, title: '生活艺术家', badgeIcon: '🎨', createdAt: now),
      UserLevel(level: 15, xpRequired: 8500, title: '习惯大师', badgeIcon: '🏆', createdAt: now),
      UserLevel(level: 16, xpRequired: 10000, title: '人生记录者', badgeIcon: '📖', createdAt: now),
      UserLevel(level: 17, xpRequired: 11600, title: '洞察高手', badgeIcon: '🧠', createdAt: now),
      UserLevel(level: 18, xpRequired: 13300, title: '时间大师', badgeIcon: '⏳', createdAt: now),
      UserLevel(level: 19, xpRequired: 15100, title: '人生规划师', badgeIcon: '📋', createdAt: now),
      UserLevel(level: 20, xpRequired: 17000, title: '传奇记录者', badgeIcon: '👑', createdAt: now),
    ];
  }

  static Color getBadgeColor(int level) {
    if (level < 5) return Colors.green;
    if (level < 10) return Colors.blue;
    if (level < 15) return Colors.purple;
    if (level < 20) return Colors.orange;
    return Colors.red;
  }

  static IconData getBadgeIconData(String? badgeIcon) {
    switch (badgeIcon) {
      case '🌱': return Icons.eco;
      case '🌿': return Icons.grass;
      case '🌾': return Icons.spa;
      case '🌻': return Icons.wb_sunny;
      case '🌺': return Icons.local_florist;
      case '🌸': return Icons.local_florist;
      case '🌷': return Icons.filter_vintage;
      case '⏰': return Icons.access_time;
      case '🎯': return Icons.gps_fixed;
      case '💪': return Icons.fitness_center;
      case '🚀': return Icons.rocket_launch;
      case '⚡': return Icons.bolt;
      case '🔍': return Icons.search;
      case '🎨': return Icons.palette;
      case '🏆': return Icons.emoji_events;
      case '📖': return Icons.auto_stories;
      case '🧠': return Icons.psychology;
      case '⏳': return Icons.hourglass_bottom;
      case '📋': return Icons.assignment;
      case '👑': return Icons.workspace_premium;
      default: return Icons.star;
    }
  }
}

class XpTransaction {
  final int? id;
  final int amount;
  final String source;
  final int? sourceId;
  final String? description;
  final String createdAt;

  XpTransaction({
    this.id,
    required this.amount,
    required this.source,
    this.sourceId,
    this.description,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'source': source,
      'source_id': sourceId,
      'description': description,
      'created_at': createdAt,
    };
  }

  factory XpTransaction.fromMap(Map<String, dynamic> map) {
    return XpTransaction(
      id: map['id'] as int?,
      amount: map['amount'] as int,
      source: map['source'] as String,
      sourceId: map['source_id'] as int?,
      description: map['description'] as String?,
      createdAt: map['created_at'] as String,
    );
  }
}

class DailyQuest {
  final int? id;
  final String questType;
  final String title;
  final String? description;
  final int xpReward;
  final int targetCount;
  final int currentCount;
  final bool isCompleted;
  final String date;
  final String createdAt;

  DailyQuest({
    this.id,
    required this.questType,
    required this.title,
    this.description,
    required this.xpReward,
    this.targetCount = 1,
    this.currentCount = 0,
    this.isCompleted = false,
    required this.date,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'quest_type': questType,
      'title': title,
      'description': description,
      'xp_reward': xpReward,
      'target_count': targetCount,
      'current_count': currentCount,
      'is_completed': isCompleted ? 1 : 0,
      'date': date,
      'created_at': createdAt,
    };
  }

  factory DailyQuest.fromMap(Map<String, dynamic> map) {
    return DailyQuest(
      id: map['id'] as int?,
      questType: map['quest_type'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      xpReward: map['xp_reward'] as int,
      targetCount: map['target_count'] as int? ?? 1,
      currentCount: map['current_count'] as int? ?? 0,
      isCompleted: (map['is_completed'] as int? ?? 0) == 1,
      date: map['date'] as String,
      createdAt: map['created_at'] as String,
    );
  }

  double get progress => targetCount > 0 ? (currentCount / targetCount).clamp(0.0, 1.0) : 0.0;

  DailyQuest copyWith({
    int? id, String? questType, String? title, String? description,
    int? xpReward, int? targetCount, int? currentCount, bool? isCompleted,
    String? date, String? createdAt,
  }) {
    return DailyQuest(
      id: id ?? this.id,
      questType: questType ?? this.questType,
      title: title ?? this.title,
      description: description ?? this.description,
      xpReward: xpReward ?? this.xpReward,
      targetCount: targetCount ?? this.targetCount,
      currentCount: currentCount ?? this.currentCount,
      isCompleted: isCompleted ?? this.isCompleted,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class UserProfile {
  final int totalXp;
  final int currentLevel;
  final int xpInCurrentLevel;
  final int xpToNextLevel;
  final UserLevel? currentLevelInfo;
  final UserLevel? nextLevelInfo;

  UserProfile({
    required this.totalXp,
    required this.currentLevel,
    required this.xpInCurrentLevel,
    required this.xpToNextLevel,
    this.currentLevelInfo,
    this.nextLevelInfo,
  });

  double get levelProgress {
    if (xpToNextLevel == 0) return 1.0;
    return xpInCurrentLevel / xpToNextLevel;
  }
}
