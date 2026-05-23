import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final quickAccessItemsProvider = StateProvider<List<QuickAccessItem>>((_) => [
  QuickAccessItem(id: '1', name: '新建记录', icon: Icons.add, color: Colors.blue),
  QuickAccessItem(id: '2', name: '习惯打卡', icon: Icons.check_circle, color: Colors.green),
  QuickAccessItem(id: '3', name: '快速搜索', icon: Icons.search, color: Colors.orange),
  QuickAccessItem(id: '4', name: '日历视图', icon: Icons.calendar_today, color: Colors.purple),
  QuickAccessItem(id: '5', name: '统计数据', icon: Icons.bar_chart, color: Colors.teal),
]);

class QuickAccessItem {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final int useCount;
  final bool isEnabled;

  QuickAccessItem({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.useCount = 0,
    this.isEnabled = true,
  });

  QuickAccessItem copyWith({
    String? id,
    String? name,
    IconData? icon,
    Color? color,
    int? useCount,
    bool? isEnabled,
  }) {
    return QuickAccessItem(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      useCount: useCount ?? this.useCount,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }
}

class QuickAccessBarScreen extends ConsumerStatefulWidget {
  const QuickAccessBarScreen({super.key});

  @override
  ConsumerState<QuickAccessBarScreen> createState() => _QuickAccessBarScreenState();
}

class _QuickAccessBarScreenState extends ConsumerState<QuickAccessBarScreen> {
  bool _isEditing = false;

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(quickAccessItemsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('快捷访问栏'),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.check : Icons.edit),
            onPressed: () => setState(() => _isEditing = !_isEditing),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildPreviewBar(context, items),
          const Divider(),
          Expanded(
            child: ListView(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('可用项目', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                ...items.map((item) => _buildItemTile(context, item)),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: OutlinedButton.icon(
                    onPressed: () => _showAddItemDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('添加自定义项'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewBar(BuildContext context, List<QuickAccessItem> items) {
    final enabledItems = items.where((i) => i.isEnabled).toList();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: enabledItems.take(5).map((item) => _buildQuickButton(context, item)).toList(),
      ),
    );
  }

  Widget _buildQuickButton(BuildContext context, QuickAccessItem item) {
    return InkWell(
      onTap: () {
        final updated = ref.read(quickAccessItemsProvider.notifier).state.map((i) {
          return i.id == item.id ? i.copyWith(useCount: i.useCount + 1) : i;
        }).toList();
        ref.read(quickAccessItemsProvider.notifier).state = updated;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('执行: ${item.name}')),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 60,
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: item.color.withOpacity( 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(item.icon, color: item.color),
            ),
            const SizedBox(height: 4),
            Text(
              item.name,
              style: const TextStyle(fontSize: 11),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemTile(BuildContext context, QuickAccessItem item) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: item.color.withOpacity( 0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(item.icon, color: item.color),
      ),
      title: Text(item.name),
      subtitle: Text('使用 ${item.useCount} 次'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isEditing) ...[
            IconButton(
              icon: Icon(item.isEnabled ? Icons.visibility : Icons.visibility_off),
              onPressed: () {
                final updated = ref.read(quickAccessItemsProvider.notifier).state.map((i) {
                  return i.id == item.id ? i.copyWith(isEnabled: !i.isEnabled) : i;
                }).toList();
                ref.read(quickAccessItemsProvider.notifier).state = updated;
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                final updated = ref.read(quickAccessItemsProvider.notifier).state
                    .where((i) => i.id != item.id)
                    .toList();
                ref.read(quickAccessItemsProvider.notifier).state = updated;
              },
            ),
          ] else
            Switch(
              value: item.isEnabled,
              onChanged: (v) {
                final updated = ref.read(quickAccessItemsProvider.notifier).state.map((i) {
                  return i.id == item.id ? i.copyWith(isEnabled: v) : i;
                }).toList();
                ref.read(quickAccessItemsProvider.notifier).state = updated;
              },
            ),
        ],
      ),
    );
  }

  Future<void> _showAddItemDialog(BuildContext context) async {
    final nameController = TextEditingController();
    IconData selectedIcon = Icons.star;
    Color selectedColor = Colors.blue;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('添加快捷项'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: '名称'),
              ),
              const SizedBox(height: 16),
              const Text('选择图标'),
              Wrap(
                spacing: 8,
                children: [Icons.star, Icons.home, Icons.settings, Icons.person, Icons.search]
                    .map((icon) => IconButton(
                          icon: Icon(icon),
                          onPressed: () => setState(() => selectedIcon = icon),
                          color: selectedIcon == icon ? Colors.blue : null,
                        ))
                    .toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  final newItem = QuickAccessItem(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: nameController.text,
                    icon: selectedIcon,
                    color: selectedColor,
                  );
                  ref.read(quickAccessItemsProvider.notifier).state = [
                    ...ref.read(quickAccessItemsProvider),
                    newItem,
                  ];
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