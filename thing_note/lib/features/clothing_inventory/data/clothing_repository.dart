import 'package:thing_note/core/database/database_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/clothing_item.dart';

final clothingRepositoryProvider = Provider<ClothingRepository>((ref) {
  return ClothingRepository(ref);
});

class ClothingRepository {
  final Ref _ref;

  ClothingRepository(this._ref);

  Future<dynamic> get _db async {
    return await _ref.read(databaseProvider.future);
  }

  Future<int> insertClothing(ClothingItem item) async {
    final db = await _db;
    return await db.insert('clothing_items', item.toMap());
  }

  Future<List<ClothingItem>> getAllClothing() async {
    final db = await _db;
    final maps = await db.query('clothing_items', orderBy: 'created_at DESC');
    return maps.map((map) => ClothingItem.fromMap(map)).toList();
  }

  Future<List<ClothingItem>> getClothingByCategory(String category) async {
    final db = await _db;
    final maps = await db.query('clothing_items', where: 'category = ?', whereArgs: [category], orderBy: 'created_at DESC');
    return maps.map((map) => ClothingItem.fromMap(map)).toList();
  }

  Future<int> updateClothing(ClothingItem item) async {
    final db = await _db;
    return await db.update('clothing_items', item.toMap(), where: 'id = ?', whereArgs: [item.id]);
  }

  Future<int> deleteClothing(int id) async {
    final db = await _db;
    return await db.delete('clothing_items', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> incrementWearCount(int id) async {
    final db = await _db;
    return await db.rawUpdate('UPDATE clothing_items SET wear_count = wear_count + 1 WHERE id = ?', [id]);
  }

  Future<Map<String, int>> getCategoryStats() async {
    final db = await _db;
    final result = await db.rawQuery('SELECT category, COUNT(*) as count FROM clothing_items GROUP BY category');
    return {for (final row in result) row['category'] as String: row['count'] as int};
  }
}