class ReminderOptimization {
  final int? id;
  final int? reminderId;
  final String? optimalTime;
  final String? optimalFrequency;
  final double successRate;
  final int basedOnSamples;
  final String optimizedAt;

  ReminderOptimization({
    this.id,
    this.reminderId,
    this.optimalTime,
    this.optimalFrequency,
    this.successRate = 0,
    this.basedOnSamples = 0,
    required this.optimizedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'reminder_id': reminderId,
      'optimal_time': optimalTime,
      'optimal_frequency': optimalFrequency,
      'success_rate': successRate,
      'based_on_samples': basedOnSamples,
      'optimized_at': optimizedAt,
    };
  }

  factory ReminderOptimization.fromMap(Map<String, dynamic> map) {
    return ReminderOptimization(
      id: map['id'],
      reminderId: map['reminder_id'],
      optimalTime: map['optimal_time'],
      optimalFrequency: map['optimal_frequency'],
      successRate: (map['success_rate'] ?? 0).toDouble(),
      basedOnSamples: map['based_on_samples'] ?? 0,
      optimizedAt: map['optimized_at'],
    );
  }

  ReminderOptimization copyWith({
    int? id,
    int? reminderId,
    String? optimalTime,
    String? optimalFrequency,
    double? successRate,
    int? basedOnSamples,
    String? optimizedAt,
  }) {
    return ReminderOptimization(
      id: id ?? this.id,
      reminderId: reminderId ?? this.reminderId,
      optimalTime: optimalTime ?? this.optimalTime,
      optimalFrequency: optimalFrequency ?? this.optimalFrequency,
      successRate: successRate ?? this.successRate,
      basedOnSamples: basedOnSamples ?? this.basedOnSamples,
      optimizedAt: optimizedAt ?? this.optimizedAt,
    );
  }
}