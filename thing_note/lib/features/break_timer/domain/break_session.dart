/// 休息计时数据模型
class BreakSession {
  final int? id;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int durationMinutes;
  final String breakType; // short / long / micro
  final String? activity;
  final int? moodBefore;
  final int? moodAfter;
  final bool isMicroBreak;
  final String? note;
  final DateTime createdAt;

  const BreakSession({
    this.id,
    required this.startedAt,
    this.endedAt,
    this.durationMinutes = 0,
    this.breakType = 'short',
    this.activity,
    this.moodBefore,
    this.moodAfter,
    this.isMicroBreak = true,
    this.note,
    required this.createdAt,
  });

  bool get isActive => endedAt == null;

  bool get isLongBreak => breakType == 'long';

  BreakSession copyWith({
    int? id,
    DateTime? startedAt,
    DateTime? endedAt,
    int? durationMinutes,
    String? breakType,
    String? activity,
    int? moodBefore,
    int? moodAfter,
    bool? isMicroBreak,
    String? note,
    DateTime? createdAt,
  }) {
    return BreakSession(
      id: id ?? this.id,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      breakType: breakType ?? this.breakType,
      activity: activity ?? this.activity,
      moodBefore: moodBefore ?? this.moodBefore,
      moodAfter: moodAfter ?? this.moodAfter,
      isMicroBreak: isMicroBreak ?? this.isMicroBreak,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'started_at': startedAt.toIso8601String(),
      'ended_at': endedAt?.toIso8601String(),
      'duration_minutes': durationMinutes,
      'break_type': breakType,
      'activity': activity,
      'mood_before': moodBefore,
      'mood_after': moodAfter,
      'is_micro_break': isMicroBreak ? 1 : 0,
      'note': note,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory BreakSession.fromMap(Map<String, dynamic> map) {
    return BreakSession(
      id: map['id'] as int?,
      startedAt: DateTime.parse(map['started_at'] as String),
      endedAt: map['ended_at'] != null
          ? DateTime.parse(map['ended_at'] as String)
          : null,
      durationMinutes: map['duration_minutes'] as int? ?? 0,
      breakType: map['break_type'] as String? ?? 'short',
      activity: map['activity'] as String?,
      moodBefore: map['mood_before'] as int?,
      moodAfter: map['mood_after'] as int?,
      isMicroBreak: (map['is_micro_break'] as int? ?? 1) == 1,
      note: map['note'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

class BreakSuggestion {
  final int? id;
  final String title;
  final String? description;
  final int durationMinutes;
  final String category;
  final String? icon;
  final int energyImpact;

  const BreakSuggestion({
    this.id,
    required this.title,
    this.description,
    this.durationMinutes = 5,
    this.category = 'relax',
    this.icon,
    this.energyImpact = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'description': description,
      'duration_minutes': durationMinutes,
      'category': category,
      'icon': icon,
      'energy_impact': energyImpact,
      'created_at': DateTime.now().toIso8601String(),
    };
  }

  factory BreakSuggestion.fromMap(Map<String, dynamic> map) {
    return BreakSuggestion(
      id: map['id'] as int?,
      title: map['title'] as String,
      description: map['description'] as String?,
      durationMinutes: map['duration_minutes'] as int? ?? 5,
      category: map['category'] as String? ?? 'relax',
      icon: map['icon'] as String?,
      energyImpact: map['energy_impact'] as int? ?? 0,
    );
  }

  static const List<BreakSuggestion> defaults = [
    BreakSuggestion(title: '深呼吸', description: '缓慢深呼吸5次', durationMinutes: 1, category: 'relax', energyImpact: 2),
    BreakSuggestion(title: '伸展运动', description: '站起来伸展全身', durationMinutes: 3, category: 'movement', energyImpact: 3),
    BreakSuggestion(title: '眼保健操', description: '看远处放松眼睛', durationMinutes: 2, category: 'health', energyImpact: 1),
    BreakSuggestion(title: '喝杯水', description: '起身倒杯水', durationMinutes: 1, category: 'health', energyImpact: 1),
    BreakSuggestion(title: '散步5分钟', description: '简单走动一下', durationMinutes: 5, category: 'movement', energyImpact: 4),
    BreakSuggestion(title: '冥想', description: '闭眼静坐几分钟', durationMinutes: 5, category: 'mindfulness', energyImpact: 3),
    BreakSuggestion(title: '听音乐', description: '听一首喜欢的歌', durationMinutes: 4, category: 'entertainment', energyImpact: 2),
    BreakSuggestion(title: '聊天', description: '和同事简单聊几句', durationMinutes: 5, category: 'social', energyImpact: 2),
  ];
}
