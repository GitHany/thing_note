class DailyBriefing {
  final int habitCount;
  final int completedHabits;
  final String weather;
  final int temperature;
  final List<String> todoItems;
  final int energyLevel;
  final DateTime date;

  DailyBriefing({
    required this.habitCount,
    required this.completedHabits,
    required this.weather,
    required this.temperature,
    required this.todoItems,
    required this.energyLevel,
    required this.date,
  });

  double get completionRate => habitCount > 0 ? completedHabits / habitCount : 0;
}

class WidgetConfig {
  final String widgetType;
  final int sizeColumns;
  final int sizeRows;
  final List<String> dataFields;
  final bool showBorder;

  WidgetConfig({
    required this.widgetType,
    this.sizeColumns = 4,
    this.sizeRows = 2,
    this.dataFields = const [],
    this.showBorder = true,
  });
}