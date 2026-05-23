class RecordInfluenceLink {
  final int? id;
  final int sourceRecordId;
  final int targetRecordId;
  final String influenceType;
  final double influenceStrength;
  final DateTime createdAt;

  RecordInfluenceLink({
    this.id,
    required this.sourceRecordId,
    required this.targetRecordId,
    required this.influenceType,
    this.influenceStrength = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'source_record_id': sourceRecordId,
      'target_record_id': targetRecordId,
      'influence_type': influenceType,
      'influence_strength': influenceStrength,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory RecordInfluenceLink.fromMap(Map<String, dynamic> map) {
    return RecordInfluenceLink(
      id: map['id'],
      sourceRecordId: map['source_record_id'],
      targetRecordId: map['target_record_id'],
      influenceType: map['influence_type'],
      influenceStrength: (map['influence_strength'] ?? 0).toDouble(),
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  RecordInfluenceLink copyWith({
    int? id,
    int? sourceRecordId,
    int? targetRecordId,
    String? influenceType,
    double? influenceStrength,
    DateTime? createdAt,
  }) {
    return RecordInfluenceLink(
      id: id ?? this.id,
      sourceRecordId: sourceRecordId ?? this.sourceRecordId,
      targetRecordId: targetRecordId ?? this.targetRecordId,
      influenceType: influenceType ?? this.influenceType,
      influenceStrength: influenceStrength ?? this.influenceStrength,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

enum InfluenceType {
  direct('直接影响'),
  indirect('间接影响'),
  tagSpread('标签扩散'),
  behaviorChange('行为改变');

  final String label;
  const InfluenceType(this.label);
}