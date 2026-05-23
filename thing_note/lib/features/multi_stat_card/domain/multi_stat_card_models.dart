/// 多维度统计卡片 - Multi Stat Card
/// 可定制的多功能统计展示组件
library;

import 'package:flutter/material.dart';

/// 统计卡片配置
class StatCardConfig {
  final String id;
  final String title;
  final StatType type;
  final StatPeriod period;
  final bool showTrend;
  final bool showComparison;
  final Color? accentColor;

  StatCardConfig({
    required this.id,
    required this.title,
    required this.type,
    this.period = StatPeriod.week,
    this.showTrend = true,
    this.showComparison = true,
    this.accentColor,
  });
}

/// 统计类型
enum StatType {
  recordCount, // 记录数量
  totalDuration, // 总时长
  activeDays, // 活跃天数
  topThing, // 最常用事情
  topTag, // 最常用标签
  moodAverage, // 平均情绪
  streakDays, // 连续天数
  completionRate, // 完成率
}

/// 统计周期
enum StatPeriod {
  today,
  week,
  month,
  year,
  all,
}

/// 统计数据
class StatData {
  final StatType type;
  final dynamic value;
  final dynamic previousValue;
  final double changePercent;
  final List<StatDataPoint> trend;
  final Map<String, dynamic> meta;

  StatData({
    required this.type,
    required this.value,
    this.previousValue,
    this.changePercent = 0,
    this.trend = const [],
    this.meta = const {},
  });
}

/// 趋势数据点
class StatDataPoint {
  final DateTime date;
  final double value;

  StatDataPoint({
    required this.date,
    required this.value,
  });
}

/// 卡片布局
enum CardLayout {
  compact, // 紧凑型
  standard, // 标准型
  expanded, // 展开型
  chart, // 图表型
}