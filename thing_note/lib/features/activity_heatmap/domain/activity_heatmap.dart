/// Activity heatmap data point
class ActivityDataPoint {
  final int year;
  final int month;
  final int day;
  final int hour;
  final int recordCount;
  final int totalDurationMinutes;

  ActivityDataPoint({
    required this.year,
    required this.month,
    required this.day,
    required this.hour,
    this.recordCount = 0,
    this.totalDurationMinutes = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'year': year,
      'month': month,
      'day': day,
      'hour': hour,
      'record_count': recordCount,
      'total_duration_minutes': totalDurationMinutes,
      'created_at': DateTime.now().toIso8601String(),
    };
  }

  factory ActivityDataPoint.fromMap(Map<String, dynamic> map) {
    return ActivityDataPoint(
      year: map['year'] as int,
      month: map['month'] as int,
      day: map['day'] as int,
      hour: map['hour'] as int,
      recordCount: map['record_count'] as int? ?? 0,
      totalDurationMinutes: map['total_duration_minutes'] as int? ?? 0,
    );
  }

  double get intensity {
    // Normalize intensity to 0-1 range
    if (recordCount == 0) return 0;
    return (recordCount / 20).clamp(0.0, 1.0);
  }
}

/// Monthly heatmap grid
class MonthlyHeatmap {
  final int year;
  final int month;
  final Map<int, Map<int, ActivityDataPoint>> grid; // day -> hour -> data

  MonthlyHeatmap({
    required this.year,
    required this.month,
    required this.grid,
  });

  ActivityDataPoint? getDataPoint(int day, int hour) {
    return grid[day]?[hour];
  }

  int get totalRecords {
    int total = 0;
    for (final dayData in grid.values) {
      for (final point in dayData.values) {
        total += point.recordCount;
      }
    }
    return total;
  }
}

/// Yearly heatmap summary
class YearlyHeatmap {
  final int year;
  final Map<int, MonthlyHeatmap> months; // month -> data

  YearlyHeatmap({
    required this.year,
    required this.months,
  });
}