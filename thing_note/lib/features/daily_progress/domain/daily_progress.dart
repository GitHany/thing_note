/// Daily Progress 数据模型
class DailyProgressItem {
  final String id;
  final String title;
  final bool isCompleted;
  final int? targetValue;
  final int? currentValue;
  final String? unit;
  final String category;

  const DailyProgressItem({
    required this.id,
    required this.title,
    this.isCompleted = false,
    this.targetValue,
    this.currentValue,
    this.unit,
    required this.category,
  });

  double get progress {
    if (targetValue == null || currentValue == null) return isCompleted ? 1.0 : 0.0;
    return (currentValue! / targetValue!).clamp(0.0, 1.0);
  }
}

class DailyProgress {
  final DateTime date;
  final List<DailyProgressItem> items;
  final int completedCount;
  final int totalCount;

  const DailyProgress({
    required this.date,
    this.items = const [],
    this.completedCount = 0,
    this.totalCount = 0,
  });

  double get completionRate => totalCount > 0 ? completedCount / totalCount : 0;
}