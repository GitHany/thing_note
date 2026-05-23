import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/smart_shortcut/data/smart_shortcut_repository.dart';
import 'package:thing_note/features/smart_shortcut/domain/smart_shortcut.dart';

class SmartShortcutScreen extends ConsumerStatefulWidget {
  const SmartShortcutScreen({super.key});

  @override
  ConsumerState<SmartShortcutScreen> createState() => _SmartShortcutScreenState();
}

class _SmartShortcutScreenState extends ConsumerState<SmartShortcutScreen> {
  List<SmartShortcut> _shortcuts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadShortcuts();
  }

  Future<void> _loadShortcuts() async {
    setState(() => _isLoading = true);
    final repo = ref.read(smartShortcutRepositoryProvider);
    await repo.initDefaultShortcuts();
    _shortcuts = await repo.getAllShortcuts();
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('智能快捷方式'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _shortcuts.isEmpty
              ? _buildEmptyState()
              : _buildShortcutList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.flash_on, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('暂无快捷方式'),
          const SizedBox(height: 8),
          Text(
            '创建快捷方式来提高操作效率',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showAddDialog,
            icon: const Icon(Icons.add),
            label: const Text('添加快捷方式'),
          ),
        ],
      ),
    );
  }

  Widget _buildShortcutList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _shortcuts.length,
      itemBuilder: (context, index) {
        final shortcut = _shortcuts[index];
        return _ShortcutCard(
          shortcut: shortcut,
          onToggle: () => _toggleShortcut(shortcut),
          onEdit: () => _showEditDialog(shortcut),
          onDelete: () => _deleteShortcut(shortcut),
        );
      },
    );
  }

  Future<void> _toggleShortcut(SmartShortcut shortcut) async {
    final repo = ref.read(smartShortcutRepositoryProvider);
    await repo.toggleShortcut(shortcut.id!);
    _loadShortcuts();
  }

  void _showAddDialog() {
    _showFormDialog();
  }

  void _showEditDialog(SmartShortcut shortcut) {
    _showFormDialog(shortcut: shortcut);
  }

  void _showFormDialog({SmartShortcut? shortcut}) {
    final nameController = TextEditingController(text: shortcut?.name ?? '');
    final iconController = TextEditingController(text: shortcut?.icon ?? '⚡');
    String actionType = shortcut?.actionType ?? 'navigate';
    final actionConfigController = TextEditingController(text: shortcut?.actionConfig ?? '');
    String triggerType = shortcut?.triggerType ?? 'button';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(shortcut == null ? '添加快捷方式' : '编辑快捷方式'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: '名称'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: iconController,
                  decoration: const InputDecoration(labelText: '图标 (emoji)'),
                ),
                const SizedBox(height: 16),
                const Text('动作类型'),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('导航'),
                      selected: actionType == 'navigate',
                      onSelected: (s) => setDialogState(() => actionType = 'navigate'),
                    ),
                    ChoiceChip(
                      label: const Text('快捷操作'),
                      selected: actionType == 'quick_action',
                      onSelected: (s) => setDialogState(() => actionType = 'quick_action'),
                    ),
                    ChoiceChip(
                      label: const Text('模板'),
                      selected: actionType == 'template',
                      onSelected: (s) => setDialogState(() => actionType = 'template'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: actionConfigController,
                  decoration: InputDecoration(
                    labelText: '动作配置',
                    hintText: actionType == 'navigate' ? '/statistics' : 'camera',
                  ),
                ),
                const SizedBox(height: 16),
                const Text('触发类型'),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('按钮'),
                      selected: triggerType == 'button',
                      onSelected: (s) => setDialogState(() => triggerType = 'button'),
                    ),
                    ChoiceChip(
                      label: const Text('手势'),
                      selected: triggerType == 'gesture',
                      onSelected: (s) => setDialogState(() => triggerType = 'gesture'),
                    ),
                    ChoiceChip(
                      label: const Text('语音'),
                      selected: triggerType == 'voice',
                      onSelected: (s) => setDialogState(() => triggerType = 'voice'),
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
                final repo = ref.read(smartShortcutRepositoryProvider);
                final newShortcut = SmartShortcut(
                  id: shortcut?.id,
                  name: nameController.text.trim(),
                  icon: iconController.text.trim(),
                  actionType: actionType,
                  actionConfig: actionConfigController.text.trim(),
                  triggerType: triggerType,
                  isEnabled: shortcut?.isEnabled ?? true,
                  useCount: shortcut?.useCount ?? 0,
                  createdAt: shortcut?.createdAt ?? DateTime.now(),
                );
                if (shortcut == null) {
                  await repo.insertShortcut(newShortcut);
                } else {
                  await repo.updateShortcut(newShortcut);
                }
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                _loadShortcuts();
              },
              child: Text(shortcut == null ? '添加' : '保存'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteShortcut(SmartShortcut shortcut) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除快捷方式 "${shortcut.name}" 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final repo = ref.read(smartShortcutRepositoryProvider);
      await repo.deleteShortcut(shortcut.id!);
      _loadShortcuts();
    }
  }
}

class _ShortcutCard extends StatelessWidget {
  final SmartShortcut shortcut;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ShortcutCard({
    required this.shortcut,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  IconData _getTriggerIcon() {
    switch (shortcut.triggerType) {
      case 'button':
        return Icons.touch_app;
      case 'gesture':
        return Icons.gesture;
      case 'voice':
        return Icons.mic;
      default:
        return Icons.bolt;
    }
  }

  String _getTriggerName() {
    switch (shortcut.triggerType) {
      case 'button':
        return '按钮';
      case 'gesture':
        return '手势';
      case 'voice':
        return '语音';
      default:
        return shortcut.triggerType;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(shortcut.icon, style: const TextStyle(fontSize: 24)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    shortcut.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(_getTriggerIcon(), size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        _getTriggerName(),
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.history, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '使用 ${shortcut.useCount} 次',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Switch(
              value: shortcut.isEnabled,
              onChanged: (_) => onToggle(),
            ),
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () => _showOptions(context),
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
            leading: const Icon(Icons.edit_outlined),
            title: const Text('编辑'),
            onTap: () {
              Navigator.pop(ctx);
              onEdit();
            },
          ),
          ListTile(
            leading: Icon(
              shortcut.isEnabled ? Icons.toggle_off : Icons.toggle_on,
            ),
            title: Text(shortcut.isEnabled ? '禁用' : '启用'),
            onTap: () {
              Navigator.pop(ctx);
              onToggle();
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