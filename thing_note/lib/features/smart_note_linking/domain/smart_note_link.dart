/// Smart Note Link Model
class SmartNoteLink {
  final int? id;
  final int sourceNoteId;
  final int targetRecordId;
  final String linkType;
  final double strengthScore;
  final String? linkBasis;
  final DateTime createdAt;

  SmartNoteLink({
    this.id,
    required this.sourceNoteId,
    required this.targetRecordId,
    this.linkType = 'auto',
    this.strengthScore = 0,
    this.linkBasis,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'source_note_id': sourceNoteId,
      'target_record_id': targetRecordId,
      'link_type': linkType,
      'strength_score': strengthScore,
      'link_basis': linkBasis,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory SmartNoteLink.fromMap(Map<String, dynamic> map) {
    return SmartNoteLink(
      id: map['id'] as int?,
      sourceNoteId: map['source_note_id'] as int,
      targetRecordId: map['target_record_id'] as int,
      linkType: map['link_type'] as String? ?? 'auto',
      strengthScore: (map['strength_score'] as num?)?.toDouble() ?? 0,
      linkBasis: map['link_basis'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  SmartNoteLink copyWith({
    int? id,
    int? sourceNoteId,
    int? targetRecordId,
    String? linkType,
    double? strengthScore,
    String? linkBasis,
    DateTime? createdAt,
  }) {
    return SmartNoteLink(
      id: id ?? this.id,
      sourceNoteId: sourceNoteId ?? this.sourceNoteId,
      targetRecordId: targetRecordId ?? this.targetRecordId,
      linkType: linkType ?? this.linkType,
      strengthScore: strengthScore ?? this.strengthScore,
      linkBasis: linkBasis ?? this.linkBasis,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}