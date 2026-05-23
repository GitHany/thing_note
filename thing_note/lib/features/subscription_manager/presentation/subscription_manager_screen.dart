import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/subscription_repository.dart';
import '../domain/subscription_entry.dart';

final subscriptionProvider = StateNotifierProvider<SubscriptionNotifier, AsyncValue<List<SubscriptionEntry>>>((ref) {
  return SubscriptionNotifier(ref.watch(subscriptionRepositoryProvider));
});

class SubscriptionNotifier extends StateNotifier<AsyncValue<List<SubscriptionEntry>>> {
  final SubscriptionRepository _repository;

  SubscriptionNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadSubscriptions();
  }

  Future<void> loadSubscriptions() async {
    state = const AsyncValue.loading();
    try {
      final subscriptions = await _repository.getAllSubscriptions();
      state = AsyncValue.data(subscriptions);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addSubscription(SubscriptionEntry subscription) async {
    await _repository.insertSubscription(subscription);
    await loadSubscriptions();
  }

  Future<void> updateSubscription(SubscriptionEntry subscription) async {
    await _repository.updateSubscription(subscription);
    await loadSubscriptions();
  }

  Future<void> deleteSubscription(int id) async {
    await _repository.deleteSubscription(id);
    await loadSubscriptions();
  }
}

class SubscriptionManagerScreen extends ConsumerWidget {
  const SubscriptionManagerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptionsAsync = ref.watch(subscriptionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('订阅管理'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
      ),
      body: subscriptionsAsync.when(
        data: (subscriptions) => subscriptions.isEmpty
            ? const Center(child: Text('暂无订阅'))
            : _buildSubscriptionList(context, ref, subscriptions),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('错误: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showSubscriptionDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSubscriptionList(BuildContext context, WidgetRef ref, List<SubscriptionEntry> subscriptions) {
    final activeSubscriptions = subscriptions.where((s) => s.isActive).toList();
    final inactiveSubscriptions = subscriptions.where((s) => !s.isActive).toList();

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildSummaryCard(context, activeSubscriptions)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text('活跃订阅 (${activeSubscriptions.length})', style: Theme.of(context).textTheme.titleMedium),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => _buildSubscriptionItem(context, ref, activeSubscriptions[index]),
            childCount: activeSubscriptions.length,
          ),
        ),
        if (inactiveSubscriptions.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('已取消 (${inactiveSubscriptions.length})', style: Theme.of(context).textTheme.titleMedium),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildSubscriptionItem(context, ref, inactiveSubscriptions[index]),
              childCount: inactiveSubscriptions.length,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSummaryCard(BuildContext context, List<SubscriptionEntry> activeSubscriptions) {
    final monthlyTotal = activeSubscriptions.fold(0.0, (sum, s) {
      switch (s.billingCycle) {
        case 'monthly': return sum + s.amount;
        case 'yearly': return sum + s.amount / 12;
        case 'quarterly': return sum + s.amount / 3;
        default: return sum + s.amount;
      }
    });

    final yearlyTotal = activeSubscriptions.fold(0.0, (sum, s) => sum + s.yearlyAmount);

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(context, '¥${monthlyTotal.toStringAsFixed(0)}', '每月'),
                _buildStatItem(context, '¥${yearlyTotal.toStringAsFixed(0)}', '每年'),
                _buildStatItem(context, '${activeSubscriptions.length}', '订阅数'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String value, String label) {
    return Column(
      children: [
        Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Widget _buildSubscriptionItem(BuildContext context, WidgetRef ref, SubscriptionEntry subscription) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: subscription.isActive ? Theme.of(context).primaryColor : Colors.grey,
          child: const Icon(Icons.subscriptions, color: Colors.white),
        ),
        title: Text(subscription.name),
        subtitle: Text('${subscription.billingCycle == 'monthly' ? '每月' : subscription.billingCycle == 'yearly' ? '每年' : subscription.billingCycle} ¥${subscription.amount.toStringAsFixed(0)}'),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Text('编辑')),
            const PopupMenuItem(value: 'toggle', child: Text('取消订阅')),
            const PopupMenuItem(value: 'delete', child: Text('删除')),
          ],
          onSelected: (value) {
            if (value == 'edit') {
              _showSubscriptionDialog(context, subscription);
            } else if (value == 'toggle') {
              ref.read(subscriptionProvider.notifier).updateSubscription(
                subscription.copyWith(isActive: !subscription.isActive));
            } else if (value == 'delete') {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('删除订阅'),
                  content: Text('确定要删除 "${subscription.name}" 吗？'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        ref.read(subscriptionProvider.notifier).deleteSubscription(subscription.id!);
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

  void _showSubscriptionDialog(BuildContext context, [SubscriptionEntry? subscription]) {
    showDialog(context: context, builder: (context) => SubscriptionFormDialog(subscription: subscription));
  }
}

class SubscriptionFormDialog extends ConsumerStatefulWidget {
  final SubscriptionEntry? subscription;

  const SubscriptionFormDialog({super.key, this.subscription});

  @override
  ConsumerState<SubscriptionFormDialog> createState() => _SubscriptionFormDialogState();
}

class _SubscriptionFormDialogState extends ConsumerState<SubscriptionFormDialog> {
  late TextEditingController _nameController;
  late TextEditingController _amountController;
  late TextEditingController _websiteController;
  late TextEditingController _noteController;
  String _billingCycle = 'monthly';
  String? _category;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.subscription?.name ?? '');
    _amountController = TextEditingController(text: widget.subscription?.amount.toString() ?? '');
    _websiteController = TextEditingController(text: widget.subscription?.website ?? '');
    _noteController = TextEditingController(text: widget.subscription?.note ?? '');
    if (widget.subscription != null) {
      _billingCycle = widget.subscription!.billingCycle;
      _category = widget.subscription!.category;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.subscription != null;

    return AlertDialog(
      title: Text(isEditing ? '编辑订阅' : '添加订阅'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: '订阅名称 *')),
            TextField(controller: _amountController, decoration: const InputDecoration(labelText: '金额 (¥)'), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
            DropdownButtonFormField<String>(
              value: _billingCycle,
              decoration: const InputDecoration(labelText: '计费周期'),
              items: const [
                DropdownMenuItem(value: 'monthly', child: Text('每月')),
                DropdownMenuItem(value: 'quarterly', child: Text('每季度')),
                DropdownMenuItem(value: 'yearly', child: Text('每年')),
              ],
              onChanged: (value) => setState(() => _billingCycle = value!),
            ),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(labelText: '分类'),
              items: SubscriptionEntry.categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (value) => setState(() => _category = value),
            ),
            TextField(controller: _websiteController, decoration: const InputDecoration(labelText: '网站 (可选)')),
            TextField(controller: _noteController, decoration: const InputDecoration(labelText: '备注'), maxLines: 2),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
        TextButton(
          onPressed: () {
            if (_nameController.text.isEmpty || _amountController.text.isEmpty) return;

            final subscription = SubscriptionEntry(
              id: widget.subscription?.id,
              name: _nameController.text,
              amount: double.tryParse(_amountController.text) ?? 0,
              billingCycle: _billingCycle,
              category: _category,
              website: _websiteController.text.isEmpty ? null : _websiteController.text,
              note: _noteController.text.isEmpty ? null : _noteController.text,
              isActive: widget.subscription?.isActive ?? true,
              createdAt: widget.subscription?.createdAt ?? DateTime.now().toIso8601String(),
            );

            if (isEditing) {
              ref.read(subscriptionProvider.notifier).updateSubscription(subscription);
            } else {
              ref.read(subscriptionProvider.notifier).addSubscription(subscription);
            }
            Navigator.pop(context);
          },
          child: Text(isEditing ? '保存' : '添加'),
        ),
      ],
    );
  }
}