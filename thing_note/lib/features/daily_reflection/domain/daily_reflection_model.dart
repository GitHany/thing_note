class DailyReflection {
  final int? id;
  final String date;
  final String? achievements;
  final String? gratitudeItems;
  final String? tomorrowPlans;
  final int moodRating;
  final String? overallNote;
  final List<int>? linkedRecordIds;
  final String createdAt;
  final String updatedAt;

  DailyReflection({
    this.id,
    required this.date,
    this.achievements,
    this.gratitudeItems,
    this.tomorrowPlans,
    this.moodRating = 3,
    this.overallNote,
    this.linkedRecordIds,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'achievements': achievements,
      'gratitude_items': gratitudeItems,
      'tomorrow_plans': tomorrowPlans,
      'mood_rating': moodRating,
      'overall_note': overallNote,
      'linked_record_ids': linkedRecordIds?.join(','),
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory DailyReflection.fromMap(Map<String, dynamic> map) {
    List<int>? linkedIds;
    if (map['linked_record_ids'] != null && map['linked_record_ids'].toString().isNotEmpty) {
      linkedIds = map['linked_record_ids'].toString().split(',').map((e) => int.tryParse(e) ?? 0).toList();
    }
    
    return DailyReflection(
      id: map['id'] as int?,
      date: map['date'] as String,
      achievements: map['achievements'] as String?,
      gratitudeItems: map['gratitude_items'] as String?,
      tomorrowPlans: map['tomorrow_plans'] as String?,
      moodRating: map['mood_rating'] as int? ?? 3,
      overallNote: map['overall_note'] as String?,
      linkedRecordIds: linkedIds,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
    );
  }

  DailyReflection copyWith({
    int? id,
    String? date,
    String? achievements,
    String? gratitudeItems,
    String? tomorrowPlans,
    int? moodRating,
    String? overallNote,
    List<int>? linkedRecordIds,
    String? createdAt,
    String? updatedAt,
  }) {
    return DailyReflection(
      id: id ?? this.id,
      date: date ?? this.date,
      achievements: achievements ?? this.achievements,
      gratitudeItems: gratitudeItems ?? this.gratitudeItems,
      tomorrowPlans: tomorrowPlans ?? this.tomorrowPlans,
      moodRating: moodRating ?? this.moodRating,
      overallNote: overallNote ?? this.overallNote,
      linkedRecordIds: linkedRecordIds ?? this.linkedRecordIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class ReflectionEntry {
  final int? id;
  final int reflectionId;
  final String entryType;
  final String content;
  final String? category;
  final String createdAt;

  ReflectionEntry({
    this.id,
    required this.reflectionId,
    required this.entryType,
    required this.content,
    this.category,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'reflection_id': reflectionId,
      'entry_type': entryType,
      'content': content,
      'category': category,
      'created_at': createdAt,
    };
  }

  factory ReflectionEntry.fromMap(Map<String, dynamic> map) {
    return ReflectionEntry(
      id: map['id'] as int?,
      reflectionId: map['reflection_id'] as int,
      entryType: map['entry_type'] as String,
      content: map['content'] as String,
      category: map['category'] as String?,
      createdAt: map['created_at'] as String,
    );
  }
}