/// 习惯挑战赛模型
class HabitTournament {
  final int? id;
  final String name;
  final String? description;
  final String targetHabit;
  final DateTime startDate;
  final DateTime? endDate;
  final int maxParticipants;
  final String? reward;
  final String status; // active, completed, cancelled
  final DateTime createdAt;

  HabitTournament({
    this.id,
    required this.name,
    this.description,
    required this.targetHabit,
    required this.startDate,
    this.endDate,
    this.maxParticipants = 50,
    this.reward,
    this.status = 'active',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'description': description,
      'target_habit': targetHabit,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'max_participants': maxParticipants,
      'reward': reward,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory HabitTournament.fromMap(Map<String, dynamic> map) {
    return HabitTournament(
      id: map['id'] as int?,
      name: map['name'] as String,
      description: map['description'] as String?,
      targetHabit: map['target_habit'] as String,
      startDate: DateTime.parse(map['start_date'] as String),
      endDate: map['end_date'] != null ? DateTime.parse(map['end_date'] as String) : null,
      maxParticipants: map['max_participants'] as int? ?? 50,
      reward: map['reward'] as String?,
      status: map['status'] as String? ?? 'active',
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

/// 挑战赛参与者
class TournamentParticipant {
  final int? id;
  final int tournamentId;
  final String participantName;
  final int currentStreak;
  final int totalScore;
  final int rank;
  final bool isActive;
  final DateTime joinedAt;

  TournamentParticipant({
    this.id,
    required this.tournamentId,
    required this.participantName,
    this.currentStreak = 0,
    this.totalScore = 0,
    this.rank = 0,
    this.isActive = true,
    required this.joinedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'tournament_id': tournamentId,
      'participant_name': participantName,
      'current_streak': currentStreak,
      'total_score': totalScore,
      'rank': rank,
      'is_active': isActive ? 1 : 0,
      'joined_at': joinedAt.toIso8601String(),
    };
  }

  factory TournamentParticipant.fromMap(Map<String, dynamic> map) {
    return TournamentParticipant(
      id: map['id'] as int?,
      tournamentId: map['tournament_id'] as int,
      participantName: map['participant_name'] as String,
      currentStreak: map['current_streak'] as int? ?? 0,
      totalScore: map['total_score'] as int? ?? 0,
      rank: map['rank'] as int? ?? 0,
      isActive: (map['is_active'] as int?) == 1,
      joinedAt: DateTime.parse(map['joined_at'] as String),
    );
  }
}

/// 目标树模型
class GoalTree {
  final int? id;
  final String name;
  final String? description;
  final int? rootGoalId;
  final DateTime createdAt;

  GoalTree({
    this.id,
    required this.name,
    this.description,
    this.rootGoalId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'description': description,
      'root_goal_id': rootGoalId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory GoalTree.fromMap(Map<String, dynamic> map) {
    return GoalTree(
      id: map['id'] as int?,
      name: map['name'] as String,
      description: map['description'] as String?,
      rootGoalId: map['root_goal_id'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

/// 目标节点
class GoalNode {
  final int? id;
  final int treeId;
  final int goalId;
  final int? parentNodeId;
  final int level;
  final int sortOrder;

  GoalNode({
    this.id,
    required this.treeId,
    required this.goalId,
    this.parentNodeId,
    this.level = 0,
    this.sortOrder = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'tree_id': treeId,
      'goal_id': goalId,
      'parent_node_id': parentNodeId,
      'level': level,
      'sort_order': sortOrder,
    };
  }

  factory GoalNode.fromMap(Map<String, dynamic> map) {
    return GoalNode(
      id: map['id'] as int?,
      treeId: map['tree_id'] as int,
      goalId: map['goal_id'] as int,
      parentNodeId: map['parent_node_id'] as int?,
      level: map['level'] as int? ?? 0,
      sortOrder: map['sort_order'] as int? ?? 0,
    );
  }
}

/// 提醒模式
class ReminderPattern {
  final int? id;
  final String patternType; // daily, weekly, custom
  final String? triggerTime;
  final String? triggerDays;
  final double successRate;
  final int totalTriggers;
  final DateTime? lastTriggered;
  final DateTime createdAt;

  ReminderPattern({
    this.id,
    required this.patternType,
    this.triggerTime,
    this.triggerDays,
    this.successRate = 0,
    this.totalTriggers = 0,
    this.lastTriggered,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'pattern_type': patternType,
      'trigger_time': triggerTime,
      'trigger_days': triggerDays,
      'success_rate': successRate,
      'total_triggers': totalTriggers,
      'last_triggered': lastTriggered?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ReminderPattern.fromMap(Map<String, dynamic> map) {
    return ReminderPattern(
      id: map['id'] as int?,
      patternType: map['pattern_type'] as String,
      triggerTime: map['trigger_time'] as String?,
      triggerDays: map['trigger_days'] as String?,
      successRate: (map['success_rate'] as num?)?.toDouble() ?? 0,
      totalTriggers: map['total_triggers'] as int? ?? 0,
      lastTriggered: map['last_triggered'] != null ? DateTime.parse(map['last_triggered'] as String) : null,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

/// 隐私设置
class PrivacySetting {
  final int? id;
  final String settingKey;
  final String settingValue;
  final DateTime updatedAt;

  PrivacySetting({
    this.id,
    required this.settingKey,
    required this.settingValue,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'setting_key': settingKey,
      'setting_value': settingValue,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory PrivacySetting.fromMap(Map<String, dynamic> map) {
    return PrivacySetting(
      id: map['id'] as int?,
      settingKey: map['setting_key'] as String,
      settingValue: map['setting_value'] as String,
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}

/// 情绪日记
class MoodJournal {
  final int? id;
  final DateTime date;
  final int moodLevel; // 1-5
  final String? gratitudeItems;
  final String? detailedNote;
  final String? triggers;
  final int? linkedRecordId;
  final DateTime createdAt;

  MoodJournal({
    this.id,
    required this.date,
    required this.moodLevel,
    this.gratitudeItems,
    this.detailedNote,
    this.triggers,
    this.linkedRecordId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'date': date.toIso8601String(),
      'mood_level': moodLevel,
      'gratitude_items': gratitudeItems,
      'detailed_note': detailedNote,
      'triggers': triggers,
      'linked_record_id': linkedRecordId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory MoodJournal.fromMap(Map<String, dynamic> map) {
    return MoodJournal(
      id: map['id'] as int?,
      date: DateTime.parse(map['date'] as String),
      moodLevel: map['mood_level'] as int,
      gratitudeItems: map['gratitude_items'] as String?,
      detailedNote: map['detailed_note'] as String?,
      triggers: map['triggers'] as String?,
      linkedRecordId: map['linked_record_id'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}