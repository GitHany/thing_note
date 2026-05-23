class Relationship {
  final int? id;
  final String personName;
  final String? relationshipType;
  final int contactFrequency;
  final DateTime? lastContactDate;
  final int closenessLevel;
  final List<String> sharedInterests;
  final String? notes;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  Relationship({
    this.id,
    required this.personName,
    this.relationshipType,
    this.contactFrequency = 0,
    this.lastContactDate,
    this.closenessLevel = 0,
    this.sharedInterests = const [],
    this.notes,
    this.photoUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'person_name': personName,
      'relationship_type': relationshipType,
      'contact_frequency': contactFrequency,
      'last_contact_date': lastContactDate?.toIso8601String(),
      'closeness_level': closenessLevel,
      'shared_interests': sharedInterests.join(','),
      'notes': notes,
      'photo_url': photoUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Relationship.fromMap(Map<String, dynamic> map) {
    return Relationship(
      id: map['id'] as int?,
      personName: map['person_name'] as String,
      relationshipType: map['relationship_type'] as String?,
      contactFrequency: map['contact_frequency'] as int? ?? 0,
      lastContactDate: map['last_contact_date'] != null
          ? DateTime.parse(map['last_contact_date'] as String)
          : null,
      closenessLevel: map['closeness_level'] as int? ?? 0,
      sharedInterests: (map['shared_interests'] as String?)?.split(',').where((i) => i.isNotEmpty).toList() ?? [],
      notes: map['notes'] as String?,
      photoUrl: map['photo_url'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}

class RelationshipInteraction {
  final int? id;
  final int relationshipId;
  final String interactionType;
  final int qualityRating;
  final int durationMinutes;
  final DateTime interactionDate;
  final List<String> topics;
  final int emotionalImpact;
  final bool followUpPlanned;
  final int? linkedRecordId;
  final String? note;
  final DateTime createdAt;

  RelationshipInteraction({
    this.id,
    required this.relationshipId,
    required this.interactionType,
    this.qualityRating = 0,
    this.durationMinutes = 0,
    required this.interactionDate,
    this.topics = const [],
    this.emotionalImpact = 0,
    this.followUpPlanned = false,
    this.linkedRecordId,
    this.note,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'relationship_id': relationshipId,
      'interaction_type': interactionType,
      'quality_rating': qualityRating,
      'duration_minutes': durationMinutes,
      'interaction_date': interactionDate.toIso8601String(),
      'topics': topics.join(','),
      'emotional_impact': emotionalImpact,
      'follow_up_planned': followUpPlanned ? 1 : 0,
      'linked_record_id': linkedRecordId,
      'note': note,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory RelationshipInteraction.fromMap(Map<String, dynamic> map) {
    return RelationshipInteraction(
      id: map['id'] as int?,
      relationshipId: map['relationship_id'] as int,
      interactionType: map['interaction_type'] as String,
      qualityRating: map['quality_rating'] as int? ?? 0,
      durationMinutes: map['duration_minutes'] as int? ?? 0,
      interactionDate: DateTime.parse(map['interaction_date'] as String),
      topics: (map['topics'] as String?)?.split(',').where((t) => t.isNotEmpty).toList() ?? [],
      emotionalImpact: map['emotional_impact'] as int? ?? 0,
      followUpPlanned: (map['follow_up_planned'] as int?) == 1,
      linkedRecordId: map['linked_record_id'] as int?,
      note: map['note'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}