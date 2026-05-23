import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';
import '../domain/knowledge_model.dart';

final knowledgeBaseRepositoryProvider = Provider<KnowledgeBaseRepository>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return KnowledgeBaseRepository(dbAsync);
});

class KnowledgeBaseRepository {
  final AsyncValue<Database> _dbAsync;

  KnowledgeBaseRepository(this._dbAsync);

  Future<Database> get _db async {
    final db = _dbAsync.value;
    if (db == null) throw Exception('Database not initialized');
    return db;
  }

  Future<int> insertKnowledge(KnowledgeEntry entry) async {
    final db = await _db;
    return await db.insert('knowledge_base', entry.toMap());
  }

  Future<int> updateKnowledge(KnowledgeEntry entry) async {
    final db = await _db;
    return await db.update(
      'knowledge_base',
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  Future<int> deleteKnowledge(int id) async {
    final db = await _db;
    return await db.delete(
      'knowledge_base',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<KnowledgeEntry>> getAllKnowledge() async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      'knowledge_base',
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => KnowledgeEntry.fromMap(map)).toList();
  }

  Future<List<KnowledgeEntry>> searchKnowledge(String query) async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      'knowledge_base',
      where: 'title LIKE ? OR content LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => KnowledgeEntry.fromMap(map)).toList();
  }

  Future<List<KnowledgeEntry>> getKnowledgeByTag(String tag) async {
    final db = await _db;
    final results = await db.rawQuery('''
      SELECT k.* FROM knowledge_base k
      INNER JOIN knowledge_tags kt ON k.id = kt.knowledge_id
      WHERE kt.tag = ?
      ORDER BY k.created_at DESC
    ''', [tag]);
    return results.map((map) => KnowledgeEntry.fromMap(map)).toList();
  }

  Future<List<String>> getAllTags() async {
    final db = await _db;
    final result = await db.rawQuery('''
      SELECT DISTINCT tag FROM knowledge_tags
      WHERE tag IS NOT NULL AND tag != ''
      ORDER BY tag
    ''');
    return result.map((r) => r['tag'] as String).toList();
  }

  Future<void> addTag(int knowledgeId, String tag) async {
    final db = await _db;
    await db.insert('knowledge_tags', {
      'knowledge_id': knowledgeId,
      'tag': tag,
    });
  }

  Future<List<String>> getTagsForKnowledge(int knowledgeId) async {
    final db = await _db;
    final result = await db.query(
      'knowledge_tags',
      where: 'knowledge_id = ?',
      whereArgs: [knowledgeId],
    );
    return result.map((r) => r['tag'] as String).toList();
  }

  Future<void> removeTag(int knowledgeId, String tag) async {
    final db = await _db;
    await db.delete(
      'knowledge_tags',
      where: 'knowledge_id = ? AND tag = ?',
      whereArgs: [knowledgeId, tag],
    );
  }

  Future<Map<String, int>> getStatistics() async {
    final db = await _db;
    
    final totalResult = await db.rawQuery('SELECT COUNT(*) as count FROM knowledge_base');
    final total = totalResult.first['count'] as int? ?? 0;
    
    final tagsResult = await db.rawQuery('SELECT COUNT(DISTINCT tag) as count FROM knowledge_tags');
    final tagsCount = tagsResult.first['count'] as int? ?? 0;
    
    return {
      'total_entries': total,
      'total_tags': tagsCount,
    };
  }
}
