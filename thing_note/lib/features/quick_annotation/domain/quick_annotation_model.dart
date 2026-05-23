class QuickAnnotation {
  final int? id;
  final int recordId;
  final String annotationType;
  final String? annotationValue;
  final DateTime createdAt;

  QuickAnnotation({
    this.id,
    required this.recordId,
    required this.annotationType,
    this.annotationValue,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'record_id': recordId,
      'annotation_type': annotationType,
      'annotation_value': annotationValue,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory QuickAnnotation.fromMap(Map<String, dynamic> map) {
    return QuickAnnotation(
      id: map['id'],
      recordId: map['record_id'],
      annotationType: map['annotation_type'],
      annotationValue: map['annotation_value'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  QuickAnnotation copyWith({
    int? id,
    int? recordId,
    String? annotationType,
    String? annotationValue,
    DateTime? createdAt,
  }) {
    return QuickAnnotation(
      id: id ?? this.id,
      recordId: recordId ?? this.recordId,
      annotationType: annotationType ?? this.annotationType,
      annotationValue: annotationValue ?? this.annotationValue,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

enum AnnotationType {
  emoji('心情表情'),
  importance('重要性'),
  quickTag('快捷标签'),
  custom('自定义');

  final String label;
  const AnnotationType(this.label);
}

class AnnotationEmoji {
  static const String like = '👍';
  static const String love = '❤️';
  static const String star = '⭐';
  static const String fire = '🔥';
  static const String thinking = '🤔';
  static const String important = '❗';

  static const List<String> all = [like, love, star, fire, thinking, important];
}