import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:thing_note/features/quick_actions_widget/data/quick_actions_repository.dart';
import 'package:thing_note/features/quick_actions_widget/domain/quick_action.dart';

class QuickActionsWidget extends ConsumerStatefulWidget {
  final bool showLabels;
  final int maxActions;

  const QuickActionsWidget({
    super.key,
    this.showLabels = true,
    this.maxActions = 6,
  });

  @override
  ConsumerState<QuickActionsWidget> createState() => _QuickActionsWidgetState();
}

class _QuickActionsWidgetState extends ConsumerState<QuickActionsWidget> {
  List<QuickAction> _actions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadActions();
  }

  Future<void> _loadActions() async {
    final repo = ref.read(quickActionsRepositoryProvider);
    await repo.initDefaultActions();
    final actions = await repo.getEnabledActions();
    setState(() {
      _actions = actions.take(widget.maxActions).toList();
      _isLoading = false;
    });
  }

  Future<void> _executeAction(QuickAction action) async {
    final repo = ref.read(quickActionsRepositoryProvider);
    await repo.incrementUseCount(action.id!);
    if (!mounted) return;

    switch (action.actionType) {
      case 'quick_record':
        context.push('/record/new');
        break;
      case 'voice_record':
        context.push('/voice-recorder');
        break;
      case 'camera_record':
        context.push('/record/new?camera=true');
        break;
      case 'navigation':
        if (action.actionConfig != null) {
          context.push(action.actionConfig!);
        }
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('执行: ${action.name}')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 80,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_actions.isEmpty) {
      return const SizedBox(
        height: 80,
        child: Center(child: Text('暂无快捷操作')),
      );
    }

    return SizedBox(
      height: widget.showLabels ? 100 : 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _actions.length,
        itemBuilder: (context, index) {
          final action = _actions[index];
          return _QuickActionButton(
            action: action,
            showLabel: widget.showLabels,
            onTap: () => _executeAction(action),
            onLongPress: () => _showActionOptions(action),
          );
        },
      ),
    );
  }

  void _showActionOptions(QuickAction action) {
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
              _showEditDialog(action);
            },
          ),
          ListTile(
            leading: Icon(
              action.isEnabled ? Icons.toggle_off : Icons.toggle_on,
            ),
            title: Text(action.isEnabled ? '禁用' : '启用'),
            onTap: () async {
              Navigator.pop(ctx);
              final repo = ref.read(quickActionsRepositoryProvider);
              await repo.toggleAction(action.id!);
              _loadActions();
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            title: const Text('删除'),
            onTap: () async {
              Navigator.pop(ctx);
              final confirmed = await _confirmDelete();
              if (confirmed) {
                final repo = ref.read(quickActionsRepositoryProvider);
                await repo.deleteAction(action.id!);
                _loadActions();
              }
            },
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmDelete() async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('确认删除'),
            content: const Text('确定要删除此快捷操作吗？'),
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
        ) ??
        false;
  }

  void _showEditDialog(QuickAction action) {
    final nameController = TextEditingController(text: action.name);
    final iconController = TextEditingController(text: action.icon);
    final colorController = TextEditingController(text: action.color);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('编辑快捷操作'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
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
            TextField(
              controller: colorController,
              decoration: const InputDecoration(labelText: '颜色'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              final updatedAction = action.copyWith(
                name: nameController.text.trim(),
                icon: iconController.text.trim(),
                color: colorController.text.trim(),
              );
              final repo = ref.read(quickActionsRepositoryProvider);
              await repo.updateAction(updatedAction);
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              _loadActions();
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final QuickAction action;
  final bool showLabel;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _QuickActionButton({
    required this.action,
    required this.showLabel,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(int.parse(action.color.replaceFirst('#', '0xFF')));

    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: showLabel ? 70 : 50,
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    action.icon,
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
              ),
              if (showLabel) ...[
                const SizedBox(height: 6),
                Text(
                  action.name,
                  style: const TextStyle(fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Full screen for managing quick actions
class QuickActionsScreen extends ConsumerStatefulWidget {
  const QuickActionsScreen({super.key});

  @override
  ConsumerState<QuickActionsScreen> createState() => _QuickActionsScreenState();
}

class _QuickActionsScreenState extends ConsumerState<QuickActionsScreen> {
  List<QuickAction> _allActions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadActions();
  }

  Future<void> _loadActions() async {
    setState(() => _isLoading = true);
    final repo = ref.read(quickActionsRepositoryProvider);
    await repo.initDefaultActions();
    _allActions = await repo.getAllActions();
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('快捷操作'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _allActions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.flash_on, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('暂无快捷操作'),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _showAddDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('添加快捷操作'),
                      ),
                    ],
                  ),
                )
              : ReorderableListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _allActions.length,
                  onReorder: (oldIndex, newIndex) {
                    setState(() {
                      if (newIndex > oldIndex) newIndex--;
                      final item = _allActions.removeAt(oldIndex);
                      _allActions.insert(newIndex, item);
                    });
                    // Save new order
                    final repo = ref.read(quickActionsRepositoryProvider);
                    repo.reorderActions(_allActions.map((a) => a.id!).toList());
                  },
                  itemBuilder: (context, index) {
                    final action = _allActions[index];
                    return _ActionListItem(
                      key: ValueKey(action.id),
                      action: action,
                      onTap: () => _executeAction(action),
                      onToggle: () async {
                        final repo = ref.read(quickActionsRepositoryProvider);
                        await repo.toggleAction(action.id!);
                        _loadActions();
                      },
                      onEdit: () => _showEditDialog(action),
                      onDelete: () async {
                        final confirmed = await _confirmDelete();
                        if (confirmed) {
                          final repo = ref.read(quickActionsRepositoryProvider);
                          await repo.deleteAction(action.id!);
                          _loadActions();
                        }
                      },
                    );
                  },
                ),
    );
  }

  void _executeAction(QuickAction action) {
    switch (action.actionType) {
      case 'quick_record':
        context.push('/record/new');
        break;
      case 'voice_record':
        context.push('/voice-recorder');
        break;
      case 'camera_record':
        context.push('/record/new?camera=true');
        break;
      case 'navigation':
        if (action.actionConfig != null) {
          context.push(action.actionConfig!);
        }
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('执行: ${action.name}')),
        );
    }
  }

  void _showAddDialog() {
    _showActionFormDialog();
  }

  void _showEditDialog(QuickAction action) {
    _showActionFormDialog(action: action);
  }

  void _showActionFormDialog({QuickAction? action}) {
    final nameController = TextEditingController(text: action?.name ?? '');
    final iconController = TextEditingController(text: action?.icon ?? '⚡');
    final colorController = TextEditingController(text: action?.color ?? '#607D8B');
    String actionType = action?.actionType ?? 'quick_record';
    final configController = TextEditingController(text: action?.actionConfig ?? '');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(action == null ? '添加快捷操作' : '编辑快捷操作'),
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
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: iconController,
                        decoration: const InputDecoration(labelText: '图标'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: colorController,
                        decoration: const InputDecoration(labelText: '颜色'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('动作类型'),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('快速记录'),
                      selected: actionType == 'quick_record',
                      onSelected: (s) => setDialogState(() => actionType = 'quick_record'),
                    ),
                    ChoiceChip(
                      label: const Text('语音记录'),
                      selected: actionType == 'voice_record',
                      onSelected: (s) => setDialogState(() => actionType = 'voice_record'),
                    ),
                    ChoiceChip(
                      label: const Text('拍照记录'),
                      selected: actionType == 'camera_record',
                      onSelected: (s) => setDialogState(() => actionType = 'camera_record'),
                    ),
                    ChoiceChip(
                      label: const Text('导航'),
                      selected: actionType == 'navigation',
                      onSelected: (s) => setDialogState(() => actionType = 'navigation'),
                    ),
                  ],
                ),
                if (actionType == 'navigation') ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: configController,
                    decoration: const InputDecoration(
                      labelText: '导航路径',
                      hintText: '/statistics',
                    ),
                  ),
                ],
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
                final repo = ref.read(quickActionsRepositoryProvider);
                final newAction = QuickAction(
                  id: action?.id,
                  name: nameController.text.trim(),
                  icon: iconController.text.trim(),
                  color: colorController.text.trim(),
                  actionType: actionType,
                  actionConfig: actionType == 'navigation' ? configController.text.trim() : null,
                  order: action?.order ?? _allActions.length,
                  isEnabled: action?.isEnabled ?? true,
                  createdAt: action?.createdAt ?? DateTime.now(),
                );
                if (action == null) {
                  await repo.insertAction(newAction);
                } else {
                  await repo.updateAction(newAction);
                }
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                _loadActions();
              },
              child: Text(action == null ? '添加' : '保存'),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _confirmDelete() async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('确认删除'),
            content: const Text('删除后无法恢复，确定要删除吗？'),
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
        ) ??
        false;
  }
}

class _ActionListItem extends StatelessWidget {
  final QuickAction action;
  final VoidCallback onTap;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ActionListItem({
    super.key,
    required this.action,
    required this.onTap,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(int.parse(action.color.replaceFirst('#', '0xFF')));

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(action.icon, style: const TextStyle(fontSize: 22)),
          ),
        ),
        title: Text(action.name),
        subtitle: Text(
          _getActionTypeName(action.actionType),
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: action.isEnabled,
              onChanged: (_) => onToggle(),
            ),
            const Icon(Icons.drag_handle),
          ],
        ),
        onTap: onTap,
        onLongPress: () => _showOptions(context),
      ),
    );
  }

  String _getActionTypeName(String type) {
    switch (type) {
      case 'quick_record':
        return '快速记录';
      case 'voice_record':
        return '语音记录';
      case 'camera_record':
        return '拍照记录';
      case 'navigation':
        return '导航到 ${action.actionConfig ?? ''}';
      default:
        return type;
    }
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
              action.isEnabled ? Icons.toggle_off : Icons.toggle_on,
            ),
            title: Text(action.isEnabled ? '禁用' : '启用'),
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