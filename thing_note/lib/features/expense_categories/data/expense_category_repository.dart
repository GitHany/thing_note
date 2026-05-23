import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/expense_category.dart';

final expenseCategoryRepositoryProvider = Provider<ExpenseCategoryRepository>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return ExpenseCategoryRepository(dbAsync);
});

class ExpenseCategoryRepository {
  final AsyncValue<Database> _dbAsync;

  ExpenseCategoryRepository(this._dbAsync);

  Future<Database> get _db async {
    final db = _dbAsync.value;
    if (db == null) throw Exception('Database not initialized');
    return db;
  }

  Future<int> insertCategory(ExpenseCategory category) async {
    final db = await _db;
    return await db.insert('expense_categories', category.toMap());
  }

  Future<List<ExpenseCategory>> getAllCategories() async {
    final db = await _db;
    final maps = await db.query('expense_categories', orderBy: 'name ASC');
    return maps.map((map) => ExpenseCategory.fromMap(map)).toList();
  }

  Future<int> updateCategory(ExpenseCategory category) async {
    final db = await _db;
    return await db.update(
      'expense_categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<int> deleteCategory(int id) async {
    final db = await _db;
    return await db.delete(
      'expense_categories',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<ExpenseCategory?> getCategoryById(int id) async {
    final db = await _db;
    final maps = await db.query(
      'expense_categories',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return maps.isNotEmpty ? ExpenseCategory.fromMap(maps.first) : null;
  }
}