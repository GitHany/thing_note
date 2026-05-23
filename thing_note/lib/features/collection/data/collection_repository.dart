import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/collection/domain/collection.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';

final collectionRepositoryProvider = Provider<CollectionRepository>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return CollectionRepository(dbAsync);
});

final collectionsProvider = StateNotifierProvider<CollectionsNotifier, AsyncValue<List<Collection>>>((ref) {
  final repository = ref.watch(collectionRepositoryProvider);
  return CollectionsNotifier(repository);
});

class CollectionRepository {
  final AsyncValue<Database> _dbAsync;

  CollectionRepository(this._dbAsync);

  Future<Database> get _db async {
    final db = _dbAsync.value;
    if (db == null) throw Exception('Database not initialized');
    return db;
  }

  Future<void> initTable() async {
    final db = await _db;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS collections (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        icon TEXT NOT NULL DEFAULT 'folder',
        color INTEGER NOT NULL DEFAULT 0xFF2196F3,
        record_ids TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
  }

  Future<int> insertCollection(Collection collection) async {
    final db = await _db;
    return db.insert('collections', collection.toMap());
  }

  Future<int> updateCollection(Collection collection) async {
    final db = await _db;
    return db.update(
      'collections',
      collection.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [collection.id],
    );
  }

  Future<int> deleteCollection(int id) async {
    final db = await _db;
    return db.delete('collections', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Collection>> getAllCollections() async {
    final db = await _db;
    final maps = await db.query('collections', orderBy: 'created_at DESC');
    return maps.map((m) => Collection.fromMap(m)).toList();
  }

  Future<Collection?> getCollectionById(int id) async {
    final db = await _db;
    final maps = await db.query('collections', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Collection.fromMap(maps.first);
  }

  Future<void> addRecordToCollection(int collectionId, int recordId) async {
    final collection = await getCollectionById(collectionId);
    if (collection == null) return;

    final ids = List<int>.from(collection.recordIds);
    if (!ids.contains(recordId)) {
      ids.add(recordId);
      await updateCollection(collection.copyWith(recordIds: ids));
    }
  }

  Future<void> removeRecordFromCollection(int collectionId, int recordId) async {
    final collection = await getCollectionById(collectionId);
    if (collection == null) return;

    final ids = List<int>.from(collection.recordIds);
    ids.remove(recordId);
    await updateCollection(collection.copyWith(recordIds: ids));
  }
}

class CollectionsNotifier extends StateNotifier<AsyncValue<List<Collection>>> {
  final CollectionRepository _repository;

  CollectionsNotifier(this._repository) : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    await _repository.initTable();
    await loadCollections();
  }

  Future<void> loadCollections() async {
    state = const AsyncValue.loading();
    try {
      final collections = await _repository.getAllCollections();
      state = AsyncValue.data(collections);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addCollection(Collection collection) async {
    try {
      await _repository.insertCollection(collection);
      await loadCollections();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateCollection(Collection collection) async {
    try {
      await _repository.updateCollection(collection);
      await loadCollections();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteCollection(int id) async {
    try {
      await _repository.deleteCollection(id);
      await loadCollections();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addRecordToCollection(int collectionId, int recordId) async {
    try {
      await _repository.addRecordToCollection(collectionId, recordId);
      await loadCollections();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> removeRecordFromCollection(int collectionId, int recordId) async {
    try {
      await _repository.removeRecordFromCollection(collectionId, recordId);
      await loadCollections();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}