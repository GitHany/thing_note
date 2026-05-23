import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';
import 'package:thing_note/features/archive/domain/archived_record.dart';
import 'package:thing_note/features/record/domain/episode_record.dart';
import 'package:thing_note/features/record/data/record_repository_impl.dart';

/// 归档仓库提供者
final archiveRepositoryProvider = Provider<ArchiveRepository>((ref) {
  return ArchiveRepository(ref);
});

class ArchiveRepository {
  final Ref _ref;
  Database? _cachedDb;

  ArchiveRepository(this._ref);

  Future<Database> get _db async {
    if (_cachedDb != null) return _cachedDb!;
    _cachedDb = await _ref.read(databaseProvider.future);
    return _cachedDb!;
  }

  /// 初始化归档表（如果不存在）
  Future<void> initArchiveTable() async {
    final db = await _db;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS archived_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        original_id INTEGER NOT NULL,
        occurred_at TEXT NOT NULL,
        duration_sec INTEGER NOT NULL DEFAULT 0,
        note TEXT NOT NULL DEFAULT '',
        photo_paths TEXT NOT NULL DEFAULT '[]',
        audio_paths TEXT NOT NULL DEFAULT '[]',
        audio_durations_sec TEXT NOT NULL DEFAULT '[]',
        thing_name_id INTEGER,
        annotations TEXT,
        has_reminder INTEGER NOT NULL DEFAULT 0,
        latitude REAL,
        longitude REAL,
        address TEXT,
        video_paths TEXT NOT NULL DEFAULT '[]',
        document_paths TEXT NOT NULL DEFAULT '[]',
        is_favorite INTEGER NOT NULL DEFAULT 0,
        repeat_type TEXT NOT NULL DEFAULT 'none',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        tag_ids TEXT NOT NULL DEFAULT '[]',
        linked_record_ids TEXT,
        rating INTEGER,
        importance INTEGER,
        archived_at TEXT NOT NULL,
        archived_reason TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS trash_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        original_id INTEGER NOT NULL,
        occurred_at TEXT NOT NULL,
        duration_sec INTEGER NOT NULL DEFAULT 0,
        note TEXT NOT NULL DEFAULT '',
        photo_paths TEXT NOT NULL DEFAULT '[]',
        audio_paths TEXT NOT NULL DEFAULT '[]',
        audio_durations_sec TEXT NOT NULL DEFAULT '[]',
        thing_name_id INTEGER,
        annotations TEXT,
        has_reminder INTEGER NOT NULL DEFAULT 0,
        latitude REAL,
        longitude REAL,
        address TEXT,
        video_paths TEXT NOT NULL DEFAULT '[]',
        document_paths TEXT NOT NULL DEFAULT '[]',
        is_favorite INTEGER NOT NULL DEFAULT 0,
        repeat_type TEXT NOT NULL DEFAULT 'none',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        tag_ids TEXT NOT NULL DEFAULT '[]',
        linked_record_ids TEXT,
        rating INTEGER,
        importance INTEGER,
        trashed_at TEXT NOT NULL,
        trash_reason TEXT
      )
    ''');
  }

  /// 归档单条记录
  Future<void> archiveRecord(EpisodeRecord record, {String? reason}) async {
    await initArchiveTable();
    final db = await _db;

    // 获取关联的标签
    final tagMaps = await db.query(
      'record_tags',
      where: 'record_id = ?',
      whereArgs: [record.id],
    );
    final tagIds = tagMaps.map((m) => m['tag_id'] as int).toList();

    // 获取关联的记录
    final linkMaps = await db.query(
      'record_links',
      where: 'record_id_a = ? OR record_id_b = ?',
      whereArgs: [record.id, record.id],
    );
    final linkedIds = linkMaps.map((m) {
      final a = m['record_id_a'] as int;
      final b = m['record_id_b'] as int;
      return a == record.id ? b : a;
    }).toList();

    final archived = ArchivedRecord(
      originalId: record.id!,
      occurredAt: record.occurredAt.toIso8601String(),
      durationSec: record.durationSec,
      note: record.note,
      photoPaths: jsonEncode(record.photoPaths),
      audioPaths: jsonEncode(record.audioPaths),
      audioDurationsSec: jsonEncode(record.audioDurationsSec),
      thingNameId: record.thingNameId,
      annotations: record.annotationsJson,
      hasReminder: record.hasReminder ? 1 : 0,
      latitude: record.latitude,
      longitude: record.longitude,
      address: record.address,
      videoPaths: jsonEncode(record.videoPaths),
      documentPaths: jsonEncode(record.documentPaths),
      isFavorite: record.isFavorite ? 1 : 0,
      repeatType: record.repeatType,
      createdAt: record.createdAt.toIso8601String(),
      updatedAt: record.updatedAt.toIso8601String(),
      tagIds: jsonEncode(tagIds),
      linkedRecordIds: linkedIds.isNotEmpty ? jsonEncode(linkedIds) : null,
      archivedAt: DateTime.now().toIso8601String(),
      archivedReason: reason,
    );

    await db.insert('archived_records', archived.toMap());
  }

  /// 批量归档记录
  Future<void> archiveRecords(List<EpisodeRecord> records, {String? reason}) async {
    for (final record in records) {
      await archiveRecord(record, reason: reason);
    }
  }

  /// 获取归档记录
  Future<List<ArchivedRecord>> getArchivedRecords() async {
    await initArchiveTable();
    final db = await _db;
    final maps = await db.query('archived_records', orderBy: 'archived_at DESC');
    return maps.map((m) => ArchivedRecord.fromMap(m)).toList();
  }

  /// 从归档恢复记录
  Future<EpisodeRecord?> restoreFromArchive(ArchivedRecord archived) async {
    await initArchiveTable();
    final db = await _db;

    // 创建新的记录
    final record = EpisodeRecord(
      occurredAt: DateTime.parse(archived.occurredAt),
      durationSec: archived.durationSec,
      note: archived.note,
      photoPaths: _parseJsonList(archived.photoPaths, []),
      audioPaths: _parseJsonList(archived.audioPaths, []),
      audioDurationsSec: _parseJsonIntList(archived.audioDurationsSec, []),
      thingNameId: archived.thingNameId,
      annotationsJson: archived.annotations,
      hasReminder: archived.hasReminder == 1,
      latitude: archived.latitude,
      longitude: archived.longitude,
      address: archived.address,
      videoPaths: _parseJsonList(archived.videoPaths, []),
      documentPaths: _parseJsonList(archived.documentPaths, []),
      isFavorite: archived.isFavorite == 1,
      repeatType: archived.repeatType,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // 插入新记录
    final recordRepo = _ref.read(recordRepositoryProvider);
    final newRecord = await recordRepo.create(record);

    // 恢复标签关联
    if (archived.tagIds.isNotEmpty) {
      final tagIds = _parseJsonIntList(archived.tagIds, []);
      for (final tagId in tagIds) {
        await db.insert(
          'record_tags',
          {'record_id': newRecord.id, 'tag_id': tagId},
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
    }

    // 删除归档记录
    if (archived.id != null) {
      await db.delete(
        'archived_records',
        where: 'id = ?',
        whereArgs: [archived.id],
      );
    }

    return newRecord;
  }

  /// 删除归档记录
  Future<void> deleteArchived(int archivedId) async {
    await initArchiveTable();
    final db = await _db;
    await db.delete('archived_records', where: 'id = ?', whereArgs: [archivedId]);
  }

  /// 清空归档
  Future<void> clearArchive() async {
    await initArchiveTable();
    final db = await _db;
    await db.delete('archived_records');
  }

  // ===== 回收站功能 =====

  /// 将记录移至回收站
  Future<void> trashRecord(EpisodeRecord record, {String? reason}) async {
    await initArchiveTable();
    final db = await _db;

    // 获取关联的标签
    final tagMaps = await db.query(
      'record_tags',
      where: 'record_id = ?',
      whereArgs: [record.id],
    );
    final tagIds = tagMaps.map((m) => m['tag_id'] as int).toList();

    // 获取关联的记录
    final linkMaps = await db.query(
      'record_links',
      where: 'record_id_a = ? OR record_id_b = ?',
      whereArgs: [record.id, record.id],
    );
    final linkedIds = linkMaps.map((m) {
      final a = m['record_id_a'] as int;
      final b = m['record_id_b'] as int;
      return a == record.id ? b : a;
    }).toList();

    final trashed = ArchivedRecord(
      originalId: record.id!,
      occurredAt: record.occurredAt.toIso8601String(),
      durationSec: record.durationSec,
      note: record.note,
      photoPaths: jsonEncode(record.photoPaths),
      audioPaths: jsonEncode(record.audioPaths),
      audioDurationsSec: jsonEncode(record.audioDurationsSec),
      thingNameId: record.thingNameId,
      annotations: record.annotationsJson,
      hasReminder: record.hasReminder ? 1 : 0,
      latitude: record.latitude,
      longitude: record.longitude,
      address: record.address,
      videoPaths: jsonEncode(record.videoPaths),
      documentPaths: jsonEncode(record.documentPaths),
      isFavorite: record.isFavorite ? 1 : 0,
      repeatType: record.repeatType,
      createdAt: record.createdAt.toIso8601String(),
      updatedAt: record.updatedAt.toIso8601String(),
      tagIds: jsonEncode(tagIds),
      linkedRecordIds: linkedIds.isNotEmpty ? jsonEncode(linkedIds) : null,
      archivedAt: DateTime.now().toIso8601String(), // 复用这个字段作为 trashed_at
      archivedReason: reason,
    );

    final map = trashed.toMap();
    map.remove('rating');
    map.remove('importance');
    map['trashed_at'] = map.remove('archived_at');
    map['trash_reason'] = map.remove('archived_reason');

    await db.insert('trash_records', map);
  }

  /// 批量移至回收站
  Future<void> trashRecords(List<EpisodeRecord> records, {String? reason}) async {
    for (final record in records) {
      await trashRecord(record, reason: reason);
    }
  }

  /// 获取回收站记录
  Future<List<ArchivedRecord>> getTrashRecords() async {
    await initArchiveTable();
    final db = await _db;
    final maps = await db.query('trash_records', orderBy: 'trashed_at DESC');
    return maps.map((m) {
      final map = Map<String, dynamic>.from(m);
      map['archived_at'] = map['trashed_at'];
      map['archived_reason'] = map['trash_reason'];
      return ArchivedRecord.fromMap(map);
    }).toList();
  }

  /// 从回收站恢复
  Future<EpisodeRecord?> restoreFromTrash(ArchivedRecord trashed) async {
    await initArchiveTable();
    final db = await _db;

    final record = EpisodeRecord(
      occurredAt: DateTime.parse(trashed.occurredAt),
      durationSec: trashed.durationSec,
      note: trashed.note,
      photoPaths: _parseJsonList(trashed.photoPaths, []),
      audioPaths: _parseJsonList(trashed.audioPaths, []),
      audioDurationsSec: _parseJsonIntList(trashed.audioDurationsSec, []),
      thingNameId: trashed.thingNameId,
      annotationsJson: trashed.annotations,
      hasReminder: trashed.hasReminder == 1,
      latitude: trashed.latitude,
      longitude: trashed.longitude,
      address: trashed.address,
      videoPaths: _parseJsonList(trashed.videoPaths, []),
      documentPaths: _parseJsonList(trashed.documentPaths, []),
      isFavorite: trashed.isFavorite == 1,
      repeatType: trashed.repeatType,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final recordRepo = _ref.read(recordRepositoryProvider);
    final newRecord = await recordRepo.create(record);

    // 恢复标签关联
    if (trashed.tagIds.isNotEmpty) {
      final tagIds = _parseJsonIntList(trashed.tagIds, []);
      for (final tagId in tagIds) {
        await db.insert(
          'record_tags',
          {'record_id': newRecord.id, 'tag_id': tagId},
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
    }

    // 删除回收站记录
    if (trashed.id != null) {
      await db.delete('trash_records', where: 'id = ?', whereArgs: [trashed.id]);
    }

    return newRecord;
  }

  /// 永久删除
  Future<void> permanentDelete(int trashId) async {
    await initArchiveTable();
    final db = await _db;
    await db.delete('trash_records', where: 'id = ?', whereArgs: [trashId]);
  }

  /// 清空回收站
  Future<void> emptyTrash() async {
    await initArchiveTable();
    final db = await _db;
    await db.delete('trash_records');
  }

  /// 获取归档数量
  Future<int> getArchiveCount() async {
    await initArchiveTable();
    final db = await _db;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM archived_records');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// 获取回收站数量
  Future<int> getTrashCount() async {
    await initArchiveTable();
    final db = await _db;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM trash_records');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  List<String> _parseJsonList(String? jsonStr, List<String> defaultValue) {
    if (jsonStr == null || jsonStr.isEmpty) return defaultValue;
    try {
      return List<String>.from(jsonDecode(jsonStr) as List);
    } catch (_) {
      return defaultValue;
    }
  }

  List<int> _parseJsonIntList(String? jsonStr, List<int> defaultValue) {
    if (jsonStr == null || jsonStr.isEmpty) return defaultValue;
    try {
      return List<int>.from(jsonDecode(jsonStr) as List);
    } catch (_) {
      return defaultValue;
    }
  }
}