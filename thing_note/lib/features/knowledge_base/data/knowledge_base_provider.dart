import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';
import 'package:thing_note/features/knowledge_base/domain/knowledge_entry.dart';

final knowledgeBaseProvider = StateNotifierProvider<KnowledgeBaseNotifier, AsyncValue<List<KnowledgeEntry>>>((ref) {
  return KnowledgeBaseNotifier(ref);
});

class KnowledgeBaseNotifier extends StateNotifier<AsyncValue<List<KnowledgeEntry>>> {
  final Ref ref;

  KnowledgeBaseNotifier(this.ref) : super(const AsyncValue.loading()) {
    loadEntries();
  }

  Future<Database> get _db => ref.read(databaseProvider.future);

  Future<void> loadEntries() async {
    try {
      state = const AsyncValue.loading();
      final db = await _db;
      final maps = await db.query('knowledge_entries', orderBy: 'use_count DESC, created_at DESC');
      final entries = maps.map((m) => KnowledgeEntry.fromMap(m)).toList();
      state = AsyncValue.data(entries);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<int> addEntry(KnowledgeEntry entry) async {
    final db = await _db;
    final id = await db.insert('knowledge_entries', entry.toMap()..remove('id'));
    await loadEntries();
    return id;
  }

  Future<void> updateEntry(KnowledgeEntry entry) async {
    final db = await _db;
    await db.update(
      'knowledge_entries',
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
    await loadEntries();
  }

  Future<void> deleteEntry(int id) async {
    final db = await _db;
    await db.delete('knowledge_entries', where: 'id = ?', whereArgs: [id]);
    await loadEntries();
  }

  Future<void> incrementUseCount(int id) async {
    final db = await _db;
    await db.rawUpdate(
      'UPDATE knowledge_entries SET use_count = use_count + 1 WHERE id = ?',
      [id],
    );
    await loadEntries();
  }

  Future<void> toggleFavorite(int id) async {
    final db = await _db;
    final entries = state.value ?? [];
    final entry = entries.firstWhere((e) => e.id == id);
    await db.update(
      'knowledge_entries',
      {'is_favorite': entry.isFavorite == 1 ? 0 : 1},
      where: 'id = ?',
      whereArgs: [id],
    );
    await loadEntries();
  }

  Future<List<KnowledgeEntry>> searchEntries(String query) async {
    final db = await _db;
    final maps = await db.query(
      'knowledge_entries',
      where: 'title LIKE ? OR content LIKE ? OR tags LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: 'use_count DESC',
    );
    return maps.map((m) => KnowledgeEntry.fromMap(m)).toList();
  }

  Future<List<KnowledgeEntry>> getEntriesByCategory(String category) async {
    final entries = state.value ?? [];
    return entries.where((e) => e.category == category).toList();
  }
}