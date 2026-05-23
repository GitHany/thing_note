import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/receipt_collection/domain/receipt.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';

final receiptRepositoryProvider = Provider<ReceiptRepository>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return ReceiptRepository(dbAsync);
});

final receiptsProvider = StateNotifierProvider<ReceiptsNotifier, AsyncValue<List<Receipt>>>((ref) {
  final repository = ref.watch(receiptRepositoryProvider);
  return ReceiptsNotifier(repository);
});

final unclaimedReceiptsProvider = Provider<AsyncValue<List<Receipt>>>((ref) {
  final receipts = ref.watch(receiptsProvider);
  return receipts.whenData((list) => list.where((r) => !r.isClaimed).toList());
});

class ReceiptRepository {
  final AsyncValue<Database> _dbAsync;

  ReceiptRepository(this._dbAsync);

  Future<Database> get _db async {
    final db = _dbAsync.value;
    if (db == null) throw Exception('Database not initialized');
    return db;
  }

  Future<int> insertReceipt(Receipt receipt) async {
    final db = await _db;
    return db.insert('receipts', receipt.toMap());
  }

  Future<int> updateReceipt(Receipt receipt) async {
    final db = await _db;
    return db.update(
      'receipts',
      receipt.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [receipt.id],
    );
  }

  Future<int> deleteReceipt(int id) async {
    final db = await _db;
    return db.delete('receipts', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Receipt>> getAllReceipts() async {
    final db = await _db;
    final maps = await db.query('receipts', orderBy: 'created_at DESC');
    return maps.map((m) => Receipt.fromMap(m)).toList();
  }

  Future<List<Receipt>> getReceiptsByMonth(int year, int month) async {
    final db = await _db;
    final startOfMonth = DateTime(year, month, 1);
    final endOfMonth = DateTime(year, month + 1, 1);
    final maps = await db.query(
      'receipts',
      where: 'purchase_date >= ? AND purchase_date < ?',
      whereArgs: [startOfMonth.toIso8601String(), endOfMonth.toIso8601String()],
      orderBy: 'purchase_date DESC',
    );
    return maps.map((m) => Receipt.fromMap(m)).toList();
  }

  Future<double> getTotalUnclaimedAmount() async {
    final db = await _db;
    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM receipts WHERE is_claimed = 0 AND amount IS NOT NULL',
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }
}

class ReceiptsNotifier extends StateNotifier<AsyncValue<List<Receipt>>> {
  final ReceiptRepository _repository;

  ReceiptsNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadReceipts();
  }

  Future<void> loadReceipts() async {
    state = const AsyncValue.loading();
    try {
      final receipts = await _repository.getAllReceipts();
      state = AsyncValue.data(receipts);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addReceipt(Receipt receipt) async {
    try {
      await _repository.insertReceipt(receipt);
      await loadReceipts();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateReceipt(Receipt receipt) async {
    try {
      await _repository.updateReceipt(receipt);
      await loadReceipts();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteReceipt(int id) async {
    try {
      await _repository.deleteReceipt(id);
      await loadReceipts();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> markAsClaimed(int id) async {
    try {
      final receipts = state.value;
      if (receipts == null) return;
      final receipt = receipts.firstWhere((r) => r.id == id);
      await _repository.updateReceipt(receipt.copyWith(isClaimed: true));
      await loadReceipts();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}