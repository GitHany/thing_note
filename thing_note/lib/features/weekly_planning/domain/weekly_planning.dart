/// Weekly Planning 数据模型
class WeeklyPlan {
  final int? id;
  final int year;
  final int weekNumber;
  final List<PlanDay> days;
  final DateTime createdAt;

  const WeeklyPlan({
    this.id,
    required this.year,
    required this.weekNumber,
    this.days = const [],
    required this.createdAt,
  });
}

class PlanDay {
  final int dayOfWeek; // 1-7
  final String? theme; // 主题
  final List<PlanItem> items;

  const PlanDay({
    required this.dayOfWeek,
    this.theme,
    this.items = const [],
  });
}

class PlanItem {
  final String id;
  final String content;
  final bool isCompleted;
  final int? priority;

  const PlanItem({
    required this.id,
    required this.content,
    this.isCompleted = false,
    this.priority,
  });
}