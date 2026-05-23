import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';
import 'package:thing_note/features/voice_recorder/domain/voice_entry.dart';

final voiceEntriesProvider = FutureProvider<List<VoiceEntry>>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  final List<Map<String, dynamic>> maps = await db.query(
    'voice_entries',
    orderBy: 'created_at DESC',
  );
  return maps.map((map) => VoiceEntry.fromMap(map)).toList();
});

class VoiceRecorderRepository {
  final Database db;

  VoiceRecorderRepository(this.db);

  Future<int> insert(VoiceEntry entry) async {
    final map = entry.toMap();
    map.remove('id');
    return db.insert('voice_entries', map);
  }

  Future<void> update(VoiceEntry entry) async {
    await db.update(
      'voice_entries',
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  Future<void> delete(int id) async {
    await db.delete(
      'voice_entries',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<VoiceEntry>> getAll() async {
    final List<Map<String, dynamic>> maps = await db.query(
      'voice_entries',
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => VoiceEntry.fromMap(map)).toList();
  }

  Future<List<VoiceEntry>> getFavorites() async {
    final List<Map<String, dynamic>> maps = await db.query(
      'voice_entries',
      where: 'is_favorite = ?',
      whereArgs: [1],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => VoiceEntry.fromMap(map)).toList();
  }

  Future<void> toggleFavorite(int id) async {
    final entry = await db.query(
      'voice_entries',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (entry.isNotEmpty) {
      final current = entry.first['is_favorite'] as int;
      await db.update(
        'voice_entries',
        {'is_favorite': current == 1 ? 0 : 1},
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }

  Future<int> getTotalCount() async {
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM voice_entries');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getTotalDuration() async {
    final result = await db.rawQuery(
        'SELECT SUM(duration_sec) as total FROM voice_entries');
    return Sqflite.firstIntValue(result) ?? 0;
  }
}