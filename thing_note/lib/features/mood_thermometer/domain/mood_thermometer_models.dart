/// 情绪温度计 - Mood Thermometer
/// 更精细的情绪记录与分析系统
library;

/// 情绪记录模型
class MoodThermometerRecord {
  final int? id;
  final int moodLevel; // 0-100, 温度计刻度
  final String? category; // 工作/生活/健康/关系
  final String? trigger; // 触发因素
  final String? note;
  final DateTime recordedAt;
  final List<String> tags;
  final int? linkedRecordId;

  MoodThermometerRecord({
    this.id,
    required this.moodLevel,
    this.category,
    this.trigger,
    this.note,
    required this.recordedAt,
    this.tags = const [],
    this.linkedRecordId,
  });

  Map<String, dynamic> toMap() {
    return {
      'mood_level': moodLevel,
      'category': category,
      'trigger': trigger,
      'note': note,
      'recorded_at': recordedAt.toIso8601String(),
      'tags': tags.join(','),
      'linked_record_id': linkedRecordId,
    };
  }

  factory MoodThermometerRecord.fromMap(Map<String, dynamic> map) {
    final tagsStr = map['tags'] as String? ?? '';
    return MoodThermometerRecord(
      id: map['id'] as int?,
      moodLevel: map['mood_level'] as int,
      category: map['category'] as String?,
      trigger: map['trigger'] as String?,
      note: map['note'] as String?,
      recordedAt: DateTime.parse(map['recorded_at'] as String),
      tags: tagsStr.isEmpty ? [] : tagsStr.split(','),
      linkedRecordId: map['linked_record_id'] as int?,
    );
  }

  MoodThermometerRecord copyWith({
    int? id,
    int? moodLevel,
    String? category,
    String? trigger,
    String? note,
    DateTime? recordedAt,
    List<String>? tags,
    int? linkedRecordId,
  }) {
    return MoodThermometerRecord(
      id: id ?? this.id,
      moodLevel: moodLevel ?? this.moodLevel,
      category: category ?? this.category,
      trigger: trigger ?? this.trigger,
      note: note ?? this.note,
      recordedAt: recordedAt ?? this.recordedAt,
      tags: tags ?? this.tags,
      linkedRecordId: linkedRecordId ?? this.linkedRecordId,
    );
  }

  /// 获取情绪状态描述
  String get moodDescription {
    if (moodLevel >= 90) return '非常好';
    if (moodLevel >= 80) return '很好';
    if (moodLevel >= 70) return '不错';
    if (moodLevel >= 60) return '良好';
    if (moodLevel >= 50) return '一般';
    if (moodLevel >= 40) return '有点低落';
    if (moodLevel >= 30) return '不太好';
    if (moodLevel >= 20) return '低落';
    if (moodLevel >= 10) return '很差';
    return '非常差';
  }

  /// 获取情绪颜色
  int get moodColorValue {
    if (moodLevel >= 80) return 0xFF4CAF50; // 绿色
    if (moodLevel >= 60) return 0xFF8BC34A; // 浅绿
    if (moodLevel >= 40) return 0xFFFFC107; // 黄色
    if (moodLevel >= 20) return 0xFFFF9800; // 橙色
    return 0xFFF44336; // 红色
  }
}

/// 情绪统计
class MoodThermometerStats {
  final int totalRecords;
  final double averageMood;
  final int highestMood;
  final int lowestMood;
  final Map<int, int> distribution; // moodLevel -> count
  final List<MoodTrendPoint> trend;

  MoodThermometerStats({
    required this.totalRecords,
    required this.averageMood,
    required this.highestMood,
    required this.lowestMood,
    required this.distribution,
    required this.trend,
  });
}

/// 情绪趋势数据点
class MoodTrendPoint {
  final DateTime date;
  final int moodLevel;
  final String? note;

  MoodTrendPoint({
    required this.date,
    required this.moodLevel,
    this.note,
  });
}

/// 情绪类别
enum MoodCategory {
  work('工作', '💼'),
  life('生活', '🏠'),
  health('健康', '🏥'),
  relationship('人际关系', '💕'),
  finance('财务', '💰'),
  hobby('兴趣爱好', '🎯'),
  family('家庭', '👨‍👩‍👧'),
  study('学习', '📚');

  final String label;
  final String emoji;

  const MoodCategory(this.label, this.emoji);
}

/// 常见触发因素
class MoodTrigger {
  static const List<String> common = [
    '工作压力',
    '睡眠不足',
    '运动锻炼',
    '社交活动',
    '饮食状况',
    '天气变化',
    '家庭问题',
    '感情问题',
    '经济压力',
    '健康问题',
    '学习任务',
    '朋友相聚',
    '独自一人',
    '旅行出行',
    '完成目标',
    '获得奖励',
  ];
}