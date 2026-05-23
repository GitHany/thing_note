import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/quick_template/data/quick_template_repository.dart';
import 'package:thing_note/features/quick_template/domain/quick_template.dart';

final quickTemplateRepoProvider = Provider((ref) => QuickTemplateRepository(ref));

class QuickTemplateScreen extends ConsumerStatefulWidget {
  const QuickTemplateScreen({super.key});

  @override
  ConsumerState<QuickTemplateScreen> createState() => _QuickTemplateScreenState();
}

class _QuickTemplateScreenState extends ConsumerState<QuickTemplateScreen> {
  List<QuickTemplate> _templates = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    setState(() => _isLoading = true);
    final repo = ref.read(quickTemplateRepoProvider);
    await repo.initDefaultTemplates();
    _templates = await repo.getAllTemplates();
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('快捷模板'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildTemplateGrid(),
    );
  }

  Widget _buildTemplateGrid() {
    if (_templates.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.flash_on, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('暂无模板'),
            ElevatedButton.icon(
              onPressed: _showAddDialog,
              icon: const Icon(Icons.add),
              label: const Text('创建模板'),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _templates.length,
      itemBuilder: (context, index) {
        final template = _templates[index];
        return _TemplateCard(
          template: template,
          onTap: () => _useTemplate(template),
          onFavorite: () => _toggleFavorite(template),
          onDelete: () => _deleteTemplate(template.id!),
        );
      },
    );
  }

  void _showAddDialog() {
    final nameController = TextEditingController();
    final iconController = TextEditingController(text: '📌');
    final colorController = TextEditingController(text: '#607D8B');
    int duration = 30;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('创建模板'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: '模板名称'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: iconController,
                  decoration: const InputDecoration(labelText: '图标 (emoji)'),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('时长: '),
                    Expanded(
                      child: Slider(
                        value: duration.toDouble(),
                        min: 5,
                        max: 120,
                        divisions: 23,
                        label: '$duration 分钟',
                        onChanged: (v) => setDialogState(() => duration = v.toInt()),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) return;
                final repo = ref.read(quickTemplateRepoProvider);
                await repo.insertTemplate(QuickTemplate(
                  name: nameController.text.trim(),
                  icon: iconController.text.trim(),
                  color: colorController.text.trim(),
                  defaultDurationMinutes: duration,
                  createdAt: DateTime.now(),
                ));
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                _loadTemplates();
              },
              child: const Text('创建'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _useTemplate(QuickTemplate template) async {
    final repo = ref.read(quickTemplateRepoProvider);
    await repo.incrementUseCount(template.id!);
    _loadTemplates();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Text(template.icon),
              const SizedBox(width: 8),
              Text('使用模板: ${template.name} (${template.defaultDurationMinutes}分钟)'),
            ],
          ),
        ),
      );
    }
  }

  Future<void> _toggleFavorite(QuickTemplate template) async {
    final repo = ref.read(quickTemplateRepoProvider);
    await repo.toggleFavorite(template.id!);
    _loadTemplates();
  }

  Future<void> _deleteTemplate(int id) async {
    final repo = ref.read(quickTemplateRepoProvider);
    await repo.deleteTemplate(id);
    _loadTemplates();
  }
}

class _TemplateCard extends StatelessWidget {
  final QuickTemplate template;
  final VoidCallback onTap;
  final VoidCallback onFavorite;
  final VoidCallback onDelete;

  const _TemplateCard({
    required this.template,
    required this.onTap,
    required this.onFavorite,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(int.parse(template.color.replaceFirst('#', '0xFF')));

    return Card(
      color: color.withOpacity(0.1),
      child: InkWell(
        onTap: onTap,
        onLongPress: () => _showOptions(context),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(template.icon, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 8),
            Text(
              template.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            Text(
              '${template.defaultDurationMinutes}分钟',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(
              template.isFavorite ? Icons.star : Icons.star_border,
              color: Colors.amber,
            ),
            title: Text(template.isFavorite ? '取消收藏' : '收藏'),
            onTap: () {
              Navigator.pop(ctx);
              onFavorite();
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            title: const Text('删除'),
            onTap: () {
              Navigator.pop(ctx);
              onDelete();
            },
          ),
        ],
      ),
    );
  }
}