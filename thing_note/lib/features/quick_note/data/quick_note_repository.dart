import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/quick_note/domain/quick_note.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';

final quickNoteRepositoryProvider = Provider<QuickNoteRepository>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return QuickNoteRepository(dbAsync);
});

final quickNotesProvider = StateNotifierProvider<QuickNotesNotifier, AsyncValue<List<QuickNote>>>((ref) {
  final repository = ref.watch(quickNoteRepositoryProvider);
  return QuickNotesNotifier(repository);
});

final pinnedNotesProvider = Provider<AsyncValue<List<QuickNote>>>((ref) {
  final notes = ref.watch(quickNotesProvider);
  return notes.whenData((list) => list.where((n) => n.isPinned).toList());
});

class QuickNoteRepository {
  final AsyncValue<Database> _dbAsync;

  QuickNoteRepository(this._dbAsync);

  Future<Database> get _db async {
    final db = _dbAsync.value;
    if (db == null) throw Exception('Database not initialized');
    return db;
  }

  Future<void> initTable() async {
    final db = await _db;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS quick_notes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        content TEXT NOT NULL,
        color INTEGER NOT NULL DEFAULT 0xFFFFFFFF,
        is_pinned INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
  }

  Future<int> insertNote(QuickNote note) async {
    final db = await _db;
    return db.insert('quick_notes', note.toMap());
  }

  Future<int> updateNote(QuickNote note) async {
    final db = await _db;
    return db.update(
      'quick_notes',
      note.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  Future<int> deleteNote(int id) async {
    final db = await _db;
    return db.delete('quick_notes', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<QuickNote>> getAllNotes() async {
    final db = await _db;
    final maps = await db.query('quick_notes', orderBy: 'is_pinned DESC, updated_at DESC');
    return maps.map((m) => QuickNote.fromMap(m)).toList();
  }

  Future<QuickNote?> getNoteById(int id) async {
    final db = await _db;
    final maps = await db.query('quick_notes', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return QuickNote.fromMap(maps.first);
  }

  Future<void> togglePin(int id) async {
    final note = await getNoteById(id);
    if (note != null) {
      await updateNote(note.copyWith(isPinned: !note.isPinned));
    }
  }
}

class QuickNotesNotifier extends StateNotifier<AsyncValue<List<QuickNote>>> {
  final QuickNoteRepository _repository;

  QuickNotesNotifier(this._repository) : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    await _repository.initTable();
    await loadNotes();
  }

  Future<void> loadNotes() async {
    state = const AsyncValue.loading();
    try {
      final notes = await _repository.getAllNotes();
      state = AsyncValue.data(notes);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addNote(QuickNote note) async {
    try {
      await _repository.insertNote(note);
      await loadNotes();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateNote(QuickNote note) async {
    try {
      await _repository.updateNote(note);
      await loadNotes();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteNote(int id) async {
    try {
      await _repository.deleteNote(id);
      await loadNotes();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> togglePin(int id) async {
    try {
      await _repository.togglePin(id);
      await loadNotes();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}