class HabitChain {
  final int id;
  final String chainName;
  final List<int> habitIds;
  final String chainType;
  final int completionCount;
  final double successRate;
  final DateTime createdAt;

  HabitChain({
    required this.id,
    required this.chainName,
    required this.habitIds,
    this.chainType = 'time',
    this.completionCount = 0,
    this.successRate = 0,
    required this.createdAt,
  });

  factory HabitChain.fromMap(Map<String, dynamic> map) {
    final habitIdsStr = map['habit_ids'] as String? ?? '';
    final habitIds = habitIdsStr.isEmpty
        ? <int>[]
        : habitIdsStr.split(',').map((e) => int.tryParse(e) ?? 0).toList();
    
    return HabitChain(
      id: map['id'] as int,
      chainName: map['chain_name'] as String,
      habitIds: habitIds,
      chainType: map['chain_type'] as String? ?? 'time',
      completionCount: map['completion_count'] as int? ?? 0,
      successRate: (map['success_rate'] as num?)?.toDouble() ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chain_name': chainName,
      'habit_ids': habitIds.join(','),
      'chain_type': chainType,
      'completion_count': completionCount,
      'success_rate': successRate,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class ChainRecommendation {
  final int habitId;
  final int suggestedNextHabitId;
  final String reason;
  final double confidence;
  final String chainType;

  ChainRecommendation({
    required this.habitId,
    required this.suggestedNextHabitId,
    required this.reason,
    required this.confidence,
    required this.chainType,
  });
}