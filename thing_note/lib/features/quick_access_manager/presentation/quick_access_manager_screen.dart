import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';

/// 快速入口服务
final quickAccessServiceProvider = Provider<QuickAccessService>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return QuickAccessService(dbAsync);
});

final quickAccessItemsProvider = FutureProvider<List<QuickAccessItem>>((ref) async {
  final service = ref.watch(quickAccessServiceProvider);
  return service.getItems();
});

class QuickAccessService {
  final AsyncValue<Database> _dbAsync;

  QuickAccessService(this._dbAsync);

  Future<Database> get _db async {
    final db = _dbAsync.value;
    if (db == null) throw Exception('Database not initialized');
    return db;
  }

  Future<List<QuickAccessItem>> getItems() async {
    final db = await _db;
    final maps = await db.query('quick_access_items', orderBy: 'sort_order ASC');
    return maps.map((m) => QuickAccessItem.fromMap(m)).toList();
  }

  Future<int> addItem(QuickAccessItem item) async {
    final db = await _db;
    return db.insert('quick_access_items', item.toMap()..remove('id'));
  }

  Future<void> updateOrder(List<int> itemIds) async {
    final db = await _db;
    for (int i = 0; i < itemIds.length; i++) {
      await db.update(
        'quick_access_items',
        {'sort_order': i},
        where: 'id = ?',
        whereArgs: [itemIds[i]],
      );
    }
  }

  Future<int> deleteItem(int id) async {
    final db = await _db;
    return db.delete('quick_access_items', where: 'id = ?', whereArgs: [id]);
  }
}

class QuickAccessItem {
  final int? id;
  final String name;
  final String? icon;
  final String routePath;
  final String? color;
  final int sortOrder;
  final bool isEnabled;
  final int useCount;

  QuickAccessItem({
    this.id,
    required this.name,
    this.icon,
    required this.routePath,
    this.color,
    this.sortOrder = 0,
    this.isEnabled = true,
    this.useCount = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'route_path': routePath,
      'color': color,
      'sort_order': sortOrder,
      'is_enabled': isEnabled ? 1 : 0,
      'use_count': useCount,
    };
  }

  factory QuickAccessItem.fromMap(Map<String, dynamic> map) {
    return QuickAccessItem(
      id: map['id'] as int?,
      name: map['name'] as String,
      icon: map['icon'] as String?,
      routePath: map['route_path'] as String,
      color: map['color'] as String?,
      sortOrder: map['sort_order'] as int? ?? 0,
      isEnabled: (map['is_enabled'] as int?) == 1,
      useCount: map['use_count'] as int? ?? 0,
    );
  }
}

class QuickAccessManagerScreen extends ConsumerStatefulWidget {
  const QuickAccessManagerScreen({super.key});

  @override
  ConsumerState<QuickAccessManagerScreen> createState() => _QuickAccessManagerScreenState();
}

class _QuickAccessManagerScreenState extends ConsumerState<QuickAccessManagerScreen> {
  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(quickAccessItemsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('快速入口管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddDialog(context),
            tooltip: '添加入口',
          ),
        ],
      ),
      body: itemsAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shortcut, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('暂无快速入口'),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => _showAddDialog(context),
                    child: const Text('添加入口'),
                  ),
                ],
              ),
            );
          }

          return ReorderableListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            onReorder: (oldIndex, newIndex) async {
              if (newIndex > oldIndex) newIndex--;
              final itemIds = items.map((i) => i.id!).toList();
              final moved = itemIds.removeAt(oldIndex);
              itemIds.insert(newIndex, moved);

              final service = ref.read(quickAccessServiceProvider);
              await service.updateOrder(itemIds);
              ref.invalidate(quickAccessItemsProvider);
            },
            itemBuilder: (context, index) => Card(
              key: ValueKey(items[index].id),
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _parseColor(items[index].color).withOpacity( 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(_parseIcon(items[index].icon), color: _parseColor(items[index].color)),
                ),
                title: Text(items[index].name),
                subtitle: Text('${items[index].useCount} 次使用'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(items[index].isEnabled ? Icons.visibility : Icons.visibility_off),
                      onPressed: () async {
                        // 切换启用状态
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        final service = ref.read(quickAccessServiceProvider);
                        await service.deleteItem(items[index].id!);
                        ref.invalidate(quickAccessItemsProvider);
                      },
                    ),
                    const Icon(Icons.drag_handle),
                  ],
                ),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    final nameController = TextEditingController();
    final pathController = TextEditingController();
    String selectedColor = '#2196F3';
    String selectedIcon = 'star';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('添加快速入口'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: '名称')),
                const SizedBox(height: 12),
                TextField(controller: pathController, decoration: const InputDecoration(labelText: '路径 (如 /dashboard)')),
                const SizedBox(height: 12),
                const Text('图标'),
                Wrap(
                  spacing: 8,
                  children: ['star', 'home', 'settings', 'search', 'favorite', 'folder'].map((icon) => ChoiceChip(
                    label: Icon(_parseIcon(icon), size: 20),
                    selected: selectedIcon == icon,
                    onSelected: (_) => setState(() => selectedIcon = icon),
                  )).toList(),
                ),
                const SizedBox(height: 12),
                const Text('颜色'),
                Wrap(
                  spacing: 8,
                  children: ['#2196F3', '#4CAF50', '#FF9800', '#F44336', '#9C27B0', '#607D8B'].map((color) => GestureDetector(
                    onTap: () => setState(() => selectedColor = color),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _parseColor(color),
                        shape: BoxShape.circle,
                        border: selectedColor == color ? Border.all(color: Colors.black, width: 2) : null,
                      ),
                    ),
                  )).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
            FilledButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty) {
                  final service = ref.read(quickAccessServiceProvider);
                  await service.addItem(QuickAccessItem(
                    name: nameController.text,
                    icon: selectedIcon,
                    routePath: pathController.text.isEmpty ? '/${nameController.text.toLowerCase().replaceAll(' ', '-')}' : pathController.text,
                    color: selectedColor,
                  ));
                  ref.invalidate(quickAccessItemsProvider);
                  if (!mounted) return;
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

  IconData _parseIcon(String? icon) {
    switch (icon) {
      case 'star':
        return Icons.star;
      case 'home':
        return Icons.home;
      case 'settings':
        return Icons.settings;
      case 'search':
        return Icons.search;
      case 'favorite':
        return Icons.favorite;
      case 'folder':
        return Icons.folder;
      default:
        return Icons.shortcut;
    }
  }

  Color _parseColor(String? color) {
    if (color == null || color.isEmpty) return Colors.blue;
    try {
      return Color(int.parse(color.replaceFirst('#', '0xFF')));
    } catch (_) {
      return Colors.blue;
    }
  }
}