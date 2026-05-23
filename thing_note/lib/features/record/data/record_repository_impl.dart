import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';
import 'package:thing_note/features/record/domain/episode_record.dart';
import 'package:thing_note/features/record/domain/record_repository.dart';
import 'package:thing_note/features/record_link/domain/record_link.dart';

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

  static List<String> _parseJsonList(String? jsonStr, List<String> defaultValue) {
    if (jsonStr == null || jsonStr.isEmpty) return defaultValue;
    try {
      return List<String>.from(jsonDecode(jsonStr) as List);
    } catch (_) {
      return defaultValue;
    }
  }

  static List<int> _parseJsonIntList(String? jsonStr, List<int> defaultValue) {
    if (jsonStr == null || jsonStr.isEmpty) return defaultValue;
    try {
      return List<int>.from(jsonDecode(jsonStr) as List);
    } catch (_) {
      return defaultValue;
    }
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

    return EpisodeRecord(
      id: map['id'] as int?,
      occurredAt: occurredAtStr != null ? DateTime.parse(occurredAtStr) : DateTime.now(),
      durationSec: map['duration_sec'] as int,
      note: map['note'] as String,
      photoPaths: _parseJsonList(photoPathsStr, []),
      audioPaths: _parseJsonList(audioPathsStr, []),
      audioDurationsSec: _parseJsonIntList(audioDurationsSecStr, []),
      videoPaths: _parseJsonList(videoPathsStr, []),
      documentPaths: _parseJsonList(documentPathsStr, []),
      thingNameId: map['thing_name_id'] as int?,
      annotationsJson: map['annotations'] as String?,
      hasReminder: (map['has_reminder'] as int?) == 1,
      latitude: map['latitude'] as double?,
      longitude: map['longitude'] as double?,
      address: map['address'] as String?,
      isFavorite: (map['is_favorite'] as int?) == 1,
      repeatType: map['repeat_type'] as String? ?? 'none',
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
      'is_favorite': record.isFavorite ? 1 : 0,
      'repeat_type': record.repeatType,
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
        ...record.documentPaths.map((path) => safeDelete(path)),
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

  @override
  Future<List<EpisodeRecord>> getFavoriteRecords() async {
    final db = await _db;
    final maps = await db.query(
      'episode_records',
      where: 'is_favorite = 1',
      orderBy: 'occurred_at DESC',
    );
    return maps.map(_fromMap).toList();
  }

  @override
  Future<int> getFavoriteCount() async {
    final db = await _db;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM episode_records WHERE is_favorite = 1',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  @override
  Future<List<EpisodeRecord>> search(String query) async {
    final db = await _db;
    final maps = await db.rawQuery('''
      SELECT DISTINCT r.* FROM episode_records r
      LEFT JOIN record_tags rt ON r.id = rt.record_id
      LEFT JOIN tags t ON rt.tag_id = t.id
      WHERE r.note LIKE ?
         OR r.address LIKE ?
         OR t.name LIKE ?
      ORDER BY r.occurred_at DESC
    ''', ['%$query%', '%$query%', '%$query%']);
    return maps.map(_fromMap).toList();
  }

  @override
  Future<List<EpisodeRecord>> getRecordsByTag(int tagId) async {
    final db = await _db;
    final maps = await db.rawQuery('''
      SELECT r.* FROM episode_records r
      INNER JOIN record_tags rt ON r.id = rt.record_id
      WHERE rt.tag_id = ?
      ORDER BY r.occurred_at DESC
    ''', [tagId]);
    return maps.map(_fromMap).toList();
  }

  // Record links implementation
  RecordLink _linkFromMap(Map<String, dynamic> map) {
    final createdAtStr = map['created_at'] as String?;
    return RecordLink(
      id: map['id'] as int?,
      recordIdA: map['record_id_a'] as int,
      recordIdB: map['record_id_b'] as int,
      createdAt: createdAtStr != null ? DateTime.parse(createdAtStr) : DateTime.now(),
    );
  }

  Map<String, dynamic> _linkToMap(RecordLink link) {
    return {
      if (link.id != null) 'id': link.id,
      'record_id_a': link.recordIdA,
      'record_id_b': link.recordIdB,
      'created_at': link.createdAt.toIso8601String(),
    };
  }

  @override
  Future<List<RecordLink>> getLinksForRecord(int recordId) async {
    final db = await _db;
    final maps = await db.rawQuery('''
      SELECT * FROM record_links 
      WHERE record_id_a = ? OR record_id_b = ?
      ORDER BY created_at DESC
    ''', [recordId, recordId]);
    return maps.map(_linkFromMap).toList();
  }

  @override
  Future<List<EpisodeRecord>> getLinkedRecords(int recordId) async {
    final db = await _db;
    final maps = await db.rawQuery('''
      SELECT r.* FROM episode_records r
      INNER JOIN (
        SELECT record_id_a as linked_id FROM record_links WHERE record_id_b = ?
        UNION
        SELECT record_id_b as linked_id FROM record_links WHERE record_id_a = ?
      ) AS linked ON r.id = linked.linked_id
      ORDER BY r.occurred_at DESC
    ''', [recordId, recordId]);
    return maps.map(_fromMap).toList();
  }

  @override
  Future<RecordLink> createLink(int recordIdA, int recordIdB) async {
    final db = await _db;
    // Ensure consistent ordering: smaller ID first
    final a = recordIdA < recordIdB ? recordIdA : recordIdB;
    final b = recordIdA < recordIdB ? recordIdB : recordIdA;
    
    // Use INSERT OR IGNORE to avoid race condition on UNIQUE constraint
    try {
      final link = RecordLink(
        recordIdA: a,
        recordIdB: b,
        createdAt: DateTime.now(),
      );
      final id = await db.insert('record_links', _linkToMap(link), conflictAlgorithm: ConflictAlgorithm.ignore);
      // If insert returned 0 (duplicate), fetch existing link
      if (id == 0) {
        final existing = await db.query(
          'record_links',
          where: 'record_id_a = ? AND record_id_b = ?',
          whereArgs: [a, b],
        );
        if (existing.isNotEmpty) {
          return _linkFromMap(existing.first);
        }
      }
      return link.copyWith(id: id);
    } catch (e) {
      // Fallback: fetch existing link on any error
      final existing = await db.query(
        'record_links',
        where: 'record_id_a = ? AND record_id_b = ?',
        whereArgs: [a, b],
      );
      if (existing.isNotEmpty) {
        return _linkFromMap(existing.first);
      }
      rethrow;
    }
  }

  @override
  Future<void> deleteLink(int linkId) async {
    final db = await _db;
    await db.delete('record_links', where: 'id = ?', whereArgs: [linkId]);
  }

  @override
  Future<void> deleteLinkByRecords(int recordIdA, int recordIdB) async {
    final db = await _db;
    final a = recordIdA < recordIdB ? recordIdA : recordIdB;
    final b = recordIdA < recordIdB ? recordIdB : recordIdA;
    await db.delete(
      'record_links',
      where: 'record_id_a = ? AND record_id_b = ?',
      whereArgs: [a, b],
    );
  }
}
