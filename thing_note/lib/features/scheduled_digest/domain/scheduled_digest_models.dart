/// 定时摘要 - Scheduled Digest
/// 自动生成每日/每周摘要
library;

/// 摘要配置
class DigestConfig {
  final bool enabled;
  final DigestFrequency frequency;
  final DigestTime defaultTime;
  final List<DigestContentType> contentTypes;
  final bool autoSend;
  final String? notificationChannel;

  DigestConfig({
    this.enabled = true,
    this.frequency = DigestFrequency.daily,
    this.defaultTime = DigestTime.evening,
    this.contentTypes = const [DigestContentType.summary, DigestContentType.stats],
    this.autoSend = false,
    this.notificationChannel,
  });

  DigestConfig copyWith({
    bool? enabled,
    DigestFrequency? frequency,
    DigestTime? defaultTime,
    List<DigestContentType>? contentTypes,
    bool? autoSend,
    String? notificationChannel,
  }) {
    return DigestConfig(
      enabled: enabled ?? this.enabled,
      frequency: frequency ?? this.frequency,
      defaultTime: defaultTime ?? this.defaultTime,
      contentTypes: contentTypes ?? this.contentTypes,
      autoSend: autoSend ?? this.autoSend,
      notificationChannel: notificationChannel ?? this.notificationChannel,
    );
  }
}

/// 摘要频率
enum DigestFrequency {
  daily,
  weekly,
  monthly,
}

/// 摘要时间
enum DigestTime {
  morning, // 早上 8:00
  afternoon, // 下午 14:00
  evening, // 晚上 20:00
}

/// 摘要内容类型
enum DigestContentType {
  summary, // 日/周摘要
  stats, // 统计数据
  mood, // 情绪回顾
  topRecords, // 精彩记录
  goals, // 目标进度
  suggestions, // 建议
}

/// 摘要数据
class DigestData {
  final DateTime generatedAt;
  final DateTime periodStart;
  final DateTime periodEnd;
  final DigestFrequency frequency;
  final int totalRecords;
  final int totalMinutes;
  final int activeDays;
  final List<String> topTags;
  final List<String> topThings;
  final double? averageMood;
  final List<Map<String, dynamic>> highlights;
  final String? aiInsight;

  DigestData({
    required this.generatedAt,
    required this.periodStart,
    required this.periodEnd,
    required this.frequency,
    required this.totalRecords,
    required this.totalMinutes,
    required this.activeDays,
    this.topTags = const [],
    this.topThings = const [],
    this.averageMood,
    this.highlights = const [],
    this.aiInsight,
  });
}

/// 摘要模板
class DigestTemplate {
  final String id;
  final String name;
  final String content;
  final bool isDefault;

  DigestTemplate({
    required this.id,
    required this.name,
    required this.content,
    this.isDefault = false,
  });
}