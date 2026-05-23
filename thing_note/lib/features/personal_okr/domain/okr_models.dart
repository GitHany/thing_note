// Personal OKR (Objectives & Key Results) feature
// Version: 1.0
// Description: 个人目标与关键结果管理系统，支持OKR目标分解、进度追踪和评估

class OkrObjective {
  final int? id;
  final String title;
  final String? description;
  final int quarter; // 1-4
  final int year;
  final double progress; // 0-100
  final String status; // active, completed, cancelled
  final String? createdAt;
  final String? updatedAt;

  OkrObjective({
    this.id,
    required this.title,
    this.description,
    required this.quarter,
    required this.year,
    this.progress = 0.0,
    this.status = 'active',
    this.createdAt,
    this.updatedAt,
  });

  factory OkrObjective.fromMap(Map<String, dynamic> map) {
    return OkrObjective(
      id: map['id'] as int?,
      title: map['title'] as String,
      description: map['description'] as String?,
      quarter: map['quarter'] as int? ?? 1,
      year: map['year'] as int? ?? DateTime.now().year,
      progress: (map['progress'] as num?)?.toDouble() ?? 0.0,
      status: map['status'] as String? ?? 'active',
      createdAt: map['created_at'] as String?,
      updatedAt: map['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'quarter': quarter,
      'year': year,
      'progress': progress,
      'status': status,
      'created_at': createdAt ?? DateTime.now().toIso8601String(),
      'updated_at': updatedAt ?? DateTime.now().toIso8601String(),
    };
  }

  OkrObjective copyWith({
    int? id,
    String? title,
    String? description,
    int? quarter,
    int? year,
    double? progress,
    String? status,
    String? createdAt,
    String? updatedAt,
  }) {
    return OkrObjective(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      quarter: quarter ?? this.quarter,
      year: year ?? this.year,
      progress: progress ?? this.progress,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class OkrKeyResult {
  final int? id;
  final int objectiveId;
  final String title;
  final String metric; // e.g., "完成10篇文章", "达到1000用户"
  final double targetValue;
  final double currentValue;
  final String unit;
  final int sortOrder;
  final String? createdAt;

  OkrKeyResult({
    this.id,
    required this.objectiveId,
    required this.title,
    this.metric = '',
    this.targetValue = 100,
    this.currentValue = 0,
    this.unit = '',
    this.sortOrder = 0,
    this.createdAt,
  });

  double get progressPercent => targetValue > 0 ? (currentValue / targetValue * 100).clamp(0, 100) : 0;

  factory OkrKeyResult.fromMap(Map<String, dynamic> map) {
    return OkrKeyResult(
      id: map['id'] as int?,
      objectiveId: map['objective_id'] as int,
      title: map['title'] as String,
      metric: map['metric'] as String? ?? '',
      targetValue: (map['target_value'] as num?)?.toDouble() ?? 100,
      currentValue: (map['current_value'] as num?)?.toDouble() ?? 0,
      unit: map['unit'] as String? ?? '',
      sortOrder: map['sort_order'] as int? ?? 0,
      createdAt: map['created_at'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'objective_id': objectiveId,
      'title': title,
      'metric': metric,
      'target_value': targetValue,
      'current_value': currentValue,
      'unit': unit,
      'sort_order': sortOrder,
      'created_at': createdAt ?? DateTime.now().toIso8601String(),
    };
  }

  OkrKeyResult copyWith({
    int? id,
    int? objectiveId,
    String? title,
    String? metric,
    double? targetValue,
    double? currentValue,
    String? unit,
    int? sortOrder,
    String? createdAt,
  }) {
    return OkrKeyResult(
      id: id ?? this.id,
      objectiveId: objectiveId ?? this.objectiveId,
      title: title ?? this.title,
      metric: metric ?? this.metric,
      targetValue: targetValue ?? this.targetValue,
      currentValue: currentValue ?? this.currentValue,
      unit: unit ?? this.unit,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class OkrWithKeyResults {
  final OkrObjective objective;
  final List<OkrKeyResult> keyResults;

  OkrWithKeyResults({
    required this.objective,
    required this.keyResults,
  });

  double get overallProgress {
    if (keyResults.isEmpty) return 0;
    double total = 0;
    for (final kr in keyResults) {
      total += kr.progressPercent;
    }
    return total / keyResults.length;
  }
}