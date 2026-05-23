class LinkDiscovery {
  final int? id;
  final int recordIdA;
  final int recordIdB;
  final String linkType;
  final double confidenceScore;
  final bool isAccepted;
  final DateTime createdAt;

  LinkDiscovery({
    this.id,
    required this.recordIdA,
    required this.recordIdB,
    required this.linkType,
    this.confidenceScore = 0,
    this.isAccepted = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'record_id_a': recordIdA,
      'record_id_b': recordIdB,
      'link_type': linkType,
      'confidence_score': confidenceScore,
      'is_accepted': isAccepted ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory LinkDiscovery.fromMap(Map<String, dynamic> map) {
    return LinkDiscovery(
      id: map['id'],
      recordIdA: map['record_id_a'],
      recordIdB: map['record_id_b'],
      linkType: map['link_type'],
      confidenceScore: (map['confidence_score'] ?? 0).toDouble(),
      isAccepted: map['is_accepted'] == 1,
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  LinkDiscovery copyWith({
    int? id,
    int? recordIdA,
    int? recordIdB,
    String? linkType,
    double? confidenceScore,
    bool? isAccepted,
    DateTime? createdAt,
  }) {
    return LinkDiscovery(
      id: id ?? this.id,
      recordIdA: recordIdA ?? this.recordIdA,
      recordIdB: recordIdB ?? this.recordIdB,
      linkType: linkType ?? this.linkType,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      isAccepted: isAccepted ?? this.isAccepted,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

enum LinkType {
  timeProximity('时间相近'),
  location('同一地点'),
  tagShared('标签共现'),
  contentSimilar('内容相似'),
  personShared('涉及同一人');

  final String label;
  const LinkType(this.label);
}