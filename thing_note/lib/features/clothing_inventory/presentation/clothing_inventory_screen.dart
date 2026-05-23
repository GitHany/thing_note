import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/clothing_repository.dart';
import '../domain/clothing_item.dart';

final clothingProvider = StateNotifierProvider<ClothingNotifier, AsyncValue<List<ClothingItem>>>((ref) {
  return ClothingNotifier(ref.watch(clothingRepositoryProvider));
});

class ClothingNotifier extends StateNotifier<AsyncValue<List<ClothingItem>>> {
  final ClothingRepository _repository;

  ClothingNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadClothing();
  }

  Future<void> loadClothing() async {
    state = const AsyncValue.loading();
    try {
      final items = await _repository.getAllClothing();
      state = AsyncValue.data(items);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addClothing(ClothingItem item) async {
    await _repository.insertClothing(item);
    await loadClothing();
  }

  Future<void> updateClothing(ClothingItem item) async {
    await _repository.updateClothing(item);
    await loadClothing();
  }

  Future<void> deleteClothing(int id) async {
    await _repository.deleteClothing(id);
    await loadClothing();
  }

  Future<void> incrementWearCount(int id) async {
    await _repository.incrementWearCount(id);
    await loadClothing();
  }
}

class ClothingInventoryScreen extends ConsumerWidget {
  const ClothingInventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clothingAsync = ref.watch(clothingProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('衣橱管理'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
      ),
      body: clothingAsync.when(
        data: (items) => items.isEmpty
            ? const Center(child: Text('衣橱为空'))
            : _buildClothingList(context, ref, items),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('错误: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showClothingDialog(context),
        child: const Icon(Icons.checkroom),
      ),
    );
  }

  Widget _buildClothingList(BuildContext context, WidgetRef ref, List<ClothingItem> items) {
    final grouped = <String, List<ClothingItem>>{};
    for (final item in items) {
      grouped.putIfAbsent(item.category, () => []).add(item);
    }

    return ListView(
      children: grouped.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(entry.key, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(width: 8),
                  Chip(label: Text('${entry.value.length}')),
                ],
              ),
            ),
            ...entry.value.map((item) => _buildClothingItem(context, ref, item)),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildClothingItem(BuildContext context, WidgetRef ref, ClothingItem item) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: item.isFavorite ? Colors.amber : Colors.grey[300],
          child: Icon(item.isFavorite ? Icons.star : Icons.checkroom, color: item.isFavorite ? Colors.white : Colors.grey),
        ),
        title: Text(item.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.brand != null) Text(item.brand!),
            Text('穿着 ${item.wearCount} 次'),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'wear', child: Text('记录穿着')),
            const PopupMenuItem(value: 'favorite', child: Text('收藏')),
            const PopupMenuItem(value: 'edit', child: Text('编辑')),
            const PopupMenuItem(value: 'delete', child: Text('删除')),
          ],
          onSelected: (value) {
            if (value == 'wear') {
              ref.read(clothingProvider.notifier).incrementWearCount(item.id!);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已记录穿着')));
            } else if (value == 'favorite') {
              ref.read(clothingProvider.notifier).updateClothing(item.copyWith(isFavorite: !item.isFavorite));
            } else if (value == 'edit') {
              _showClothingDialog(context, item);
            } else if (value == 'delete') {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('删除衣物'),
                  content: Text('确定要删除 "${item.name}" 吗？'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        ref.read(clothingProvider.notifier).deleteClothing(item.id!);
                      },
                      child: const Text('删除'),
                    ),
                  ],
                ),
              );
            }
          },
        ),
      ),
    );
  }

  void _showClothingDialog(BuildContext context, [ClothingItem? item]) {
    showDialog(context: context, builder: (context) => ClothingFormDialog(item: item));
  }
}

class ClothingFormDialog extends ConsumerStatefulWidget {
  final ClothingItem? item;

  const ClothingFormDialog({super.key, this.item});

  @override
  ConsumerState<ClothingFormDialog> createState() => _ClothingFormDialogState();
}

class _ClothingFormDialogState extends ConsumerState<ClothingFormDialog> {
  late TextEditingController _nameController;
  late TextEditingController _brandController;
  late TextEditingController _sizeController;
  late TextEditingController _priceController;
  late TextEditingController _noteController;
  String _category = '上装';
  String _season = '四季通用';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item?.name ?? '');
    _brandController = TextEditingController(text: widget.item?.brand ?? '');
    _sizeController = TextEditingController(text: widget.item?.size ?? '');
    _priceController = TextEditingController(text: widget.item?.price?.toString() ?? '');
    _noteController = TextEditingController(text: widget.item?.note ?? '');
    if (widget.item != null) {
      _category = widget.item!.category;
      _season = widget.item!.season ?? '四季通用';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.item != null ? '编辑衣物' : '添加衣物'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(labelText: '类别'),
              items: ClothingItem.categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (value) => setState(() => _category = value!),
            ),
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: '名称 *')),
            TextField(controller: _brandController, decoration: const InputDecoration(labelText: '品牌')),
            TextField(controller: _sizeController, decoration: const InputDecoration(labelText: '尺码')),
            TextField(controller: _priceController, decoration: const InputDecoration(labelText: '价格 (¥)'), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
            DropdownButtonFormField<String>(
              value: _season,
              decoration: const InputDecoration(labelText: '季节'),
              items: ClothingItem.seasons.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (value) => setState(() => _season = value!),
            ),
            TextField(controller: _noteController, decoration: const InputDecoration(labelText: '备注'), maxLines: 2),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
        TextButton(
          onPressed: () {
            if (_nameController.text.isEmpty) return;
            final item = ClothingItem(
              id: widget.item?.id,
              name: _nameController.text,
              category: _category,
              brand: _brandController.text.isEmpty ? null : _brandController.text,
              size: _sizeController.text.isEmpty ? null : _sizeController.text,
              price: _priceController.text.isNotEmpty ? double.tryParse(_priceController.text) : null,
              season: _season,
              note: _noteController.text.isEmpty ? null : _noteController.text,
              isFavorite: widget.item?.isFavorite ?? false,
              wearCount: widget.item?.wearCount ?? 0,
              createdAt: widget.item?.createdAt ?? DateTime.now().toIso8601String(),
            );
            if (widget.item != null) {
              ref.read(clothingProvider.notifier).updateClothing(item);
            } else {
              ref.read(clothingProvider.notifier).addClothing(item);
            }
            Navigator.pop(context);
          },
          child: Text(widget.item != null ? '保存' : '添加'),
        ),
      ],
    );
  }
}