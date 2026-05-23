import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';

final quickExportRepositoryProvider = Provider<QuickExportRepository>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return QuickExportRepository(dbAsync);
});

class QuickExportRepository {
  final AsyncValue<Database> _dbAsync;

  QuickExportRepository(this._dbAsync);

  Future<Database> get _db async {
    final db = _dbAsync.value;
    if (db == null) throw Exception('Database not initialized');
    return db;
  }

  Future<List<Map<String, dynamic>>> getAllConfigs() async {
    final db = await _db;
    return db.query('quick_export_configs', orderBy: 'use_count DESC');
  }

  Future<int> insertConfig(Map<String, dynamic> config) async {
    final db = await _db;
    return db.insert('quick_export_configs', config);
  }

  Future<void> incrementUseCount(int id) async {
    final db = await _db;
    await db.rawUpdate(
      'UPDATE quick_export_configs SET use_count = use_count + 1 WHERE id = ?',
      [id],
    );
  }
}
