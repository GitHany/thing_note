/// 快速命令模型
class QuickCommand {
  final int? id;
  final String name;
  final String? alias;
  final String commandType; // navigate, action, shortcut
  final String actionConfig; // JSON配置
  final String? category;
  final int useCount;
  final bool isEnabled;
  final DateTime createdAt;

  QuickCommand({
    this.id,
    required this.name,
    this.alias,
    required this.commandType,
    required this.actionConfig,
    this.category,
    this.useCount = 0,
    this.isEnabled = true,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'alias': alias,
      'command_type': commandType,
      'action_config': actionConfig,
      'category': category,
      'use_count': useCount,
      'is_enabled': isEnabled ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory QuickCommand.fromMap(Map<String, dynamic> map) {
    return QuickCommand(
      id: map['id'] as int?,
      name: map['name'] as String,
      alias: map['alias'] as String?,
      commandType: map['command_type'] as String,
      actionConfig: map['action_config'] as String,
      category: map['category'] as String?,
      useCount: map['use_count'] as int? ?? 0,
      isEnabled: (map['is_enabled'] as int?) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  QuickCommand copyWith({
    int? id,
    String? name,
    String? alias,
    String? commandType,
    String? actionConfig,
    String? category,
    int? useCount,
    bool? isEnabled,
    DateTime? createdAt,
  }) {
    return QuickCommand(
      id: id ?? this.id,
      name: name ?? this.name,
      alias: alias ?? this.alias,
      commandType: commandType ?? this.commandType,
      actionConfig: actionConfig ?? this.actionConfig,
      category: category ?? this.category,
      useCount: useCount ?? this.useCount,
      isEnabled: isEnabled ?? this.isEnabled,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}