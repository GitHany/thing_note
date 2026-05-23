import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/core/database/database_provider.dart';
import 'package:sqflite/sqflite.dart';

class TimeBlock {
  final int? id;
  final String title;
  final DateTime startTime;
  final DateTime endTime;
  final String color;
  final String repeatType; // 'none' | 'daily' | 'weekly' | 'monthly'
  final int? linkedRecordId;
  final String? note;
  final bool isActive;
  final DateTime createdAt;

  TimeBlock({
    this.id,
    required this.title,
    required this.startTime,
    required this.endTime,
    this.color = '#2196F3',
    this.repeatType = 'none',
    this.linkedRecordId,
    this.note,
    this.isActive = true,
    required this.createdAt,
  });

  int get durationMinutes => endTime.difference(startTime).inMinutes;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'color': color,
      'repeat_type': repeatType,
      'linked_record_id': linkedRecordId,
      'note': note,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory TimeBlock.fromMap(Map<String, dynamic> map) {
    return TimeBlock(
      id: map['id'] as int?,
      title: map['title'] as String,
      startTime: DateTime.parse(map['start_time'] as String),
      endTime: DateTime.parse(map['end_time'] as String),
      color: map['color'] as String? ?? '#2196F3',
      repeatType: map['repeat_type'] as String? ?? 'none',
      linkedRecordId: map['linked_record_id'] as int?,
      note: map['note'] as String?,
      isActive: (map['is_active'] as int?) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  TimeBlock copyWith({
    int? id,
    String? title,
    DateTime? startTime,
    DateTime? endTime,
    String? color,
    String? repeatType,
    int? linkedRecordId,
    String? note,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return TimeBlock(
      id: id ?? this.id,
      title: title ?? this.title,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      color: color ?? this.color,
      repeatType: repeatType ?? this.repeatType,
      linkedRecordId: linkedRecordId ?? this.linkedRecordId,
      note: note ?? this.note,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool conflictsWith(TimeBlock other) {
    if (id == other.id) return false;
    return startTime.isBefore(other.endTime) && endTime.isAfter(other.startTime);
  }
}

class TimeBlockRepository {
  final Database _db;

  TimeBlockRepository(this._db);

  Future<int> insert(TimeBlock block) async {
    return _db.insert('time_blocks', block.toMap()..remove('id'));
  }

  Future<int> update(TimeBlock block) async {
    return _db.update(
      'time_blocks',
      block.toMap(),
      where: 'id = ?',
      whereArgs: [block.id],
    );
  }

  Future<int> delete(int id) async {
    return _db.delete('time_blocks', where: 'id = ?', whereArgs: [id]);
  }

  Future<TimeBlock?> getById(int id) async {
    final results = await _db.query(
      'time_blocks',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (results.isEmpty) return null;
    return TimeBlock.fromMap(results.first);
  }

  Future<List<TimeBlock>> getAll() async {
    final results = await _db.query('time_blocks', orderBy: 'start_time ASC');
    return results.map((e) => TimeBlock.fromMap(e)).toList();
  }

  Future<List<TimeBlock>> getByDate(DateTime date) async {
    final dateStr = date.toIso8601String().substring(0, 10);
    final results = await _db.query(
      'time_blocks',
      where: 'date(start_time) = ? AND is_active = 1',
      whereArgs: [dateStr],
      orderBy: 'start_time ASC',
    );
    return results.map((e) => TimeBlock.fromMap(e)).toList();
  }

  Future<List<TimeBlock>> getByDateRange(DateTime start, DateTime end) async {
    final results = await _db.query(
      'time_blocks',
      where: 'start_time >= ? AND start_time <= ? AND is_active = 1',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'start_time ASC',
    );
    return results.map((e) => TimeBlock.fromMap(e)).toList();
  }

  Future<List<TimeBlock>> getRepeating() async {
    final results = await _db.query(
      'time_blocks',
      where: "repeat_type != 'none'",
      orderBy: 'start_time ASC',
    );
    return results.map((e) => TimeBlock.fromMap(e)).toList();
  }

  Future<bool> hasConflict(TimeBlock block) async {
    final blocks = await getByDate(block.startTime);
    for (final existing in blocks) {
      if (block.conflictsWith(existing)) return true;
    }
    return false;
  }
}

final timeBlockRepositoryProvider = Provider<TimeBlockRepository>((ref) {
  final db = ref.watch(databaseProvider).requireValue;
  return TimeBlockRepository(db);
});

final timeBlockListProvider = FutureProvider<List<TimeBlock>>((ref) async {
  final repo = ref.watch(timeBlockRepositoryProvider);
  return repo.getAll();
});

final todayTimeBlocksProvider = FutureProvider<List<TimeBlock>>((ref) async {
  final repo = ref.watch(timeBlockRepositoryProvider);
  return repo.getByDate(DateTime.now());
});