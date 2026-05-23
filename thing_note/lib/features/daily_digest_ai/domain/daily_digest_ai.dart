// Daily Digest AI Models
// 智能每日摘要功能 - 使用AI分析每日记录并生成有意义的摘要

class DailyDigestAI {
  final int? id;
  final String date;
  final String summary;
  final List<String> highlights;
  final List<String> patterns;
  final String? insight;
  final int recordCount;
  final int totalMinutes;
  final double? moodAverage;
  final String? topThingName;
  final List<String> topTags;
  final List<String> suggestions;
  final String? weeklyComparison;
  final int? streakDays;
  final String createdAt;

  DailyDigestAI({
    this.id,
    required this.date,
    required this.summary,
    required this.highlights,
    required this.patterns,
    this.insight,
    required this.recordCount,
    required this.totalMinutes,
    this.moodAverage,
    this.topThingName,
    required this.topTags,
    required this.suggestions,
    this.weeklyComparison,
    this.streakDays,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'summary': summary,
      'highlights': highlights.join('|||'),
      'patterns': patterns.join('|||'),
      'insight': insight,
      'record_count': recordCount,
      'total_minutes': totalMinutes,
      'mood_average': moodAverage,
      'top_thing_name': topThingName,
      'top_tags': topTags.join('|||'),
      'suggestions': suggestions.join('|||'),
      'weekly_comparison': weeklyComparison,
      'streak_days': streakDays,
      'created_at': createdAt,
    };
  }

  factory DailyDigestAI.fromMap(Map<String, dynamic> map) {
    return DailyDigestAI(
      id: map['id'] as int?,
      date: map['date'] as String,
      summary: map['summary'] as String? ?? '',
      highlights: (map['highlights'] as String?)?.split('|||') ?? [],
      patterns: (map['patterns'] as String?)?.split('|||') ?? [],
      insight: map['insight'] as String?,
      recordCount: map['record_count'] as int? ?? 0,
      totalMinutes: map['total_minutes'] as int? ?? 0,
      moodAverage: map['mood_average'] as double?,
      topThingName: map['top_thing_name'] as String?,
      topTags: (map['top_tags'] as String?)?.split('|||') ?? [],
      suggestions: (map['suggestions'] as String?)?.split('|||') ?? [],
      weeklyComparison: map['weekly_comparison'] as String?,
      streakDays: map['streak_days'] as int?,
      createdAt: map['created_at'] as String,
    );
  }

  DailyDigestAI copyWith({
    int? id,
    String? date,
    String? summary,
    List<String>? highlights,
    List<String>? patterns,
    String? insight,
    int? recordCount,
    int? totalMinutes,
    double? moodAverage,
    String? topThingName,
    List<String>? topTags,
    List<String>? suggestions,
    String? weeklyComparison,
    int? streakDays,
    String? createdAt,
  }) {
    return DailyDigestAI(
      id: id ?? this.id,
      date: date ?? this.date,
      summary: summary ?? this.summary,
      highlights: highlights ?? this.highlights,
      patterns: patterns ?? this.patterns,
      insight: insight ?? this.insight,
      recordCount: recordCount ?? this.recordCount,
      totalMinutes: totalMinutes ?? this.totalMinutes,
      moodAverage: moodAverage ?? this.moodAverage,
      topThingName: topThingName ?? this.topThingName,
      topTags: topTags ?? this.topTags,
      suggestions: suggestions ?? this.suggestions,
      weeklyComparison: weeklyComparison ?? this.weeklyComparison,
      streakDays: streakDays ?? this.streakDays,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class DigestConfig {
  final int? id;
  final bool enabled;
  final String generateTime; // 'morning', 'evening', 'night'
  final bool includeHighlights;
  final bool includePatterns;
  final bool includeSuggestions;
  final bool includeComparison;
  final bool autoSave;

  DigestConfig({
    this.id,
    this.enabled = true,
    this.generateTime = 'evening',
    this.includeHighlights = true,
    this.includePatterns = true,
    this.includeSuggestions = true,
    this.includeComparison = true,
    this.autoSave = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'enabled': enabled ? 1 : 0,
      'generate_time': generateTime,
      'include_highlights': includeHighlights ? 1 : 0,
      'include_patterns': includePatterns ? 1 : 0,
      'include_suggestions': includeSuggestions ? 1 : 0,
      'include_comparison': includeComparison ? 1 : 0,
      'auto_save': autoSave ? 1 : 0,
    };
  }

  factory DigestConfig.fromMap(Map<String, dynamic> map) {
    return DigestConfig(
      id: map['id'] as int?,
      enabled: (map['enabled'] as int?) == 1,
      generateTime: map['generate_time'] as String? ?? 'evening',
      includeHighlights: (map['include_highlights'] as int?) == 1,
      includePatterns: (map['include_patterns'] as int?) == 1,
      includeSuggestions: (map['include_suggestions'] as int?) == 1,
      includeComparison: (map['include_comparison'] as int?) == 1,
      autoSave: (map['auto_save'] as int?) == 1,
    );
  }
}

class WeeklyDigest {
  final int? id;
  final int weekNumber;
  final int year;
  final String summary;
  final List<String> highlights;
  final Map<String, int> activityBreakdown;
  final double? averageMood;
  final int totalRecords;
  final int totalMinutes;
  final List<String> patterns;
  final String? insight;
  final String createdAt;

  WeeklyDigest({
    this.id,
    required this.weekNumber,
    required this.year,
    required this.summary,
    required this.highlights,
    required this.activityBreakdown,
    this.averageMood,
    required this.totalRecords,
    required this.totalMinutes,
    required this.patterns,
    this.insight,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'week_number': weekNumber,
      'year': year,
      'summary': summary,
      'highlights': highlights.join('|||'),
      'activity_breakdown': activityBreakdown.entries.map((e) => '${e.key}:${e.value}').join('|||'),
      'average_mood': averageMood,
      'total_records': totalRecords,
      'total_minutes': totalMinutes,
      'patterns': patterns.join('|||'),
      'insight': insight,
      'created_at': createdAt,
    };
  }

  factory WeeklyDigest.fromMap(Map<String, dynamic> map) {
    final breakdownStr = map['activity_breakdown'] as String? ?? '';
    final breakdown = <String, int>{};
    for (final entry in breakdownStr.split('|||')) {
      if (entry.contains(':')) {
        final parts = entry.split(':');
        breakdown[parts[0]] = int.tryParse(parts[1]) ?? 0;
      }
    }

    return WeeklyDigest(
      id: map['id'] as int?,
      weekNumber: map['week_number'] as int,
      year: map['year'] as int,
      summary: map['summary'] as String? ?? '',
      highlights: (map['highlights'] as String?)?.split('|||') ?? [],
      activityBreakdown: breakdown,
      averageMood: map['average_mood'] as double?,
      totalRecords: map['total_records'] as int? ?? 0,
      totalMinutes: map['total_minutes'] as int? ?? 0,
      patterns: (map['patterns'] as String?)?.split('|||') ?? [],
      insight: map['insight'] as String?,
      createdAt: map['created_at'] as String,
    );
  }
}