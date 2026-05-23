/// 社交互动数据模型
class SocialInteraction {
  final int? id;
  final String? contactName;
  final ContactType contactType;
  final InteractionType interactionType;
  final String? note;
  final int? linkedRecordId;
  final DateTime occurredAt;
  final DateTime createdAt;

  const SocialInteraction({
    this.id,
    this.contactName,
    this.contactType = ContactType.person,
    this.interactionType = InteractionType.meet,
    this.note,
    this.linkedRecordId,
    required this.occurredAt,
    required this.createdAt,
  });

  SocialInteraction copyWith({
    int? id,
    String? contactName,
    ContactType? contactType,
    InteractionType? interactionType,
    String? note,
    int? linkedRecordId,
    DateTime? occurredAt,
    DateTime? createdAt,
  }) {
    return SocialInteraction(
      id: id ?? this.id,
      contactName: contactName ?? this.contactName,
      contactType: contactType ?? this.contactType,
      interactionType: interactionType ?? this.interactionType,
      note: note ?? this.note,
      linkedRecordId: linkedRecordId ?? this.linkedRecordId,
      occurredAt: occurredAt ?? this.occurredAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'contact_name': contactName,
      'contact_type': contactType.name,
      'interaction_type': interactionType.name,
      'note': note,
      'linked_record_id': linkedRecordId,
      'occurred_at': occurredAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory SocialInteraction.fromMap(Map<String, dynamic> map) {
    return SocialInteraction(
      id: map['id'] as int?,
      contactName: map['contact_name'] as String?,
      contactType: ContactType.values.firstWhere(
        (e) => e.name == map['contact_type'],
        orElse: () => ContactType.person,
      ),
      interactionType: InteractionType.values.firstWhere(
        (e) => e.name == map['interaction_type'],
        orElse: () => InteractionType.meet,
      ),
      note: map['note'] as String?,
      linkedRecordId: map['linked_record_id'] as int?,
      occurredAt: DateTime.parse(map['occurred_at'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

enum ContactType { person, group, organization }

enum InteractionType { meet, call, message, video, email, other }

extension InteractionTypeExtension on InteractionType {
  String get displayName {
    switch (this) {
      case InteractionType.meet: return '见面';
      case InteractionType.call: return '通话';
      case InteractionType.message: return '消息';
      case InteractionType.video: return '视频';
      case InteractionType.email: return '邮件';
      case InteractionType.other: return '其他';
    }
  }

  String get icon {
    switch (this) {
      case InteractionType.meet: return '👋';
      case InteractionType.call: return '📞';
      case InteractionType.message: return '💬';
      case InteractionType.video: return '📹';
      case InteractionType.email: return '📧';
      case InteractionType.other: return '📝';
    }
  }
}

extension ContactTypeExtension on ContactType {
  String get displayName {
    switch (this) {
      case ContactType.person: return '个人';
      case ContactType.group: return '群组';
      case ContactType.organization: return '组织';
    }
  }
}