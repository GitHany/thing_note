import 'package:thing_note/core/database/database_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/warranty_entry.dart';

final warrantyRepositoryProvider = Provider<WarrantyRepository>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return WarrantyRepository(dbAsync);
});

class WarrantyRepository {
  final AsyncValue<dynamic> _dbAsync;

  WarrantyRepository(this._dbAsync);

  Future<dynamic> get _db async {
    final db = _dbAsync.value;
    if (db == null) throw Exception('Database not initialized');
    return db;
  }

  Future<int> insertWarranty(WarrantyEntry warranty) async {
    final db = await _db;
    return await db.insert('warranties', warranty.toMap());
  }

  Future<List<WarrantyEntry>> getAllWarranties() async {
    final db = await _db;
    final maps = await db.query('warranties', orderBy: 'expiry_date ASC');
    return maps.map((map) => WarrantyEntry.fromMap(map)).toList();
  }

  Future<List<WarrantyEntry>> getExpiringWarranties(int days) async {
    final db = await _db;
    final futureDate = DateTime.now().add(Duration(days: days)).toIso8601String().split('T')[0];
    final maps = await db.query(
      'warranties',
      where: 'expiry_date IS NOT NULL AND expiry_date <= ? AND is_active = 1',
      whereArgs: [futureDate],
      orderBy: 'expiry_date ASC',
    );
    return maps.map((map) => WarrantyEntry.fromMap(map)).toList();
  }

  Future<int> updateWarranty(WarrantyEntry warranty) async {
    final db = await _db;
    return await db.update('warranties', warranty.toMap(),
        where: 'id = ?', whereArgs: [warranty.id]);
  }

  Future<int> deleteWarranty(int id) async {
    final db = await _db;
    return await db.delete('warranties', where: 'id = ?', whereArgs: [id]);
  }
}