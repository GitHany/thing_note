import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/receipt_collection/data/receipt_repository.dart';
import 'package:thing_note/features/receipt_collection/domain/receipt.dart';

class ReceiptCollectionScreen extends ConsumerStatefulWidget {
  const ReceiptCollectionScreen({super.key});

  @override
  ConsumerState<ReceiptCollectionScreen> createState() => _ReceiptCollectionScreenState();
}

class _ReceiptCollectionScreenState extends ConsumerState<ReceiptCollectionScreen> {
  @override
  Widget build(BuildContext context) {
    final receiptsAsync = ref.watch(receiptsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('发票收集'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddReceiptDialog(context),
          ),
        ],
      ),
      body: receiptsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('错误: $e')),
        data: (receipts) {
          if (receipts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('暂无发票', style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => _showAddReceiptDialog(context),
                    child: const Text('添加发票'),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: receipts.length,
            itemBuilder: (context, index) => _ReceiptCard(receipt: receipts[index]),
          );
        },
      ),
    );
  }

  void _showAddReceiptDialog(BuildContext context) {
    final merchantController = TextEditingController();
    final amountController = TextEditingController();
    final categoryController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加发票'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: merchantController,
                decoration: const InputDecoration(labelText: '商家名称'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                decoration: const InputDecoration(labelText: '金额'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: categoryController,
                decoration: const InputDecoration(labelText: '分类（可选）'),
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
              final now = DateTime.now();
              final receipt = Receipt(
                merchant: merchantController.text.trim().isEmpty ? null : merchantController.text.trim(),
                amount: double.tryParse(amountController.text),
                category: categoryController.text.trim().isEmpty ? null : categoryController.text.trim(),
                purchaseDate: now,
                createdAt: now,
                updatedAt: now,
              );
              ref.read(receiptsProvider.notifier).addReceipt(receipt);
              Navigator.pop(context);
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }
}

class _ReceiptCard extends ConsumerWidget {
  final Receipt receipt;

  const _ReceiptCard({required this.receipt});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: receipt.isClaimed ? Colors.grey : Colors.green.withOpacity(0.2),
          child: const Icon(Icons.receipt_long, color: Colors.green),
        ),
        title: Text(receipt.merchant ?? '未知商家'),
        subtitle: Text(
          receipt.amount != null ? '¥${receipt.amount!.toStringAsFixed(2)}' : '金额未知',
        ),
        trailing: receipt.isClaimed
            ? const Chip(label: Text('已报销'))
            : ElevatedButton(
                onPressed: () => ref.read(receiptsProvider.notifier).markAsClaimed(receipt.id!),
                child: const Text('报销'),
              ),
      ),
    );
  }
}