import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/maintenance_log/data/maintenance_repository.dart';
import 'package:thing_note/features/maintenance_log/domain/maintenance_item.dart';

class MaintenanceLogScreen extends ConsumerStatefulWidget {
  const MaintenanceLogScreen({super.key});

  @override
  ConsumerState<MaintenanceLogScreen> createState() => _MaintenanceLogScreenState();
}

class _MaintenanceLogScreenState extends ConsumerState<MaintenanceLogScreen> {
  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(maintenanceItemsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('维修记录'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddItemDialog(context),
          ),
        ],
      ),
      body: itemsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('错误: $e')),
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.build, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('暂无维修记录', style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => _showAddItemDialog(context),
                    child: const Text('添加物品'),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) => _MaintenanceItemCard(item: items[index]),
          );
        },
      ),
    );
  }

  void _showAddItemDialog(BuildContext context) {
    final nameController = TextEditingController();
    final brandController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加物品'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: '物品名称'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: brandController,
                decoration: const InputDecoration(labelText: '品牌（可选）'),
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
                final now = DateTime.now();
                final item = MaintenanceItem(
                  name: nameController.text.trim(),
                  brand: brandController.text.trim().isEmpty ? null : brandController.text.trim(),
                  createdAt: now,
                  updatedAt: now,
                );
                ref.read(maintenanceItemsProvider.notifier).addMaintenanceItem(item);
                Navigator.pop(context);
              }
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }
}

class _MaintenanceItemCard extends ConsumerWidget {
  final MaintenanceItem item;

  const _MaintenanceItemCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: item.isUnderWarranty ? Colors.green.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
          child: Icon(Icons.build, color: item.isUnderWarranty ? Colors.green : Colors.grey),
        ),
        title: Text(item.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.brand != null) Text('品牌: ${item.brand}'),
            if (item.warrantyEndDate != null)
              Text(
                item.isUnderWarranty ? '保修中' : '已过保',
                style: TextStyle(
                  color: item.isUnderWarranty ? Colors.green : Colors.red,
                  fontSize: 12,
                ),
              ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: () => ref.read(maintenanceItemsProvider.notifier).deleteMaintenanceItem(item.id!),
        ),
      ),
    );
  }
}