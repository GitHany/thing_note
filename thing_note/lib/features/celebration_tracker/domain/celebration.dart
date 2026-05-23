class Celebration {
  final int? id;
  final String title;
  final String? description;
  final String? celebrationType;
  final DateTime achievedAt;
  final String? badgeId;
  final int shared;
  final DateTime createdAt;

  Celebration({
    this.id,
    required this.title,
    this.description,
    this.celebrationType,
    DateTime? achievedAt,
    this.badgeId,
    this.shared = 0,
    DateTime? createdAt,
  })  : achievedAt = achievedAt ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'description': description,
      'celebration_type': celebrationType,
      'achieved_at': achievedAt.toIso8601String(),
      'badge_id': badgeId,
      'shared': shared,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Celebration.fromMap(Map<String, dynamic> map) {
    return Celebration(
      id: map['id'] as int?,
      title: map['title'] as String,
      description: map['description'] as String?,
      celebrationType: map['celebration_type'] as String?,
      achievedAt: DateTime.parse(map['achieved_at'] as String),
      badgeId: map['badge_id'] as String?,
      shared: map['shared'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Celebration copyWith({
    int? id,
    String? title,
    String? description,
    String? celebrationType,
    DateTime? achievedAt,
    String? badgeId,
    int? shared,
    DateTime? createdAt,
  }) {
    return Celebration(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      celebrationType: celebrationType ?? this.celebrationType,
      achievedAt: achievedAt ?? this.achievedAt,
      badgeId: badgeId ?? this.badgeId,
      shared: shared ?? this.shared,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static const List<String> celebrationTypes = [
    'milestone',
    'streak',
    'breakthrough',
    'consistency',
    'personal_best',
    'daily_win',
  ];

  static const Map<String, String> typeLabels = {
    'milestone': '里程碑',
    'streak': '连续达成',
    'breakthrough': '突破自我',
    'consistency': '坚持不懈',
    'personal_best': '最佳记录',
    'daily_win': '每日胜利',
  };

  static const Map<String, String> typeEmojis = {
    'milestone': '🏆',
    'streak': '🔥',
    'breakthrough': '🚀',
    'consistency': '⭐',
    'personal_best': '💯',
    'daily_win': '✨',
  };

  static const List<Map<String, dynamic>> badgeDefinitions = [
    {'id': 'first_step', 'name': '第一步', 'icon': '👣', 'requirement': 1},
    {'id': 'week_warrior', 'name': '周战士', 'icon': '⚔️', 'requirement': 7},
    {'id': 'month_master', 'name': '月大师', 'icon': '👑', 'requirement': 30},
    {'id': 'quarter_champion', 'name': '季度冠军', 'icon': '🏅', 'requirement': 90},
    {'id': 'year_legend', 'name': '年度传奇', 'icon': '🌟', 'requirement': 365},
  ];
}