class DistractionRecord {
  final int? id;
  final String distractionType;
  final String? source;
  final int durationMinutes;
  final int costEstimate;
  final String distractionDate;
  final int? linkedRecordId;
  final String? note;
  final DateTime createdAt;

  DistractionRecord({
    this.id,
    required this.distractionType,
    this.source,
    this.durationMinutes = 0,
    this.costEstimate = 0,
    required this.distractionDate,
    this.linkedRecordId,
    this.note,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'distraction_type': distractionType,
      'source': source,
      'duration_minutes': durationMinutes,
      'cost_estimate': costEstimate,
      'distraction_date': distractionDate,
      'linked_record_id': linkedRecordId,
      'note': note,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory DistractionRecord.fromMap(Map<String, dynamic> map) {
    return DistractionRecord(
      id: map['id'] as int?,
      distractionType: map['distraction_type'] as String,
      source: map['source'] as String?,
      durationMinutes: map['duration_minutes'] as int? ?? 0,
      costEstimate: map['cost_estimate'] as int? ?? 0,
      distractionDate: map['distraction_date'] as String,
      linkedRecordId: map['linked_record_id'] as int?,
      note: map['note'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  DistractionRecord copyWith({
    int? id,
    String? distractionType,
    String? source,
    int? durationMinutes,
    int? costEstimate,
    String? distractionDate,
    int? linkedRecordId,
    String? note,
    DateTime? createdAt,
  }) {
    return DistractionRecord(
      id: id ?? this.id,
      distractionType: distractionType ?? this.distractionType,
      source: source ?? this.source,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      costEstimate: costEstimate ?? this.costEstimate,
      distractionDate: distractionDate ?? this.distractionDate,
      linkedRecordId: linkedRecordId ?? this.linkedRecordId,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static const List<String> distractionTypes = [
    'social_media',
    'unrelated_thoughts',
    'noise',
    'sudden_task',
    'fatigue',
    'other',
  ];

  static const Map<String, String> typeLabels = {
    'social_media': '社交媒体',
    'unrelated_thoughts': '无关念头',
    'noise': '噪音干扰',
    'sudden_task': '突发任务',
    'fatigue': '疲劳走神',
    'other': '其他',
  };

  static const Map<String, String> typeIcons = {
    'social_media': '📱',
    'unrelated_thoughts': '💭',
    'noise': '🔊',
    'sudden_task': '⚡',
    'fatigue': '😴',
    'other': '❓',
  };
}