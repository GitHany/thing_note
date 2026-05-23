/// Interrupt Tracker 数据模型
class Interrupt {
  final int? id;
  final String title;
  final InterruptType type;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int durationSeconds;
  final String? source;
  final bool isProductive;
  final String? note;
  final int? linkedTaskId;

  const Interrupt({
    this.id,
    required this.title,
    required this.type,
    required this.startedAt,
    this.endedAt,
    this.durationSeconds = 0,
    this.source,
    this.isProductive = false,
    this.note,
    this.linkedTaskId,
  });

  Interrupt copyWith({
    int? id,
    String? title,
    InterruptType? type,
    DateTime? startedAt,
    DateTime? endedAt,
    int? durationSeconds,
    String? source,
    bool? isProductive,
    String? note,
    int? linkedTaskId,
  }) {
    return Interrupt(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      source: source ?? this.source,
      isProductive: isProductive ?? this.isProductive,
      note: note ?? this.note,
      linkedTaskId: linkedTaskId ?? this.linkedTaskId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'type': type.name,
      'started_at': startedAt.toIso8601String(),
      'ended_at': endedAt?.toIso8601String(),
      'duration_seconds': durationSeconds,
      'source': source,
      'is_productive': isProductive ? 1 : 0,
      'note': note,
      'linked_task_id': linkedTaskId,
    };
  }

  factory Interrupt.fromMap(Map<String, dynamic> map) {
    return Interrupt(
      id: map['id'] as int?,
      title: map['title'] as String,
      type: InterruptType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => InterruptType.other,
      ),
      startedAt: DateTime.parse(map['started_at'] as String),
      endedAt: map['ended_at'] != null ? DateTime.parse(map['ended_at'] as String) : null,
      durationSeconds: map['duration_seconds'] as int? ?? 0,
      source: map['source'] as String?,
      isProductive: (map['is_productive'] as int?) == 1,
      note: map['note'] as String?,
      linkedTaskId: map['linked_task_id'] as int?,
    );
  }
}

enum InterruptType {
  notification,
  phone,
  email,
  meeting,
  colleague,
  personal,
  other,
}

extension InterruptTypeExtension on InterruptType {
  String get displayName {
    switch (this) {
      case InterruptType.notification:
        return '通知';
      case InterruptType.phone:
        return '电话';
      case InterruptType.email:
        return '邮件';
      case InterruptType.meeting:
        return '会议';
      case InterruptType.colleague:
        return '同事';
      case InterruptType.personal:
        return '个人';
      case InterruptType.other:
        return '其他';
    }
  }
}

/// 中断统计
class InterruptStats {
  final int todayTotal;
  final int todayProductive;
  final int todayMinutes;
  final double productivityRate;
  final Map<InterruptType, int> byType;

  const InterruptStats({
    this.todayTotal = 0,
    this.todayProductive = 0,
    this.todayMinutes = 0,
    this.productivityRate = 0,
    this.byType = const {},
  });
}