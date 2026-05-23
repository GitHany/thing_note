import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';
import 'package:thing_note/features/smart_calendar/domain/smart_calendar_event.dart';

final smartCalendarRepositoryProvider = Provider<SmartCalendarRepository>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return SmartCalendarRepository(dbAsync);
});

class SmartCalendarRepository {
  final AsyncValue<Database> _dbAsync;

  SmartCalendarRepository(this._dbAsync);

  Future<Database> get _db async {
    final db = _dbAsync.value;
    if (db == null) throw Exception('Database not initialized');
    return db;
  }

  Future<int> insertEvent(SmartCalendarEvent event) async {
    final db = await _db;
    return await db.insert('smart_calendar_events', event.toMap());
  }

  Future<List<SmartCalendarEvent>> getEventsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      'smart_calendar_events',
      where: 'start_time >= ? AND start_time <= ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'start_time ASC',
    );
    return maps.map((map) => SmartCalendarEvent.fromMap(map)).toList();
  }

  Future<List<SmartCalendarEvent>> getAllEvents() async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      'smart_calendar_events',
      orderBy: 'start_time ASC',
    );
    return maps.map((map) => SmartCalendarEvent.fromMap(map)).toList();
  }

  Future<int> updateEvent(SmartCalendarEvent event) async {
    final db = await _db;
    return await db.update(
      'smart_calendar_events',
      event.toMap(),
      where: 'id = ?',
      whereArgs: [event.id],
    );
  }

  Future<int> deleteEvent(int id) async {
    final db = await _db;
    return await db.delete(
      'smart_calendar_events',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> getEventCount() async {
    final db = await _db;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM smart_calendar_events');
    return result.first['count'] as int;
  }
}
