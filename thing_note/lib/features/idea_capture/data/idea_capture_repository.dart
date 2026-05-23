import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/core/database/database_provider.dart';
import 'package:thing_note/features/idea_capture/domain/idea_capture.dart';

class IdeaCaptureRepository {
  final Ref _ref;

  IdeaCaptureRepository(this._ref);

  Future<List<IdeaCapture>> getAllIdeas() async {
    final db = await _ref.read(databaseProvider.future);
    final result = await db.query(
      'idea_captures',
      orderBy: 'created_at DESC',
    );
    return result.map((e) => IdeaCapture.fromMap(e)).toList();
  }

  Future<List<IdeaCapture>> getUnconvertedIdeas() async {
    final db = await _ref.read(databaseProvider.future);
    final result = await db.query(
      'idea_captures',
      where: 'is_converted = 0',
      orderBy: 'created_at DESC',
    );
    return result.map((e) => IdeaCapture.fromMap(e)).toList();
  }

  Future<List<IdeaCapture>> getIdeasByCategory(String category) async {
    final db = await _ref.read(databaseProvider.future);
    final result = await db.query(
      'idea_captures',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'created_at DESC',
    );
    return result.map((e) => IdeaCapture.fromMap(e)).toList();
  }

  Future<int> insertIdea(IdeaCapture idea) async {
    final db = await _ref.read(databaseProvider.future);
    return db.insert('idea_captures', idea.toMap()..remove('id'));
  }

  Future<int> updateIdea(IdeaCapture idea) async {
    final db = await _ref.read(databaseProvider.future);
    return db.update(
      'idea_captures',
      idea.toMap()..['updated_at'] = DateTime.now().toIso8601String(),
      where: 'id = ?',
      whereArgs: [idea.id],
    );
  }

  Future<int> deleteIdea(int id) async {
    final db = await _ref.read(databaseProvider.future);
    return db.delete('idea_captures', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> markAsConverted(int id, String type, int recordId) async {
    final db = await _ref.read(databaseProvider.future);
    return db.update(
      'idea_captures',
      {
        'is_converted': 1,
        'converted_to_type': type,
        'converted_to_id': recordId,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<String>> getCategories() async {
    final db = await _ref.read(databaseProvider.future);
    final result = await db.rawQuery('''
      SELECT DISTINCT category FROM idea_captures
      WHERE category IS NOT NULL AND category != ''
    ''');
    return result.map((e) => e['category'] as String).toList();
  }
}