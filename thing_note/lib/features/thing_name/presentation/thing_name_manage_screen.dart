import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:thing_note/features/thing_name/domain/thing_name.dart';
import 'package:thing_note/features/thing_name/presentation/providers/thing_name_provider.dart';

class ThingNameManageScreen extends ConsumerStatefulWidget {
  const ThingNameManageScreen({super.key});

  @override
  ConsumerState<ThingNameManageScreen> createState() => _ThingNameManageScreenState();
}

class _ThingNameManageScreenState extends ConsumerState<ThingNameManageScreen> {
  final _nameController = TextEditingController();
  final _remarkController = TextEditingController();
  final Set<int> _selectedIds = {};
  bool _isMultiSelectMode = false;

  @override
  void dispose() {
    _nameController.dispose();
    _remarkController.dispose();
    super.dispose();
  }

  Future<void> _showAddDialog() async {
    _nameController.clear();
    _remarkController.clear();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('添加事件名称'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: '名称',
                hintText: '请输入事件名称',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _remarkController,
              maxLines: 3,
              minLines: 1,
              decoration: const InputDecoration(
                labelText: '备注',
                hintText: '请输入备注（可选）',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              final name = _nameController.text.trim();
              if (name.isEmpty) return;
              if (name == '默认') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('不能创建名为"默认"的事件名称')),
                );
                return;
              }
              ref.read(thingNameNotifierProvider.notifier).add(
                name,
                remark: _remarkController.text.trim().isEmpty
                    ? null
                    : _remarkController.text.trim(),
              );
              Navigator.pop(ctx);
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }

  void _toggleSelect(int id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
      if (_selectedIds.isEmpty) {
        _isMultiSelectMode = false;
      }
    });
  }

  void _selectAll(List<int> ids) {
    setState(() {
      if (_selectedIds.length == ids.length) {
        _selectedIds.clear();
        _isMultiSelectMode = false;
      } else {
        _selectedIds.addAll(ids);
      }
    });
  }

  Future<void> _deleteSelected() async {
    final defaultId = ref.read(thingNameListProvider).valueOrNull
        ?.firstWhere((tn) => tn.name == '默认', orElse: () => ThingName(name: '', createdAt: DateTime.now()))
        .id;
    final idsToDelete = _selectedIds.where((id) => id != defaultId).toList();
    
    if (idsToDelete.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('默认事件名称不能被删除')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除选中的 ${idsToDelete.length} 个事件名称吗？\n\n相关的记录不会被删除，但它们的事件名称会被移除。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              '删除',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      for (final id in idsToDelete) {
        await ref.read(thingNameNotifierProvider.notifier).remove(id);
      }
      setState(() {
        _isMultiSelectMode = false;
        _selectedIds.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final thingNamesAsync = ref.watch(thingNameListProvider);

    return Scaffold(
      appBar: AppBar(
        title: _isMultiSelectMode
            ? Text('已选择 ${_selectedIds.length} 个')
            : const Text('事件名称管理'),
        leading: _isMultiSelectMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _isMultiSelectMode = false;
                    _selectedIds.clear();
                  });
                },
              )
            : null,
        actions: _isMultiSelectMode
            ? thingNamesAsync.when(
                data: (thingNames) => [
                  IconButton(
                    icon: Icon(
                      _selectedIds.length == thingNames.length
                          ? Icons.check_box
                          : Icons.check_box_outline_blank,
                    ),
                    onPressed: () => _selectAll(thingNames.map((t) => t.id!).toList()),
                    tooltip: '全选',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: _selectedIds.isEmpty ? null : _deleteSelected,
                    tooltip: '删除',
                  ),
                ],
                loading: () => [],
                error: (_, __) => [],
              )
            : [],
      ),
      body: thingNamesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('加载失败: $err')),
        data: (thingNames) {
          if (thingNames.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.category_outlined,
                    size: 80,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '暂无事件名称',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '点击右下角按钮添加',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: thingNames.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final thingName = thingNames[index];
              final isSelected = thingName.id != null && _selectedIds.contains(thingName.id);
              
              return InkWell(
                onTap: _isMultiSelectMode && thingName.id != null
                    ? () => _toggleSelect(thingName.id!)
                    : () => context.push('/settings/thing-names/${thingName.id}'),
                onLongPress: thingName.id != null
                    ? () {
                        setState(() {
                          _isMultiSelectMode = true;
                          _selectedIds.add(thingName.id!);
                        });
                      }
                    : null,
                child: Container(
                  decoration: isSelected
                      ? BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        )
                      : null,
                  child: ListTile(
                    title: Text(thingName.name),
                    subtitle: thingName.remark != null && thingName.remark!.isNotEmpty
                        ? Text(thingName.remark!, maxLines: 1, overflow: TextOverflow.ellipsis)
                        : null,
                    trailing: _isMultiSelectMode && thingName.id != null
                        ? Icon(
                            isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                            color: Theme.of(context).colorScheme.primary,
                          )
                        : null,
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: _isMultiSelectMode
          ? null
          : FloatingActionButton(
              onPressed: _showAddDialog,
              child: const Icon(Icons.add),
            ),
    );
  }
}
