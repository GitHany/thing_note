class AccountabilityGroup {
  final int? id;
  final String groupName;
  final String? memberIds;
  final int isAnonymous;
  final DateTime createdAt;

  AccountabilityGroup({
    this.id,
    required this.groupName,
    this.memberIds,
    this.isAnonymous = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'group_name': groupName,
      'member_ids': memberIds,
      'is_anonymous': isAnonymous,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory AccountabilityGroup.fromMap(Map<String, dynamic> map) {
    return AccountabilityGroup(
      id: map['id'] as int?,
      groupName: map['group_name'] as String,
      memberIds: map['member_ids'] as String?,
      isAnonymous: map['is_anonymous'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  List<String> get memberIdList =>
      (memberIds ?? '').split(',').where((s) => s.isNotEmpty).toList();

  AccountabilityGroup copyWith({
    int? id,
    String? groupName,
    String? memberIds,
    int? isAnonymous,
    DateTime? createdAt,
  }) {
    return AccountabilityGroup(
      id: id ?? this.id,
      groupName: groupName ?? this.groupName,
      memberIds: memberIds ?? this.memberIds,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class AccountabilityUpdate {
  final int? id;
  final int groupId;
  final String memberId;
  final int? goalId;
  final String? progressNote;
  final int isEncouragement;
  final DateTime createdAt;

  AccountabilityUpdate({
    this.id,
    required this.groupId,
    required this.memberId,
    this.goalId,
    this.progressNote,
    this.isEncouragement = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'group_id': groupId,
      'member_id': memberId,
      'goal_id': goalId,
      'progress_note': progressNote,
      'is_encouragement': isEncouragement,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory AccountabilityUpdate.fromMap(Map<String, dynamic> map) {
    return AccountabilityUpdate(
      id: map['id'] as int?,
      groupId: map['group_id'] as int,
      memberId: map['member_id'] as String,
      goalId: map['goal_id'] as int?,
      progressNote: map['progress_note'] as String?,
      isEncouragement: map['is_encouragement'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  AccountabilityUpdate copyWith({
    int? id,
    int? groupId,
    String? memberId,
    int? goalId,
    String? progressNote,
    int? isEncouragement,
    DateTime? createdAt,
  }) {
    return AccountabilityUpdate(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      memberId: memberId ?? this.memberId,
      goalId: goalId ?? this.goalId,
      progressNote: progressNote ?? this.progressNote,
      isEncouragement: isEncouragement ?? this.isEncouragement,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}