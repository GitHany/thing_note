/// 情绪记录数据模型
class MoodEntry {
  final int? id;
  final DateTime timestamp;
  final MoodLevel mood;
  final String? note;
  final List<String> triggers;
  final int? linkedRecordId;
  final DateTime createdAt;

  const MoodEntry({
    this.id,
    required this.timestamp,
    required this.mood,
    this.note,
    this.triggers = const [],
    this.linkedRecordId,
    required this.createdAt,
  });

  MoodEntry copyWith({
    int? id,
    DateTime? timestamp,
    MoodLevel? mood,
    String? note,
    List<String>? triggers,
    int? linkedRecordId,
    DateTime? createdAt,
  }) {
    return MoodEntry(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      mood: mood ?? this.mood,
      note: note ?? this.note,
      triggers: triggers ?? this.triggers,
      linkedRecordId: linkedRecordId ?? this.linkedRecordId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'timestamp': timestamp.toIso8601String(),
      'mood': mood.name,
      'note': note,
      'triggers': triggers.join(','),
      'linked_record_id': linkedRecordId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory MoodEntry.fromMap(Map<String, dynamic> map) {
    return MoodEntry(
      id: map['id'] as int?,
      timestamp: DateTime.parse(map['timestamp'] as String),
      mood: MoodLevel.values.firstWhere(
        (e) => e.name == map['mood'],
        orElse: () => MoodLevel.neutral,
      ),
      note: map['note'] as String?,
      triggers: (map['triggers'] as String?)?.split(',').where((t) => t.isNotEmpty).toList() ?? [],
      linkedRecordId: map['linked_record_id'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

enum MoodLevel {
  veryBad,
  bad,
  neutral,
  good,
  veryGood,
}

extension MoodLevelExtension on MoodLevel {
  String get emoji {
    switch (this) {
      case MoodLevel.veryBad:
        return '😢';
      case MoodLevel.bad:
        return '😔';
      case MoodLevel.neutral:
        return '😐';
      case MoodLevel.good:
        return '🙂';
      case MoodLevel.veryGood:
        return '😄';
    }
  }

  String get displayName {
    switch (this) {
      case MoodLevel.veryBad:
        return '非常差';
      case MoodLevel.bad:
        return '较差';
      case MoodLevel.neutral:
        return '一般';
      case MoodLevel.good:
        return '良好';
      case MoodLevel.veryGood:
        return '非常好';
    }
  }

  int get value {
    switch (this) {
      case MoodLevel.veryBad:
        return 1;
      case MoodLevel.bad:
        return 2;
      case MoodLevel.neutral:
        return 3;
      case MoodLevel.good:
        return 4;
      case MoodLevel.veryGood:
        return 5;
    }
  }
}

/// 常用情绪触发因素
class MoodTrigger {
  static const List<String> commonTriggers = [
    '工作',
    '学习',
    '家庭',
    '朋友',
    '健康',
    '睡眠',
    '运动',
    '饮食',
    '天气',
    '财务',
    '社交',
    '独处',
  ];
}