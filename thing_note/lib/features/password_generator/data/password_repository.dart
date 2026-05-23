import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';
import 'package:thing_note/features/password_generator/domain/password_generator.dart';

final passwordGeneratorRepositoryProvider = Provider<PasswordGeneratorRepository>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return PasswordGeneratorRepository(dbAsync);
});

class PasswordGeneratorRepository {
  final AsyncValue<Database> _dbAsync;

  PasswordGeneratorRepository(this._dbAsync);

  Future<Database> get _db async {
    final db = _dbAsync.value;
    if (db == null) throw Exception('Database not initialized');
    return db;
  }

  Future<void> savePassword(GeneratedPassword password) async {
    final db = await _db;
    await db.insert('generated_passwords', password.toMap()..remove('id'));
  }

  Future<List<GeneratedPassword>> getRecentPasswords({int limit = 10}) async {
    final db = await _db;
    final result = await db.query(
      'generated_passwords',
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return result.map((map) => GeneratedPassword.fromMap(map)).toList();
  }

  Future<void> deletePassword(int id) async {
    final db = await _db;
    await db.delete(
      'generated_passwords',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> clearHistory() async {
    final db = await _db;
    await db.delete('generated_passwords');
  }
}
