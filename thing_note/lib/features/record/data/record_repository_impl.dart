import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';
import 'package:thing_note/features/record/domain/episode_record.dart';
import 'package:thing_note/features/record/domain/record_repository.dart';

final recordRepositoryProvider = Provider<RecordRepository>((ref) {
  return RecordRepositoryImpl(ref);
});

class RecordRepositoryImpl implements RecordRepository {
  final Ref _ref;

  RecordRepositoryImpl(this._ref);

  Future<Database> get _db async {
    return await _ref.read(databaseProvider.future);
  }

  EpisodeRecord _fromMap(Map<String, dynamic> map) {
    return EpisodeRecord(
      id: map['id'] as int?,
      occurredAt: DateTime.parse(map['occurred_at'] as String),
      durationSec: map['duration_sec'] as int,
      note: map['note'] as String,
      photoPaths: List<String>.from(
        jsonDecode(map['photo_paths'] as String) as List,
      ),
      audioPaths: List<String>.from(
        jsonDecode(map['audio_paths'] as String) as List,
      ),
      audioDurationsSec: List<int>.from(
        jsonDecode(map['audio_durations_sec'] as String) as List,
      ),
      thingNameId: map['thing_name_id'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> _toMap(EpisodeRecord record) {
    return {
      if (record.id != null) 'id': record.id,
      'occurred_at': record.occurredAt.toIso8601String(),
      'duration_sec': record.durationSec,
      'note': record.note,
      'photo_paths': jsonEncode(record.photoPaths),
      'audio_paths': jsonEncode(record.audioPaths),
      'audio_durations_sec': jsonEncode(record.audioDurationsSec),
      'thing_name_id': record.thingNameId,
      'created_at': record.createdAt.toIso8601String(),
      'updated_at': record.updatedAt.toIso8601String(),
    };
  }

  @override
  Future<List<EpisodeRecord>> getAll() async {
    final db = await _db;
    final maps = await db.query(
      'episode_records',
      orderBy: 'occurred_at DESC',
    );
    return maps.map(_fromMap).toList();
  }

  @override
  Future<EpisodeRecord?> getById(int id) async {
    final db = await _db;
    final maps = await db.query(
      'episode_records',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return _fromMap(maps.first);
  }

  @override
  Future<EpisodeRecord> create(EpisodeRecord record) async {
    final db = await _db;
    final id = await db.insert('episode_records', _toMap(record));
    return record.copyWith(id: id);
  }

  @override
  Future<EpisodeRecord> update(EpisodeRecord record) async {
    final db = await _db;
    await db.update(
      'episode_records',
      _toMap(record),
      where: 'id = ?',
      whereArgs: [record.id],
    );
    return record;
  }

  @override
  Future<void> delete(int id) async {
    final db = await _db;
    await db.delete('episode_records', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> deleteAll() async {
    final db = await _db;
    await db.delete('episode_records');
  }

  @override
  Stream<List<EpisodeRecord>> watchAll() async* {
    while (true) {
      yield await getAll();
      await Future.delayed(const Duration(seconds: 1));
    }
  }
}
