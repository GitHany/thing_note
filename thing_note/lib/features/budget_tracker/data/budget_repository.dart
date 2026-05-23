import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/budget_tracker/domain/budget.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';

final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return BudgetRepository(dbAsync);
});

final budgetsProvider = StateNotifierProvider<BudgetsNotifier, AsyncValue<List<Budget>>>((ref) {
  final repository = ref.watch(budgetRepositoryProvider);
  return BudgetsNotifier(repository);
});

final expensesProvider = StateNotifierProvider<ExpensesNotifier, AsyncValue<List<Expense>>>((ref) {
  final repository = ref.watch(budgetRepositoryProvider);
  return ExpensesNotifier(repository);
});

final budgetStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repository = ref.watch(budgetRepositoryProvider);
  return repository.getBudgetStats();
});

class BudgetRepository {
  final AsyncValue<Database> _dbAsync;

  BudgetRepository(this._dbAsync);

  Future<Database> get _db async {
    final db = _dbAsync.value;
    if (db == null) throw Exception('Database not initialized');
    return db;
  }

  Future<int> insertBudget(Budget budget) async {
    final db = await _db;
    return db.insert('budgets', budget.toMap());
  }

  Future<int> updateBudget(Budget budget) async {
    final db = await _db;
    return db.update('budgets', budget.toMap(), where: 'id = ?', whereArgs: [budget.id]);
  }

  Future<int> deleteBudget(int id) async {
    final db = await _db;
    return db.delete('budgets', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Budget>> getAllBudgets() async {
    final db = await _db;
    final maps = await db.query('budgets', orderBy: 'created_at DESC');
    return maps.map((m) => Budget.fromMap(m)).toList();
  }

  Future<int> insertExpense(Expense expense) async {
    final db = await _db;
    return db.insert('expenses', expense.toMap());
  }

  Future<int> deleteExpense(int id) async {
    final db = await _db;
    return db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Expense>> getExpensesByDate(String date) async {
    final db = await _db;
    final maps = await db.query(
      'expenses',
      where: 'date = ?',
      whereArgs: [date],
      orderBy: 'created_at DESC',
    );
    return maps.map((m) => Expense.fromMap(m)).toList();
  }

  Future<List<Expense>> getExpensesForMonth(int year, int month) async {
    final db = await _db;
    final startDate = '$year-${month.toString().padLeft(2, '0')}-01';
    final endDate = '$year-${month.toString().padLeft(2, '0')}-31';
    
    final maps = await db.query(
      'expenses',
      where: 'date >= ? AND date <= ?',
      whereArgs: [startDate, endDate],
      orderBy: 'date DESC',
    );
    return maps.map((m) => Expense.fromMap(m)).toList();
  }

  Future<double> getMonthTotal(int year, int month) async {
    final db = await _db;
    final startDate = '$year-${month.toString().padLeft(2, '0')}-01';
    final endDate = '$year-${month.toString().padLeft(2, '0')}-31';
    
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) as total FROM expenses WHERE date >= ? AND date <= ?',
      [startDate, endDate],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0;
  }

  Future<Map<String, double>> getCategoryStats(int year, int month) async {
    final db = await _db;
    final startDate = '$year-${month.toString().padLeft(2, '0')}-01';
    final endDate = '$year-${month.toString().padLeft(2, '0')}-31';
    
    final result = await db.rawQuery('''
      SELECT category, COALESCE(SUM(amount), 0) as total 
      FROM expenses 
      WHERE date >= ? AND date <= ?
      GROUP BY category
    ''', [startDate, endDate]);
    
    final stats = <String, double>{};
    for (final row in result) {
      stats[row['category'] as String] = (row['total'] as num).toDouble();
    }
    return stats;
  }

  Future<Map<String, dynamic>> getBudgetStats() async {
    final now = DateTime.now();
    final monthTotal = await getMonthTotal(now.year, now.month);
    final budgets = await getAllBudgets();
    
    final monthBudget = budgets.isNotEmpty ? budgets.first.amount : 0.0;
    final remaining = monthBudget - monthTotal;
    final percentage = monthBudget > 0 ? (monthTotal / monthBudget * 100) : 0.0;
    
    return {
      'monthTotal': monthTotal,
      'monthBudget': monthBudget,
      'remaining': remaining,
      'percentage': percentage.clamp(0, 100),
    };
  }
}

class BudgetsNotifier extends StateNotifier<AsyncValue<List<Budget>>> {
  final BudgetRepository _repository;

  BudgetsNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadBudgets();
  }

  Future<void> loadBudgets() async {
    state = const AsyncValue.loading();
    try {
      final budgets = await _repository.getAllBudgets();
      state = AsyncValue.data(budgets);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addBudget(Budget budget) async {
    try {
      await _repository.insertBudget(budget);
      await loadBudgets();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteBudget(int id) async {
    try {
      await _repository.deleteBudget(id);
      await loadBudgets();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

class ExpensesNotifier extends StateNotifier<AsyncValue<List<Expense>>> {
  final BudgetRepository _repository;

  ExpensesNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadExpenses();
  }

  Future<void> loadExpenses() async {
    state = const AsyncValue.loading();
    try {
      final now = DateTime.now();
      final expenses = await _repository.getExpensesForMonth(now.year, now.month);
      state = AsyncValue.data(expenses);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addExpense(Expense expense) async {
    try {
      await _repository.insertExpense(expense);
      await loadExpenses();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteExpense(int id) async {
    try {
      await _repository.deleteExpense(id);
      await loadExpenses();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}