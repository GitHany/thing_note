class HabitChain {
  final int? id;
  final String chainName;
  final String habitIds;
  final String? triggerOrder;
  final int completionCount;
  final DateTime createdAt;

  HabitChain({
    this.id,
    required this.chainName,
    required this.habitIds,
    this.triggerOrder,
    this.completionCount = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'chain_name': chainName,
      'habit_ids': habitIds,
      'trigger_order': triggerOrder,
      'completion_count': completionCount,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory HabitChain.fromMap(Map<String, dynamic> map) {
    return HabitChain(
      id: map['id'] as int?,
      chainName: map['chain_name'] as String,
      habitIds: map['habit_ids'] as String,
      triggerOrder: map['trigger_order'] as String?,
      completionCount: map['completion_count'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  List<int> get habitIdList => habitIds.split(',').where((s) => s.isNotEmpty).map(int.parse).toList();

  HabitChain copyWith({
    int? id,
    String? chainName,
    String? habitIds,
    String? triggerOrder,
    int? completionCount,
    DateTime? createdAt,
  }) {
    return HabitChain(
      id: id ?? this.id,
      chainName: chainName ?? this.chainName,
      habitIds: habitIds ?? this.habitIds,
      triggerOrder: triggerOrder ?? this.triggerOrder,
      completionCount: completionCount ?? this.completionCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}