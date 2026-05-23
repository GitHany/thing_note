class Achievement {
  final int? id;
  final String title;
  final String? description;
  final String type;
  final int targetValue;
  final int currentValue;
  final String icon;
  final String? reward;
  final bool isUnlocked;
  final String? unlockedAt;
  final String createdAt;

  Achievement({
    this.id,
    required this.title,
    this.description,
    required this.type,
    this.targetValue = 1,
    this.currentValue = 0,
    this.icon = '🏆',
    this.reward,
    this.isUnlocked = false,
    this.unlockedAt,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type,
      'target_value': targetValue,
      'current_value': currentValue,
      'icon': icon,
      'reward': reward,
      'is_unlocked': isUnlocked ? 1 : 0,
      'unlocked_at': unlockedAt,
      'created_at': createdAt,
    };
  }

  factory Achievement.fromMap(Map<String, dynamic> map) {
    return Achievement(
      id: map['id'] as int?,
      title: map['title'] as String,
      description: map['description'] as String?,
      type: map['type'] as String,
      targetValue: map['target_value'] as int? ?? 1,
      currentValue: map['current_value'] as int? ?? 0,
      icon: map['icon'] as String? ?? '🏆',
      reward: map['reward'] as String?,
      isUnlocked: (map['is_unlocked'] as int? ?? 0) == 1,
      unlockedAt: map['unlocked_at'] as String?,
      createdAt: map['created_at'] as String,
    );
  }

  Achievement copyWith({
    int? id, String? title, String? description, String? type, int? targetValue,
    int? currentValue, String? icon, String? reward, bool? isUnlocked, String? unlockedAt, String? createdAt,
  }) {
    return Achievement(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      targetValue: targetValue ?? this.targetValue,
      currentValue: currentValue ?? this.currentValue,
      icon: icon ?? this.icon,
      reward: reward ?? this.reward,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  double get progress => targetValue > 0 ? (currentValue / targetValue).clamp(0.0, 1.0) : 0.0;

  static List<Achievement> get defaultAchievements {
    final now = DateTime.now().toIso8601String();
    return [
      Achievement(title: '初次记录', description: '创建你的第一条记录', type: 'record', targetValue: 1, icon: '📝', createdAt: now),
      Achievement(title: '记录达人', description: '创建 100 条记录', type: 'record', targetValue: 100, icon: '📚', createdAt: now),
      Achievement(title: '记录大师', description: '创建 500 条记录', type: 'record', targetValue: 500, icon: '🏅', createdAt: now),
      Achievement(title: '坚持不懈', description: '连续记录 7 天', type: 'streak', targetValue: 7, icon: '🔥', createdAt: now),
      Achievement(title: '习惯养成', description: '连续记录 30 天', type: 'streak', targetValue: 30, icon: '⭐', createdAt: now),
      Achievement(title: '长期主义', description: '连续记录 100 天', type: 'streak', targetValue: 100, icon: '💎', createdAt: now),
      Achievement(title: '标签达人', description: '创建 10 个标签', type: 'tag', targetValue: 10, icon: '🏷️', createdAt: now),
      Achievement(title: '分类专家', description: '创建 50 个标签', type: 'tag', targetValue: 50, icon: '📋', createdAt: now),
      Achievement(title: '早起鸟', description: '在早上 6 点前创建记录', type: 'time', targetValue: 1, icon: '🌅', createdAt: now),
      Achievement(title: '夜猫子', description: '在晚上 11 点后创建记录', type: 'time', targetValue: 1, icon: '🌙', createdAt: now),
    ];
  }
}