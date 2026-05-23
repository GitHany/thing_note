import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/invoice_repository.dart';
import '../domain/invoice_entry.dart';

final invoiceProvider = StateNotifierProvider<InvoiceNotifier, AsyncValue<List<InvoiceEntry>>>((ref) {
  return InvoiceNotifier(ref.watch(invoiceRepositoryProvider));
});

class InvoiceNotifier extends StateNotifier<AsyncValue<List<InvoiceEntry>>> {
  final InvoiceRepository _repository;

  InvoiceNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadInvoices();
  }

  Future<void> loadInvoices() async {
    state = const AsyncValue.loading();
    try {
      final invoices = await _repository.getAllInvoices();
      state = AsyncValue.data(invoices);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addInvoice(InvoiceEntry invoice) async {
    await _repository.insertInvoice(invoice);
    await loadInvoices();
  }

  Future<void> updateInvoice(InvoiceEntry invoice) async {
    await _repository.updateInvoice(invoice);
    await loadInvoices();
  }

  Future<void> deleteInvoice(int id) async {
    await _repository.deleteInvoice(id);
    await loadInvoices();
  }

  Future<void> markAsPaid(int id) async {
    final invoice = await _repository.getInvoiceById(id);
    if (invoice != null) {
      final updated = invoice.copyWith(
        status: 'paid',
        paidDate: DateTime.now().toIso8601String().split('T')[0],
      );
      await _repository.updateInvoice(updated);
      await loadInvoices();
    }
  }
}

class InvoiceManagerScreen extends ConsumerWidget {
  const InvoiceManagerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoicesAsync = ref.watch(invoiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('发票管理'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
      ),
      body: invoicesAsync.when(
        data: (invoices) => invoices.isEmpty
            ? const Center(child: Text('暂无发票'))
            : _buildInvoiceList(context, ref, invoices),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('错误: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showInvoiceDialog(context, ref),
        child: const Icon(Icons.receipt_long),
      ),
    );
  }

  Widget _buildInvoiceList(BuildContext context, WidgetRef ref, List<InvoiceEntry> invoices) {
    final pending = invoices.where((i) => i.status == 'pending' || i.status == 'sent' || i.status == 'overdue').toList();
    final paid = invoices.where((i) => i.status == 'paid').toList();
    final totalPending = pending.fold(0.0, (sum, i) => sum + i.amount);
    final totalPaid = paid.fold(0.0, (sum, i) => sum + i.amount);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(context, '¥${totalPending.toStringAsFixed(0)}', '待收款', Colors.orange),
                  _buildStatItem(context, '¥${totalPaid.toStringAsFixed(0)}', '已收款', Colors.green),
                  _buildStatItem(context, '${invoices.length}', '发票数', Colors.blue),
                ],
              ),
            ),
          ),
        ),
        if (pending.isNotEmpty) ...[
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text('待处理 (${pending.length})', style: Theme.of(context).textTheme.titleMedium),
          )),
          SliverList(delegate: SliverChildBuilderDelegate(
            (context, index) => _buildInvoiceItem(context, ref, pending[index]),
            childCount: pending.length,
          )),
        ],
        if (paid.isNotEmpty) ...[
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text('已完成 (${paid.length})', style: Theme.of(context).textTheme.titleMedium),
          )),
          SliverList(delegate: SliverChildBuilderDelegate(
            (context, index) => _buildInvoiceItem(context, ref, paid[index]),
            childCount: paid.length,
          )),
        ],
      ],
    );
  }

  Widget _buildStatItem(BuildContext context, String value, String label, Color color) {
    return Column(
      children: [
        Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: color, fontWeight: FontWeight.bold)),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Widget _buildInvoiceItem(BuildContext context, WidgetRef ref, InvoiceEntry invoice) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(invoice.status),
          child: const Icon(Icons.receipt, color: Colors.white),
        ),
        title: Text(invoice.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (invoice.clientName != null) Text(invoice.clientName!),
            Text('¥${invoice.amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Chip(
              label: Text(InvoiceEntry.getStatusLabel(invoice.status), style: const TextStyle(fontSize: 12)),
              backgroundColor: _getStatusColor(invoice.status).withAlpha(51),
            ),
            PopupMenuButton(
              itemBuilder: (context) => [
                if (invoice.status != 'paid') const PopupMenuItem(value: 'mark_paid', child: Text('标记已支付')),
                const PopupMenuItem(value: 'edit', child: Text('编辑')),
                const PopupMenuItem(value: 'delete', child: Text('删除')),
              ],
              onSelected: (value) {
                if (value == 'mark_paid') {
                  ref.read(invoiceProvider.notifier).markAsPaid(invoice.id!);
                } else if (value == 'edit') {
                  _showInvoiceDialog(context, ref, invoice);
                } else if (value == 'delete') {
                  _showDeleteDialog(context, ref, invoice);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    const colors = {
      'draft': Colors.grey,
      'sent': Colors.blue,
      'paid': Colors.green,
      'overdue': Colors.red,
      'cancelled': Colors.grey,
    };
    return colors[status] ?? Colors.grey;
  }

  void _showInvoiceDialog(BuildContext context, WidgetRef ref, [InvoiceEntry? invoice]) {
    showDialog(context: context, builder: (context) => InvoiceFormDialog(invoice: invoice));
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, InvoiceEntry invoice) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除发票'),
        content: Text('确定要删除 "${invoice.title}" 吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(invoiceProvider.notifier).deleteInvoice(invoice.id!);
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}

class InvoiceFormDialog extends ConsumerStatefulWidget {
  final InvoiceEntry? invoice;

  const InvoiceFormDialog({super.key, this.invoice});

  @override
  ConsumerState<InvoiceFormDialog> createState() => _InvoiceFormDialogState();
}

class _InvoiceFormDialogState extends ConsumerState<InvoiceFormDialog> {
  late TextEditingController _titleController;
  late TextEditingController _clientNameController;
  late TextEditingController _clientEmailController;
  late TextEditingController _amountController;
  late TextEditingController _noteController;
  String _status = 'draft';

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.invoice?.title ?? '');
    _clientNameController = TextEditingController(text: widget.invoice?.clientName ?? '');
    _clientEmailController = TextEditingController(text: widget.invoice?.clientEmail ?? '');
    _amountController = TextEditingController(text: widget.invoice?.amount.toString() ?? '');
    _noteController = TextEditingController(text: widget.invoice?.note ?? '');
    if (widget.invoice != null) _status = widget.invoice!.status;
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.invoice != null;

    return AlertDialog(
      title: Text(isEditing ? '编辑发票' : '添加发票'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _titleController, decoration: const InputDecoration(labelText: '发票标题 *')),
            TextField(controller: _clientNameController, decoration: const InputDecoration(labelText: '客户名称')),
            TextField(controller: _clientEmailController, decoration: const InputDecoration(labelText: '客户邮箱')),
            TextField(controller: _amountController, decoration: const InputDecoration(labelText: '金额 (¥) *'), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
            DropdownButtonFormField<String>(
              value: _status,
              decoration: const InputDecoration(labelText: '状态'),
              items: InvoiceEntry.statuses.map((s) => DropdownMenuItem(value: s, child: Text(InvoiceEntry.getStatusLabel(s)))).toList(),
              onChanged: (value) => setState(() => _status = value!),
            ),
            TextField(controller: _noteController, decoration: const InputDecoration(labelText: '备注'), maxLines: 2),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
        TextButton(
          onPressed: () async {
            if (_titleController.text.isEmpty || _amountController.text.isEmpty) return;

            final invoiceNumber = isEditing ? widget.invoice!.invoiceNumber : 
                'INV-${await ref.read(invoiceRepositoryProvider).generateInvoiceNumber()}';

            final invoice = InvoiceEntry(
              id: widget.invoice?.id,
              title: _titleController.text,
              clientName: _clientNameController.text.isEmpty ? null : _clientNameController.text,
              clientEmail: _clientEmailController.text.isEmpty ? null : _clientEmailController.text,
              amount: double.tryParse(_amountController.text) ?? 0,
              status: _status,
              invoiceNumber: invoiceNumber,
              note: _noteController.text.isEmpty ? null : _noteController.text,
              createdAt: widget.invoice?.createdAt ?? DateTime.now().toIso8601String(),
            );

            if (isEditing) {
              ref.read(invoiceProvider.notifier).updateInvoice(invoice);
            } else {
              ref.read(invoiceProvider.notifier).addInvoice(invoice);
            }
            if (!context.mounted) return;
            Navigator.pop(context);
          },
          child: Text(isEditing ? '保存' : '添加'),
        ),
      ],
    );
  }
}