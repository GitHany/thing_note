import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/link_saver/domain/saved_link.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';

final linkSaverRepositoryProvider = Provider<LinkSaverRepository>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return LinkSaverRepository(dbAsync);
});

final savedLinksProvider = StateNotifierProvider<SavedLinksNotifier, AsyncValue<List<SavedLink>>>((ref) {
  final repository = ref.watch(linkSaverRepositoryProvider);
  return SavedLinksNotifier(repository);
});

class LinkSaverRepository {
  final AsyncValue<Database> _dbAsync;

  LinkSaverRepository(this._dbAsync);

  Future<Database> get _db async {
    final db = _dbAsync.value;
    if (db == null) throw Exception('Database not initialized');
    return db;
  }

  Future<int> insertLink(SavedLink link) async {
    final db = await _db;
    return db.insert('saved_links', link.toMap());
  }

  Future<int> updateLink(SavedLink link) async {
    final db = await _db;
    return db.update(
      'saved_links',
      link.toMap(),
      where: 'id = ?',
      whereArgs: [link.id],
    );
  }

  Future<int> deleteLink(int id) async {
    final db = await _db;
    return db.delete('saved_links', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<SavedLink>> getAllLinks() async {
    final db = await _db;
    final maps = await db.query('saved_links', orderBy: 'created_at DESC');
    return maps.map((m) => SavedLink.fromMap(m)).toList();
  }

  Future<List<SavedLink>> getLinksByStatus(String status) async {
    final db = await _db;
    final maps = await db.query(
      'saved_links',
      where: 'status = ?',
      whereArgs: [status],
      orderBy: 'created_at DESC',
    );
    return maps.map((m) => SavedLink.fromMap(m)).toList();
  }

  Future<List<SavedLink>> searchLinks(String query) async {
    final db = await _db;
    final maps = await db.query(
      'saved_links',
      where: 'title LIKE ? OR description LIKE ? OR note LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: 'created_at DESC',
    );
    return maps.map((m) => SavedLink.fromMap(m)).toList();
  }
}

class SavedLinksNotifier extends StateNotifier<AsyncValue<List<SavedLink>>> {
  final LinkSaverRepository _repository;

  SavedLinksNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadLinks();
  }

  Future<void> loadLinks() async {
    state = const AsyncValue.loading();
    try {
      final links = await _repository.getAllLinks();
      state = AsyncValue.data(links);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addLink(SavedLink link) async {
    try {
      await _repository.insertLink(link);
      await loadLinks();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateLink(SavedLink link) async {
    try {
      await _repository.updateLink(link);
      await loadLinks();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteLink(int id) async {
    try {
      await _repository.deleteLink(id);
      await loadLinks();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateStatus(int id, String status) async {
    final links = state.valueOrNull ?? [];
    final link = links.firstWhere((l) => l.id == id);
    final updated = link.copyWith(
      status: status,
      updatedAt: DateTime.now(),
    );
    await updateLink(updated);
  }
}