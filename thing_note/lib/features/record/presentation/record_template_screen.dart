import 'package:flutter/material.dart';
import 'package:thing_note/l10n/generated/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// 记录模板管理
class RecordTemplateScreen extends ConsumerStatefulWidget {
  const RecordTemplateScreen({super.key});

  @override
  ConsumerState<RecordTemplateScreen> createState() => _RecordTemplateScreenState();
}

class _RecordTemplateScreenState extends ConsumerState<RecordTemplateScreen> {
  final List<RecordTemplate> _templates = [];

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    // Load templates from local storage or generate default ones
    setState(() {
      _templates.addAll([
        const RecordTemplate(
          id: '1',
          name: '工作日志',
          icon: Icons.work,
          defaultThingName: '工作',
          defaultNote: '',
          defaultTags: ['工作'],
        ),
        const RecordTemplate(
          id: '2',
          name: '会议记录',
          icon: Icons.meeting_room,
          defaultThingName: '会议',
          defaultNote: '',
          defaultTags: ['会议'],
        ),
        const RecordTemplate(
          id: '3',
          name: '日常打卡',
          icon: Icons.check_circle,
          defaultThingName: '日常',
          defaultNote: '',
          defaultTags: [],
        ),
        const RecordTemplate(
          id: '4',
          name: '学习笔记',
          icon: Icons.book,
          defaultThingName: '学习',
          defaultNote: '',
          defaultTags: ['学习'],
        ),
        const RecordTemplate(
          id: '5',
          name: '健身记录',
          icon: Icons.fitness_center,
          defaultThingName: '运动',
          defaultNote: '',
          defaultTags: ['健康'],
        ),
      ]);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.recordTemplates),
      ),
      body: _templates.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.description_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.noTemplates,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    icon: const Icon(Icons.add),
                    label: Text(l10n.createTemplate),
                    onPressed: () => _showCreateTemplateDialog(),
                  ),
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.1,
              ),
              itemCount: _templates.length,
              itemBuilder: (context, index) {
                final template = _templates[index];
                return _TemplateCard(
                  template: template,
                  onTap: () => _useTemplate(template),
                  onEdit: () => _showEditTemplateDialog(template),
                  onDelete: () => _deleteTemplate(template),
                );
              },
            ),
      floatingActionButton: _templates.isNotEmpty
          ? FloatingActionButton(
              onPressed: () => _showCreateTemplateDialog(),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Future<void> _useTemplate(RecordTemplate template) async {
    // Navigate to record form with template pre-filled
    if (mounted) {
      Navigator.pop(context);
      context.push('/record/new?templateId=${template.id}');
    }
  }

  Future<void> _showCreateTemplateDialog() async {
    final result = await showDialog<RecordTemplate>(
      context: context,
      builder: (ctx) => _TemplateEditDialog(
        template: null,
        l10n: AppLocalizations.of(ctx)!,
      ),
    );

    if (result != null) {
      setState(() {
        _templates.add(result);
      });
    }
  }

  Future<void> _showEditTemplateDialog(RecordTemplate template) async {
    final result = await showDialog<RecordTemplate>(
      context: context,
      builder: (ctx) => _TemplateEditDialog(
        template: template,
        l10n: AppLocalizations.of(ctx)!,
      ),
    );

    if (result != null) {
      setState(() {
        final index = _templates.indexWhere((t) => t.id == result.id);
        if (index != -1) {
          _templates[index] = result;
        }
      });
    }
  }

  Future<void> _deleteTemplate(RecordTemplate template) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(ctx)!.confirmDelete),
        content: Text('确定要删除模板 "${template.name}" 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocalizations.of(ctx)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              AppLocalizations.of(ctx)!.delete,
              style: TextStyle(color: Theme.of(ctx).colorScheme.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _templates.removeWhere((t) => t.id == template.id);
      });
    }
  }
}

class _TemplateCard extends StatelessWidget {
  final RecordTemplate template;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TemplateCard({
    required this.template,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Icon(
                  template.icon,
                  size: 48,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Text(
                    template.name,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (template.defaultThingName.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      template.defaultThingName,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 18),
                        onPressed: onEdit,
                        tooltip: '编辑',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 18),
                        onPressed: onDelete,
                        tooltip: '删除',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TemplateEditDialog extends StatefulWidget {
  final RecordTemplate? template;
  final AppLocalizations l10n;

  const _TemplateEditDialog({
    required this.template,
    required this.l10n,
  });

  @override
  State<_TemplateEditDialog> createState() => _TemplateEditDialogState();
}

class _TemplateEditDialogState extends State<_TemplateEditDialog> {
  late TextEditingController _nameController;
  late TextEditingController _thingNameController;
  late TextEditingController _noteController;
  IconData _selectedIcon = Icons.description;
  List<String> _tags = [];

  final List<IconData> _availableIcons = [
    Icons.description,
    Icons.work,
    Icons.meeting_room,
    Icons.check_circle,
    Icons.book,
    Icons.fitness_center,
    Icons.music_note,
    Icons.restaurant,
    Icons.shopping_cart,
    Icons.home,
    Icons.flight,
    Icons.directions_car,
    Icons.pets,
    Icons.school,
    Icons.local_hospital,
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.template?.name ?? '');
    _thingNameController = TextEditingController(text: widget.template?.defaultThingName ?? '');
    _noteController = TextEditingController(text: widget.template?.defaultNote ?? '');
    _selectedIcon = widget.template?.icon ?? Icons.description;
    _tags = List.from(widget.template?.defaultTags ?? []);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _thingNameController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.template == null ? '创建模板' : '编辑模板'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '模板名称',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '选择图标',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableIcons.map((icon) {
                final isSelected = _selectedIcon == icon;
                return InkWell(
                  onTap: () => setState(() => _selectedIcon = icon),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                      border: isSelected
                          ? Border.all(
                              color: Theme.of(context).colorScheme.primary,
                              width: 2,
                            )
                          : null,
                    ),
                    child: Icon(
                      icon,
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _thingNameController,
              decoration: const InputDecoration(
                labelText: '默认事件名称',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: '默认备注模板',
                border: OutlineInputBorder(),
                hintText: '可留空，创建记录时可编辑',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  '默认标签',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addTag,
                ),
              ],
            ),
            if (_tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: _tags.map((tag) {
                  return Chip(
                    label: Text(tag),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () {
                      setState(() => _tags.remove(tag));
                    },
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(widget.l10n.cancel),
        ),
        FilledButton(
          onPressed: () {
            if (_nameController.text.isEmpty) return;
            final template = RecordTemplate(
              id: widget.template?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
              name: _nameController.text,
              icon: _selectedIcon,
              defaultThingName: _thingNameController.text,
              defaultNote: _noteController.text,
              defaultTags: _tags,
            );
            Navigator.pop(context, template);
          },
          child: Text(widget.l10n.confirm),
        ),
      ],
    );
  }

  Future<void> _addTag() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('添加标签'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '输入标签名称',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('添加'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      setState(() => _tags.add(result));
    }
  }
}

/// 记录模板数据模型
class RecordTemplate {
  final String id;
  final String name;
  final IconData icon;
  final String defaultThingName;
  final String defaultNote;
  final List<String> defaultTags;

  const RecordTemplate({
    required this.id,
    required this.name,
    required this.icon,
    this.defaultThingName = '',
    this.defaultNote = '',
    this.defaultTags = const [],
  });
}