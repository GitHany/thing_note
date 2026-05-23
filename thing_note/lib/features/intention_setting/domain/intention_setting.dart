/// Intention Setting 数据模型
class Intention {
  final int? id;
  final DateTime date;
  final String intention;
  final String? affirmation;
  final List<String> focusAreas;
  final int energyLevel;
  final DateTime createdAt;

  const Intention({
    this.id,
    required this.date,
    required this.intention,
    this.affirmation,
    this.focusAreas = const [],
    this.energyLevel = 3,
    required this.createdAt,
  });

  Intention copyWith({
    int? id,
    DateTime? date,
    String? intention,
    String? affirmation,
    List<String>? focusAreas,
    int? energyLevel,
    DateTime? createdAt,
  }) {
    return Intention(
      id: id ?? this.id,
      date: date ?? this.date,
      intention: intention ?? this.intention,
      affirmation: affirmation ?? this.affirmation,
      focusAreas: focusAreas ?? this.focusAreas,
      energyLevel: energyLevel ?? this.energyLevel,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'date': date.toIso8601String(),
      'intention': intention,
      'affirmation': affirmation,
      'focus_areas': focusAreas.join(','),
      'energy_level': energyLevel,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Intention.fromMap(Map<String, dynamic> map) {
    return Intention(
      id: map['id'] as int?,
      date: DateTime.parse(map['date'] as String),
      intention: map['intention'] as String,
      affirmation: map['affirmation'] as String?,
      focusAreas: (map['focus_areas'] as String?)?.isNotEmpty == true
          ? (map['focus_areas'] as String).split(',')
          : [],
      energyLevel: map['energy_level'] as int? ?? 3,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

/// 意图模板
class IntentionTemplate {
  final String category;
  final List<String> intentions;
  final List<String> affirmations;

  const IntentionTemplate({
    required this.category,
    required this.intentions,
    required this.affirmations,
  });
}

const defaultIntentionTemplates = [
  IntentionTemplate(
    category: '工作',
    intentions: [
      '今天我要高效完成任务',
      '我专注于最重要的目标',
      '保持专业和积极的态度',
    ],
    affirmations: [
      '我是有能力的人',
      '我能够克服挑战',
    ],
  ),
  IntentionTemplate(
    category: '学习',
    intentions: [
      '今天我要学到新知识',
      '保持好奇心和开放心态',
      '坚持不懈地追求成长',
    ],
    affirmations: [
      '学习让我变得更好',
      '每一天我都在进步',
    ],
  ),
  IntentionTemplate(
    category: '健康',
    intentions: [
      '今天我要照顾好自己的身体',
      '保持活力和精力充沛',
      '倾听身体的需求',
    ],
    affirmations: [
      '我的身体很健康',
      '我有足够的能量',
    ],
  ),
  IntentionTemplate(
    category: '人际',
    intentions: [
      '今天我要用心倾听他人',
      '传递正能量和温暖',
      '建立更深层的连接',
    ],
    affirmations: [
      '我值得被爱',
      '我能够给予他人支持',
    ],
  ),
];