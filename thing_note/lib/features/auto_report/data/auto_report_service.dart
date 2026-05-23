import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/auto_report/domain/report_config.dart';

class AutoReportService {
  /// Generate a report based on records within date range
  Future<GeneratedReport> generateReport({
    required ReportConfig config,
    required List<Map<String, dynamic>> records,
    required List<Map<String, dynamic>> thingNames,
    required List<Map<String, dynamic>> tags,
  }) async {
    // Filter records by date range
    final filteredRecords = records.where((record) {
      final occurredAt = DateTime.parse(record['occurred_at'] as String);
      return occurredAt.isAfter(config.startDate.subtract(const Duration(days: 1))) &&
          occurredAt.isBefore(config.endDate.add(const Duration(days: 1)));
    }).toList();

    // Calculate statistics
    final stats = _calculateStatistics(filteredRecords, config);

    // Generate content
    final content = _generateContent(filteredRecords, config, stats);

    // Generate insights
    final insights = _generateInsights(filteredRecords, config, stats);

    // Get top records and tags
    final topRecords = _getTopRecords(filteredRecords, thingNames);
    final topTags = _getTopTags(filteredRecords, tags);

    return GeneratedReport(
      title: _getReportTitle(config),
      content: content,
      generatedAt: DateTime.now(),
      statistics: stats,
      insights: insights,
      topRecords: topRecords,
      topTags: topTags,
    );
  }

  String _getReportTitle(ReportConfig config) {
    final startStr = '${config.startDate.month}/${config.startDate.day}';
    final endStr = '${config.endDate.month}/${config.endDate.day}';

    switch (config.type) {
      case ReportType.daily:
        return 'Daily Report - ${config.startDate.month}/${config.startDate.day}';
      case ReportType.weekly:
        return 'Weekly Report ($startStr - $endStr)';
      case ReportType.monthly:
        return 'Monthly Report - ${config.startDate.year}/${config.startDate.month}';
      case ReportType.custom:
        return 'Report ($startStr - $endStr)';
    }
  }

  Map<String, dynamic> _calculateStatistics(
    List<Map<String, dynamic>> records,
    ReportConfig config,
  ) {
    final totalRecords = records.length;
    int totalDuration = 0;

    for (final record in records) {
      totalDuration += (record['duration_sec'] as int?) ?? 0;
    }

    final activeDays = records
        .map((r) => (r['occurred_at'] as String).substring(0, 10))
        .toSet()
        .length;

    final avgDuration = totalRecords > 0 ? totalDuration ~/ totalRecords : 0;

    return {
      'Total Records': totalRecords,
      'Total Duration': '${(totalDuration / 3600).toStringAsFixed(1)} hours',
      'Active Days': activeDays,
      'Average Duration': '${(avgDuration / 60).toStringAsFixed(0)} min',
    };
  }

  String _generateContent(
    List<Map<String, dynamic>> records,
    ReportConfig config,
    Map<String, dynamic> stats,
  ) {
    final buffer = StringBuffer();

    buffer.writeln('You recorded ${stats['Total Records']} events during this period.');

    if ((stats['Active Days'] as int) > 0) {
      buffer.writeln(
          'You were active on ${stats['Active Days']} different days.');
    }

    final totalDuration = (stats['Total Duration'] as String).replaceAll(' hours', '');
    if (double.tryParse(totalDuration) != null && double.parse(totalDuration) > 0) {
      buffer.writeln('Total recording time: ${stats['Total Duration']}.');
    }

    buffer.writeln();
    buffer.writeln('Your average record duration was ${stats['Average Duration']}.');

    return buffer.toString();
  }

  List<String> _generateInsights(
    List<Map<String, dynamic>> records,
    ReportConfig config,
    Map<String, dynamic> stats,
  ) {
    final insights = <String>[];

    if ((stats['Total Records'] as int) >= 10) {
      insights.add('You\'re maintaining consistent recording habits!');
    }

    if ((stats['Active Days'] as int) >= 5) {
      insights.add('Great job staying active throughout this period!');
    }

    return insights;
  }

  List<Map<String, dynamic>> _getTopRecords(
    List<Map<String, dynamic>> records,
    List<Map<String, dynamic>> thingNames,
  ) {
    final counts = <int, int>{};
    for (final record in records) {
      final thingNameId = record['thing_name_id'] as int?;
      if (thingNameId != null) {
        counts[thingNameId] = (counts[thingNameId] ?? 0) + 1;
      }
    }

    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(5).map((entry) {
      final thingName = thingNames.firstWhere(
        (tn) => tn['id'] == entry.key,
        orElse: () => {'name': 'Unknown'},
      );
      return {
        'name': thingName['name'],
        'count': entry.value,
      };
    }).toList();
  }

  List<Map<String, dynamic>> _getTopTags(
    List<Map<String, dynamic>> records,
    List<Map<String, dynamic>> tags,
  ) {
    // Simplified - in production would query record_tags
    return [];
  }
}

final autoReportServiceProvider = Provider<AutoReportService>((ref) {
  return AutoReportService();
});