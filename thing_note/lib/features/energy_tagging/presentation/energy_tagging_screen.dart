import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/energy_tagging/data/energy_tagging_repository.dart';
import 'package:thing_note/features/energy_tagging/domain/energy_tag.dart';

class EnergyTaggingScreen extends ConsumerWidget {
  const EnergyTaggingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tagsAsync = ref.watch(activityEnergyTagsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('精力标签系统'),
      ),
      body: Column(
        children: [
          _buildLegend(),
          Expanded(
            child: tagsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('错误: $e')),
              data: (tags) {
                if (tags.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.battery_unknown, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text('暂无精力标签', style: TextStyle(fontSize: 18)),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => _showAddDialog(context, ref),
                          icon: const Icon(Icons.add),
                          label: const Text('添加活动'),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: tags.length,
                  itemBuilder: (context, index) {
                    final tag = tags[index];
                    return _EnergyTagCard(tag: tag);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey.shade100,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildLegendItem('极低', Colors.green),
          _buildLegendItem('轻度', Colors.lightGreen),
          _buildLegendItem('中度', Colors.amber),
          _buildLegendItem('高度', Colors.orange),
          _buildLegendItem('极高', Colors.red),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    int energyLevel = 3;
    bool isRecharging = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('添加活动'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: '活动名称'),
              ),
              const SizedBox(height: 16),
              const Text('精力消耗等级'),
              const SizedBox(height: 8),
              Slider(
                value: energyLevel.toDouble(),
                min: 1,
                max: 5,
                divisions: 4,
                label: ActivityEnergyTag.energyLevelLabel(energyLevel),
                onChanged: (v) => setState(() => energyLevel = v.toInt()),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('是否恢复精力'),
                value: isRecharging,
                onChanged: (v) => setState(() => isRecharging = v),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  final tag = ActivityEnergyTag(
                    activityName: nameController.text,
                    energyLevel: energyLevel,
                    isRecharging: isRecharging ? 1 : 0,
                  );
                  ref.read(activityEnergyTagsProvider.notifier).addTag(tag);
                  Navigator.pop(context);
                }
              },
              child: const Text('添加'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EnergyTagCard extends ConsumerWidget {
  final ActivityEnergyTag tag;

  const _EnergyTagCard({required this.tag});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Color(ActivityEnergyTag.energyLevelColor(tag.energyLevel));

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              '${tag.energyLevel}',
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        title: Text(tag.activityName),
        subtitle: Row(
          children: [
            Text(ActivityEnergyTag.energyLevelLabel(tag.energyLevel)),
            if (tag.isRecharging == 1) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('恢复精力', style: TextStyle(color: Colors.green, fontSize: 12)),
              ),
            ],
          ],
        ),
        trailing: Text('${tag.usageCount}次', style: const TextStyle(color: Colors.grey)),
      ),
    );
  }
}