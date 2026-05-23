import 'package:flutter/material.dart';

/// 习惯连续火焰数据模型
class HabitStreakFire {
  final int? id;
  final int habitId;
  final int currentStreak;
  final int bestStreak;
  final DateTime? streakStartDate;
  final int fireLevel; // 0-5: 无火/微火/小火/中火/大火/熊熊
  final int totalFires;
  final String flameColor;
  final bool isOnFire;
  final DateTime updatedAt;

  const HabitStreakFire({
    this.id,
    required this.habitId,
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.streakStartDate,
    this.fireLevel = 0,
    this.totalFires = 0,
    this.flameColor = '#FF6B35',
    this.isOnFire = false,
    required this.updatedAt,
  });

  /// 根据连续天数计算火焰等级
  static int calculateFireLevel(int streakDays) {
    if (streakDays >= 100) return 5; // 熊熊烈火
    if (streakDays >= 50) return 4;  // 大火
    if (streakDays >= 30) return 3;  // 中火
    if (streakDays >= 14) return 2; // 小火
    if (streakDays >= 7) return 1;   // 微火
    return 0;                        // 无火
  }

  /// 根据等级获取火焰颜色
  static Color getFlameColorByLevel(int level) {
    switch (level) {
      case 5: return const Color(0xFFFF1744); // 熊熊 - 红色
      case 4: return const Color(0xFFFF6D00); // 大火 - 橙色
      case 3: return const Color(0xFFFFAB00); // 中火 - 黄色
      case 2: return const Color(0xFFFFD600); // 小火 - 亮黄
      case 1: return const Color(0xFFFFEA00); // 微火 - 浅黄
      default: return const Color(0xFF9E9E9E); // 无火 - 灰色
    }
  }

  Color get flameColorValue {
    final hex = flameColor.replaceAll('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  String get fireLevelLabel {
    switch (fireLevel) {
      case 5: return '熊熊烈火';
      case 4: return '大火';
      case 3: return '中火';
      case 2: return '小火';
      case 1: return '微火';
      default: return '未点燃';
    }
  }

  IconData get fireIcon {
    switch (fireLevel) {
      case 5: return Icons.local_fire_department;
      case 4: return Icons.local_fire_department;
      case 3: return Icons.whatshot;
      case 2: return Icons.whatshot;
      case 1: return Icons.whatshot;
      default: return Icons.local_fire_department_outlined;
    }
  }

  HabitStreakFire copyWith({
    int? id,
    int? habitId,
    int? currentStreak,
    int? bestStreak,
    DateTime? streakStartDate,
    int? fireLevel,
    int? totalFires,
    String? flameColor,
    bool? isOnFire,
    DateTime? updatedAt,
  }) {
    return HabitStreakFire(
      id: id ?? this.id,
      habitId: habitId ?? this.habitId,
      currentStreak: currentStreak ?? this.currentStreak,
      bestStreak: bestStreak ?? this.bestStreak,
      streakStartDate: streakStartDate ?? this.streakStartDate,
      fireLevel: fireLevel ?? this.fireLevel,
      totalFires: totalFires ?? this.totalFires,
      flameColor: flameColor ?? this.flameColor,
      isOnFire: isOnFire ?? this.isOnFire,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'habit_id': habitId,
      'current_streak': currentStreak,
      'best_streak': bestStreak,
      'streak_start_date': streakStartDate?.toIso8601String(),
      'fire_level': fireLevel,
      'total_fires': totalFires,
      'flame_color': flameColor,
      'is_on_fire': isOnFire ? 1 : 0,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory HabitStreakFire.fromMap(Map<String, dynamic> map) {
    return HabitStreakFire(
      id: map['id'] as int?,
      habitId: map['habit_id'] as int,
      currentStreak: map['current_streak'] as int? ?? 0,
      bestStreak: map['best_streak'] as int? ?? 0,
      streakStartDate: map['streak_start_date'] != null
          ? DateTime.parse(map['streak_start_date'] as String)
          : null,
      fireLevel: map['fire_level'] as int? ?? 0,
      totalFires: map['total_fires'] as int? ?? 0,
      flameColor: map['flame_color'] as String? ?? '#FF6B35',
      isOnFire: (map['is_on_fire'] as int? ?? 0) == 1,
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}
