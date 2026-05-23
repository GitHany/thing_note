import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';

// Nutrition record model
class NutritionRecord {
  final int? id;
  final String mealType;
  final String foodName;
  final String? portionSize;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final DateTime recordedAt;
  final DateTime createdAt;

  const NutritionRecord({
    this.id,
    required this.mealType,
    required this.foodName,
    this.portionSize,
    this.calories = 0,
    this.protein = 0,
    this.carbs = 0,
    this.fat = 0,
    required this.recordedAt,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'meal_type': mealType,
      'food_name': foodName,
      'portion_size': portionSize,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'recorded_at': recordedAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory NutritionRecord.fromMap(Map<String, dynamic> map) {
    return NutritionRecord(
      id: map['id'] as int?,
      mealType: map['meal_type'] as String,
      foodName: map['food_name'] as String,
      portionSize: map['portion_size'] as String?,
      calories: map['calories'] as int? ?? 0,
      protein: (map['protein'] as num?)?.toDouble() ?? 0,
      carbs: (map['carbs'] as num?)?.toDouble() ?? 0,
      fat: (map['fat'] as num?)?.toDouble() ?? 0,
      recordedAt: DateTime.parse(map['recorded_at'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

// Food item model
class FoodItem {
  final int? id;
  final String name;
  final String? category;
  final double caloriesPer100g;
  final double proteinPer100g;
  final double carbsPer100g;
  final double fatPer100g;
  final DateTime createdAt;

  const FoodItem({
    this.id,
    required this.name,
    this.category,
    this.caloriesPer100g = 0,
    this.proteinPer100g = 0,
    this.carbsPer100g = 0,
    this.fatPer100g = 0,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'category': category,
      'calories_per_100g': caloriesPer100g,
      'protein_per_100g': proteinPer100g,
      'carbs_per_100g': carbsPer100g,
      'fat_per_100g': fatPer100g,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory FoodItem.fromMap(Map<String, dynamic> map) {
    return FoodItem(
      id: map['id'] as int?,
      name: map['name'] as String,
      category: map['category'] as String?,
      caloriesPer100g: (map['calories_per_100g'] as num?)?.toDouble() ?? 0,
      proteinPer100g: (map['protein_per_100g'] as num?)?.toDouble() ?? 0,
      carbsPer100g: (map['carbs_per_100g'] as num?)?.toDouble() ?? 0,
      fatPer100g: (map['fat_per_100g'] as num?)?.toDouble() ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

// Repository providers
final nutritionRepositoryProvider = Provider<NutritionRepository>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return NutritionRepository(dbAsync);
});

final nutritionRecordsProvider = StateNotifierProvider<NutritionRecordsNotifier, AsyncValue<List<NutritionRecord>>>((ref) {
  final repository = ref.watch(nutritionRepositoryProvider);
  return NutritionRecordsNotifier(repository);
});

final dailyNutritionProvider = Provider<AsyncValue<Map<String, dynamic>>>((ref) {
  final records = ref.watch(nutritionRecordsProvider);
  return records.whenData((data) {
    final today = DateTime.now();
    final todayRecords = data.where((r) =>
      r.recordedAt.year == today.year &&
      r.recordedAt.month == today.month &&
      r.recordedAt.day == today.day
    ).toList();

    int totalCalories = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;

    for (final r in todayRecords) {
      totalCalories += r.calories;
      totalProtein += r.protein;
      totalCarbs += r.carbs;
      totalFat += r.fat;
    }

    return {
      'records': todayRecords,
      'total_calories': totalCalories,
      'total_protein': totalProtein,
      'total_carbs': totalCarbs,
      'total_fat': totalFat,
      'target_calories': 2000,
    };
  });
});

final _mealTypes = ['早餐', '午餐', '晚餐', '宵夜', '零食'];

class NutritionRepository {
  final AsyncValue<Database> _dbAsync;

  NutritionRepository(this._dbAsync);

  Future<Database> get _db async {
    final db = _dbAsync.value;
    if (db == null) throw Exception('Database not initialized');
    return db;
  }

  Future<int> insertNutrition(NutritionRecord record) async {
    final db = await _db;
    return db.insert('nutrition_records', record.toMap());
  }

  Future<int> deleteNutrition(int id) async {
    final db = await _db;
    return db.delete('nutrition_records', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<NutritionRecord>> getAllNutrition() async {
    final db = await _db;
    final maps = await db.query('nutrition_records', orderBy: 'recorded_at DESC');
    return maps.map((m) => NutritionRecord.fromMap(m)).toList();
  }

  Future<List<NutritionRecord>> getNutritionByDate(DateTime date) async {
    final db = await _db;
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final maps = await db.query(
      'nutrition_records',
      where: 'recorded_at >= ? AND recorded_at < ?',
      whereArgs: [startOfDay.toIso8601String(), endOfDay.toIso8601String()],
      orderBy: 'recorded_at DESC',
    );
    return maps.map((m) => NutritionRecord.fromMap(m)).toList();
  }
}

class NutritionRecordsNotifier extends StateNotifier<AsyncValue<List<NutritionRecord>>> {
  final NutritionRepository _repository;

  NutritionRecordsNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadNutrition();
  }

  Future<void> loadNutrition() async {
    state = const AsyncValue.loading();
    try {
      final records = await _repository.getAllNutrition();
      state = AsyncValue.data(records);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addNutrition(NutritionRecord record) async {
    try {
      await _repository.insertNutrition(record);
      await loadNutrition();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteNutrition(int id) async {
    try {
      await _repository.deleteNutrition(id);
      await loadNutrition();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

List<String> get mealTypes => _mealTypes;