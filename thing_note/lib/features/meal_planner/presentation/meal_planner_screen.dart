import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/date_formatter.dart';
import '../data/meal_plan_repository.dart';
import '../domain/meal_plan.dart';

final mealPlanProvider = StateNotifierProvider<MealPlanNotifier, AsyncValue<List<MealPlan>>>((ref) {
  return MealPlanNotifier(ref.watch(mealPlanRepositoryProvider));
});

final groceryProvider = StateNotifierProvider<GroceryNotifier, AsyncValue<List<GroceryItem>>>((ref) {
  return GroceryNotifier(ref.watch(mealPlanRepositoryProvider));
});

class MealPlanNotifier extends StateNotifier<AsyncValue<List<MealPlan>>> {
  final MealPlanRepository _repository;

  MealPlanNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadMealPlans(DateTime.now());
  }

  Future<void> loadMealPlans(DateTime date) async {
    state = const AsyncValue.loading();
    try {
      final plans = await _repository.getMealPlansByDate(DateFormatter.formatDate(date));
      state = AsyncValue.data(plans);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addMealPlan(MealPlan plan) async {
    await _repository.insertMealPlan(plan);
    await loadMealPlans(DateTime.parse(plan.date));
  }

  Future<void> updateMealPlan(MealPlan plan) async {
    await _repository.updateMealPlan(plan);
    await loadMealPlans(DateTime.parse(plan.date));
  }

  Future<void> deleteMealPlan(int id, String date) async {
    await _repository.deleteMealPlan(id);
    await loadMealPlans(DateTime.parse(date));
  }
}

class GroceryNotifier extends StateNotifier<AsyncValue<List<GroceryItem>>> {
  final MealPlanRepository _repository;

  GroceryNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadGroceries();
  }

  Future<void> loadGroceries() async {
    state = const AsyncValue.loading();
    try {
      final items = await _repository.getAllGroceryItems();
      state = AsyncValue.data(items);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addGroceryItem(GroceryItem item) async {
    await _repository.insertGroceryItem(item);
    await loadGroceries();
  }

  Future<void> toggleItem(int id, bool isPurchased) async {
    await _repository.toggleGroceryItem(id, isPurchased);
    await loadGroceries();
  }

  Future<void> deleteItem(int id) async {
    await _repository.deleteGroceryItem(id);
    await loadGroceries();
  }
}

class MealPlannerScreen extends ConsumerStatefulWidget {
  const MealPlannerScreen({super.key});

  @override
  ConsumerState<MealPlannerScreen> createState() => _MealPlannerScreenState();
}

class _MealPlannerScreenState extends ConsumerState<MealPlannerScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();

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
        title: const Text('膳食计划'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: '膳食计划'), Tab(text: '购物清单')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildMealPlanTab(), _buildGroceryTab()],
      ),
    );
  }

  Widget _buildMealPlanTab() {
    return Column(
      children: [
        _buildDateSelector(),
        Expanded(
          child: ref.watch(mealPlanProvider).when(
            data: (plans) => plans.isEmpty
                ? const Center(child: Text('暂无膳食计划'))
                : ListView.builder(
                    itemCount: plans.length,
                    itemBuilder: (context, index) => _buildMealPlanItem(plans[index]),
                  ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('错误: $e')),
          ),
        ),
      ],
    );
  }

  Widget _buildDateSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => _changeDate(-1)),
          TextButton(
            onPressed: () => _selectDate(context),
            child: Text(DateFormatter.formatDateFull(_selectedDate), style: Theme.of(context).textTheme.titleMedium),
          ),
          IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => _changeDate(1)),
        ],
      ),
    );
  }

  void _changeDate(int days) {
    setState(() => _selectedDate = _selectedDate.add(Duration(days: days)));
    ref.read(mealPlanProvider.notifier).loadMealPlans(_selectedDate);
  }

  Future<void> _selectDate(BuildContext context) async {
    final date = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime(2020), lastDate: DateTime(2030));
    if (date != null) {
      setState(() => _selectedDate = date);
      ref.read(mealPlanProvider.notifier).loadMealPlans(date);
    }
  }

  Widget _buildMealPlanItem(MealPlan plan) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getMealTypeColor(plan.mealType),
          child: Icon(_getMealTypeIcon(plan.mealType), color: Colors.white),
        ),
        title: Text(plan.title ?? '未命名'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(plan.mealType),
            if (plan.calories != null) Text('${plan.calories} 千卡'),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'toggle', child: Text('标记完成')),
            const PopupMenuItem(value: 'edit', child: Text('编辑')),
            const PopupMenuItem(value: 'delete', child: Text('删除')),
          ],
          onSelected: (value) {
            if (value == 'toggle') {
              ref.read(mealPlanProvider.notifier).updateMealPlan(plan.copyWith(isCompleted: !plan.isCompleted));
            } else if (value == 'edit') {
              _showMealPlanDialog(context, plan);
            } else if (value == 'delete') {
              ref.read(mealPlanProvider.notifier).deleteMealPlan(plan.id!, plan.date);
            }
          },
        ),
      ),
    );
  }

  Color _getMealTypeColor(String type) {
    const colors = {'早餐': Colors.orange, '午餐': Colors.green, '晚餐': Colors.blue, '宵夜': Colors.purple, '零食': Colors.pink};
    return colors[type] ?? Colors.grey;
  }

  IconData _getMealTypeIcon(String type) {
    const icons = {
      '早餐': Icons.free_breakfast,
      '午餐': Icons.lunch_dining,
      '晚餐': Icons.dinner_dining,
      '宵夜': Icons.nightlight,
      '零食': Icons.cookie
    };
    return icons[type] ?? Icons.restaurant;
  }

  Widget _buildGroceryTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: () => _showGroceryDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('添加购物项'),
          ),
        ),
        Expanded(
          child: ref.watch(groceryProvider).when(
            data: (items) => items.isEmpty
                ? const Center(child: Text('购物清单为空'))
                : ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return ListTile(
                        leading: Checkbox(
                          value: item.isPurchased,
                          onChanged: (value) => ref.read(groceryProvider.notifier).toggleItem(item.id!, value!),
                        ),
                        title: Text(item.name, style: TextStyle(decoration: item.isPurchased ? TextDecoration.lineThrough : null)),
                        subtitle: Text('${item.quantity} ${item.unit}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => ref.read(groceryProvider.notifier).deleteItem(item.id!),
                        ),
                      );
                    },
                  ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('错误: $e')),
          ),
        ),
      ],
    );
  }

  void _showMealPlanDialog(BuildContext context, [MealPlan? plan]) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(plan != null ? '编辑膳食' : '添加膳食'),
        content: SingleChildScrollView(
          child: MealPlanForm(date: DateFormatter.formatDate(_selectedDate), plan: plan),
        ),
      ),
    );
  }

  void _showGroceryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const GroceryFormDialog(),
    );
  }
}

class MealPlanForm extends ConsumerStatefulWidget {
  final String date;
  final MealPlan? plan;

  const MealPlanForm({super.key, required this.date, this.plan});

  @override
  ConsumerState<MealPlanForm> createState() => _MealPlanFormState();
}

class _MealPlanFormState extends ConsumerState<MealPlanForm> {
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _caloriesController;
  String _mealType = '早餐';

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.plan?.title ?? '');
    _descController = TextEditingController(text: widget.plan?.description ?? '');
    _caloriesController = TextEditingController(text: widget.plan?.calories?.toString() ?? '');
    if (widget.plan != null) _mealType = widget.plan!.mealType;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        DropdownButtonFormField<String>(
          value: _mealType,
          decoration: const InputDecoration(labelText: '餐类型'),
          items: MealPlan.mealTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
          onChanged: (value) => setState(() => _mealType = value!),
        ),
        TextField(controller: _titleController, decoration: const InputDecoration(labelText: '标题')),
        TextField(controller: _descController, decoration: const InputDecoration(labelText: '描述'), maxLines: 2),
        TextField(controller: _caloriesController, decoration: const InputDecoration(labelText: '热量 (千卡)'), keyboardType: TextInputType.number),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
            TextButton(
              onPressed: () {
                final plan = MealPlan(
                  id: widget.plan?.id,
                  date: widget.date,
                  mealType: _mealType,
                  title: _titleController.text.isEmpty ? null : _titleController.text,
                  description: _descController.text.isEmpty ? null : _descController.text,
                  calories: int.tryParse(_caloriesController.text),
                  isCompleted: widget.plan?.isCompleted ?? false,
                  createdAt: widget.plan?.createdAt ?? DateTime.now().toIso8601String(),
                );
                if (widget.plan != null) {
                  ref.read(mealPlanProvider.notifier).updateMealPlan(plan);
                } else {
                  ref.read(mealPlanProvider.notifier).addMealPlan(plan);
                }
                Navigator.pop(context);
              },
              child: Text(widget.plan != null ? '保存' : '添加'),
            ),
          ],
        ),
      ],
    );
  }
}

class GroceryFormDialog extends ConsumerStatefulWidget {
  const GroceryFormDialog({super.key});

  @override
  ConsumerState<GroceryFormDialog> createState() => _GroceryFormDialogState();
}

class _GroceryFormDialogState extends ConsumerState<GroceryFormDialog> {
  late TextEditingController _nameController;
  late TextEditingController _quantityController;
  String _unit = '个';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _quantityController = TextEditingController(text: '1');
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('添加购物项'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: _nameController, decoration: const InputDecoration(labelText: '物品名称 *')),
          Row(
            children: [
              Expanded(
                child: TextField(controller: _quantityController, decoration: const InputDecoration(labelText: '数量'), keyboardType: TextInputType.number),
              ),
              const SizedBox(width: 16),
              DropdownButton<String>(
                value: _unit,
                items: const [
                  DropdownMenuItem(value: '个', child: Text('个')),
                  DropdownMenuItem(value: '斤', child: Text('斤')),
                  DropdownMenuItem(value: 'kg', child: Text('kg')),
                  DropdownMenuItem(value: '升', child: Text('升')),
                ],
                onChanged: (value) => setState(() => _unit = value!),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
        TextButton(
          onPressed: () {
            if (_nameController.text.isEmpty) return;
            final item = GroceryItem(
              name: _nameController.text,
              quantity: int.tryParse(_quantityController.text) ?? 1,
              unit: _unit,
              createdAt: DateTime.now().toIso8601String(),
            );
            ref.read(groceryProvider.notifier).addGroceryItem(item);
            Navigator.pop(context);
          },
          child: const Text('添加'),
        ),
      ],
    );
  }
}