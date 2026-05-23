enum InteractionType {
  chat,
  call,
  meeting,
  dinner,
  event,
  videoCall,
}

extension InteractionTypeExtension on InteractionType {
  String get displayName {
    switch (this) {
      case InteractionType.chat:
        return 'Chat';
      case InteractionType.call:
        return 'Call';
      case InteractionType.meeting:
        return 'Meeting';
      case InteractionType.dinner:
        return 'Dinner';
      case InteractionType.event:
        return 'Event';
      case InteractionType.videoCall:
        return 'Video Call';
    }
  }

  String get value {
    switch (this) {
      case InteractionType.chat:
        return 'chat';
      case InteractionType.call:
        return 'call';
      case InteractionType.meeting:
        return 'meeting';
      case InteractionType.dinner:
        return 'dinner';
      case InteractionType.event:
        return 'event';
      case InteractionType.videoCall:
        return 'video_call';
    }
  }

  static InteractionType fromString(String value) {
    switch (value) {
      case 'chat':
        return InteractionType.chat;
      case 'call':
        return InteractionType.call;
      case 'meeting':
        return InteractionType.meeting;
      case 'dinner':
        return InteractionType.dinner;
      case 'event':
        return InteractionType.event;
      case 'video_call':
        return InteractionType.videoCall;
      default:
        return InteractionType.chat;
    }
  }
}

class SocialInteraction {
  final int? id;
  final String personName;
  final InteractionType interactionType;
  final int durationMinutes;
  final int qualityRating; // 1-5
  final String? location;
  final DateTime interactionDate;
  final List<String> topicsDiscussed;
  final bool followUpNeeded;
  final int? linkedRecordId;
  final String? note;
  final DateTime createdAt;

  SocialInteraction({
    this.id,
    required this.personName,
    required this.interactionType,
    this.durationMinutes = 0,
    this.qualityRating = 3,
    this.location,
    required this.interactionDate,
    this.topicsDiscussed = const [],
    this.followUpNeeded = false,
    this.linkedRecordId,
    this.note,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  SocialInteraction copyWith({
    int? id,
    String? personName,
    InteractionType? interactionType,
    int? durationMinutes,
    int? qualityRating,
    String? location,
    DateTime? interactionDate,
    List<String>? topicsDiscussed,
    bool? followUpNeeded,
    int? linkedRecordId,
    String? note,
    DateTime? createdAt,
  }) {
    return SocialInteraction(
      id: id ?? this.id,
      personName: personName ?? this.personName,
      interactionType: interactionType ?? this.interactionType,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      qualityRating: qualityRating ?? this.qualityRating,
      location: location ?? this.location,
      interactionDate: interactionDate ?? this.interactionDate,
      topicsDiscussed: topicsDiscussed ?? this.topicsDiscussed,
      followUpNeeded: followUpNeeded ?? this.followUpNeeded,
      linkedRecordId: linkedRecordId ?? this.linkedRecordId,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'person_name': personName,
      'interaction_type': interactionType.value,
      'duration_minutes': durationMinutes,
      'quality_rating': qualityRating,
      'location': location,
      'interaction_date': interactionDate.toIso8601String(),
      'topics_discussed': topicsDiscussed.join(','),
      'follow_up_needed': followUpNeeded ? 1 : 0,
      'linked_record_id': linkedRecordId,
      'note': note,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory SocialInteraction.fromMap(Map<String, dynamic> map) {
    return SocialInteraction(
      id: map['id'] as int?,
      personName: map['person_name'] as String,
      interactionType: InteractionTypeExtension.fromString(map['interaction_type'] as String),
      durationMinutes: map['duration_minutes'] as int? ?? 0,
      qualityRating: map['quality_rating'] as int? ?? 3,
      location: map['location'] as String?,
      interactionDate: DateTime.parse(map['interaction_date'] as String),
      topicsDiscussed: (map['topics_discussed'] as String?)?.split(',').where((t) => t.isNotEmpty).toList() ?? [],
      followUpNeeded: (map['follow_up_needed'] as int?) == 1,
      linkedRecordId: map['linked_record_id'] as int?,
      note: map['note'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  @override
  String toString() {
    return 'SocialInteraction(id: $id, personName: $personName, type: ${interactionType.displayName}, date: $interactionDate)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SocialInteraction && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}