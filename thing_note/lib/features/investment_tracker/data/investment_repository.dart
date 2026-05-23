import 'package:thing_note/core/database/database_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/investment_entry.dart';

final investmentRepositoryProvider = Provider<InvestmentRepository>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return InvestmentRepository(dbAsync);
});

class InvestmentRepository {
  final AsyncValue<dynamic> _dbAsync;

  InvestmentRepository(this._dbAsync);

  Future<dynamic> get _db async {
    final db = _dbAsync.value;
    if (db == null) throw Exception('Database not initialized');
    return db;
  }

  Future<int> insertInvestment(InvestmentEntry investment) async {
    final db = await _db;
    return await db.insert('investments', investment.toMap());
  }

  Future<List<InvestmentEntry>> getAllInvestments() async {
    final db = await _db;
    final maps = await db.query('investments', orderBy: 'created_at DESC');
    return maps.map((map) => InvestmentEntry.fromMap(map)).toList();
  }

  Future<InvestmentEntry?> getInvestmentById(int id) async {
    final db = await _db;
    final maps = await db.query('investments', where: 'id = ?', whereArgs: [id], limit: 1);
    return maps.isNotEmpty ? InvestmentEntry.fromMap(maps.first) : null;
  }

  Future<int> updateInvestment(InvestmentEntry investment) async {
    final db = await _db;
    return await db.update('investments', investment.toMap(),
        where: 'id = ?', whereArgs: [investment.id]);
  }

  Future<int> deleteInvestment(int id) async {
    final db = await _db;
    return await db.delete('investments', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> insertTransaction(InvestmentTransaction transaction) async {
    final db = await _db;
    return await db.insert('investment_transactions', transaction.toMap());
  }

  Future<List<InvestmentTransaction>> getTransactionsByInvestment(int investmentId) async {
    final db = await _db;
    final maps = await db.query('investment_transactions',
        where: 'investment_id = ?', whereArgs: [investmentId], orderBy: 'date DESC');
    return maps.map((map) => InvestmentTransaction.fromMap(map)).toList();
  }

  Future<double> getTotalInvestmentValue() async {
    final db = await _db;
    final result = await db.rawQuery('SELECT SUM(current_value ?? amount) as total FROM investments');
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<double> getTotalInvestedAmount() async {
    final db = await _db;
    final result = await db.rawQuery('SELECT SUM(amount) as total FROM investments');
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }
}