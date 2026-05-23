class QuickMoodCheckin {
  final int? id;
  final int moodLevel;
  final String? moodCategory;
  final String? quickNote;
  final int? energyLevel;
  final DateTime checkinTime;
  final int? linkedRecordId;
  final DateTime createdAt;

  QuickMoodCheckin({
    this.id,
    required this.moodLevel,
    this.moodCategory,
    this.quickNote,
    this.energyLevel,
    required this.checkinTime,
    this.linkedRecordId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  static const moodLevels = [
    {'value': 1, 'name': '非常差', 'icon': '😢', 'color': 0xFFE57373},
    {'value': 2, 'name': '比较差', 'icon': '😟', 'color': 0xFFFFB74D},
    {'value': 3, 'name': '一般', 'icon': '😐', 'color': 0xFFFFD54F},
    {'value': 4, 'name': '比较好', 'icon': '🙂', 'color': 0xFFAED581},
    {'value': 5, 'name': '非常好', 'icon': '😄', 'color': 0xFF81C784},
  ];

  static const moodCategories = [
    {'value': 'work', 'name': '工作'},
    {'value': 'life', 'name': '生活'},
    {'value': 'health', 'name': '健康'},
    {'value': 'relationship', 'name': '关系'},
    {'value': 'hobby', 'name': '爱好'},
    {'value': 'unknown', 'name': '未知'},
  ];

  String get moodIcon {
    final defaultMood = {'icon': '😐'};
    final mood = moodLevels.firstWhere(
      (m) => m['value'] == moodLevel,
      orElse: () => defaultMood,
    );
    return mood['icon']?.toString() ?? '😐';
  }

  String get moodName {
    final defaultMood = {'name': '未知'};
    final mood = moodLevels.firstWhere(
      (m) => m['value'] == moodLevel,
      orElse: () => defaultMood,
    );
    return mood['name']?.toString() ?? '未知';
  }

  int get moodColor {
    return moodLevels
        .firstWhere((m) => m['value'] == moodLevel,
            orElse: () => {'color': 0xFFFFD54F})['color'] as int;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'mood_level': moodLevel,
      'mood_category': moodCategory,
      'quick_note': quickNote,
      'energy_level': energyLevel,
      'checkin_time': checkinTime.toIso8601String(),
      'linked_record_id': linkedRecordId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory QuickMoodCheckin.fromMap(Map<String, dynamic> map) {
    return QuickMoodCheckin(
      id: map['id'] as int?,
      moodLevel: map['mood_level'] as int,
      moodCategory: map['mood_category'] as String?,
      quickNote: map['quick_note'] as String?,
      energyLevel: map['energy_level'] as int?,
      checkinTime: DateTime.parse(map['checkin_time'] as String),
      linkedRecordId: map['linked_record_id'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  QuickMoodCheckin copyWith({
    int? id,
    int? moodLevel,
    String? moodCategory,
    String? quickNote,
    int? energyLevel,
    DateTime? checkinTime,
    int? linkedRecordId,
    DateTime? createdAt,
  }) {
    return QuickMoodCheckin(
      id: id ?? this.id,
      moodLevel: moodLevel ?? this.moodLevel,
      moodCategory: moodCategory ?? this.moodCategory,
      quickNote: quickNote ?? this.quickNote,
      energyLevel: energyLevel ?? this.energyLevel,
      checkinTime: checkinTime ?? this.checkinTime,
      linkedRecordId: linkedRecordId ?? this.linkedRecordId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
