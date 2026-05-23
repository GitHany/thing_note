import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:thing_note/features/quick_commands/data/quick_commands_repository.dart';
import 'package:thing_note/features/quick_commands/domain/quick_command_model.dart';

class QuickCommandsScreen extends ConsumerStatefulWidget {
  const QuickCommandsScreen({super.key});

  @override
  ConsumerState<QuickCommandsScreen> createState() => _QuickCommandsScreenState();
}

class _QuickCommandsScreenState extends ConsumerState<QuickCommandsScreen> {
  String? _selectedCategory;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final commandsAsync = ref.watch(quickCommandsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('快速命令'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildCategoryFilter(),
          Expanded(
            child: commandsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('错误: $e')),
              data: (commands) => _buildCommandList(commands),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddCommandDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    final commands = ref.watch(quickCommandsProvider).value ?? [];
    final categories = commands
        .where((c) => c.category != null)
        .map((c) => c.category!)
        .toSet()
        .toList();

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: const Text('全部'),
              selected: _selectedCategory == null,
              onSelected: (_) => setState(() => _selectedCategory = null),
            ),
          ),
          ...categories.map((cat) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(cat),
              selected: _selectedCategory == cat,
              onSelected: (_) => setState(() => _selectedCategory = cat),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildCommandList(List<QuickCommand> commands) {
    var filtered = commands;
    
    if (_selectedCategory != null) {
      filtered = filtered.where((c) => c.category == _selectedCategory).toList();
    }
    
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((c) =>
        c.name.contains(_searchQuery) ||
        (c.alias?.contains(_searchQuery) ?? false)
      ).toList();
    }

    if (filtered.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bolt, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('暂无命令', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text('创建你自己的快速命令', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    // Group by category
    final grouped = <String, List<QuickCommand>>{};
    for (final cmd in filtered) {
      grouped.putIfAbsent(cmd.category ?? '未分类', () => []).add(cmd);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: grouped.length,
      itemBuilder: (context, index) {
        final category = grouped.keys.elementAt(index);
        final items = grouped[category]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                category,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
            ),
            ...items.map((cmd) => _CommandCard(
              command: cmd,
              onTap: () => _executeCommand(cmd),
              onEdit: () => _showEditCommandDialog(context, cmd),
              onDelete: () => ref.read(quickCommandsProvider.notifier).deleteCommand(cmd.id!),
            )),
          ],
        );
      },
    );
  }

  void _executeCommand(QuickCommand command) {
    ref.read(quickCommandsProvider.notifier).incrementUseCount(command.id!);
    
    final config = _parseConfig(command.actionConfig);
    
    switch (command.commandType) {
      case 'navigate':
        final path = config['path'] as String?;
        if (path != null) {
          context.push(path);
        }
        break;
      case 'action':
        final action = config['action'] as String?;
        if (action == 'open_search') {
          context.push('/search');
        }
        break;
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('执行: ${command.name}')),
    );
  }

  Map<String, dynamic> _parseConfig(String config) {
    try {
      return jsonDecode(config) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  void _showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('搜索命令'),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '输入命令名称或别名',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (value) => setState(() => _searchQuery = value),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _searchQuery = '');
              Navigator.pop(context);
            },
            child: const Text('清除'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  void _showAddCommandDialog(BuildContext context) {
    _showCommandEditor(context, null);
  }

  void _showEditCommandDialog(BuildContext context, QuickCommand command) {
    _showCommandEditor(context, command);
  }

  void _showCommandEditor(BuildContext context, QuickCommand? existing) {
    final nameController = TextEditingController(text: existing?.name);
    final aliasController = TextEditingController(text: existing?.alias);
    final categoryController = TextEditingController(text: existing?.category);
    String commandType = existing?.commandType ?? 'navigate';
    final pathController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(existing != null ? '编辑命令' : '添加命令'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: '名称'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: aliasController,
                  decoration: const InputDecoration(labelText: '别名（快捷词）'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: categoryController,
                  decoration: const InputDecoration(labelText: '分类'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: commandType,
                  decoration: const InputDecoration(labelText: '命令类型'),
                  items: const [
                    DropdownMenuItem(value: 'navigate', child: Text('导航')),
                    DropdownMenuItem(value: 'action', child: Text('动作')),
                  ],
                  onChanged: (v) => setState(() => commandType = v!),
                ),
                if (commandType == 'navigate') ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: pathController,
                    decoration: const InputDecoration(
                      labelText: '路径',
                      hintText: '/record/new',
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isEmpty) return;
                
                String actionConfig;
                if (commandType == 'navigate') {
                  actionConfig = jsonEncode({'path': pathController.text});
                } else {
                  actionConfig = jsonEncode({'action': 'custom'});
                }
                
                final command = QuickCommand(
                  id: existing?.id,
                  name: nameController.text,
                  alias: aliasController.text.isEmpty ? null : aliasController.text,
                  commandType: commandType,
                  actionConfig: actionConfig,
                  category: categoryController.text.isEmpty ? null : categoryController.text,
                  useCount: existing?.useCount ?? 0,
                  isEnabled: existing?.isEnabled ?? true,
                  createdAt: existing?.createdAt ?? DateTime.now(),
                );
                
                if (existing != null) {
                  ref.read(quickCommandsProvider.notifier).updateCommand(command);
                } else {
                  ref.read(quickCommandsProvider.notifier).addCommand(command);
                }
                Navigator.pop(context);
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommandCard extends StatelessWidget {
  final QuickCommand command;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CommandCard({
    required this.command,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getTypeColor(command.commandType).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(_getTypeIcon(command.commandType), color: _getTypeColor(command.commandType)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(command.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    if (command.alias != null)
                      Text(
                        '/' '${command.alias}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                  ],
                ),
              ),
              Text(
                '${command.useCount}次',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') onEdit();
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Text('编辑')),
                  const PopupMenuItem(value: 'delete', child: Text('删除')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'navigate':
        return Icons.navigation;
      case 'action':
        return Icons.flash_on;
      case 'shortcut':
        return Icons.keyboard;
      default:
        return Icons.bolt;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'navigate':
        return Colors.blue;
      case 'action':
        return Colors.orange;
      case 'shortcut':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}