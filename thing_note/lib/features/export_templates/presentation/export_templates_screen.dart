import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/export_templates/data/export_templates_provider.dart';

class ExportTemplatesScreen extends ConsumerWidget {
  const ExportTemplatesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templatesAsync = ref.watch(exportTemplatesProvider);
    final historyAsync = ref.watch(exportHistoryProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('导出模板'),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _showCreateTemplateDialog(context),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: '模板'),
              Tab(text: '历史'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Templates Tab
            templatesAsync.when(
              data: (templates) {
                if (templates.isEmpty) {
                  return _buildEmptyTemplates(context);
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: templates.length,
                  itemBuilder: (context, index) {
                    return _buildTemplateCard(context, templates[index]);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
            // History Tab
            historyAsync.when(
              data: (history) {
                if (history.isEmpty) {
                  return _buildEmptyHistory(context);
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: history.length,
                  itemBuilder: (context, index) {
                    return _buildHistoryCard(context, history[index]);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showQuickExport(context),
          icon: const Icon(Icons.download),
          label: const Text('快速导出'),
        ),
      ),
    );
  }

  Widget _buildEmptyTemplates(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.file_download,
            size: 80,
            color: Colors.grey.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            '暂无导出模板',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '创建模板以快速导出数据',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showCreateTemplateDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('创建模板'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyHistory(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 80,
            color: Colors.grey.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            '暂无导出历史',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '执行导出后会显示在这里',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateCard(BuildContext context, ExportTemplate template) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showTemplateDetail(context, template),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: template.formatColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(template.icon, color: template.formatColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          template.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '使用 ${template.useCount} 次',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: template.formatColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      template.formatLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: template.includedItems.map((item) {
                  return Chip(
                    label: Text(item, style: const TextStyle(fontSize: 10)),
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryCard(BuildContext context, ExportHistory history) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _getFormatColor(history.format).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getFormatIcon(history.format),
            color: _getFormatColor(history.format),
          ),
        ),
        title: Text(history.templateName),
        subtitle: Text(
          '${history.recordCount}条记录 · ${history.formattedSize}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Text(
          _formatDate(history.createdAt),
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ),
    );
  }

  IconData _getFormatIcon(String format) {
    switch (format) {
      case 'csv':
        return Icons.table_chart;
      case 'json':
        return Icons.data_object;
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'html':
        return Icons.web;
      default:
        return Icons.file_download;
    }
  }

  Color _getFormatColor(String format) {
    switch (format) {
      case 'csv':
        return Colors.green;
      case 'json':
        return Colors.orange;
      case 'pdf':
        return Colors.red;
      case 'html':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showCreateTemplateDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const CreateTemplateSheet(),
    );
  }

  void _showTemplateDetail(BuildContext context, ExportTemplate template) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => TemplateDetailSheet(template: template),
    );
  }

  void _showQuickExport(BuildContext context) {
    final templates = [
      PredefinedTemplates.simpleCsv,
      PredefinedTemplates.fullBackup,
      PredefinedTemplates.summaryReport,
      PredefinedTemplates.timelineHtml,
      PredefinedTemplates.compactPdf,
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '快速导出',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ...templates.map((template) => ListTile(
              leading: Icon(template.icon, color: template.formatColor),
              title: Text(template.name),
              subtitle: Text(template.formatLabel),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('正在导出 ${template.name}...')),
                );
              },
            )),
          ],
        ),
      ),
    );
  }
}

class CreateTemplateSheet extends StatefulWidget {
  const CreateTemplateSheet({super.key});

  @override
  State<CreateTemplateSheet> createState() => _CreateTemplateSheetState();
}

class _CreateTemplateSheetState extends State<CreateTemplateSheet> {
  final _nameController = TextEditingController();
  String _format = 'csv';
  bool _includePhotos = false;
  bool _includeAudio = false;
  bool _includeVideo = false;
  bool _includeLocation = true;
  bool _includeTags = true;
  bool _includeNotes = true;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '创建导出模板',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '模板名称',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField(
              value: _format,
              decoration: const InputDecoration(
                labelText: '导出格式',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'csv', child: Text('CSV')),
                DropdownMenuItem(value: 'json', child: Text('JSON')),
                DropdownMenuItem(value: 'pdf', child: Text('PDF')),
                DropdownMenuItem(value: 'html', child: Text('HTML')),
                DropdownMenuItem(value: 'markdown', child: Text('Markdown')),
              ],
              onChanged: (value) => setState(() => _format = value!),
            ),
            const SizedBox(height: 16),
            const Text('包含内容'),
            CheckboxListTile(
              title: const Text('照片'),
              value: _includePhotos,
              onChanged: (value) => setState(() => _includePhotos = value!),
            ),
            CheckboxListTile(
              title: const Text('音频'),
              value: _includeAudio,
              onChanged: (value) => setState(() => _includeAudio = value!),
            ),
            CheckboxListTile(
              title: const Text('视频'),
              value: _includeVideo,
              onChanged: (value) => setState(() => _includeVideo = value!),
            ),
            CheckboxListTile(
              title: const Text('位置'),
              value: _includeLocation,
              onChanged: (value) => setState(() => _includeLocation = value!),
            ),
            CheckboxListTile(
              title: const Text('标签'),
              value: _includeTags,
              onChanged: (value) => setState(() => _includeTags = value!),
            ),
            CheckboxListTile(
              title: const Text('笔记'),
              value: _includeNotes,
              onChanged: (value) => setState(() => _includeNotes = value!),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('模板已创建')),
                  );
                },
                child: const Text('创建模板'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TemplateDetailSheet extends StatelessWidget {
  final ExportTemplate template;

  const TemplateDetailSheet({super.key, required this.template});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: template.formatColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(template.icon, color: template.formatColor),
              ),
              const SizedBox(width: 12),
              Text(
                template.name,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('格式: ${template.formatLabel}'),
          const SizedBox(height: 8),
          Text('使用次数: ${template.useCount}'),
          const SizedBox(height: 16),
          const Text('包含内容:'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: template.includedItems
                .map((item) => Chip(label: Text(item)))
                .toList(),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    // Edit template
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('编辑'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('正在导出 ${template.name}...')),
                    );
                  },
                  icon: const Icon(Icons.download),
                  label: const Text('导出'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}