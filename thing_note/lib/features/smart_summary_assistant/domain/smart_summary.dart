class SmartSummary {
  final int? id;
  final String summaryType;
  final String periodStart;
  final String periodEnd;
  final String? title;
  final String content;
  final String? highlights;
  final String? insights;
  final int recordCount;
  final String? topThings;
  final String? topTags;
  final double? moodAverage;
  final double? energyAverage;
  final int isRead;
  final String createdAt;

  SmartSummary({
    this.id,
    required this.summaryType,
    required this.periodStart,
    required this.periodEnd,
    this.title,
    required this.content,
    this.highlights,
    this.insights,
    this.recordCount = 0,
    this.topThings,
    this.topTags,
    this.moodAverage,
    this.energyAverage,
    this.isRead = 0,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'summary_type': summaryType,
      'period_start': periodStart,
      'period_end': periodEnd,
      'title': title,
      'content': content,
      'highlights': highlights,
      'insights': insights,
      'record_count': recordCount,
      'top_things': topThings,
      'top_tags': topTags,
      'mood_average': moodAverage,
      'energy_average': energyAverage,
      'is_read': isRead,
      'created_at': createdAt,
    };
  }

  factory SmartSummary.fromMap(Map<String, dynamic> map) {
    return SmartSummary(
      id: map['id'] as int?,
      summaryType: map['summary_type'] as String,
      periodStart: map['period_start'] as String,
      periodEnd: map['period_end'] as String,
      title: map['title'] as String?,
      content: map['content'] as String,
      highlights: map['highlights'] as String?,
      insights: map['insights'] as String?,
      recordCount: map['record_count'] as int? ?? 0,
      topThings: map['top_things'] as String?,
      topTags: map['top_tags'] as String?,
      moodAverage: map['mood_average'] as double?,
      energyAverage: map['energy_average'] as double?,
      isRead: map['is_read'] as int? ?? 0,
      createdAt: map['created_at'] as String,
    );
  }

  String get typeLabel {
    switch (summaryType) {
      case 'daily':
        return '日报';
      case 'weekly':
        return '周报';
      case 'monthly':
        return '月报';
      default:
        return summaryType;
    }
  }
}

class SummaryInsight {
  final String title;
  final String description;
  final String type;
  final int importance;

  SummaryInsight({
    required this.title,
    required this.description,
    required this.type,
    this.importance = 1,
  });
}