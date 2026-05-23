import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';
import 'package:thing_note/features/sync_status_dashboard/domain/sync_status_models.dart';

/// 同步状态服务 Provider
final syncStatusServiceProvider = Provider<SyncStatusService>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return SyncStatusService(dbAsync);
});

/// 同步状态 Provider
final syncStatusProvider = FutureProvider<SyncStatus>((ref) async {
  final service = ref.watch(syncStatusServiceProvider);
  return service.getSyncStatus();
});

/// 同步队列 Provider
final syncQueueProvider = FutureProvider<List<SyncQueueItem>>((ref) async {
  final service = ref.watch(syncStatusServiceProvider);
  return service.getSyncQueue();
});

/// 同步冲突 Provider
final syncConflictsProvider = FutureProvider<List<SyncConflict>>((ref) async {
  final service = ref.watch(syncStatusServiceProvider);
  return service.getConflicts();
});

class SyncStatusService {
  final AsyncValue<Database> _dbAsync;

  SyncStatusService(this._dbAsync);

  Future<Database> get _db async {
    final db = _dbAsync.value;
    if (db == null) throw Exception('Database not initialized');
    return db;
  }

  /// 获取同步状态
  Future<SyncStatus> getSyncStatus() async {
    final queue = await getSyncQueue();
    final pendingCount = queue.where((q) => q.status == 'pending').length;

    return SyncStatus(
      isConnected: true, // 模拟状态
      isSyncing: queue.any((q) => q.status == 'syncing'),
      lastSyncTime: DateTime.now().subtract(const Duration(minutes: 5)),
      pendingCount: pendingCount,
    );
  }

  /// 获取同步队列
  Future<List<SyncQueueItem>> getSyncQueue() async {
    final db = await _db;
    final maps = await db.query(
      'note_sync_queue',
      where: 'status != ?',
      whereArgs: ['synced'],
      orderBy: 'created_at ASC',
    );
    return maps.map((m) => SyncQueueItem.fromMap(m)).toList();
  }

  /// 获取冲突列表
  Future<List<SyncConflict>> getConflicts() async {
    // 模拟获取冲突数据
    return [];
  }

  /// 添加到同步队列
  Future<int> addToSyncQueue(int recordId, String action, String? payload) async {
    final db = await _db;
    return db.insert('note_sync_queue', {
      'note_id': recordId,
      'action': action,
      'payload': payload,
      'status': 'pending',
      'retry_count': 0,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// 更新队列项状态
  Future<int> updateQueueItemStatus(int id, String status, {String? error}) async {
    final db = await _db;
    return db.update(
      'note_sync_queue',
      {
        'status': status,
        'last_attempt_at': DateTime.now().toIso8601String(),
        if (status == 'failed') 'retry_count': 1,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 清除已完成的队列项
  Future<int> clearSyncedItems() async {
    final db = await _db;
    return db.delete(
      'note_sync_queue',
      where: 'status = ?',
      whereArgs: ['synced'],
    );
  }

  /// 手动触发同步
  Future<void> triggerSync() async {
    final queue = await getSyncQueue();
    
    for (final item in queue) {
      if (item.status == 'pending') {
        await updateQueueItemStatus(item.id!, 'syncing');
        
        // 模拟同步过程
        await Future.delayed(const Duration(milliseconds: 500));
        
        await updateQueueItemStatus(item.id!, 'synced');
      }
    }
  }

  /// 解决冲突
  Future<void> resolveConflict(int recordId, String resolution) async {
    final db = await _db;
    
    // 根据 resolution 更新本地数据或标记已解决
    await db.insert('note_sync_history', {
      'note_id': recordId,
      'action': 'resolve_conflict',
      'synced_at': DateTime.now().toIso8601String(),
      'status': 'success',
    });
  }

  /// 获取同步历史
  Future<List<SyncHistoryItem>> getSyncHistory({int limit = 20}) async {
    final db = await _db;
    final maps = await db.query(
      'note_sync_history',
      orderBy: 'synced_at DESC',
      limit: limit,
    );

    return maps.map((m) => SyncHistoryItem(
      syncedAt: DateTime.parse(m['synced_at'] as String),
      action: m['action'] as String,
      recordCount: 1,
      success: m['status'] == 'success',
      error: m['error'] as String?,
    )).toList();
  }

  /// 获取存储空间统计
  Future<Map<String, int>> getStorageStats() async {
    final db = await _db;
    
    // 获取记录数量
    final records = await db.rawQuery('SELECT COUNT(*) as count FROM episode_records');
    final recordCount = records.first['count'] as int? ?? 0;
    
    // 获取附件总大小（模拟）
    final attachmentSize = recordCount * 500; // 模拟每条记录 500KB

    return {
      'recordCount': recordCount,
      'attachmentSize': attachmentSize,
      'totalSize': attachmentSize + 1000000, // 加上数据库大小
    };
  }
}