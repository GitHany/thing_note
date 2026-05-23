import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/gift_list/data/gift_list_repository.dart';
import 'package:thing_note/features/gift_list/domain/gift_item.dart';

class GiftListScreen extends ConsumerStatefulWidget {
  const GiftListScreen({super.key});

  @override
  ConsumerState<GiftListScreen> createState() => _GiftListScreenState();
}

class _GiftListScreenState extends ConsumerState<GiftListScreen> {
  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(giftItemsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('礼物清单'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddGiftDialog(context),
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
                  const Icon(Icons.card_giftcard, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('暂无礼物清单', style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => _showAddGiftDialog(context),
                    child: const Text('添加礼物'),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) => _GiftItemCard(item: items[index]),
          );
        },
      ),
    );
  }

  void _showAddGiftDialog(BuildContext context) {
    final recipientController = TextEditingController();
    final titleController = TextEditingController();
    final priceController = TextEditingController();
    GiftPriority priority = GiftPriority.medium;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('添加礼物'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: recipientController,
                  decoration: const InputDecoration(labelText: '送给谁'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: '礼物名称'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: priceController,
                  decoration: const InputDecoration(labelText: '预算（可选）'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                DropdownButton<GiftPriority>(
                  value: priority,
                  isExpanded: true,
                  items: GiftPriority.values.map((p) {
                    return DropdownMenuItem(
                      value: p,
                      child: Text(p.displayName),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => priority = v!),
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
                if (recipientController.text.trim().isNotEmpty && titleController.text.trim().isNotEmpty) {
                  final now = DateTime.now();
                  final item = GiftItem(
                    recipient: recipientController.text.trim(),
                    title: titleController.text.trim(),
                    price: double.tryParse(priceController.text),
                    priority: priority,
                    createdAt: now,
                    updatedAt: now,
                  );
                  ref.read(giftItemsProvider.notifier).addGiftItem(item);
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

class _GiftItemCard extends ConsumerWidget {
  final GiftItem item;

  const _GiftItemCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Color priorityColor;
    switch (item.priority) {
      case GiftPriority.urgent:
        priorityColor = Colors.red;
        break;
      case GiftPriority.high:
        priorityColor = Colors.orange;
        break;
      case GiftPriority.medium:
        priorityColor = Colors.blue;
        break;
      case GiftPriority.low:
        priorityColor = Colors.grey;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: priorityColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.card_giftcard, color: Colors.pink),
        ),
        title: Text(item.title),
        subtitle: Text('送给: ${item.recipient}'),
        trailing: item.status == GiftStatus.pending
            ? ElevatedButton(
                onPressed: () => ref.read(giftItemsProvider.notifier).markAsPurchased(item.id!),
                child: const Text('已购'),
              )
            : const Chip(label: Text('已送')),
      ),
    );
  }
}