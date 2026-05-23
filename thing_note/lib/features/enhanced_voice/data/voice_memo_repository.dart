import 'package:sqflite/sqflite.dart';
import 'package:thing_note/features/enhanced_voice/domain/voice_memo.dart';

class VoiceMemoRepository {
  final Database db;

  VoiceMemoRepository(this.db);

  Future<int> insertMemo(VoiceMemo memo) async {
    return await db.insert('voice_memos', memo.toMap());
  }

  Future<List<VoiceMemo>> getAllMemos() async {
    final maps = await db.query(
      'voice_memos',
      orderBy: 'created_at DESC',
    );
    return maps.map((m) => VoiceMemo.fromMap(m)).toList();
  }

  Future<List<VoiceMemo>> getMemosForRecord(int recordId) async {
    final maps = await db.query(
      'voice_memos',
      where: 'record_id = ?',
      whereArgs: [recordId],
      orderBy: 'created_at DESC',
    );
    return maps.map((m) => VoiceMemo.fromMap(m)).toList();
  }

  Future<List<VoiceMemo>> searchByTranscription(String query) async {
    final maps = await db.query(
      'voice_memos',
      where: 'transcription LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'created_at DESC',
    );
    return maps.map((m) => VoiceMemo.fromMap(m)).toList();
  }

  Future<List<VoiceMemo>> getFavoriteMemos() async {
    final maps = await db.query(
      'voice_memos',
      where: 'is_favorite = 1',
      orderBy: 'created_at DESC',
    );
    return maps.map((m) => VoiceMemo.fromMap(m)).toList();
  }

  Future<VoiceMemo?> getMemo(int id) async {
    final maps = await db.query(
      'voice_memos',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return VoiceMemo.fromMap(maps.first);
  }

  Future<int> updateMemo(VoiceMemo memo) async {
    return await db.update(
      'voice_memos',
      memo.toMap(),
      where: 'id = ?',
      whereArgs: [memo.id],
    );
  }

  Future<int> deleteMemo(int id) async {
    return await db.delete(
      'voice_memos',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> toggleFavorite(int id) async {
    final memo = await getMemo(id);
    if (memo != null) {
      return await db.update(
        'voice_memos',
        {'is_favorite': memo.isFavorite ? 0 : 1},
        where: 'id = ?',
        whereArgs: [id],
      );
    }
    return 0;
  }

  Future<int> getTotalDuration() async {
    final result = await db.rawQuery(
      'SELECT SUM(duration_sec) as total FROM voice_memos',
    );
    return (result.first['total'] as int?) ?? 0;
  }

  Future<int> getMemoCount() async {
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM voice_memos');
    return (result.first['count'] as int?) ?? 0;
  }

  Future<List<VoiceMemo>> getRecentMemos({int limit = 5}) async {
    final maps = await db.query(
      'voice_memos',
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return maps.map((m) => VoiceMemo.fromMap(m)).toList();
  }
}