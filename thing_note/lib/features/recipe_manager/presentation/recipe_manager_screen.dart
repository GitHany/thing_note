import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/recipe_manager/data/recipe_repository.dart';
import 'package:thing_note/features/recipe_manager/domain/recipe.dart';

class RecipeManagerScreen extends ConsumerStatefulWidget {
  const RecipeManagerScreen({super.key});

  @override
  ConsumerState<RecipeManagerScreen> createState() => _RecipeManagerScreenState();
}

class _RecipeManagerScreenState extends ConsumerState<RecipeManagerScreen> {
  @override
  Widget build(BuildContext context) {
    final recipesAsync = ref.watch(recipesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('食谱管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddRecipeDialog(context, ref),
          ),
        ],
      ),
      body: recipesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('错误: $e')),
        data: (recipes) {
          if (recipes.isEmpty) {
            return _buildEmptyState(context, ref);
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: recipes.length,
            itemBuilder: (context, index) {
              return _RecipeCard(
                recipe: recipes[index],
                onTap: () => _showRecipeDetail(context, recipes[index]),
                onDelete: () => ref.read(recipesProvider.notifier).deleteRecipe(recipes[index].id!),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddRecipeDialog(context, ref),
        child: const Icon(Icons.restaurant_menu),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.restaurant, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('暂无食谱', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () => _showAddRecipeDialog(context, ref),
            icon: const Icon(Icons.add),
            label: const Text('添加食谱'),
          ),
        ],
      ),
    );
  }

  void _showAddRecipeDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final ingredientsController = TextEditingController();
    final stepsController = TextEditingController();
    int servings = 1;
    int prepTime = 15;
    int cookTime = 30;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('添加食谱'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: '食谱名称'),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('准备时间'),
                          Slider(
                            value: prepTime.toDouble(),
                            min: 5,
                            max: 120,
                            divisions: 23,
                            label: '$prepTime 分钟',
                            onChanged: (v) => setState(() => prepTime = v.round()),
                          ),
                          Text('$prepTime 分钟'),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('烹饪时间'),
                          Slider(
                            value: cookTime.toDouble(),
                            min: 5,
                            max: 240,
                            divisions: 47,
                            label: '$cookTime 分钟',
                            onChanged: (v) => setState(() => cookTime = v.round()),
                          ),
                          Text('$cookTime 分钟'),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: servings,
                  decoration: const InputDecoration(labelText: '份量'),
                  items: List.generate(10, (i) => i + 1).map((s) {
                    return DropdownMenuItem(value: s, child: Text('$s 人份'));
                  }).toList(),
                  onChanged: (v) => setState(() => servings = v!),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: ingredientsController,
                  decoration: const InputDecoration(
                    labelText: '材料（每行一个）',
                    hintText: '番茄\n鸡蛋\n盐',
                  ),
                  maxLines: 4,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: stepsController,
                  decoration: const InputDecoration(
                    labelText: '步骤（每行一个）',
                    hintText: '切番茄\n打鸡蛋\n炒菜',
                  ),
                  maxLines: 4,
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
                  final ingredients = ingredientsController.text
                      .split('\n')
                      .where((s) => s.trim().isNotEmpty)
                      .toList();
                  final steps = stepsController.text
                      .split('\n')
                      .where((s) => s.trim().isNotEmpty)
                      .toList();

                  final recipe = Recipe(
                    name: nameController.text.trim(),
                    ingredients: ingredients,
                    steps: steps,
                    servings: servings,
                    prepTimeMinutes: prepTime,
                    cookTimeMinutes: cookTime,
                    createdAt: DateTime.now(),
                  );
                  ref.read(recipesProvider.notifier).addRecipe(recipe);
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

  void _showRecipeDetail(BuildContext context, Recipe recipe) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: ListView(
            controller: scrollController,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      recipe.name,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildInfoChip(Icons.timer, '${recipe.totalTimeMinutes}分钟'),
                  _buildInfoChip(Icons.people, '${recipe.servings}人份'),
                  _buildInfoChip(Icons.restaurant, '${recipe.timesCooked}次'),
                ],
              ),
              const SizedBox(height: 24),
              const Text('材料', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...recipe.ingredients.map((i) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.circle, size: 8),
                    const SizedBox(width: 8),
                    Text(i),
                  ],
                ),
              )),
              const SizedBox(height: 24),
              const Text('步骤', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...recipe.steps.asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${e.key + 1}',
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(e.value)),
                  ],
                ),
              )),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  ref.read(cookingLogsProvider.notifier).addLog(
                    CookingLog(recipeId: recipe.id!, cookedAt: DateTime.now()),
                  );
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('烹饪记录已添加 ✓')),
                  );
                },
                icon: const Icon(Icons.check),
                label: const Text('记录烹饪'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 4),
          Text(text),
        ],
      ),
    );
  }
}

class _RecipeCard extends StatelessWidget {
  final Recipe recipe;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _RecipeCard({
    required this.recipe,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.restaurant_menu, color: Colors.orange),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recipe.name,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '已烹饪 ${recipe.timesCooked} 次',
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'delete') onDelete();
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'delete', child: Text('删除', style: TextStyle(color: Colors.red))),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.timer, size: 14, color: Colors.grey[400]),
                  const SizedBox(width: 4),
                  Text('${recipe.totalTimeMinutes}分钟', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  const SizedBox(width: 16),
                  Icon(Icons.people, size: 14, color: Colors.grey[400]),
                  const SizedBox(width: 4),
                  Text('${recipe.servings}人份', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  const SizedBox(width: 16),
                  Icon(Icons.list, size: 14, color: Colors.grey[400]),
                  const SizedBox(width: 4),
                  Text('${recipe.ingredients.length}种材料', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}