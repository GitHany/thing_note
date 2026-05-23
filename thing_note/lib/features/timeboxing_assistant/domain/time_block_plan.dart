class TimeBlockPlan {
  final int? id;
  final String planDate;
  final String suggestedBlocks;
  final String? actualBlocks;
  final double efficiencyScore;
  final String? adjustmentReason;
  final int isAccepted;
  final DateTime createdAt;

  TimeBlockPlan({
    this.id,
    required this.planDate,
    this.suggestedBlocks = '',
    this.actualBlocks,
    this.efficiencyScore = 0,
    this.adjustmentReason,
    this.isAccepted = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'plan_date': planDate,
      'suggested_blocks': suggestedBlocks,
      'actual_blocks': actualBlocks,
      'efficiency_score': efficiencyScore,
      'adjustment_reason': adjustmentReason,
      'is_accepted': isAccepted,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory TimeBlockPlan.fromMap(Map<String, dynamic> map) {
    return TimeBlockPlan(
      id: map['id'] as int?,
      planDate: map['plan_date'] as String,
      suggestedBlocks: map['suggested_blocks'] as String? ?? '',
      actualBlocks: map['actual_blocks'] as String?,
      efficiencyScore: (map['efficiency_score'] as num?)?.toDouble() ?? 0,
      adjustmentReason: map['adjustment_reason'] as String?,
      isAccepted: map['is_accepted'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  List<TimeBlock> get suggestedBlockList => _parseBlocks(suggestedBlocks);
  List<TimeBlock> get actualBlockList => _parseBlocks(actualBlocks ?? '');

  List<TimeBlock> _parseBlocks(String blocks) {
    if (blocks.isEmpty) return [];
    return blocks.split(';').where((s) => s.isNotEmpty).map((s) {
      final parts = s.split(',');
      return TimeBlock(
        startHour: int.parse(parts[0]),
        endHour: int.parse(parts[1]),
        activity: parts.length > 2 ? parts[2] : '',
        type: parts.length > 3 ? parts[3] : 'work',
      );
    }).toList();
  }

  TimeBlockPlan copyWith({
    int? id,
    String? planDate,
    String? suggestedBlocks,
    String? actualBlocks,
    double? efficiencyScore,
    String? adjustmentReason,
    int? isAccepted,
    DateTime? createdAt,
  }) {
    return TimeBlockPlan(
      id: id ?? this.id,
      planDate: planDate ?? this.planDate,
      suggestedBlocks: suggestedBlocks ?? this.suggestedBlocks,
      actualBlocks: actualBlocks ?? this.actualBlocks,
      efficiencyScore: efficiencyScore ?? this.efficiencyScore,
      adjustmentReason: adjustmentReason ?? this.adjustmentReason,
      isAccepted: isAccepted ?? this.isAccepted,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class TimeBlock {
  final int startHour;
  final int endHour;
  final String activity;
  final String type;

  TimeBlock({
    required this.startHour,
    required this.endHour,
    this.activity = '',
    this.type = 'work',
  });

  int get duration => endHour - startHour;

  String toBlockString() => '$startHour,$endHour,$activity,$type';

  static String blocksToString(List<TimeBlock> blocks) =>
      blocks.map((b) => b.toBlockString()).join(';');

  static const Map<String, String> typeLabels = {
    'work': '工作',
    'break': '休息',
    'personal': '个人',
    'exercise': '运动',
    'learning': '学习',
    'social': '社交',
  };

  static const Map<String, int> typeColors = {
    'work': 0xFF2196F3,
    'break': 0xFF4CAF50,
    'personal': 0xFF9C27B0,
    'exercise': 0xFFFF5722,
    'learning': 0xFF00BCD4,
    'social': 0xFFE91E63,
  };
}