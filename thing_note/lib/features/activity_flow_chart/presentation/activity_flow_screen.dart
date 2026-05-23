import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/flow_models.dart';

/// 活动流向图屏幕
class ActivityFlowScreen extends ConsumerWidget {
  const ActivityFlowScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flowAsync = ref.watch(activityFlowProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('活动流向'),
      ),
      body: flowAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
        data: (flow) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // 节点
              Text('📊 活动节点', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: flow.nodes.map((node) => _NodeCard(node: node)).toList(),
              ),
              const SizedBox(height: 32),
              // 连接关系
              Text('🔗 活动关联', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              ...flow.links.map((link) {
                final fromNode = flow.nodes.firstWhere((n) => n.id == link.fromId, orElse: () => flow.nodes.first);
                final toNode = flow.nodes.firstWhere((n) => n.id == link.toId, orElse: () => flow.nodes.first);
                return Card(
                  child: ListTile(
                    leading: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(color: fromNode.color, shape: BoxShape.circle),
                          child: Center(child: Text(fromNode.name[0], style: const TextStyle(color: Colors.white, fontSize: 12))),
                        ),
                        const Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Icon(Icons.arrow_forward, size: 16)),
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(color: toNode.color, shape: BoxShape.circle),
                          child: Center(child: Text(toNode.name[0], style: const TextStyle(color: Colors.white, fontSize: 12))),
                        ),
                      ],
                    ),
                    title: Text('${fromNode.name} → ${toNode.name}'),
                    subtitle: Text('关联强度: ${link.strength}/5'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(link.strength, (i) => const Icon(Icons.circle, size: 8, color: Colors.amber)),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _NodeCard extends StatelessWidget {
  final ActivityNode node;
  const _NodeCard({required this.node});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: node.color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: node.color, shape: BoxShape.circle),
              child: Center(
                child: Text(node.name[0], style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 8),
            Text(node.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('${node.count} 条记录'),
          ],
        ),
      ),
    );
  }
}