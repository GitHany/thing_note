/// 项目管理数据模型
class Project {
  final int? id;
  final String name;
  final String? description;
  final String color;
  final ProjectStatus status;
  final DateTime? deadline;
  final int progress;
  final List<int> linkedRecordIds;
  final List<int> goalIds;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Project({
    this.id,
    required this.name,
    this.description,
    this.color = '#2196F3',
    this.status = ProjectStatus.active,
    this.deadline,
    this.progress = 0,
    this.linkedRecordIds = const [],
    this.goalIds = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  Project copyWith({
    int? id,
    String? name,
    String? description,
    String? color,
    ProjectStatus? status,
    DateTime? deadline,
    int? progress,
    List<int>? linkedRecordIds,
    List<int>? goalIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      color: color ?? this.color,
      status: status ?? this.status,
      deadline: deadline ?? this.deadline,
      progress: progress ?? this.progress,
      linkedRecordIds: linkedRecordIds ?? this.linkedRecordIds,
      goalIds: goalIds ?? this.goalIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isOverdue =>
      deadline != null && deadline!.isBefore(DateTime.now()) && status != ProjectStatus.completed;

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'description': description,
      'color': color,
      'status': status.name,
      'deadline': deadline?.toIso8601String(),
      'progress': progress,
      'linked_record_ids': linkedRecordIds.join(','),
      'goal_ids': goalIds.join(','),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Project.fromMap(Map<String, dynamic> map) {
    return Project(
      id: map['id'] as int?,
      name: map['name'] as String,
      description: map['description'] as String?,
      color: map['color'] as String? ?? '#2196F3',
      status: ProjectStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => ProjectStatus.active,
      ),
      deadline: map['deadline'] != null ? DateTime.parse(map['deadline'] as String) : null,
      progress: map['progress'] as int? ?? 0,
      linkedRecordIds: (map['linked_record_ids'] as String?)
              ?.split(',')
              .where((s) => s.isNotEmpty)
              .map((s) => int.parse(s))
              .toList() ??
          [],
      goalIds: (map['goal_ids'] as String?)
              ?.split(',')
              .where((s) => s.isNotEmpty)
              .map((s) => int.parse(s))
              .toList() ??
          [],
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}

enum ProjectStatus { active, paused, completed, archived }

extension ProjectStatusExtension on ProjectStatus {
  String get displayName {
    switch (this) {
      case ProjectStatus.active:
        return '进行中';
      case ProjectStatus.paused:
        return '已暂停';
      case ProjectStatus.completed:
        return '已完成';
      case ProjectStatus.archived:
        return '已归档';
    }
  }
}

/// 预设项目颜色
class ProjectColors {
  static const List<String> presets = [
    '#2196F3', // 蓝色
    '#4CAF50', // 绿色
    '#FF9800', // 橙色
    '#F44336', // 红色
    '#9C27B0', // 紫色
    '#00BCD4', // 青色
    '#E91E63', // 粉色
    '#795548', // 棕色
    '#607D8B', // 蓝灰
    '#FF5722', // 深橙
  ];
}