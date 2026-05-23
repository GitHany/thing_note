import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/voice_journal/domain/voice_journal_entry.dart';
import 'package:thing_note/core/database/database_provider.dart';
import 'package:sqflite/sqflite.dart';

final voiceJournalRepositoryProvider = Provider<VoiceJournalRepository>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return VoiceJournalRepository(dbAsync);
});

final voiceJournalEntriesProvider = FutureProvider<List<VoiceJournalEntry>>((ref) async {
  final repo = ref.watch(voiceJournalRepositoryProvider);
  return repo.getAllEntries();
});

final voiceJournalTodayProvider = FutureProvider<List<VoiceJournalEntry>>((ref) async {
  final repo = ref.watch(voiceJournalRepositoryProvider);
  return repo.getEntriesForDate(_todayDate());
});

String _todayDate() {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
}

class VoiceJournalRepository {
  final AsyncValue<Database> _dbAsync;

  VoiceJournalRepository(this._dbAsync);

  Future<Database> get _db async {
    final db = _dbAsync.value;
    if (db == null) throw Exception('Database not initialized');
    return db;
  }

  Future<int> insertEntry(VoiceJournalEntry entry) async {
    final db = await _db;
    return db.insert('voice_journal_entries', entry.toMap());
  }

  Future<int> updateEntry(VoiceJournalEntry entry) async {
    final db = await _db;
    return db.update('voice_journal_entries', entry.toMap(), where: 'id = ?', whereArgs: [entry.id]);
  }

  Future<int> deleteEntry(int id) async {
    final db = await _db;
    return db.delete('voice_journal_entries', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<VoiceJournalEntry>> getAllEntries() async {
    final db = await _db;
    final maps = await db.query('voice_journal_entries', orderBy: 'created_at DESC');
    return maps.map((m) => VoiceJournalEntry.fromMap(m)).toList();
  }

  Future<List<VoiceJournalEntry>> getEntriesForDate(String date) async {
    final db = await _db;
    final maps = await db.query(
      'voice_journal_entries',
      where: 'date = ?',
      whereArgs: [date],
      orderBy: 'created_at DESC',
    );
    return maps.map((m) => VoiceJournalEntry.fromMap(m)).toList();
  }

  Future<List<VoiceJournalEntry>> getFavoriteEntries() async {
    final db = await _db;
    final maps = await db.query(
      'voice_journal_entries',
      where: 'is_favorite = 1',
      orderBy: 'created_at DESC',
    );
    return maps.map((m) => VoiceJournalEntry.fromMap(m)).toList();
  }

  Future<int> updateTranscript(int id, String transcript) async {
    final db = await _db;
    return db.update(
      'voice_journal_entries',
      {'transcript': transcript, 'is_transcribed': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> toggleFavorite(int id, bool isFavorite) async {
    final db = await _db;
    return db.update(
      'voice_journal_entries',
      {'is_favorite': isFavorite ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<Map<String, int>> getStats() async {
    final db = await _db;
    final total = await db.rawQuery('SELECT COUNT(*) as count, SUM(duration_seconds) as total_duration FROM voice_journal_entries');
    final maps = total.first;
    return {
      'count': maps['count'] as int? ?? 0,
      'total_duration': maps['total_duration'] as int? ?? 0,
    };
  }
}
