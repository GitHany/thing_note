import 'dart:convert';
import 'dart:io';
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
  Database? _cachedDb;

  RecordRepositoryImpl(this._ref);

  Future<Database> get _db async {
    if (_cachedDb != null) return _cachedDb!;
    _cachedDb = await _ref.read(databaseProvider.future);
    return _cachedDb!;
  }

  EpisodeRecord _fromMap(Map<String, dynamic> map) {
    final occurredAtStr = map['occurred_at'] as String?;
    final photoPathsStr = map['photo_paths'] as String?;
    final audioPathsStr = map['audio_paths'] as String?;
    final audioDurationsSecStr = map['audio_durations_sec'] as String?;
    final videoPathsStr = map['video_paths'] as String?;
    final documentPathsStr = map['document_paths'] as String?;
    final createdAtStr = map['created_at'] as String?;
    final updatedAtStr = map['updated_at'] as String?;

    List<String> parseJsonList(String? jsonStr, List<String> defaultValue) {
      if (jsonStr == null || jsonStr.isEmpty) return defaultValue;
      try {
        return List<String>.from(jsonDecode(jsonStr) as List);
      } catch (_) {
        return defaultValue;
      }
    }

    return EpisodeRecord(
      id: map['id'] as int?,
      occurredAt: occurredAtStr != null ? DateTime.parse(occurredAtStr) : DateTime.now(),
      durationSec: map['duration_sec'] as int,
      note: map['note'] as String,
      photoPaths: parseJsonList(photoPathsStr, []),
      audioPaths: parseJsonList(audioPathsStr, []),
      audioDurationsSec: List<int>.from(
        audioDurationsSecStr != null
            ? (jsonDecode(audioDurationsSecStr) as List)
            : [],
      ),
      videoPaths: parseJsonList(videoPathsStr, []),
      documentPaths: parseJsonList(documentPathsStr, []),
      thingNameId: map['thing_name_id'] as int?,
      annotationsJson: map['annotations'] as String?,
      hasReminder: (map['has_reminder'] as int?) == 1,
      latitude: map['latitude'] as double?,
      longitude: map['longitude'] as double?,
      address: map['address'] as String?,
      createdAt: createdAtStr != null ? DateTime.parse(createdAtStr) : DateTime.now(),
      updatedAt: updatedAtStr != null ? DateTime.parse(updatedAtStr) : DateTime.now(),
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
      'video_paths': jsonEncode(record.videoPaths),
      'document_paths': jsonEncode(record.documentPaths),
      'thing_name_id': record.thingNameId,
      if (record.annotationsJson != null) 'annotations': record.annotationsJson,
      'has_reminder': record.hasReminder ? 1 : 0,
      'latitude': record.latitude,
      'longitude': record.longitude,
      'address': record.address,
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
    final record = await getById(id);
    if (record != null) {
      Future<void> safeDelete(String path) async {
        try {
          final file = File(path);
          if (await file.exists()) await file.delete();
        } catch (_) {}
      }

      await Future.wait([
        ...record.photoPaths.map((path) => safeDelete(path)),
        ...record.audioPaths.map((path) => safeDelete(path)),
        ...record.videoPaths.map((path) => safeDelete(path)),
      ]);
    }
    await db.delete('episode_records', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> deleteAll() async {
    final db = await _db;
    final records = await getAll();

    Future<void> safeDelete(String path) async {
      try {
        final file = File(path);
        if (await file.exists()) await file.delete();
      } catch (_) {}
    }

    await Future.wait(
      records.expand((record) => [
        ...record.photoPaths.map((path) => safeDelete(path)),
        ...record.audioPaths.map((path) => safeDelete(path)),
        ...record.videoPaths.map((path) => safeDelete(path)),
      ]),
    );
    await db.delete('episode_records');
  }

  @override
  Future<List<EpisodeRecord>> getReminderRecords() async {
    final db = await _db;
    final maps = await db.query(
      'episode_records',
      where: 'has_reminder = 1',
      orderBy: 'occurred_at DESC',
    );
    return maps.map(_fromMap).toList();
  }

  @override
  Future<int> getReminderCount() async {
    final db = await _db;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM episode_records WHERE has_reminder = 1',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
