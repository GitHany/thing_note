class WidgetRecordData {
  final String title;
  final String subtitle;
  final DateTime? lastRecordTime;
  final int todayCount;
  final int weekCount;
  final int streakDays;

  const WidgetRecordData({
    required this.title,
    required this.subtitle,
    this.lastRecordTime,
    this.todayCount = 0,
    this.weekCount = 0,
    this.streakDays = 0,
  });
}

class WidgetConfig {
  final bool showTodayCount;
  final bool showStreak;
  final bool showLastRecord;
  final String customTitle;

  const WidgetConfig({
    this.showTodayCount = true,
    this.showStreak = true,
    this.showLastRecord = false,
    this.customTitle = '',
  });

  WidgetConfig copyWith({
    bool? showTodayCount,
    bool? showStreak,
    bool? showLastRecord,
    String? customTitle,
  }) {
    return WidgetConfig(
      showTodayCount: showTodayCount ?? this.showTodayCount,
      showStreak: showStreak ?? this.showStreak,
      showLastRecord: showLastRecord ?? this.showLastRecord,
      customTitle: customTitle ?? this.customTitle,
    );
  }
}