import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/collection/data/collection_repository.dart';
import 'package:thing_note/features/collection/domain/collection.dart';
import 'package:thing_note/l10n/generated/app_localizations.dart';

class CollectionsScreen extends ConsumerStatefulWidget {
  const CollectionsScreen({super.key});

  @override
  ConsumerState<CollectionsScreen> createState() => _CollectionsScreenState();
}

class _CollectionsScreenState extends ConsumerState<CollectionsScreen> {
  @override
  Widget build(BuildContext context) {
    final collectionsAsync = ref.watch(collectionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('收藏集'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddCollectionDialog(context),
          ),
        ],
      ),
      body: collectionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('错误: $e')),
        data: (collections) {
          if (collections.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.collections_bookmark, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('暂无收藏集', style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => _showAddCollectionDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('创建收藏集'),
                  ),
                ],
              ),
            );
          }

          return LayoutBuilder(
          builder: (context, constraints) {
            // Responsive grid: more columns on wider screens
            final crossAxisCount = constraints.maxWidth > 600 ? 3 : (constraints.maxWidth > 400 ? 2 : 1);
            final childAspectRatio = constraints.maxWidth > 600 ? 1.0 : 1.2;
            
            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio: childAspectRatio,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: collections.length,
              itemBuilder: (context, index) => _CollectionCard(collection: collections[index]),
            );
          },
        );
        },
      ),
    );
  }

  void _showAddCollectionDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    String selectedIcon = CollectionIcons.presets[0];
    int selectedColor = 0xFF2196F3;

    final colors = [
      0xFF2196F3, 0xFF4CAF50, 0xFFFF9800, 0xFFF44336,
      0xFF9C27B0, 0xFF00BCD4, 0xFFE91E63, 0xFF795548,
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('创建收藏集'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: '收藏集名称'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: '描述（可选）'),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                const Text('选择图标'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: CollectionIcons.presets.map((iconName) {
                    final isSelected = iconName == selectedIcon;
                    return GestureDetector(
                      onTap: () => setState(() => selectedIcon = iconName),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.blue.withOpacity(0.2) : Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: isSelected ? Border.all(color: Colors.blue, width: 2) : null,
                        ),
                        child: Icon(_getIconData(iconName), size: 24),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                const Text('选择颜色'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: colors.map((color) {
                    final isSelected = color == selectedColor;
                    return GestureDetector(
                      onTap: () => setState(() => selectedColor = color),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Color(color),
                          borderRadius: BorderRadius.circular(18),
                          border: isSelected ? Border.all(color: Colors.black, width: 2) : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
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
                if (nameController.text.trim().isNotEmpty) {
                  final collection = Collection(
                    name: nameController.text.trim(),
                    description: descController.text.trim().isEmpty ? null : descController.text.trim(),
                    icon: selectedIcon,
                    color: selectedColor,
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  );
                  ref.read(collectionsProvider.notifier).addCollection(collection);
                  Navigator.pop(context);
                }
              },
              child: const Text('创建'),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'folder': return Icons.folder;
      case 'star': return Icons.star;
      case 'favorite': return Icons.favorite;
      case 'work': return Icons.work;
      case 'school': return Icons.school;
      case 'fitness': return Icons.fitness_center;
      case 'music': return Icons.music_note;
      case 'camera': return Icons.camera_alt;
      case 'travel': return Icons.flight;
      case 'home': return Icons.home;
      default: return Icons.folder;
    }
  }
}

class _CollectionCard extends ConsumerWidget {
  final Collection collection;

  const _CollectionCard({required this.collection});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: InkWell(
        onTap: () => _showCollectionDetails(context),
        onLongPress: () => _showOptions(context, ref),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Color(collection.color).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getIconData(collection.icon),
                      color: Color(collection.color),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${collection.recordCount} 条',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                collection.name,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (collection.description != null && collection.description!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  collection.description!,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'folder': return Icons.folder;
      case 'star': return Icons.star;
      case 'favorite': return Icons.favorite;
      case 'work': return Icons.work;
      case 'school': return Icons.school;
      case 'fitness': return Icons.fitness_center;
      case 'music': return Icons.music_note;
      case 'camera': return Icons.camera_alt;
      case 'travel': return Icons.flight;
      case 'home': return Icons.home;
      default: return Icons.folder;
    }
  }

  void _showCollectionDetails(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Color(collection.color).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getIconData(collection.icon),
                color: Color(collection.color),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                collection.name,
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (collection.description != null && collection.description!.isNotEmpty) ...[
              Text(
                collection.description!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
            ],
            Row(
              children: [
                const Icon(Icons.article_outlined, size: 18),
                const SizedBox(width: 8),
                Text(
                  '${collection.recordCount} ${l10n.records}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time, size: 18),
                const SizedBox(width: 8),
                Text(
                  _formatDate(collection.updatedAt),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void _showOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('编辑'),
              onTap: () {
                Navigator.pop(context);
                // TODO: 编辑收藏集
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('删除', style: TextStyle(color: Colors.red)),
              onTap: () {
                ref.read(collectionsProvider.notifier).deleteCollection(collection.id!);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}