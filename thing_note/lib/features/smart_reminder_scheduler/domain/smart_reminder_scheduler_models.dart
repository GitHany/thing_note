/// 智能提醒调度器 - Smart Reminder Scheduler
/// 智能安排和调度提醒
library;

/// 提醒调度
class ReminderSchedule {
  final int id;
  final String title;
  final DateTime scheduledTime;
  final ReminderScheduleType type;
  final bool isEnabled;
  final int? linkedRecordId;
  final ReminderPriority priority;

  ReminderSchedule({
    required this.id,
    required this.title,
    required this.scheduledTime,
    required this.type,
    this.isEnabled = true,
    this.linkedRecordId,
    this.priority = ReminderPriority.normal,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'scheduled_time': scheduledTime.toIso8601String(),
      'type': type.name,
      'is_enabled': isEnabled ? 1 : 0,
      'linked_record_id': linkedRecordId,
      'priority': priority.name,
    };
  }

  factory ReminderSchedule.fromMap(Map<String, dynamic> map) {
    return ReminderSchedule(
      id: map['id'] as int,
      title: map['title'] as String,
      scheduledTime: DateTime.parse(map['scheduled_time'] as String),
      type: ReminderScheduleType.values.firstWhere(
        (t) => t.name == (map['type'] as String? ?? 'oneTime'),
        orElse: () => ReminderScheduleType.oneTime,
      ),
      isEnabled: (map['is_enabled'] as int?) == 1,
      linkedRecordId: map['linked_record_id'] as int?,
      priority: ReminderPriority.values.firstWhere(
        (p) => p.name == (map['priority'] as String? ?? 'normal'),
        orElse: () => ReminderPriority.normal,
      ),
    );
  }
}

/// 调度类型
enum ReminderScheduleType {
  oneTime, // 一次性
  daily, // 每日
  weekly, // 每周
  monthly, // 每月
  custom, // 自定义
}

/// 提醒优先级
enum ReminderPriority {
  low,
  normal,
  high,
  urgent,
}

/// 智能调度配置
class SmartSchedulerConfig {
  final bool enabled;
  final int maxRemindersPerDay;
  final bool avoidConflicts;
  final bool groupSimilarReminders;

  SmartSchedulerConfig({
    this.enabled = true,
    this.maxRemindersPerDay = 10,
    this.avoidConflicts = true,
    this.groupSimilarReminders = true,
  });
}

/// 调度冲突
class ScheduleConflict {
  final DateTime time;
  final List<ReminderSchedule> conflictingReminders;
  final String resolution;

  ScheduleConflict({
    required this.time,
    required this.conflictingReminders,
    required this.resolution,
  });
}