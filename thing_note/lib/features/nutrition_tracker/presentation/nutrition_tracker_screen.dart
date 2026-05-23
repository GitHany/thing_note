import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/nutrition_tracker/data/nutrition_repository.dart';

class NutritionTrackerScreen extends ConsumerStatefulWidget {
  const NutritionTrackerScreen({super.key});

  @override
  ConsumerState<NutritionTrackerScreen> createState() => _NutritionTrackerScreenState();
}

class _NutritionTrackerScreenState extends ConsumerState<NutritionTrackerScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final nutritionAsync = ref.watch(dailyNutritionProvider);
    final recordsAsync = ref.watch(nutritionRecordsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('饮食追踪'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _selectDate(context),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildDateSelector(),
          nutritionAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Center(child: Text('错误: $e')),
            data: (data) => _buildNutritionSummary(data),
          ),
          Expanded(
            child: recordsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('错误: $e')),
              data: (records) => _buildRecordsList(records),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddNutritionDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildDateSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              setState(() {
                _selectedDate = _selectedDate.subtract(const Duration(days: 1));
              });
            },
          ),
          GestureDetector(
            onTap: () => _selectDate(context),
            child: Text(
              _isToday(_selectedDate) ? '今天' : '${_selectedDate.month}/${_selectedDate.day}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              setState(() {
                _selectedDate = _selectedDate.add(const Duration(days: 1));
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionSummary(Map<String, dynamic> data) {
    final totalCalories = data['total_calories'] as int;
    final targetCalories = data['target_calories'] as int;
    final totalProtein = data['total_protein'] as double;
    final totalCarbs = data['total_carbs'] as double;
    final totalFat = data['total_fat'] as double;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$totalCalories',
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              Text(
                ' / $targetCalories kcal',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (totalCalories / targetCalories).clamp(0.0, 1.0),
              minHeight: 12,
              backgroundColor: Colors.grey[300],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _MacroItem(label: '蛋白质', value: '${totalProtein.toStringAsFixed(1)}g', color: Colors.blue),
              _MacroItem(label: '碳水', value: '${totalCarbs.toStringAsFixed(1)}g', color: Colors.orange),
              _MacroItem(label: '脂肪', value: '${totalFat.toStringAsFixed(1)}g', color: Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecordsList(List<NutritionRecord> records) {
    final todayRecords = records.where((r) =>
      r.recordedAt.year == _selectedDate.year &&
      r.recordedAt.month == _selectedDate.month &&
      r.recordedAt.day == _selectedDate.day
    ).toList();

    if (todayRecords.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant_menu, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('暂无记录', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text('记录你的饮食，保持健康', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    // Group by meal type
    final groupedRecords = <String, List<NutritionRecord>>{};
    for (final record in todayRecords) {
      groupedRecords.putIfAbsent(record.mealType, () => []).add(record);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groupedRecords.length,
      itemBuilder: (context, index) {
        final mealType = groupedRecords.keys.elementAt(index);
        final mealRecords = groupedRecords[mealType]!;
        return _MealSection(
          mealType: mealType,
          records: mealRecords,
          onDelete: (id) => ref.read(nutritionRecordsProvider.notifier).deleteNutrition(id),
        );
      },
    );
  }

  void _selectDate(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  void _showAddNutritionDialog(BuildContext context) {
    String selectedMeal = mealTypes.first;
    final foodController = TextEditingController();
    final caloriesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加饮食记录'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedMeal,
                decoration: const InputDecoration(labelText: '餐食类型'),
                items: mealTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (v) => selectedMeal = v!,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: foodController,
                decoration: const InputDecoration(labelText: '食物名称'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: caloriesController,
                decoration: const InputDecoration(labelText: '卡路里 (kcal)'),
                keyboardType: TextInputType.number,
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
              if (foodController.text.isNotEmpty) {
                final record = NutritionRecord(
                  mealType: selectedMeal,
                  foodName: foodController.text,
                  calories: int.tryParse(caloriesController.text) ?? 0,
                  recordedAt: _selectedDate,
                  createdAt: DateTime.now(),
                );
                ref.read(nutritionRecordsProvider.notifier).addNutrition(record);
                Navigator.pop(context);
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }
}

class _MealSection extends StatelessWidget {
  final String mealType;
  final List<NutritionRecord> records;
  final Function(int) onDelete;

  const _MealSection({
    required this.mealType,
    required this.records,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(mealType, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            Text('${records.length}项', style: TextStyle(color: Colors.grey[600])),
          ],
        ),
        const SizedBox(height: 8),
        ...records.map((r) => _NutritionCard(record: r, onDelete: onDelete)),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _NutritionCard extends StatelessWidget {
  final NutritionRecord record;
  final Function(int) onDelete;

  const _NutritionCard({required this.record, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(record.foodName),
        subtitle: Text('${record.calories} kcal'),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: () => onDelete(record.id!),
        ),
      ),
    );
  }
}

class _MacroItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MacroItem({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      ],
    );
  }
}