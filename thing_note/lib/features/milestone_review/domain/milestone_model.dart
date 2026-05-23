class MilestoneEvent {
  final int? id;
  final String milestoneType;
  final int milestoneValue;
  final int? recordId;
  final String achievedAt;
  final String? certificatePath;
  final bool shared;

  MilestoneEvent({
    this.id,
    required this.milestoneType,
    required this.milestoneValue,
    this.recordId,
    required this.achievedAt,
    this.certificatePath,
    this.shared = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'milestone_type': milestoneType,
      'milestone_value': milestoneValue,
      'record_id': recordId,
      'achieved_at': achievedAt,
      'certificate_path': certificatePath,
      'shared': shared ? 1 : 0,
    };
  }

  factory MilestoneEvent.fromMap(Map<String, dynamic> map) {
    return MilestoneEvent(
      id: map['id'],
      milestoneType: map['milestone_type'],
      milestoneValue: map['milestone_value'],
      recordId: map['record_id'],
      achievedAt: map['achieved_at'],
      certificatePath: map['certificate_path'],
      shared: map['shared'] == 1,
    );
  }

  MilestoneEvent copyWith({
    int? id,
    String? milestoneType,
    int? milestoneValue,
    int? recordId,
    String? achievedAt,
    String? certificatePath,
    bool? shared,
  }) {
    return MilestoneEvent(
      id: id ?? this.id,
      milestoneType: milestoneType ?? this.milestoneType,
      milestoneValue: milestoneValue ?? this.milestoneValue,
      recordId: recordId ?? this.recordId,
      achievedAt: achievedAt ?? this.achievedAt,
      certificatePath: certificatePath ?? this.certificatePath,
      shared: shared ?? this.shared,
    );
  }
}

enum MilestoneType {
  recordCount('记录数量', [10, 50, 100, 500, 1000, 5000]),
  streakDays('连续天数', [7, 14, 30, 100, 365]),
  firstTry('首次尝试', [1]),
  yearReview('年度回顾', [1]);

  final String label;
  final List<int> thresholds;
  const MilestoneType(this.label, this.thresholds);
}