import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';

class NoteSyncRecord {
  final int? id;
  final int noteId;
  final String action;
  final String? payload;
  final String status;
  final int retryCount;
  final DateTime createdAt;

  const NoteSyncRecord({
    this.id,
    required this.noteId,
    required this.action,
    this.payload,
    this.status = 'pending',
    this.retryCount = 0,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'note_id': noteId,
      'action': action,
      'payload': payload,
      'status': status,
      'retry_count': retryCount,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory NoteSyncRecord.fromMap(Map<String, dynamic> map) {
    return NoteSyncRecord(
      id: map['id'] as int?,
      noteId: map['note_id'] as int,
      action: map['action'] as String,
      payload: map['payload'] as String?,
      status: map['status'] as String? ?? 'pending',
      retryCount: map['retry_count'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

class NoteSyncHistory {
  final int? id;
  final int noteId;
  final String action;
  final DateTime syncedAt;
  final String status;

  const NoteSyncHistory({
    this.id,
    required this.noteId,
    required this.action,
    required this.syncedAt,
    required this.status,
  });

  factory NoteSyncHistory.fromMap(Map<String, dynamic> map) {
    return NoteSyncHistory(
      id: map['id'] as int?,
      noteId: map['note_id'] as int,
      action: map['action'] as String,
      syncedAt: DateTime.parse(map['synced_at'] as String),
      status: map['status'] as String,
    );
  }
}

final noteSyncRepositoryProvider = Provider<NoteSyncRepository>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return NoteSyncRepository(dbAsync);
});

final noteSyncQueueProvider = StateNotifierProvider<NoteSyncQueueNotifier, AsyncValue<List<NoteSyncRecord>>>((ref) {
  final repository = ref.watch(noteSyncRepositoryProvider);
  return NoteSyncQueueNotifier(repository);
});

final noteSyncHistoryProvider = FutureProvider<List<NoteSyncHistory>>((ref) async {
  final repository = ref.watch(noteSyncRepositoryProvider);
  return repository.getSyncHistory();
});

final syncStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final queue = ref.watch(noteSyncQueueProvider);
  return queue.when(
    data: (records) {
      final pending = records.where((r) => r.status == 'pending').length;
      final failed = records.where((r) => r.status == 'failed').length;
      return {
        'pending': pending,
        'failed': failed,
        'total': records.length,
      };
    },
    loading: () => {'pending': 0, 'failed': 0, 'total': 0},
    error: (_, __) => {'pending': 0, 'failed': 0, 'total': 0},
  );
});

class NoteSyncRepository {
  final AsyncValue<Database> _dbAsync;

  NoteSyncRepository(this._dbAsync);

  Future<Database> get _db async {
    final db = _dbAsync.value;
    if (db == null) throw Exception('Database not initialized');
    return db;
  }

  Future<int> insertSyncRecord(NoteSyncRecord record) async {
    final db = await _db;
    return db.insert('note_sync_queue', record.toMap());
  }

  Future<int> updateSyncStatus(int id, String status) async {
    final db = await _db;
    return db.update(
      'note_sync_queue',
      {'status': status},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<NoteSyncRecord>> getPendingRecords() async {
    final db = await _db;
    final maps = await db.query(
      'note_sync_queue',
      where: 'status = ?',
      whereArgs: ['pending'],
    );
    return maps.map((m) => NoteSyncRecord.fromMap(m)).toList();
  }

  Future<List<NoteSyncHistory>> getSyncHistory() async {
    final db = await _db;
    final maps = await db.query('note_sync_history', orderBy: 'synced_at DESC', limit: 50);
    return maps.map((m) => NoteSyncHistory.fromMap(m)).toList();
  }

  Future<void> addToQueue(int noteId, String action, String? payload) async {
    final record = NoteSyncRecord(
      noteId: noteId,
      action: action,
      payload: payload,
      createdAt: DateTime.now(),
    );
    await insertSyncRecord(record);
  }
}

class NoteSyncQueueNotifier extends StateNotifier<AsyncValue<List<NoteSyncRecord>>> {
  final NoteSyncRepository _repository;

  NoteSyncQueueNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadQueue();
  }

  Future<void> loadQueue() async {
    state = const AsyncValue.loading();
    try {
      final records = await _repository.getPendingRecords();
      state = AsyncValue.data(records);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> retrySync(int id) async {
    await _repository.updateSyncStatus(id, 'pending');
    await loadQueue();
  }

  Future<void> clearFailed() async {
    // Clear failed records
    await loadQueue();
  }
}