class SensoryRecord {
  final int? id;
  final String recordedAt;
  final String? visualEnvironment;
  final String? auditoryEnvironment;
  final String? olfactoryEnvironment;
  final String? gustatoryEnvironment;
  final String? tactileEnvironment;
  final int moodScore;
  final int? linkedRecordId;
  final String? note;
  final DateTime createdAt;

  SensoryRecord({
    this.id,
    required this.recordedAt,
    this.visualEnvironment,
    this.auditoryEnvironment,
    this.olfactoryEnvironment,
    this.gustatoryEnvironment,
    this.tactileEnvironment,
    this.moodScore = 3,
    this.linkedRecordId,
    this.note,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'recorded_at': recordedAt,
      'visual_environment': visualEnvironment,
      'auditory_environment': auditoryEnvironment,
      'olfactory_environment': olfactoryEnvironment,
      'gustatory_environment': gustatoryEnvironment,
      'tactile_environment': tactileEnvironment,
      'mood_score': moodScore,
      'linked_record_id': linkedRecordId,
      'note': note,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory SensoryRecord.fromMap(Map<String, dynamic> map) {
    return SensoryRecord(
      id: map['id'] as int?,
      recordedAt: map['recorded_at'] as String,
      visualEnvironment: map['visual_environment'] as String?,
      auditoryEnvironment: map['auditory_environment'] as String?,
      olfactoryEnvironment: map['olfactory_environment'] as String?,
      gustatoryEnvironment: map['gustatory_environment'] as String?,
      tactileEnvironment: map['tactile_environment'] as String?,
      moodScore: map['mood_score'] as int? ?? 3,
      linkedRecordId: map['linked_record_id'] as int?,
      note: map['note'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  SensoryRecord copyWith({
    int? id,
    String? recordedAt,
    String? visualEnvironment,
    String? auditoryEnvironment,
    String? olfactoryEnvironment,
    String? gustatoryEnvironment,
    String? tactileEnvironment,
    int? moodScore,
    int? linkedRecordId,
    String? note,
    DateTime? createdAt,
  }) {
    return SensoryRecord(
      id: id ?? this.id,
      recordedAt: recordedAt ?? this.recordedAt,
      visualEnvironment: visualEnvironment ?? this.visualEnvironment,
      auditoryEnvironment: auditoryEnvironment ?? this.auditoryEnvironment,
      olfactoryEnvironment: olfactoryEnvironment ?? this.olfactoryEnvironment,
      gustatoryEnvironment: gustatoryEnvironment ?? this.gustatoryEnvironment,
      tactileEnvironment: tactileEnvironment ?? this.tactileEnvironment,
      moodScore: moodScore ?? this.moodScore,
      linkedRecordId: linkedRecordId ?? this.linkedRecordId,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static const Map<String, String> senseLabels = {
    'visual': '视觉',
    'auditory': '听觉',
    'olfactory': '嗅觉',
    'gustatory': '味觉',
    'tactile': '触觉',
  };

  static const Map<String, String> senseIcons = {
    'visual': '👁️',
    'auditory': '👂',
    'olfactory': '👃',
    'gustatory': '👅',
    'tactile': '✋',
  };
}