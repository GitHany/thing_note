import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/password_manager/domain/password_entry.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';

final passwordRepositoryProvider = Provider<PasswordRepository>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return PasswordRepository(dbAsync);
});

final passwordEntriesProvider = StateNotifierProvider<PasswordEntriesNotifier, AsyncValue<List<PasswordEntry>>>((ref) {
  final repository = ref.watch(passwordRepositoryProvider);
  return PasswordEntriesNotifier(repository);
});

final favoritePasswordsProvider = Provider<AsyncValue<List<PasswordEntry>>>((ref) {
  final entries = ref.watch(passwordEntriesProvider);
  return entries.whenData((list) => list.where((e) => e.isFavorite).toList());
});

class PasswordRepository {
  final AsyncValue<Database> _dbAsync;

  PasswordRepository(this._dbAsync);

  Future<Database> get _db async {
    final db = _dbAsync.value;
    if (db == null) throw Exception('Database not initialized');
    return db;
  }

  Future<int> insertPassword(PasswordEntry entry) async {
    final db = await _db;
    return db.insert('password_entries', entry.toMap());
  }

  Future<int> updatePassword(PasswordEntry entry) async {
    final db = await _db;
    return db.update(
      'password_entries',
      entry.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  Future<int> deletePassword(int id) async {
    final db = await _db;
    return db.delete('password_entries', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<PasswordEntry>> getAllPasswords() async {
    final db = await _db;
    final maps = await db.query('password_entries', orderBy: 'title ASC');
    return maps.map((m) => PasswordEntry.fromMap(m)).toList();
  }

  Future<List<PasswordEntry>> getPasswordsByCategory(String category) async {
    final db = await _db;
    final maps = await db.query(
      'password_entries',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'title ASC',
    );
    return maps.map((m) => PasswordEntry.fromMap(m)).toList();
  }

  Future<List<PasswordEntry>> searchPasswords(String query) async {
    final db = await _db;
    final maps = await db.query(
      'password_entries',
      where: 'title LIKE ? OR username LIKE ? OR url LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: 'title ASC',
    );
    return maps.map((m) => PasswordEntry.fromMap(m)).toList();
  }

  Future<int> toggleFavorite(int id, bool isFavorite) async {
    final db = await _db;
    return db.update(
      'password_entries',
      {'is_favorite': isFavorite ? 1 : 0, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

class PasswordEntriesNotifier extends StateNotifier<AsyncValue<List<PasswordEntry>>> {
  final PasswordRepository _repository;

  PasswordEntriesNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadPasswords();
  }

  Future<void> loadPasswords() async {
    state = const AsyncValue.loading();
    try {
      final entries = await _repository.getAllPasswords();
      state = AsyncValue.data(entries);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addPassword(PasswordEntry entry) async {
    try {
      await _repository.insertPassword(entry);
      await loadPasswords();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updatePassword(PasswordEntry entry) async {
    try {
      await _repository.updatePassword(entry);
      await loadPasswords();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deletePassword(int id) async {
    try {
      await _repository.deletePassword(id);
      await loadPasswords();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> toggleFavorite(int id, bool isFavorite) async {
    try {
      await _repository.toggleFavorite(id, isFavorite);
      await loadPasswords();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}