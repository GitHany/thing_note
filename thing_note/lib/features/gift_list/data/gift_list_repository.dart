import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/gift_list/domain/gift_item.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';

final giftListRepositoryProvider = Provider<GiftListRepository>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return GiftListRepository(dbAsync);
});

final giftItemsProvider = StateNotifierProvider<GiftItemsNotifier, AsyncValue<List<GiftItem>>>((ref) {
  final repository = ref.watch(giftListRepositoryProvider);
  return GiftItemsNotifier(repository);
});

final pendingGiftItemsProvider = Provider<AsyncValue<List<GiftItem>>>((ref) {
  final items = ref.watch(giftItemsProvider);
  return items.whenData((list) => list.where((i) => i.status == GiftStatus.pending).toList());
});

class GiftListRepository {
  final AsyncValue<Database> _dbAsync;

  GiftListRepository(this._dbAsync);

  Future<Database> get _db async {
    final db = _dbAsync.value;
    if (db == null) throw Exception('Database not initialized');
    return db;
  }

  Future<int> insertGiftItem(GiftItem item) async {
    final db = await _db;
    return db.insert('gift_items', item.toMap());
  }

  Future<int> updateGiftItem(GiftItem item) async {
    final db = await _db;
    return db.update(
      'gift_items',
      item.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> deleteGiftItem(int id) async {
    final db = await _db;
    return db.delete('gift_items', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<GiftItem>> getAllGiftItems() async {
    final db = await _db;
    final maps = await db.query('gift_items', orderBy: 'due_date ASC, priority DESC');
    return maps.map((m) => GiftItem.fromMap(m)).toList();
  }

  Future<List<GiftItem>> getGiftItemsByRecipient(String recipient) async {
    final db = await _db;
    final maps = await db.query(
      'gift_items',
      where: 'recipient = ?',
      whereArgs: [recipient],
      orderBy: 'due_date ASC',
    );
    return maps.map((m) => GiftItem.fromMap(m)).toList();
  }

  Future<List<String>> getAllRecipients() async {
    final db = await _db;
    final maps = await db.rawQuery('SELECT DISTINCT recipient FROM gift_items ORDER BY recipient');
    return maps.map((m) => m['recipient'] as String).toList();
  }

  Future<double> getTotalBudget() async {
    final db = await _db;
    final result = await db.rawQuery(
      'SELECT SUM(price) as total FROM gift_items WHERE status = ? AND price IS NOT NULL',
      [GiftStatus.pending.name],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }
}

class GiftItemsNotifier extends StateNotifier<AsyncValue<List<GiftItem>>> {
  final GiftListRepository _repository;

  GiftItemsNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadItems();
  }

  Future<void> loadItems() async {
    state = const AsyncValue.loading();
    try {
      final items = await _repository.getAllGiftItems();
      state = AsyncValue.data(items);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addGiftItem(GiftItem item) async {
    try {
      await _repository.insertGiftItem(item);
      await loadItems();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateGiftItem(GiftItem item) async {
    try {
      await _repository.updateGiftItem(item);
      await loadItems();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteGiftItem(int id) async {
    try {
      await _repository.deleteGiftItem(id);
      await loadItems();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> markAsPurchased(int id) async {
    try {
      final items = state.value;
      if (items == null) return;
      final item = items.firstWhere((i) => i.id == id);
      await _repository.updateGiftItem(item.copyWith(status: GiftStatus.purchased));
      await loadItems();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> markAsGiven(int id) async {
    try {
      final items = state.value;
      if (items == null) return;
      final item = items.firstWhere((i) => i.id == id);
      await _repository.updateGiftItem(item.copyWith(status: GiftStatus.given));
      await loadItems();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}