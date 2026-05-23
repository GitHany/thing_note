class ChartDataPoint {
  final DateTime date;
  final double value;
  final String? label;

  const ChartDataPoint({
    required this.date,
    required this.value,
    this.label,
  });
}

class RecordStatistics {
  final int totalRecords;
  final int totalDurationSec;
  final double averageDurationSec;
  final int uniqueDays;
  final Map<int?, int> recordsByThingName;
  final int? mostActiveHour;
  final int? mostActiveDayOfWeek;

  const RecordStatistics({
    required this.totalRecords,
    required this.totalDurationSec,
    required this.averageDurationSec,
    required this.uniqueDays,
    required this.recordsByThingName,
    this.mostActiveHour,
    this.mostActiveDayOfWeek,
  });

  String get formattedTotalDuration {
    final hours = totalDurationSec ~/ 3600;
    final minutes = (totalDurationSec % 3600) ~/ 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }
}

class WeeklyTrendData {
  final List<ChartDataPoint> dailyData;
  final int weekNumber;
  final int totalRecords;
  final int totalDurationSec;

  const WeeklyTrendData({
    required this.dailyData,
    required this.weekNumber,
    required this.totalRecords,
    required this.totalDurationSec,
  });
}