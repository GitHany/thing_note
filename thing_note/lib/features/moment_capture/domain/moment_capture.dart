class MomentCapture {
  final int? id;
  final String content;
  final String captureType;
  final int? moodLevel;
  final String? tags;
  final String? mediaPaths;
  final bool isConverted;
  final int? linkedRecordId;
  final DateTime capturedAt;
  final DateTime createdAt;

  MomentCapture({
    this.id,
    required this.content,
    this.captureType = 'thought',
    this.moodLevel,
    this.tags,
    this.mediaPaths,
    this.isConverted = false,
    this.linkedRecordId,
    required this.capturedAt,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  static const captureTypes = {
    'thought': {'name': '闪念', 'icon': '💡'},
    'idea': {'name': '创意', 'icon': '✨'},
    'todo': {'name': '待办', 'icon': '📝'},
    'gratitude': {'name': '感恩', 'icon': '🙏'},
    'question': {'name': '问题', 'icon': '❓'},
    'quote': {'name': '引用', 'icon': '💬'},
  };

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
      'capture_type': captureType,
      'mood_level': moodLevel,
      'tags': tags,
      'media_paths': mediaPaths,
      'is_converted': isConverted ? 1 : 0,
      'linked_record_id': linkedRecordId,
      'captured_at': capturedAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory MomentCapture.fromMap(Map<String, dynamic> map) {
    return MomentCapture(
      id: map['id'] as int?,
      content: map['content'] as String,
      captureType: map['capture_type'] as String? ?? 'thought',
      moodLevel: map['mood_level'] as int?,
      tags: map['tags'] as String?,
      mediaPaths: map['media_paths'] as String?,
      isConverted: (map['is_converted'] as int?) == 1,
      linkedRecordId: map['linked_record_id'] as int?,
      capturedAt: DateTime.parse(map['captured_at'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  MomentCapture copyWith({
    int? id,
    String? content,
    String? captureType,
    int? moodLevel,
    String? tags,
    String? mediaPaths,
    bool? isConverted,
    int? linkedRecordId,
    DateTime? capturedAt,
    DateTime? createdAt,
  }) {
    return MomentCapture(
      id: id ?? this.id,
      content: content ?? this.content,
      captureType: captureType ?? this.captureType,
      moodLevel: moodLevel ?? this.moodLevel,
      tags: tags ?? this.tags,
      mediaPaths: mediaPaths ?? this.mediaPaths,
      isConverted: isConverted ?? this.isConverted,
      linkedRecordId: linkedRecordId ?? this.linkedRecordId,
      capturedAt: capturedAt ?? this.capturedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
