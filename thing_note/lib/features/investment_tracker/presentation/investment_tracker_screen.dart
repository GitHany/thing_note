import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/investment_repository.dart';
import '../domain/investment_entry.dart';

final investmentProvider = StateNotifierProvider<InvestmentNotifier, AsyncValue<List<InvestmentEntry>>>((ref) {
  return InvestmentNotifier(ref.watch(investmentRepositoryProvider));
});

class InvestmentNotifier extends StateNotifier<AsyncValue<List<InvestmentEntry>>> {
  final InvestmentRepository _repository;

  InvestmentNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadInvestments();
  }

  Future<void> loadInvestments() async {
    state = const AsyncValue.loading();
    try {
      final investments = await _repository.getAllInvestments();
      state = AsyncValue.data(investments);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addInvestment(InvestmentEntry investment) async {
    await _repository.insertInvestment(investment);
    await loadInvestments();
  }

  Future<void> updateInvestment(InvestmentEntry investment) async {
    await _repository.updateInvestment(investment);
    await loadInvestments();
  }

  Future<void> deleteInvestment(int id) async {
    await _repository.deleteInvestment(id);
    await loadInvestments();
  }
}

class InvestmentTrackerScreen extends ConsumerWidget {
  const InvestmentTrackerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final investmentsAsync = ref.watch(investmentProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('投资追踪'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
      ),
      body: investmentsAsync.when(
        data: (investments) => investments.isEmpty
            ? const Center(child: Text('暂无投资'))
            : _buildInvestmentList(context, ref, investments),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('错误: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showInvestmentDialog(context),
        child: const Icon(Icons.trending_up),
      ),
    );
  }

  Widget _buildInvestmentList(BuildContext context, WidgetRef ref, List<InvestmentEntry> investments) {
    final totalInvested = investments.fold(0.0, (sum, i) => sum + i.amount);
    final totalCurrent = investments.fold(0.0, (sum, i) => sum + (i.currentValue ?? i.amount));
    final totalReturn = totalCurrent - totalInvested;
    final returnRate = totalInvested > 0 ? (totalReturn / totalInvested) * 100 : 0.0;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(context, '¥${totalInvested.toStringAsFixed(0)}', '投入本金'),
                      _buildStatItem(context, '¥${totalCurrent.toStringAsFixed(0)}', '当前价值'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: returnRate >= 0 ? Colors.green.withAlpha(25) : Colors.red.withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(returnRate >= 0 ? Icons.trending_up : Icons.trending_down, color: returnRate >= 0 ? Colors.green : Colors.red),
                        const SizedBox(width: 8),
                        Text(
                          '${returnRate >= 0 ? '+' : ''}${returnRate.toStringAsFixed(2)}%',
                          style: TextStyle(color: returnRate >= 0 ? Colors.green : Colors.red, fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => _buildInvestmentItem(context, ref, investments[index]),
            childCount: investments.length,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(BuildContext context, String value, String label) {
    return Column(
      children: [
        Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Widget _buildInvestmentItem(BuildContext context, WidgetRef ref, InvestmentEntry investment) {
    final returnRate = investment.returnRate;
    final isPositive = returnRate >= 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getTypeColor(investment.type),
          child: Text(investment.type[0], style: const TextStyle(color: Colors.white)),
        ),
        title: Text(investment.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('¥${investment.amount.toStringAsFixed(0)}'),
            if (investment.ticker != null) Text(investment.ticker!, style: const TextStyle(fontSize: 12)),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (investment.currentValue != null)
              Text('¥${investment.currentValue!.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(
              '${isPositive ? '+' : ''}${returnRate.toStringAsFixed(2)}%',
              style: TextStyle(color: isPositive ? Colors.green : Colors.red, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        onLongPress: () => _showDeleteDialog(context, ref, investment),
        onTap: () => _showUpdateDialog(context, ref, investment),
      ),
    );
  }

  Color _getTypeColor(String type) {
    final colors = {
      '股票': Colors.blue, '基金': Colors.green, '债券': Colors.orange,
      '房产': Colors.purple, '黄金': Colors.amber, '数字货币': Colors.pink,
      '定期存款': Colors.teal, '理财': Colors.indigo, '其他': Colors.grey,
    };
    return colors[type] ?? Colors.grey;
  }

  void _showInvestmentDialog(BuildContext context, [InvestmentEntry? investment]) {
    showDialog(context: context, builder: (context) => InvestmentFormDialog(investment: investment));
  }

  void _showUpdateDialog(BuildContext context, WidgetRef ref, InvestmentEntry investment) {
    showDialog(context: context, builder: (context) => UpdateValueDialog(investment: investment));
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, InvestmentEntry investment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除投资'),
        content: Text('确定要删除 "${investment.name}" 吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(investmentProvider.notifier).deleteInvestment(investment.id!);
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}

class InvestmentFormDialog extends ConsumerStatefulWidget {
  final InvestmentEntry? investment;

  const InvestmentFormDialog({super.key, this.investment});

  @override
  ConsumerState<InvestmentFormDialog> createState() => _InvestmentFormDialogState();
}

class _InvestmentFormDialogState extends ConsumerState<InvestmentFormDialog> {
  late TextEditingController _nameController;
  late TextEditingController _amountController;
  late TextEditingController _currentValueController;
  late TextEditingController _tickerController;
  late TextEditingController _noteController;
  String _type = '股票';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.investment?.name ?? '');
    _amountController = TextEditingController(text: widget.investment?.amount.toString() ?? '');
    _currentValueController = TextEditingController(text: widget.investment?.currentValue?.toString() ?? '');
    _tickerController = TextEditingController(text: widget.investment?.ticker ?? '');
    _noteController = TextEditingController(text: widget.investment?.note ?? '');
    if (widget.investment != null) _type = widget.investment!.type;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.investment != null ? '编辑投资' : '添加投资'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _type,
              decoration: const InputDecoration(labelText: '类型'),
              items: InvestmentEntry.types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (value) => setState(() => _type = value!),
            ),
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: '名称 *')),
            TextField(controller: _amountController, decoration: const InputDecoration(labelText: '投入金额 *'), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
            TextField(controller: _currentValueController, decoration: const InputDecoration(labelText: '当前价值'), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
            TextField(controller: _tickerController, decoration: const InputDecoration(labelText: '代码/编号 (可选)')),
            TextField(controller: _noteController, decoration: const InputDecoration(labelText: '备注'), maxLines: 2),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
        TextButton(
          onPressed: () {
            if (_nameController.text.isEmpty || _amountController.text.isEmpty) return;
            final investment = InvestmentEntry(
              id: widget.investment?.id,
              name: _nameController.text,
              type: _type,
              amount: double.tryParse(_amountController.text) ?? 0,
              currentValue: _currentValueController.text.isNotEmpty ? double.tryParse(_currentValueController.text) : null,
              ticker: _tickerController.text.isEmpty ? null : _tickerController.text,
              note: _noteController.text.isEmpty ? null : _noteController.text,
              createdAt: widget.investment?.createdAt ?? DateTime.now().toIso8601String(),
            );
            if (widget.investment != null) {
              ref.read(investmentProvider.notifier).updateInvestment(investment);
            } else {
              ref.read(investmentProvider.notifier).addInvestment(investment);
            }
            Navigator.pop(context);
          },
          child: Text(widget.investment != null ? '保存' : '添加'),
        ),
      ],
    );
  }
}

class UpdateValueDialog extends ConsumerStatefulWidget {
  final InvestmentEntry investment;

  const UpdateValueDialog({super.key, required this.investment});

  @override
  ConsumerState<UpdateValueDialog> createState() => _UpdateValueDialogState();
}

class _UpdateValueDialogState extends ConsumerState<UpdateValueDialog> {
  late TextEditingController _currentValueController;

  @override
  void initState() {
    super.initState();
    _currentValueController = TextEditingController(text: widget.investment.currentValue?.toString() ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('更新当前价值'),
      content: TextField(
        controller: _currentValueController,
        decoration: const InputDecoration(labelText: '当前价值 (¥)'),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
        TextButton(
          onPressed: () {
            final newValue = double.tryParse(_currentValueController.text);
            if (newValue != null) {
              final updated = widget.investment.copyWith(currentValue: newValue);
              ref.read(investmentProvider.notifier).updateInvestment(updated);
            }
            Navigator.pop(context);
          },
          child: const Text('更新'),
        ),
      ],
    );
  }
}