class MoodEntry {
  final int? id;
  final String date;
  final int level;
  final List<String>? triggers;
  final String? note;
  final List<String>? activities;
  final DateTime createdAt;

  MoodEntry({
    this.id,
    required this.date,
    required this.level,
    this.triggers,
    this.note,
    this.activities,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'date': date,
      'level': level,
      'triggers': triggers?.join(','),
      'note': note,
      'activities': activities?.join(','),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory MoodEntry.fromMap(Map<String, dynamic> map) {
    return MoodEntry(
      id: map['id'] as int?,
      date: map['date'] as String,
      level: map['level'] as int,
      triggers: (map['triggers'] as String?)?.split(',').where((s) => s.isNotEmpty).toList(),
      note: map['note'] as String?,
      activities: (map['activities'] as String?)?.split(',').where((s) => s.isNotEmpty).toList(),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  String get moodEmoji {
    switch (level) {
      case 1:
        return '😢';
      case 2:
        return '😕';
      case 3:
        return '😐';
      case 4:
        return '🙂';
      case 5:
        return '😄';
      default:
        return '😐';
    }
  }

  String get moodLabel {
    switch (level) {
      case 1:
        return '很差';
      case 2:
        return '较差';
      case 3:
        return '一般';
      case 4:
        return '不错';
      case 5:
        return '很好';
      default:
        return '未知';
    }
  }
}