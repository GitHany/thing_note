import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/expense_category_repository.dart';
import '../domain/expense_category.dart';

final expenseCategoryProvider = StateNotifierProvider<ExpenseCategoryNotifier, AsyncValue<List<ExpenseCategory>>>((ref) {
  return ExpenseCategoryNotifier(ref.watch(expenseCategoryRepositoryProvider));
});

class ExpenseCategoryNotifier extends StateNotifier<AsyncValue<List<ExpenseCategory>>> {
  final ExpenseCategoryRepository _repository;

  ExpenseCategoryNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadCategories();
  }

  Future<void> loadCategories() async {
    state = const AsyncValue.loading();
    try {
      final categories = await _repository.getAllCategories();
      if (categories.isEmpty) {
        await _initDefaultCategories();
        final newCategories = await _repository.getAllCategories();
        state = AsyncValue.data(newCategories);
      } else {
        state = AsyncValue.data(categories);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> _initDefaultCategories() async {
    for (final category in ExpenseCategory.defaultCategories) {
      await _repository.insertCategory(category);
    }
  }

  Future<void> addCategory(ExpenseCategory category) async {
    await _repository.insertCategory(category);
    await loadCategories();
  }

  Future<void> updateCategory(ExpenseCategory category) async {
    await _repository.updateCategory(category);
    await loadCategories();
  }

  Future<void> deleteCategory(int id) async {
    await _repository.deleteCategory(id);
    await loadCategories();
  }
}

class ExpenseCategoriesScreen extends ConsumerWidget {
  const ExpenseCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(expenseCategoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('支出分类'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: categoriesAsync.when(
        data: (categories) => _buildCategoryList(context, ref, categories),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('错误: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCategoryList(BuildContext context, WidgetRef ref, List<ExpenseCategory> categories) {
    if (categories.isEmpty) {
      return const Center(child: Text('暂无分类'));
    }

    return ListView.builder(
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Color(int.parse(category.color.replaceFirst('#', '0xFF'))),
              child: Icon(
                _getIconData(category.icon),
                color: Colors.white,
                size: 20,
              ),
            ),
            title: Text(category.name),
            subtitle: category.budgetAmount > 0 
                ? Text('预算: ¥${category.budgetAmount}')
                : null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _showEditDialog(context, ref, category),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _showDeleteDialog(context, ref, category),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _getIconData(String iconName) {
    final icons = {
      'restaurant': Icons.restaurant,
      'directions_car': Icons.directions_car,
      'shopping_bag': Icons.shopping_bag,
      'movie': Icons.movie,
      'local_hospital': Icons.local_hospital,
      'school': Icons.school,
      'home': Icons.home,
      'phone': Icons.phone,
      'more_horiz': Icons.more_horiz,
    };
    return icons[iconName] ?? Icons.category;
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => const CategoryFormDialog(),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, ExpenseCategory category) {
    showDialog(
      context: context,
      builder: (context) => CategoryFormDialog(category: category),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, ExpenseCategory category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除分类'),
        content: Text('确定要删除 "${category.name}" 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(expenseCategoryProvider.notifier).deleteCategory(category.id!);
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}

class CategoryFormDialog extends ConsumerStatefulWidget {
  final ExpenseCategory? category;

  const CategoryFormDialog({super.key, this.category});

  @override
  ConsumerState<CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends ConsumerState<CategoryFormDialog> {
  late TextEditingController _nameController;
  late TextEditingController _budgetController;
  String _selectedIcon = 'more_horiz';
  String _selectedColor = '#607D8B';

  final List<String> _icons = [
    'restaurant', 'directions_car', 'shopping_bag', 'movie',
    'local_hospital', 'school', 'home', 'phone', 'more_horiz',
  ];

  final List<String> _colors = [
    '#FF5722', '#2196F3', '#E91E63', '#9C27B0', '#F44336',
    '#4CAF50', '#795548', '#00BCD4', '#607D8B',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
    _budgetController = TextEditingController(
      text: widget.category?.budgetAmount.toString() ?? '0',
    );
    if (widget.category != null) {
      _selectedIcon = widget.category!.icon;
      _selectedColor = widget.category!.color;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.category != null;

    return AlertDialog(
      title: Text(isEditing ? '编辑分类' : '添加分类'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: '分类名称'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _budgetController,
              decoration: const InputDecoration(labelText: '月度预算（可选）'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            const Text('选择图标'),
            Wrap(
              spacing: 8,
              children: _icons.map((icon) {
                return GestureDetector(
                  onTap: () => setState(() => _selectedIcon = icon),
                  child: CircleAvatar(
                    backgroundColor: _selectedIcon == icon 
                        ? Theme.of(context).primaryColor 
                        : Colors.grey[300],
                    child: Icon(_getIconData(icon), size: 20),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            const Text('选择颜色'),
            Wrap(
              spacing: 8,
              children: _colors.map((color) {
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = color),
                  child: CircleAvatar(
                    backgroundColor: Color(int.parse(color.replaceFirst('#', '0xFF'))),
                    radius: 15,
                    child: _selectedColor == color 
                        ? const Icon(Icons.check, color: Colors.white, size: 15)
                        : null,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () {
            if (_nameController.text.isEmpty) return;
            
            final category = ExpenseCategory(
              id: widget.category?.id,
              name: _nameController.text,
              icon: _selectedIcon,
              color: _selectedColor,
              budgetAmount: int.tryParse(_budgetController.text) ?? 0,
              createdAt: widget.category?.createdAt ?? DateTime.now().toIso8601String(),
            );

            if (isEditing) {
              ref.read(expenseCategoryProvider.notifier).updateCategory(category);
            } else {
              ref.read(expenseCategoryProvider.notifier).addCategory(category);
            }
            Navigator.pop(context);
          },
          child: Text(isEditing ? '保存' : '添加'),
        ),
      ],
    );
  }

  IconData _getIconData(String iconName) {
    final icons = {
      'restaurant': Icons.restaurant,
      'directions_car': Icons.directions_car,
      'shopping_bag': Icons.shopping_bag,
      'movie': Icons.movie,
      'local_hospital': Icons.local_hospital,
      'school': Icons.school,
      'home': Icons.home,
      'phone': Icons.phone,
      'more_horiz': Icons.more_horiz,
    };
    return icons[iconName] ?? Icons.category;
  }
}