import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/budget_tracker/data/budget_repository.dart';
import 'package:thing_note/features/budget_tracker/domain/budget.dart';

class BudgetTrackerScreen extends ConsumerStatefulWidget {
  const BudgetTrackerScreen({super.key});

  @override
  ConsumerState<BudgetTrackerScreen> createState() => _BudgetTrackerScreenState();
}

class _BudgetTrackerScreenState extends ConsumerState<BudgetTrackerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('预算追踪'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '支出记录'),
            Tab(text: '预算设置'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildExpensesTab(),
          _buildBudgetsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddExpenseDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildExpensesTab() {
    final statsAsync = ref.watch(budgetStatsProvider);
    final expensesAsync = ref.watch(expensesProvider);

    return Column(
      children: [
        statsAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (e, _) => const SizedBox.shrink(),
          data: (stats) => _buildBudgetProgress(stats),
        ),
        Expanded(
          child: expensesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Center(child: Text('错误: $e')),
            data: (expenses) {
              if (expenses.isEmpty) {
                return const Center(child: Text('本月暂无支出记录'));
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: expenses.length,
                itemBuilder: (context, index) {
                  return _ExpenseCard(
                    expense: expenses[index],
                    onDelete: () => _deleteExpense(expenses[index].id!),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBudgetProgress(Map<String, dynamic> stats) {
    final total = stats['monthTotal'] as double;
    final budget = stats['monthBudget'] as double;
    final percentage = stats['percentage'] as double;

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('本月支出', style: TextStyle(color: Colors.grey[600])),
              Text(
                '¥${total.toStringAsFixed(2)} / ¥${budget.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percentage / 100,
              minHeight: 12,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                percentage > 80 ? Colors.red : (percentage > 50 ? Colors.orange : Colors.green),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '剩余 ¥${(budget - total).toStringAsFixed(2)}',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetsTab() {
    final budgetsAsync = ref.watch(budgetsProvider);

    return budgetsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('错误: $e')),
      data: (budgets) {
        if (budgets.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.account_balance_wallet, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text('暂无预算设置', style: TextStyle(fontSize: 18)),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () => _showAddBudgetDialog(context),
                  icon: const Icon(Icons.add),
                  label: const Text('添加预算'),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: budgets.length,
          itemBuilder: (context, index) {
            final budget = budgets[index];
            return Card(
              child: ListTile(
                leading: const Icon(Icons.account_balance_wallet),
                title: Text(budget.name),
                subtitle: Text('¥${budget.amount.toStringAsFixed(2)} / ${budget.period}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteBudget(budget.id!),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showAddExpenseDialog(BuildContext context) {
    final amountController = TextEditingController();
    final merchantController = TextEditingController();
    final noteController = TextEditingController();
    String category = ExpenseCategory.other;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('添加支出'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: amountController,
                  decoration: const InputDecoration(
                    labelText: '金额',
                    prefixText: '¥ ',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: category,
                  decoration: const InputDecoration(labelText: '分类'),
                  items: ExpenseCategory.all.map((c) {
                    return DropdownMenuItem(value: c, child: Text(c));
                  }).toList(),
                  onChanged: (v) => setState(() => category = v!),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: merchantController,
                  decoration: const InputDecoration(labelText: '商家（可选）'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: noteController,
                  decoration: const InputDecoration(labelText: '备注（可选）'),
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
                final amount = double.tryParse(amountController.text);
                if (amount != null && amount > 0) {
                  final now = DateTime.now();
                  final date = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
                  final expense = Expense(
                    amount: amount,
                    category: category,
                    merchant: merchantController.text.trim().isEmpty ? null : merchantController.text.trim(),
                    note: noteController.text.trim().isEmpty ? null : noteController.text.trim(),
                    date: date,
                    createdAt: now,
                  );
                  ref.read(expensesProvider.notifier).addExpense(expense);
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

  void _showAddBudgetDialog(BuildContext context) {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    String period = 'monthly';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('添加预算'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: '预算名称'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                decoration: const InputDecoration(
                  labelText: '预算金额',
                  prefixText: '¥ ',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: period,
                decoration: const InputDecoration(labelText: '周期'),
                items: const [
                  DropdownMenuItem(value: 'weekly', child: Text('每周')),
                  DropdownMenuItem(value: 'monthly', child: Text('每月')),
                  DropdownMenuItem(value: 'yearly', child: Text('每年')),
                ],
                onChanged: (v) => setState(() => period = v!),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                final amount = double.tryParse(amountController.text);
                if (nameController.text.isNotEmpty && amount != null && amount > 0) {
                  final now = DateTime.now();
                  final startDate = '${now.year}-${now.month.toString().padLeft(2, '0')}-01';
                  final budget = Budget(
                    name: nameController.text.trim(),
                    amount: amount,
                    period: period,
                    startDate: startDate,
                    createdAt: now,
                  );
                  ref.read(budgetsProvider.notifier).addBudget(budget);
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

  void _deleteExpense(int id) {
    ref.read(expensesProvider.notifier).deleteExpense(id);
  }

  void _deleteBudget(int id) {
    ref.read(budgetsProvider.notifier).deleteBudget(id);
  }
}

class _ExpenseCard extends StatelessWidget {
  final Expense expense;
  final VoidCallback onDelete;

  const _ExpenseCard({required this.expense, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getCategoryColor(expense.category).withOpacity(0.2),
          child: Icon(_getCategoryIcon(expense.category), color: _getCategoryColor(expense.category)),
        ),
        title: Text('¥${expense.amount.toStringAsFixed(2)}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(expense.category),
            if (expense.merchant != null)
              Text(expense.merchant!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(expense.date.substring(5), style: const TextStyle(color: Colors.grey)),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case '餐饮': return Colors.orange;
      case '交通': return Colors.blue;
      case '购物': return Colors.purple;
      case '娱乐': return Colors.pink;
      case '健康': return Colors.green;
      default: return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case '餐饮': return Icons.restaurant;
      case '交通': return Icons.directions_car;
      case '购物': return Icons.shopping_bag;
      case '娱乐': return Icons.movie;
      case '健康': return Icons.medical_services;
      default: return Icons.payment;
    }
  }
}