import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/ai_classifier_models.dart';

/// AI 自动分类器屏幕
class AiClassifierScreen extends ConsumerWidget {
  const AiClassifierScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rulesAsync = ref.watch(aiClassifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI 智能分类'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddRuleDialog(context, ref),
          ),
        ],
      ),
      body: Column(
        children: [
          // 说明
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.primaryContainer,
            child: const Row(
              children: [
                Icon(Icons.auto_awesome),
                SizedBox(width: 8),
                Expanded(
                  child: Text('AI 会根据关键词自动建议记录的事情名称和标签'),
                ),
              ],
            ),
          ),
          // 规则列表
          Expanded(
            child: rulesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('加载失败: $e')),
              data: (rules) => rules.isEmpty
                  ? const Center(child: Text('暂无分类规则'))
                  : ListView.builder(
                      itemCount: rules.length,
                      itemBuilder: (context, index) {
                        final rule = rules[index];
                        return ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: rule.isEnabled ? Colors.green.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              rule.isEnabled ? Icons.smart_toy : Icons.smart_toy_outlined,
                              color: rule.isEnabled ? Colors.green : Colors.grey,
                            ),
                          ),
                          title: Text(rule.keyword),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('→ ${rule.suggestedThing}'),
                              if (rule.suggestedTags.isNotEmpty)
                                Wrap(
                                  spacing: 4,
                                  children: rule.suggestedTags.map((t) => Chip(label: Text(t, style: const TextStyle(fontSize: 10)), padding: EdgeInsets.zero)).toList(),
                                ),
                            ],
                          ),
                          trailing: Text('匹配 ${rule.matchCount} 次'),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddRuleDialog(BuildContext context, WidgetRef ref) {
    final keywordController = TextEditingController();
    final thingController = TextEditingController();
    final tagsController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加分类规则'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: keywordController, decoration: const InputDecoration(labelText: '关键词')),
            const SizedBox(height: 8),
            TextField(controller: thingController, decoration: const InputDecoration(labelText: '建议的事情名称')),
            const SizedBox(height: 8),
            TextField(controller: tagsController, decoration: const InputDecoration(labelText: '建议标签（逗号分隔）')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          TextButton(
            onPressed: () {
              if (keywordController.text.isNotEmpty && thingController.text.isNotEmpty) {
                ref.read(aiClassifierProvider.notifier).addRule(ClassificationRule(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  keyword: keywordController.text,
                  suggestedThing: thingController.text,
                  suggestedTags: tagsController.text.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList(),
                ));
                Navigator.pop(context);
              }
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }
}