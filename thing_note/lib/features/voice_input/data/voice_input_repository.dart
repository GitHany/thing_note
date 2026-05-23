import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/features/voice_input/domain/voice_input.dart';
import 'package:thing_note/core/database/database_provider.dart';

final voiceInputRepositoryProvider = Provider((ref) => VoiceInputRepository(ref));

class VoiceInputRepository {
  final Ref _ref;

  VoiceInputRepository(this._ref);

  Future<Database> get _db async {
    final db = await _ref.read(databaseProvider.future);
    return db;
  }

  Future<int> saveResult(VoiceInputResult result) async {
    final db = await _db;
    return await db.insert('voice_input_history', result.toMap());
  }

  Future<List<VoiceInputResult>> getHistory({int limit = 50}) async {
    final db = await _db;
    final results = await db.query(
      'voice_input_history',
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return results.map((e) => VoiceInputResult.fromMap(e)).toList();
  }

  Future<List<VoiceInputResult>> getUsedResults() async {
    final db = await _db;
    final results = await db.query(
      'voice_input_history',
      where: 'used = 1',
      orderBy: 'created_at DESC',
    );
    return results.map((e) => VoiceInputResult.fromMap(e)).toList();
  }

  Future<void> markAsUsed(int id) async {
    final db = await _db;
    await db.update(
      'voice_input_history',
      {'used': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteResult(int id) async {
    final db = await _db;
    await db.delete(
      'voice_input_history',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> clearHistory() async {
    final db = await _db;
    await db.delete('voice_input_history');
  }

  /// Get most used phrases for suggestions
  Future<List<String>> getCommonPhrases({int limit = 20}) async {
    final db = await _db;
    final results = await db.rawQuery('''
      SELECT transcribed_text, COUNT(*) as count
      FROM voice_input_history
      WHERE used = 1
      GROUP BY transcribed_text
      ORDER BY count DESC
      LIMIT ?
    ''', [limit]);
    return results.map((e) => e['transcribed_text'] as String).toList();
  }
}