import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/template_models.dart';

/// 模板市场屏幕
class TemplateMarketScreen extends ConsumerWidget {
  const TemplateMarketScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templatesAsync = ref.watch(templateMarketProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('模板市场'),
      ),
      body: templatesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
        data: (templates) => templates.isEmpty
            ? const Center(child: Text('暂无模板'))
            : ListView.builder(
                itemCount: templates.length,
                itemBuilder: (context, index) {
                  final template = templates[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: InkWell(
                      onTap: () => _useTemplate(context, template),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Text(template.icon, style: const TextStyle(fontSize: 32)),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(template.name, style: Theme.of(context).textTheme.titleMedium),
                                  Text('分类: ${template.category}', style: Theme.of(context).textTheme.bodySmall),
                                  Text('使用 ${template.useCount} 次', style: Theme.of(context).textTheme.bodySmall),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(template.isFavorite ? Icons.star : Icons.star_border, color: Colors.amber),
                              onPressed: () => ref.read(templateMarketProvider.notifier).toggleFavorite(template.id),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  void _useTemplate(BuildContext context, TemplateItem template) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('使用模板: ${template.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('事情: ${template.defaultThingName}'),
            if (template.defaultTags.isNotEmpty)
              Text('标签: ${template.defaultTags.join(", ")}'),
            Text('默认时长: ${template.durationMinutes} 分钟'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: 导航到创建记录页面并应用模板
            },
            child: const Text('使用'),
          ),
        ],
      ),
    );
  }
}