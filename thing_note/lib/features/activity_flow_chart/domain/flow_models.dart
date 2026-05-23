import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 活动节点
class ActivityNode {
  final String id;
  final String name;
  final Color color;
  final int count;
  final List<String> relatedTags;

  const ActivityNode({
    required this.id,
    required this.name,
    required this.color,
    required this.count,
    required this.relatedTags,
  });
}

/// 活动连接
class ActivityLink {
  final String fromId;
  final String toId;
  final int strength; // 1-5

  const ActivityLink({required this.fromId, required this.toId, required this.strength});
}

/// 流向图数据
class FlowChartData {
  final List<ActivityNode> nodes;
  final List<ActivityLink> links;

  const FlowChartData({required this.nodes, required this.links});
}

/// 活动流向 Provider
final activityFlowProvider = FutureProvider<FlowChartData>((ref) async {
  await Future.delayed(const Duration(milliseconds: 400));
  return FlowChartData(
    nodes: const [
      ActivityNode(id: 'work', name: '工作', color: Colors.blue, count: 45, relatedTags: ['重要']),
      ActivityNode(id: 'exercise', name: '运动', color: Colors.green, count: 30, relatedTags: ['健康']),
      ActivityNode(id: 'reading', name: '阅读', color: Colors.purple, count: 25, relatedTags: ['学习']),
      ActivityNode(id: 'rest', name: '休息', color: Colors.orange, count: 60, relatedTags: ['放松']),
    ],
    links: const [
      ActivityLink(fromId: 'work', toId: 'exercise', strength: 4),
      ActivityLink(fromId: 'exercise', toId: 'rest', strength: 5),
      ActivityLink(fromId: 'reading', toId: 'rest', strength: 3),
    ],
  );
});