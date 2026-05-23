import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/core/database/database_provider.dart';
import 'package:thing_note/features/cloud_sync/domain/cloud_sync_queue.dart';

class CloudSyncRepository {
  final Ref _ref;

  CloudSyncRepository(this._ref);

  Future<List<CloudSyncQueue>> getPendingItems() async {
    final db = await _ref.read(databaseProvider.future);
    final result = await db.query(
      'cloud_sync_queue',
      where: 'status = ?',
      whereArgs: ['pending'],
      orderBy: 'created_at ASC',
    );
    return result.map((e) => CloudSyncQueue.fromMap(e)).toList();
  }

  Future<int> addToQueue(CloudSyncQueue item) async {
    final db = await _ref.read(databaseProvider.future);
    return db.insert('cloud_sync_queue', item.toMap()..remove('id'));
  }

  Future<int> markAsSyncing(int id) async {
    final db = await _ref.read(databaseProvider.future);
    return db.update(
      'cloud_sync_queue',
      {'status': 'syncing', 'last_attempt': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> markAsCompleted(int id) async {
    final db = await _ref.read(databaseProvider.future);
    return db.update(
      'cloud_sync_queue',
      {'status': 'completed'},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> markAsFailed(int id, String error) async {
    final db = await _ref.read(databaseProvider.future);
    return db.rawUpdate('''
      UPDATE cloud_sync_queue 
      SET status = 'failed', 
          retry_count = retry_count + 1,
          error_message = ?,
          last_attempt = ?
      WHERE id = ?
    ''', [error, DateTime.now().toIso8601String(), id]);
  }

  Future<int> clearCompleted() async {
    final db = await _ref.read(databaseProvider.future);
    return db.delete('cloud_sync_queue', where: 'status = ?', whereArgs: ['completed']);
  }

  Future<Map<String, int>> getQueueStats() async {
    final db = await _ref.read(databaseProvider.future);
    final result = await db.rawQuery('''
      SELECT status, COUNT(*) as count
      FROM cloud_sync_queue
      GROUP BY status
    ''');

    final stats = <String, int>{};
    for (final row in result) {
      stats[row['status'] as String] = row['count'] as int;
    }
    return stats;
  }

  Future<void> enqueueRecordChange(int recordId, String action, Map<String, dynamic> data) async {
    await addToQueue(CloudSyncQueue(
      entityType: 'record',
      entityId: recordId,
      action: action,
      payload: jsonEncode(data),
      createdAt: DateTime.now(),
    ));
  }
}