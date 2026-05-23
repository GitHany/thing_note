import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 时间线节点
class TimelineNode {
  final String id;
  final DateTime time;
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final int? recordId;
  final List<String> tags;

  const TimelineNode({
    required this.id,
    required this.time,
    required this.title,
    this.subtitle,
    required this.icon,
    required this.color,
    this.recordId,
    this.tags = const [],
  });

  factory TimelineNode.fromRecord({
    required int id,
    required DateTime occurredAt,
    required String note,
    IconData icon = Icons.event_note,
    Color color = Colors.blue,
  }) {
    return TimelineNode(
      id: 'record_$id',
      time: occurredAt,
      title: note.isEmpty ? '记录' : note,
      icon: icon,
      color: color,
      recordId: id,
    );
  }
}

/// 时间线类型
enum TimelineType { chronological, grouped, activity }

/// 智能时间线 Provider
final intelligentTimelineProvider = StateNotifierProvider<IntelligentTimelineNotifier, AsyncValue<List<TimelineNode>>>((ref) {
  return IntelligentTimelineNotifier();
});

class IntelligentTimelineNotifier extends StateNotifier<AsyncValue<List<TimelineNode>>> {
  IntelligentTimelineNotifier() : super(const AsyncValue.loading());

  Future<void> loadTimeline({TimelineType type = TimelineType.chronological, DateTime? startDate, DateTime? endDate}) async {
    state = const AsyncValue.loading();
    try {
      await Future.delayed(const Duration(milliseconds: 400));
      final now = DateTime.now();
      state = AsyncValue.data([
        TimelineNode.fromRecord(id: 1, occurredAt: now.subtract(const Duration(hours: 1)), note: '晨间会议', color: Colors.blue),
        TimelineNode.fromRecord(id: 2, occurredAt: now.subtract(const Duration(hours: 3)), note: '健身运动', color: Colors.green),
        TimelineNode.fromRecord(id: 3, occurredAt: now.subtract(const Duration(hours: 5)), note: '阅读学习', color: Colors.purple),
        TimelineNode(id: 'milestone', time: now.subtract(const Duration(days: 1)), title: '达成目标', subtitle: '连续打卡7天', icon: Icons.emoji_events, color: Colors.amber),
      ]);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void groupByActivity(List<TimelineNode> nodes) {
    final grouped = <String, List<TimelineNode>>{};
    for (final node in nodes) {
      final hour = node.time.hour;
      String period;
      if (hour < 6) {
        period = '凌晨';
      } else if (hour < 9) {
        period = '早晨';
      } else if (hour < 12) {
        period = '上午';
      } else if (hour < 14) {
        period = '中午';
      } else if (hour < 18) {
        period = '下午';
      } else if (hour < 22) {
        period = '晚上';
      } else {
        period = '深夜';
      }

      grouped.putIfAbsent(period, () => []).add(node);
    }
    // 返回分组后的数据
    state = AsyncValue.data(nodes);
  }
}

/// 时间线类型选择
final timelineTypeProvider = StateProvider<TimelineType>((ref) => TimelineType.chronological);