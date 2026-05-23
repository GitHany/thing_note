import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/warranty_repository.dart';
import '../domain/warranty_entry.dart';

final warrantyProvider = StateNotifierProvider<WarrantyNotifier, AsyncValue<List<WarrantyEntry>>>((ref) {
  return WarrantyNotifier(ref.watch(warrantyRepositoryProvider));
});

class WarrantyNotifier extends StateNotifier<AsyncValue<List<WarrantyEntry>>> {
  final WarrantyRepository _repository;

  WarrantyNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadWarranties();
  }

  Future<void> loadWarranties() async {
    state = const AsyncValue.loading();
    try {
      final warranties = await _repository.getAllWarranties();
      state = AsyncValue.data(warranties);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addWarranty(WarrantyEntry warranty) async {
    await _repository.insertWarranty(warranty);
    await loadWarranties();
  }

  Future<void> updateWarranty(WarrantyEntry warranty) async {
    await _repository.updateWarranty(warranty);
    await loadWarranties();
  }

  Future<void> deleteWarranty(int id) async {
    await _repository.deleteWarranty(id);
    await loadWarranties();
  }
}

class WarrantyTrackerScreen extends ConsumerWidget {
  const WarrantyTrackerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final warrantiesAsync = ref.watch(warrantyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('保修追踪'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
      ),
      body: warrantiesAsync.when(
        data: (warranties) => warranties.isEmpty
            ? const Center(child: Text('暂无保修记录'))
            : _buildWarrantyList(context, ref, warranties),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('错误: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showWarrantyDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildWarrantyList(BuildContext context, WidgetRef ref, List<WarrantyEntry> warranties) {
    final active = warranties.where((w) => !w.isExpired).toList();
    final expired = warranties.where((w) => w.isExpired).toList();
    final expiringSoon = active.where((w) => w.daysRemaining != null && w.daysRemaining! <= 30).toList();

    return CustomScrollView(
      slivers: [
        if (expiringSoon.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.orange),
                  const SizedBox(width: 8),
                  Text('${expiringSoon.length} 项保修即将过期', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                ],
              ),
            ),
          ),
        ],
        if (active.isNotEmpty) ...[
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text('有效保修 (${active.length})', style: Theme.of(context).textTheme.titleMedium),
          )),
          SliverList(delegate: SliverChildBuilderDelegate(
            (context, index) => _buildWarrantyItem(context, ref, active[index]),
            childCount: active.length,
          )),
        ],
        if (expired.isNotEmpty) ...[
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text('已过期 (${expired.length})', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey)),
          )),
          SliverList(delegate: SliverChildBuilderDelegate(
            (context, index) => _buildWarrantyItem(context, ref, expired[index]),
            childCount: expired.length,
          )),
        ],
      ],
    );
  }

  Widget _buildWarrantyItem(BuildContext context, WidgetRef ref, WarrantyEntry warranty) {
    final isExpired = warranty.isExpired;
    final daysRemaining = warranty.daysRemaining;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isExpired ? Colors.grey : Colors.green,
          child: const Icon(Icons.verified_user, color: Colors.white),
        ),
        title: Text(warranty.name, style: TextStyle(decoration: isExpired ? TextDecoration.lineThrough : null)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (warranty.brand != null) Text(warranty.brand!),
            if (warranty.expiryDate != null)
              Text(
                isExpired ? '已过期' : '剩余 $daysRemaining 天',
                style: TextStyle(color: isExpired ? Colors.red : daysRemaining != null && daysRemaining <= 30 ? Colors.orange : Colors.green),
              ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Text('编辑')),
            const PopupMenuItem(value: 'delete', child: Text('删除')),
          ],
          onSelected: (value) {
            if (value == 'edit') {
              _showWarrantyDialog(context, warranty);
            } else if (value == 'delete') {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('删除保修'),
                  content: Text('确定要删除 "${warranty.name}" 吗？'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        ref.read(warrantyProvider.notifier).deleteWarranty(warranty.id!);
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

  void _showWarrantyDialog(BuildContext context, [WarrantyEntry? warranty]) {
    showDialog(context: context, builder: (context) => WarrantyFormDialog(warranty: warranty));
  }
}

class WarrantyFormDialog extends ConsumerStatefulWidget {
  final WarrantyEntry? warranty;

  const WarrantyFormDialog({super.key, this.warranty});

  @override
  ConsumerState<WarrantyFormDialog> createState() => _WarrantyFormDialogState();
}

class _WarrantyFormDialogState extends ConsumerState<WarrantyFormDialog> {
  late TextEditingController _nameController;
  late TextEditingController _brandController;
  late TextEditingController _modelController;
  late TextEditingController _serialController;
  late TextEditingController _priceController;
  late TextEditingController _storeController;
  late TextEditingController _noteController;
  DateTime? _purchaseDate;
  DateTime? _expiryDate;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.warranty?.name ?? '');
    _brandController = TextEditingController(text: widget.warranty?.brand ?? '');
    _modelController = TextEditingController(text: widget.warranty?.model ?? '');
    _serialController = TextEditingController(text: widget.warranty?.serialNumber ?? '');
    _priceController = TextEditingController(text: widget.warranty?.purchasePrice?.toString() ?? '');
    _storeController = TextEditingController(text: widget.warranty?.store ?? '');
    _noteController = TextEditingController(text: widget.warranty?.note ?? '');
    if (widget.warranty?.purchaseDate != null) {
      _purchaseDate = DateTime.tryParse(widget.warranty!.purchaseDate!);
    }
    if (widget.warranty?.expiryDate != null) {
      _expiryDate = DateTime.tryParse(widget.warranty!.expiryDate!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.warranty != null ? '编辑保修' : '添加保修'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: '产品名称 *')),
            TextField(controller: _brandController, decoration: const InputDecoration(labelText: '品牌')),
            TextField(controller: _modelController, decoration: const InputDecoration(labelText: '型号')),
            TextField(controller: _serialController, decoration: const InputDecoration(labelText: '序列号')),
            TextField(controller: _priceController, decoration: const InputDecoration(labelText: '购买价格 (¥)'), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
            TextField(controller: _storeController, decoration: const InputDecoration(labelText: '购买渠道')),
            ListTile(
              title: const Text('购买日期'),
              subtitle: Text(_purchaseDate != null ? '${_purchaseDate!.year}-${_purchaseDate!.month}-${_purchaseDate!.day}' : '未设置'),
              onTap: () async {
                final date = await showDatePicker(context: context, initialDate: _purchaseDate ?? DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime.now());
                if (date != null) setState(() => _purchaseDate = date);
              },
            ),
            ListTile(
              title: const Text('保修到期日期'),
              subtitle: Text(_expiryDate != null ? '${_expiryDate!.year}-${_expiryDate!.month}-${_expiryDate!.day}' : '未设置'),
              onTap: () async {
                final date = await showDatePicker(context: context, initialDate: _expiryDate ?? DateTime.now().add(const Duration(days: 365)), firstDate: DateTime.now(), lastDate: DateTime(2030));
                if (date != null) setState(() => _expiryDate = date);
              },
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
            final warranty = WarrantyEntry(
              id: widget.warranty?.id,
              name: _nameController.text,
              brand: _brandController.text.isEmpty ? null : _brandController.text,
              model: _modelController.text.isEmpty ? null : _modelController.text,
              serialNumber: _serialController.text.isEmpty ? null : _serialController.text,
              purchaseDate: _purchaseDate?.toIso8601String().split('T')[0],
              expiryDate: _expiryDate?.toIso8601String().split('T')[0],
              purchasePrice: _priceController.text.isNotEmpty ? double.tryParse(_priceController.text) : null,
              store: _storeController.text.isEmpty ? null : _storeController.text,
              note: _noteController.text.isEmpty ? null : _noteController.text,
              isActive: true,
              createdAt: widget.warranty?.createdAt ?? DateTime.now().toIso8601String(),
            );
            if (widget.warranty != null) {
              ref.read(warrantyProvider.notifier).updateWarranty(warranty);
            } else {
              ref.read(warrantyProvider.notifier).addWarranty(warranty);
            }
            Navigator.pop(context);
          },
          child: Text(widget.warranty != null ? '保存' : '添加'),
        ),
      ],
    );
  }
}