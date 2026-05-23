/// Record link with metadata
class EnhancedRecordLink {
  final int? id;
  final int sourceRecordId;
  final int targetRecordId;
  final String linkType; // reference, parent, child, related
  final String? note;
  final DateTime createdAt;

  EnhancedRecordLink({
    this.id,
    required this.sourceRecordId,
    required this.targetRecordId,
    this.linkType = 'related',
    this.note,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'source_record_id': sourceRecordId,
      'target_record_id': targetRecordId,
      'link_type': linkType,
      'note': note,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory EnhancedRecordLink.fromMap(Map<String, dynamic> map) {
    return EnhancedRecordLink(
      id: map['id'] as int?,
      sourceRecordId: map['source_record_id'] as int,
      targetRecordId: map['target_record_id'] as int,
      linkType: map['link_type'] as String? ?? 'related',
      note: map['note'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

/// Link suggestion based on content similarity
class LinkSuggestion {
  final int sourceRecordId;
  final int targetRecordId;
  final double similarityScore;
  final String reason;
  final String sourceNote;
  final String targetNote;

  LinkSuggestion({
    required this.sourceRecordId,
    required this.targetRecordId,
    required this.similarityScore,
    required this.reason,
    required this.sourceNote,
    required this.targetNote,
  });
}

/// Link statistics
class LinkStats {
  final int totalLinks;
  final int referenceLinks;
  final int parentChildLinks;
  final int relatedLinks;
  final Map<String, int> linkTypeDistribution;

  LinkStats({
    this.totalLinks = 0,
    this.referenceLinks = 0,
    this.parentChildLinks = 0,
    this.relatedLinks = 0,
    this.linkTypeDistribution = const {},
  });
}