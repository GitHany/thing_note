import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thing_note/features/record/domain/episode_record.dart';
import 'package:thing_note/features/widget/data/widget_data.dart';

class WidgetService {
  static const _keyWidgetConfig = 'widget_config';

  Future<WidgetRecordData> getWidgetData(List<EpisodeRecord> records) async {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final startOfWeek = startOfToday.subtract(Duration(days: now.weekday - 1));

    // 今日记录数
    final todayCount = records.where((r) {
      final recordDate = DateTime(r.occurredAt.year, r.occurredAt.month, r.occurredAt.day);
      return recordDate.isAtSameMomentAs(startOfToday) ||
             recordDate.isAfter(startOfToday);
    }).length;

    // 本周记录数
    final weekCount = records.where((r) {
      final recordDate = DateTime(r.occurredAt.year, r.occurredAt.month, r.occurredAt.day);
      return recordDate.isAfter(startOfWeek.subtract(const Duration(days: 1)));
    }).length;

    // 最近记录时间
    DateTime? lastRecordTime;
    if (records.isNotEmpty) {
      final sorted = records.toList()..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
      lastRecordTime = sorted.first.occurredAt;
    }

    // 连续天数
    final streakDays = _calculateStreak(records);

    return WidgetRecordData(
      title: '快速记录',
      subtitle: '点击添加新记录',
      lastRecordTime: lastRecordTime,
      todayCount: todayCount,
      weekCount: weekCount,
      streakDays: streakDays,
    );
  }

  Future<WidgetConfig> getWidgetConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_keyWidgetConfig);
      if (jsonStr == null) return const WidgetConfig();

      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return WidgetConfig(
        showTodayCount: map['showTodayCount'] as bool? ?? true,
        showStreak: map['showStreak'] as bool? ?? true,
        showLastRecord: map['showLastRecord'] as bool? ?? false,
        customTitle: map['customTitle'] as String? ?? '',
      );
    } catch (_) {
      return const WidgetConfig();
    }
  }

  Future<void> saveWidgetConfig(WidgetConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyWidgetConfig, jsonEncode({
      'showTodayCount': config.showTodayCount,
      'showStreak': config.showStreak,
      'showLastRecord': config.showLastRecord,
      'customTitle': config.customTitle,
    }));
  }

  int _calculateStreak(List<EpisodeRecord> records) {
    if (records.isEmpty) return 0;

    // 获取唯一日期
    final dates = records.map((r) =>
        DateTime(r.occurredAt.year, r.occurredAt.month, r.occurredAt.day)).toSet().toList();
    dates.sort((a, b) => b.compareTo(a));

    // 检查今天或昨天是否有记录
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (dates.isEmpty) return 0;
    final latestDate = dates.first;

    // 如果最新记录不是今天或昨天，连续中断
    if (!latestDate.isAtSameMomentAs(today) && !latestDate.isAtSameMomentAs(yesterday)) {
      return 0;
    }

    int streak = 1;
    for (int i = 0; i < dates.length - 1; i++) {
      final current = dates[i];
      final next = dates[i + 1];
      final diff = current.difference(next).inDays;

      if (diff == 1) {
        streak++;
      } else {
        break;
      }
    }

    return streak;
  }
}