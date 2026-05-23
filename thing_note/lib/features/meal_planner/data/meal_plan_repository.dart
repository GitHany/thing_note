import 'package:thing_note/core/database/database_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/meal_plan.dart';

final mealPlanRepositoryProvider = Provider<MealPlanRepository>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return MealPlanRepository(dbAsync);
});

class MealPlanRepository {
  final AsyncValue<dynamic> _dbAsync;

  MealPlanRepository(this._dbAsync);

  Future<dynamic> get _db async {
    final db = _dbAsync.value;
    if (db == null) throw Exception('Database not initialized');
    return db;
  }

  Future<int> insertMealPlan(MealPlan mealPlan) async {
    final db = await _db;
    return await db.insert('meal_plans', mealPlan.toMap());
  }

  Future<List<MealPlan>> getMealPlansByDate(String date) async {
    final db = await _db;
    final maps = await db.query('meal_plans', where: 'date = ?', whereArgs: [date], orderBy: 'meal_type ASC');
    return maps.map((map) => MealPlan.fromMap(map)).toList();
  }

  Future<List<MealPlan>> getMealPlansByDateRange(String startDate, String endDate) async {
    final db = await _db;
    final maps = await db.query('meal_plans', where: 'date >= ? AND date <= ?', whereArgs: [startDate, endDate], orderBy: 'date ASC, meal_type ASC');
    return maps.map((map) => MealPlan.fromMap(map)).toList();
  }

  Future<int> updateMealPlan(MealPlan mealPlan) async {
    final db = await _db;
    return await db.update('meal_plans', mealPlan.toMap(), where: 'id = ?', whereArgs: [mealPlan.id]);
  }

  Future<int> deleteMealPlan(int id) async {
    final db = await _db;
    return await db.delete('meal_plans', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> insertGroceryItem(GroceryItem item) async {
    final db = await _db;
    return await db.insert('grocery_items', item.toMap());
  }

  Future<List<GroceryItem>> getAllGroceryItems() async {
    final db = await _db;
    final maps = await db.query('grocery_items', where: 'is_purchased = 0', orderBy: 'created_at DESC');
    return maps.map((map) => GroceryItem.fromMap(map)).toList();
  }

  Future<int> toggleGroceryItem(int id, bool isPurchased) async {
    final db = await _db;
    return await db.update('grocery_items', {'is_purchased': isPurchased ? 1 : 0}, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteGroceryItem(int id) async {
    final db = await _db;
    return await db.delete('grocery_items', where: 'id = ?', whereArgs: [id]);
  }
}