/// Auto report configuration
class ReportConfig {
  final ReportType type;
  final DateTime startDate;
  final DateTime endDate;
  final bool includeStats;
  final bool includeCharts;
  final bool includeGoals;
  final bool includeHabits;

  ReportConfig({
    required this.type,
    required this.startDate,
    required this.endDate,
    this.includeStats = true,
    this.includeCharts = true,
    this.includeGoals = true,
    this.includeHabits = true,
  });
}

enum ReportType {
  daily,
  weekly,
  monthly,
  custom,
}

/// Generated report data
class GeneratedReport {
  final String title;
  final String content;
  final DateTime generatedAt;
  final Map<String, dynamic> statistics;
  final List<String> insights;
  final List<Map<String, dynamic>> topRecords;
  final List<Map<String, dynamic>> topTags;

  GeneratedReport({
    required this.title,
    required this.content,
    required this.generatedAt,
    required this.statistics,
    required this.insights,
    required this.topRecords,
    required this.topTags,
  });

  String toFormattedString() {
    final buffer = StringBuffer();
    buffer.writeln(title);
    buffer.writeln('=' * title.length);
    buffer.writeln();
    buffer.writeln(content);
    buffer.writeln();
    buffer.writeln('Key Statistics:');
    for (final entry in statistics.entries) {
      buffer.writeln('• ${entry.key}: ${entry.value}');
    }
    if (insights.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('Insights:');
      for (final insight in insights) {
        buffer.writeln('• $insight');
      }
    }
    return buffer.toString();
  }
}