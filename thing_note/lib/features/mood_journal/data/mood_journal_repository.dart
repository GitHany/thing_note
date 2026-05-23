import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';

class MoodJournal {
  final int? id;
  final String date;
  final int moodLevel;
  final String? gratitudeItems;
  final String? detailedNote;
  final String? triggers;
  final int? linkedRecordId;
  final DateTime createdAt;

  const MoodJournal({
    this.id,
    required this.date,
    required this.moodLevel,
    this.gratitudeItems,
    this.detailedNote,
    this.triggers,
    this.linkedRecordId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'date': date,
      'mood_level': moodLevel,
      'gratitude_items': gratitudeItems,
      'detailed_note': detailedNote,
      'triggers': triggers,
      'linked_record_id': linkedRecordId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory MoodJournal.fromMap(Map<String, dynamic> map) {
    return MoodJournal(
      id: map['id'] as int?,
      date: map['date'] as String,
      moodLevel: map['mood_level'] as int,
      gratitudeItems: map['gratitude_items'] as String?,
      detailedNote: map['detailed_note'] as String?,
      triggers: map['triggers'] as String?,
      linkedRecordId: map['linked_record_id'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

final moodJournalRepositoryProvider = Provider<MoodJournalRepository>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return MoodJournalRepository(dbAsync);
});

final moodJournalsProvider = StateNotifierProvider<MoodJournalsNotifier, AsyncValue<List<MoodJournal>>>((ref) {
  final repository = ref.watch(moodJournalRepositoryProvider);
  return MoodJournalsNotifier(repository);
});

final moodJournalTrendProvider = Provider<AsyncValue<List<Map<String, dynamic>>>>((ref) {
  final journals = ref.watch(moodJournalsProvider);
  return journals.whenData((data) {
    final sorted = data.toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    return sorted.take(7).map((j) => {
      'date': j.date,
      'level': j.moodLevel,
    }).toList();
  });
});

class MoodJournalRepository {
  final AsyncValue<Database> _dbAsync;

  MoodJournalRepository(this._dbAsync);

  Future<Database> get _db async {
    final db = _dbAsync.value;
    if (db == null) throw Exception('Database not initialized');
    return db;
  }

  Future<int> insertMoodJournal(MoodJournal journal) async {
    final db = await _db;
    return db.insert('mood_journals', journal.toMap());
  }

  Future<int> deleteMoodJournal(int id) async {
    final db = await _db;
    return db.delete('mood_journals', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<MoodJournal>> getAllMoodJournals() async {
    final db = await _db;
    final maps = await db.query('mood_journals', orderBy: 'date DESC');
    return maps.map((m) => MoodJournal.fromMap(m)).toList();
  }

  Future<MoodJournal?> getMoodJournalByDate(String date) async {
    final db = await _db;
    final maps = await db.query(
      'mood_journals',
      where: 'date = ?',
      whereArgs: [date],
    );
    if (maps.isEmpty) return null;
    return MoodJournal.fromMap(maps.first);
  }
}

class MoodJournalsNotifier extends StateNotifier<AsyncValue<List<MoodJournal>>> {
  final MoodJournalRepository _repository;

  MoodJournalsNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadJournals();
  }

  Future<void> loadJournals() async {
    state = const AsyncValue.loading();
    try {
      final journals = await _repository.getAllMoodJournals();
      state = AsyncValue.data(journals);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addMoodJournal(MoodJournal journal) async {
    try {
      await _repository.insertMoodJournal(journal);
      await loadJournals();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteMoodJournal(int id) async {
    try {
      await _repository.deleteMoodJournal(id);
      await loadJournals();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

List<String> get moodLevelLabels => ['非常差', '差', '一般', '好', '非常好'];

List<String> get moodLevelEmojis => ['😢', '😕', '😐', '🙂', '😄'];

List<String> get commonTriggers => ['工作', '学习', '家庭', '健康', '社交', '睡眠', '运动', '饮食'];