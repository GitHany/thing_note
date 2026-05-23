import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/core/database/database_provider.dart';
import 'package:thing_note/features/cross_device_sync/domain/sync_model.dart';

final syncStatsProvider = FutureProvider<SyncStats>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  
  final countResult = await db.rawQuery('''
    SELECT 
      COUNT(*) as total,
      SUM(CASE WHEN status = 'active' THEN 1 ELSE 0 END) as active
    FROM device_sync_state
  ''');
  
  final lastSync = await db.query(
    'device_sync_state',
    orderBy: 'last_sync_time DESC',
    limit: 1,
  );
  
  final pendingCount = await db.rawQuery('''
    SELECT COUNT(*) as count FROM sync_queue WHERE synced = 0
  ''');
  
  return SyncStats(
    totalDevices: countResult.first['total'] as int? ?? 0,
    activeDevices: countResult.first['active'] as int? ?? 0,
    lastSyncTime: lastSync.isNotEmpty
        ? DateTime.parse(lastSync.first['last_sync_time'] as String)
        : null,
    pendingChanges: pendingCount.first['count'] as int? ?? 0,
    syncSuccessRate: 0.95,
  );
});

class SyncNotifier extends StateNotifier<AsyncValue<List<DeviceSyncState>>> {
  final Ref ref;
  
  SyncNotifier(this.ref) : super(const AsyncValue.loading()) {
    _loadDevices();
  }
  
  Future<void> _loadDevices() async {
    state = const AsyncValue.loading();
    try {
      final db = await ref.read(databaseProvider.future);
      final results = await db.query('device_sync_state');
      state = AsyncValue.data(results.map((m) => DeviceSyncState.fromMap(m)).toList());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
  
  Future<void> registerDevice(String deviceId) async {
    final db = await ref.read(databaseProvider.future);
    final existing = await db.query(
      'device_sync_state',
      where: 'device_id = ?',
      whereArgs: [deviceId],
    );
    
    if (existing.isEmpty) {
      await db.insert('device_sync_state', {
        'device_id': deviceId,
        'last_sync_time': DateTime.now().toIso8601String(),
        'sync_version': 1,
        'pending_changes': 0,
        'status': 'active',
      });
    }
    await _loadDevices();
  }
  
  Future<void> triggerSync() async {
    final db = await ref.read(databaseProvider.future);
    await db.update(
      'device_sync_state',
      {'last_sync_time': DateTime.now().toIso8601String()},
    );
    await _loadDevices();
  }
  
  Future<void> removeDevice(String deviceId) async {
    final db = await ref.read(databaseProvider.future);
    await db.delete(
      'device_sync_state',
      where: 'device_id = ?',
      whereArgs: [deviceId],
    );
    await _loadDevices();
  }
}

final syncNotifierProvider =
    StateNotifierProvider<SyncNotifier, AsyncValue<List<DeviceSyncState>>>((ref) {
  return SyncNotifier(ref);
});