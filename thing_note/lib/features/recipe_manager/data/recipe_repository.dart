import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/recipe_manager/domain/recipe.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';

final recipeRepositoryProvider = Provider<RecipeRepository>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return RecipeRepository(dbAsync);
});

final recipesProvider = StateNotifierProvider<RecipesNotifier, AsyncValue<List<Recipe>>>((ref) {
  final repository = ref.watch(recipeRepositoryProvider);
  return RecipesNotifier(repository);
});

final cookingLogsProvider = StateNotifierProvider<CookingLogsNotifier, AsyncValue<List<CookingLog>>>((ref) {
  final repository = ref.watch(recipeRepositoryProvider);
  return CookingLogsNotifier(repository);
});

class RecipeRepository {
  final AsyncValue<Database> _dbAsync;

  RecipeRepository(this._dbAsync);

  Future<Database> get _db async {
    final db = _dbAsync.value;
    if (db == null) throw Exception('Database not initialized');
    return db;
  }

  // Recipes
  Future<int> insertRecipe(Recipe recipe) async {
    final db = await _db;
    return db.insert('recipes', recipe.toMap());
  }

  Future<int> updateRecipe(Recipe recipe) async {
    final db = await _db;
    return db.update('recipes', recipe.toMap(), where: 'id = ?', whereArgs: [recipe.id]);
  }

  Future<int> deleteRecipe(int id) async {
    final db = await _db;
    return db.delete('recipes', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Recipe>> getAllRecipes() async {
    final db = await _db;
    final maps = await db.query('recipes', orderBy: 'created_at DESC');
    return maps.map((m) => Recipe.fromMap(m)).toList();
  }

  Future<Recipe?> getRecipeById(int id) async {
    final db = await _db;
    final maps = await db.query('recipes', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Recipe.fromMap(maps.first);
  }

  // Cooking Logs
  Future<int> insertCookingLog(CookingLog log) async {
    final db = await _db;
    return db.insert('cooking_logs', log.toMap());
  }

  Future<List<CookingLog>> getCookingLogs(int recipeId) async {
    final db = await _db;
    final maps = await db.query(
      'cooking_logs',
      where: 'recipe_id = ?',
      whereArgs: [recipeId],
      orderBy: 'cooked_at DESC',
    );
    return maps.map((m) => CookingLog.fromMap(m)).toList();
  }

  Future<void> incrementTimesCooked(int recipeId) async {
    final db = await _db;
    await db.rawUpdate(
      'UPDATE recipes SET times_cooked = times_cooked + 1 WHERE id = ?',
      [recipeId],
    );
  }
}

class RecipesNotifier extends StateNotifier<AsyncValue<List<Recipe>>> {
  final RecipeRepository _repository;

  RecipesNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadRecipes();
  }

  Future<void> loadRecipes() async {
    state = const AsyncValue.loading();
    try {
      final recipes = await _repository.getAllRecipes();
      state = AsyncValue.data(recipes);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addRecipe(Recipe recipe) async {
    try {
      await _repository.insertRecipe(recipe);
      await loadRecipes();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateRecipe(Recipe recipe) async {
    try {
      await _repository.updateRecipe(recipe);
      await loadRecipes();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteRecipe(int id) async {
    try {
      await _repository.deleteRecipe(id);
      await loadRecipes();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

class CookingLogsNotifier extends StateNotifier<AsyncValue<List<CookingLog>>> {
  final RecipeRepository _repository;

  CookingLogsNotifier(this._repository) : super(const AsyncValue.loading());

  Future<void> loadLogs(int recipeId) async {
    state = const AsyncValue.loading();
    try {
      final logs = await _repository.getCookingLogs(recipeId);
      state = AsyncValue.data(logs);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addLog(CookingLog log) async {
    try {
      await _repository.insertCookingLog(log);
      await _repository.incrementTimesCooked(log.recipeId);
      await loadLogs(log.recipeId);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}