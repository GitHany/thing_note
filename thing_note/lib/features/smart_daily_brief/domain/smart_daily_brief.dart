import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 智能日报模型
class SmartDailyBrief {
  final String date;
  final int recordCount;
  final int totalMinutes;
  final List<String> topThings;
  final List<String> topTags;
  final String? summary;
  final double? avgMood;
  final List<String> highlights;
  final List<String> suggestions;

  SmartDailyBrief({
    required this.date,
    required this.recordCount,
    required this.totalMinutes,
    required this.topThings,
    required this.topTags,
    this.summary,
    this.avgMood,
    required this.highlights,
    required this.suggestions,
  });

  factory SmartDailyBrief.empty(String date) => SmartDailyBrief(
        date: date,
        recordCount: 0,
        totalMinutes: 0,
        topThings: [],
        topTags: [],
        highlights: [],
        suggestions: [],
      );

  Map<String, dynamic> toJson() => {
        'date': date,
        'recordCount': recordCount,
        'totalMinutes': totalMinutes,
        'topThings': topThings,
        'topTags': topTags,
        'summary': summary,
        'avgMood': avgMood,
        'highlights': highlights,
        'suggestions': suggestions,
      };

  factory SmartDailyBrief.fromJson(Map<String, dynamic> json) => SmartDailyBrief(
        date: json['date'] as String,
        recordCount: json['recordCount'] as int,
        totalMinutes: json['totalMinutes'] as int,
        topThings: List<String>.from(json['topThings'] ?? []),
        topTags: List<String>.from(json['topTags'] ?? []),
        summary: json['summary'] as String?,
        avgMood: (json['avgMood'] as num?)?.toDouble(),
        highlights: List<String>.from(json['highlights'] ?? []),
        suggestions: List<String>.from(json['suggestions'] ?? []),
      );
}

/// Provider
final smartDailyBriefProvider =
    StateNotifierProvider<SmartDailyBriefNotifier, AsyncValue<SmartDailyBrief>>((ref) {
  return SmartDailyBriefNotifier();
});

class SmartDailyBriefNotifier extends StateNotifier<AsyncValue<SmartDailyBrief>> {
  SmartDailyBriefNotifier() : super(const AsyncValue.loading());

  Future<void> generateBrief(String date) async {
    state = const AsyncValue.loading();
    try {
      // 模拟生成日报
      await Future.delayed(const Duration(milliseconds: 500));
      final brief = _generateBriefFromData(date);
      state = AsyncValue.data(brief);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  SmartDailyBrief _generateBriefFromData(String date) {
    return SmartDailyBrief(
      date: date,
      recordCount: 8,
      totalMinutes: 240,
      topThings: ['工作', '运动', '阅读'],
      topTags: ['重要', '健康'],
      summary: '今天共记录了8条事件，总计4小时。',
      avgMood: 4.2,
      highlights: [
        '完成了重要项目汇报',
        '坚持晨跑30分钟',
      ],
      suggestions: [
        '建议早点休息',
        '明天继续加油！',
      ],
    );
  }
}