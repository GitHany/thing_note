import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';
import '../domain/record_snapshot_models.dart';

/// 记录快照服务提供者
final recordSnapshotServiceProvider = Provider<RecordSnapshotService>((ref) {
  return RecordSnapshotService(ref.read(databaseProvider.future));
});

/// 记录快照服务
class RecordSnapshotService {
  final Future<Database> _db;

  RecordSnapshotService(this._db);

  /// 创建快照
  Future<int> createSnapshot(int recordId, Map<String, dynamic> recordData, {String? note}) async {
    final db = await _db;

    // 序列化记录数据
    final snapshotData = jsonEncode(recordData);

    final id = await db.insert('record_snapshots', {
      'record_id': recordId,
      'snapshot_data': snapshotData,
      'note': note,
      'created_at': DateTime.now().toIso8601String(),
    });

    // 清理旧快照
    await _cleanupOldSnapshots(recordId);

    return id;
  }

  /// 获取记录的所有快照
  Future<List<RecordSnapshot>> getSnapshots(int recordId) async {
    final db = await _db;

    final rows = await db.query(
      'record_snapshots',
      where: 'record_id = ?',
      whereArgs: [recordId],
      orderBy: 'created_at DESC',
    );

    return rows.map((r) => RecordSnapshot.fromMap(r)).toList();
  }

  /// 获取快照详情
  Future<Map<String, dynamic>?> getSnapshotData(int snapshotId) async {
    final db = await _db;

    final rows = await db.query(
      'record_snapshots',
      where: 'id = ?',
      whereArgs: [snapshotId],
    );

    if (rows.isEmpty) return null;

    final snapshot = RecordSnapshot.fromMap(rows.first);
    return jsonDecode(snapshot.snapshotData) as Map<String, dynamic>;
  }

  /// 恢复快照
  Future<void> restoreSnapshot(int snapshotId) async {
    final db = await _db;

    final rows = await db.query(
      'record_snapshots',
      where: 'id = ?',
      whereArgs: [snapshotId],
    );

    if (rows.isEmpty) return;

    final snapshot = RecordSnapshot.fromMap(rows.first);
    final data = jsonDecode(snapshot.snapshotData) as Map<String, dynamic>;

    // 更新记录
    await db.update(
      'episode_records',
      {
        'note': data['note'],
        'duration_sec': data['duration_sec'],
        'photo_paths': data['photo_paths'],
        'video_paths': data['video_paths'],
        'audio_paths': data['audio_paths'],
        'annotations': data['annotations'],
        'thing_name_id': data['thing_name_id'],
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [snapshot.recordId],
    );
  }

  /// 删除快照
  Future<void> deleteSnapshot(int snapshotId) async {
    final db = await _db;
    await db.delete(
      'record_snapshots',
      where: 'id = ?',
      whereArgs: [snapshotId],
    );
  }

  /// 清理旧快照
  Future<void> _cleanupOldSnapshots(int recordId) async {
    final db = await _db;

    // 获取该记录的所有快照
    final snapshots = await db.query(
      'record_snapshots',
      where: 'record_id = ?',
      whereArgs: [recordId],
      orderBy: 'created_at DESC',
    );

    // 如果超过最大数量，删除多余的
    if (snapshots.length > 10) {
      final toDelete = snapshots.sublist(10);
      for (final snapshot in toDelete) {
        await db.delete(
          'record_snapshots',
          where: 'id = ?',
          whereArgs: [snapshot['id']],
        );
      }
    }

    // 删除过期快照
    await db.delete(
      'record_snapshots',
      where: 'expires_at IS NOT NULL AND expires_at < ?',
      whereArgs: [DateTime.now().toIso8601String()],
    );
  }

  /// 删除记录的所有快照
  Future<void> deleteAllSnapshots(int recordId) async {
    final db = await _db;
    await db.delete(
      'record_snapshots',
      where: 'record_id = ?',
      whereArgs: [recordId],
    );
  }
}