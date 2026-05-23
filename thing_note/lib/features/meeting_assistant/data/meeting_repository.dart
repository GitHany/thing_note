import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/meeting_assistant/domain/meeting.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';

final meetingRepositoryProvider = Provider<MeetingRepository>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return MeetingRepository(dbAsync);
});

final meetingsProvider = StateNotifierProvider<MeetingsNotifier, AsyncValue<List<Meeting>>>((ref) {
  final repository = ref.watch(meetingRepositoryProvider);
  return MeetingsNotifier(repository);
});

class MeetingRepository {
  final AsyncValue<Database> _dbAsync;

  MeetingRepository(this._dbAsync);

  Future<Database> get _db async {
    final db = _dbAsync.value;
    if (db == null) throw Exception('Database not initialized');
    return db;
  }

  Future<int> insertMeeting(Meeting meeting) async {
    final db = await _db;
    return db.insert('meetings', meeting.toMap());
  }

  Future<int> updateMeeting(Meeting meeting) async {
    final db = await _db;
    return db.update('meetings', meeting.toMap(), where: 'id = ?', whereArgs: [meeting.id]);
  }

  Future<int> deleteMeeting(int id) async {
    final db = await _db;
    return db.delete('meetings', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Meeting>> getAllMeetings() async {
    final db = await _db;
    final maps = await db.query('meetings', orderBy: 'date DESC');
    return maps.map((m) => Meeting.fromMap(m)).toList();
  }

  Future<List<Meeting>> getUpcomingMeetings() async {
    final db = await _db;
    final now = DateTime.now();
    final today = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final maps = await db.query(
      'meetings',
      where: 'date >= ?',
      whereArgs: [today],
      orderBy: 'date ASC',
    );
    return maps.map((m) => Meeting.fromMap(m)).toList();
  }
}

class MeetingsNotifier extends StateNotifier<AsyncValue<List<Meeting>>> {
  final MeetingRepository _repository;

  MeetingsNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadMeetings();
  }

  Future<void> loadMeetings() async {
    state = const AsyncValue.loading();
    try {
      final meetings = await _repository.getAllMeetings();
      state = AsyncValue.data(meetings);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addMeeting(Meeting meeting) async {
    try {
      await _repository.insertMeeting(meeting);
      await loadMeetings();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateMeeting(Meeting meeting) async {
    try {
      await _repository.updateMeeting(meeting);
      await loadMeetings();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteMeeting(int id) async {
    try {
      await _repository.deleteMeeting(id);
      await loadMeetings();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}