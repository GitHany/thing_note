/// 批量编辑规则模型
class BatchEditRule {
  final int? id;
  final String name;
  final String conditions; // JSON
  final String actions; // JSON
  final bool isEnabled;
  final DateTime createdAt;

  BatchEditRule({
    this.id,
    required this.name,
    required this.conditions,
    required this.actions,
    this.isEnabled = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'conditions': conditions,
      'actions': actions,
      'is_enabled': isEnabled ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory BatchEditRule.fromMap(Map<String, dynamic> map) {
    return BatchEditRule(
      id: map['id'] as int?,
      name: map['name'] as String,
      conditions: map['conditions'] as String,
      actions: map['actions'] as String,
      isEnabled: (map['is_enabled'] as int?) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> get conditionsMap {
    try {
      return Map<String, dynamic>.from(
        Uri.splitQueryString(conditions).map((k, v) => MapEntry(k, v)),
      );
    } catch (_) {
      return {};
    }
  }

  Map<String, dynamic> get actionsMap {
    try {
      return Map<String, dynamic>.from(
        Uri.splitQueryString(actions).map((k, v) => MapEntry(k, v)),
      );
    } catch (_) {
      return {};
    }
  }
}

/// 批量编辑历史记录
class BatchEditHistory {
  final int? id;
  final int? ruleId;
  final int recordsAffected;
  final String editType;
  final DateTime performedAt;

  BatchEditHistory({
    this.id,
    this.ruleId,
    this.recordsAffected = 0,
    required this.editType,
    DateTime? performedAt,
  }) : performedAt = performedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'rule_id': ruleId,
      'records_affected': recordsAffected,
      'edit_type': editType,
      'performed_at': performedAt.toIso8601String(),
    };
  }

  factory BatchEditHistory.fromMap(Map<String, dynamic> map) {
    return BatchEditHistory(
      id: map['id'] as int?,
      ruleId: map['rule_id'] as int?,
      recordsAffected: map['records_affected'] as int? ?? 0,
      editType: map['edit_type'] as String,
      performedAt: DateTime.parse(map['performed_at'] as String),
    );
  }
}

/// 批量编辑条件
class EditCondition {
  final String field; // time, tag, thing_name, duration, date
  final String operator; // equals, contains, greater_than, less_than, between
  final dynamic value;
  final dynamic value2; // for between operator

  EditCondition({
    required this.field,
    required this.operator,
    required this.value,
    this.value2,
  }) : assert(field.isNotEmpty);

  Map<String, dynamic> toJson() => {
    'field': field,
    'operator': operator,
    'value': value,
    'value2': value2,
  };

  factory EditCondition.fromJson(Map<String, dynamic> json) => EditCondition(
    field: json['field'] as String,
    operator: json['operator'] as String,
    value: json['value'],
    value2: json['value2'],
  );
}

/// 批量编辑动作
class EditAction {
  final String type; // set_thing_name, add_tag, remove_tag, set_reminder, adjust_time
  final dynamic value;

  EditAction({
    required this.type,
    required this.value,
  });

  Map<String, dynamic> toJson() => {
    'type': type,
    'value': value,
  };

  factory EditAction.fromJson(Map<String, dynamic> json) => EditAction(
    type: json['type'] as String,
    value: json['value'],
  );
}