class TimeFragment {
  final int? id;
  final String content;
  final String fragmentType;
  final int durationSeconds;
  final String? audioPath;
  final List<String> mediaPaths;
  final bool isConverted;
  final int? linkedRecordId;
  final DateTime capturedAt;
  final DateTime createdAt;

  TimeFragment({
    this.id,
    required this.content,
    required this.fragmentType,
    this.durationSeconds = 30,
    this.audioPath,
    this.mediaPaths = const [],
    this.isConverted = false,
    this.linkedRecordId,
    DateTime? capturedAt,
    DateTime? createdAt,
  })  : capturedAt = capturedAt ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
      'fragment_type': fragmentType,
      'duration_seconds': durationSeconds,
      'audio_path': audioPath,
      'media_paths': mediaPaths.join(','),
      'is_converted': isConverted ? 1 : 0,
      'linked_record_id': linkedRecordId,
      'captured_at': capturedAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory TimeFragment.fromMap(Map<String, dynamic> map) {
    return TimeFragment(
      id: map['id'],
      content: map['content'],
      fragmentType: map['fragment_type'],
      durationSeconds: map['duration_seconds'] ?? 30,
      audioPath: map['audio_path'],
      mediaPaths: (map['media_paths'] as String?)?.split(',').where((e) => e.isNotEmpty).toList() ?? [],
      isConverted: map['is_converted'] == 1,
      linkedRecordId: map['linked_record_id'],
      capturedAt: DateTime.parse(map['captured_at']),
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  TimeFragment copyWith({
    int? id,
    String? content,
    String? fragmentType,
    int? durationSeconds,
    String? audioPath,
    List<String>? mediaPaths,
    bool? isConverted,
    int? linkedRecordId,
    DateTime? capturedAt,
    DateTime? createdAt,
  }) {
    return TimeFragment(
      id: id ?? this.id,
      content: content ?? this.content,
      fragmentType: fragmentType ?? this.fragmentType,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      audioPath: audioPath ?? this.audioPath,
      mediaPaths: mediaPaths ?? this.mediaPaths,
      isConverted: isConverted ?? this.isConverted,
      linkedRecordId: linkedRecordId ?? this.linkedRecordId,
      capturedAt: capturedAt ?? this.capturedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

enum FragmentType {
  inspiration('灵感'),
  quickNote('快速备忘'),
  instantFeeling('瞬间感受'),
  taskFragment('任务碎片');

  final String label;
  const FragmentType(this.label);
}