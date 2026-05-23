class RelationshipGraph {
  final int? id;
  final String personName;
  final String? personType;
  final int interactionCount;
  final String? lastInteractionDate;
  final double closenessScore;
  final List<String> sharedTags;
  final List<String> sharedLocations;
  final int? groupId;
  final String? photoUrl;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;

  RelationshipGraph({
    this.id,
    required this.personName,
    this.personType,
    this.interactionCount = 0,
    this.lastInteractionDate,
    this.closenessScore = 0,
    this.sharedTags = const [],
    this.sharedLocations = const [],
    this.groupId,
    this.photoUrl,
    this.note,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'person_name': personName,
      'person_type': personType,
      'interaction_count': interactionCount,
      'last_interaction_date': lastInteractionDate,
      'closeness_score': closenessScore,
      'shared_tags': sharedTags.join(','),
      'shared_locations': sharedLocations.join(','),
      'group_id': groupId,
      'photo_url': photoUrl,
      'note': note,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory RelationshipGraph.fromMap(Map<String, dynamic> map) {
    return RelationshipGraph(
      id: map['id'],
      personName: map['person_name'],
      personType: map['person_type'],
      interactionCount: map['interaction_count'] ?? 0,
      lastInteractionDate: map['last_interaction_date'],
      closenessScore: (map['closeness_score'] ?? 0).toDouble(),
      sharedTags: (map['shared_tags'] as String?)?.split(',').where((e) => e.isNotEmpty).toList() ?? [],
      sharedLocations: (map['shared_locations'] as String?)?.split(',').where((e) => e.isNotEmpty).toList() ?? [],
      groupId: map['group_id'],
      photoUrl: map['photo_url'],
      note: map['note'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  RelationshipGraph copyWith({
    int? id,
    String? personName,
    String? personType,
    int? interactionCount,
    String? lastInteractionDate,
    double? closenessScore,
    List<String>? sharedTags,
    List<String>? sharedLocations,
    int? groupId,
    String? photoUrl,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RelationshipGraph(
      id: id ?? this.id,
      personName: personName ?? this.personName,
      personType: personType ?? this.personType,
      interactionCount: interactionCount ?? this.interactionCount,
      lastInteractionDate: lastInteractionDate ?? this.lastInteractionDate,
      closenessScore: closenessScore ?? this.closenessScore,
      sharedTags: sharedTags ?? this.sharedTags,
      sharedLocations: sharedLocations ?? this.sharedLocations,
      groupId: groupId ?? this.groupId,
      photoUrl: photoUrl ?? this.photoUrl,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

enum PersonType {
  family('家人'),
  friend('朋友'),
  colleague('同事'),
  acquaintance('认识的人'),
  stranger('陌生人');

  final String label;
  const PersonType(this.label);
}