import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/features/folder_management/domain/folder.dart';
import 'package:thing_note/core/database/database_provider.dart';

final folderRepositoryProvider = Provider((ref) => FolderRepository(ref));

class FolderRepository {
  final Ref _ref;

  FolderRepository(this._ref);

  Future<Database> get _db async {
    final db = await _ref.read(databaseProvider.future);
    return db;
  }

  Future<List<Folder>> getAllFolders() async {
    final db = await _db;
    final results = await db.rawQuery('''
      SELECT f.*, COUNT(fr.record_id) as record_count
      FROM folders f
      LEFT JOIN folder_records fr ON f.id = fr.folder_id
      GROUP BY f.id
      ORDER BY f.sort_order ASC, f.name ASC
    ''');
    return results.map((e) => Folder.fromMap(e, recordCount: e['record_count'] as int? ?? 0)).toList();
  }

  Future<List<Folder>> getRootFolders() async {
    final db = await _db;
    final results = await db.rawQuery('''
      SELECT f.*, COUNT(fr.record_id) as record_count
      FROM folders f
      LEFT JOIN folder_records fr ON f.id = fr.folder_id
      WHERE f.parent_id IS NULL
      GROUP BY f.id
      ORDER BY f.sort_order ASC, f.name ASC
    ''');
    return results.map((e) => Folder.fromMap(e, recordCount: e['record_count'] as int? ?? 0)).toList();
  }

  Future<List<Folder>> getChildFolders(int parentId) async {
    final db = await _db;
    final results = await db.rawQuery('''
      SELECT f.*, COUNT(fr.record_id) as record_count
      FROM folders f
      LEFT JOIN folder_records fr ON f.id = fr.folder_id
      WHERE f.parent_id = ?
      GROUP BY f.id
      ORDER BY f.sort_order ASC, f.name ASC
    ''', [parentId]);
    return results.map((e) => Folder.fromMap(e, recordCount: e['record_count'] as int? ?? 0)).toList();
  }

  Future<List<Folder>> getFoldersWithRecords() async {
    final db = await _db;
    final results = await db.rawQuery('''
      SELECT f.*, COUNT(fr.record_id) as record_count
      FROM folders f
      JOIN folder_records fr ON f.id = fr.folder_id
      GROUP BY f.id
      ORDER BY f.sort_order ASC, f.name ASC
    ''');
    return results.map((e) => Folder.fromMap(e, recordCount: e['record_count'] as int? ?? 0)).toList();
  }

  Future<int> insertFolder(Folder folder) async {
    final db = await _db;
    return await db.insert('folders', folder.toMap());
  }

  Future<int> updateFolder(Folder folder) async {
    final db = await _db;
    return await db.update(
      'folders',
      folder.toMap(),
      where: 'id = ?',
      whereArgs: [folder.id],
    );
  }

  Future<int> deleteFolder(int id) async {
    final db = await _db;
    return await db.delete(
      'folders',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> reorderFolders(List<int> orderedIds) async {
    final db = await _db;
    for (int i = 0; i < orderedIds.length; i++) {
      await db.update(
        'folders',
        {'sort_order': i},
        where: 'id = ?',
        whereArgs: [orderedIds[i]],
      );
    }
  }

  Future<void> addRecordToFolder(int folderId, int recordId) async {
    final db = await _db;
    await db.insert(
      'folder_records',
      {'folder_id': folderId, 'record_id': recordId},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<void> removeRecordFromFolder(int folderId, int recordId) async {
    final db = await _db;
    await db.delete(
      'folder_records',
      where: 'folder_id = ? AND record_id = ?',
      whereArgs: [folderId, recordId],
    );
  }

  Future<List<int>> getRecordIdsInFolder(int folderId) async {
    final db = await _db;
    final results = await db.query(
      'folder_records',
      columns: ['record_id'],
      where: 'folder_id = ?',
      whereArgs: [folderId],
    );
    return results.map((e) => e['record_id'] as int).toList();
  }

  Future<List<int>> getFoldersForRecord(int recordId) async {
    final db = await _db;
    final results = await db.query(
      'folder_records',
      columns: ['folder_id'],
      where: 'record_id = ?',
      whereArgs: [recordId],
    );
    return results.map((e) => e['folder_id'] as int).toList();
  }

  Future<List<Map<String, dynamic>>> getRecordsInFolder(int folderId, {int? limit}) async {
    final db = await _db;
    return await db.rawQuery('''
      SELECT r.*, tn.name as thing_name
      FROM episode_records r
      JOIN folder_records fr ON r.id = fr.record_id
      LEFT JOIN thing_names tn ON r.thing_name_id = tn.id
      WHERE fr.folder_id = ?
      ORDER BY r.occurred_at DESC
      ${limit != null ? 'LIMIT $limit' : ''}
    ''', [folderId]);
  }

  Future<List<FolderTreeNode>> getFolderTree() async {
    final folders = await getAllFolders();
    final Map<int?, List<Folder>> grouped = {};
    
    for (final folder in folders) {
      grouped.putIfAbsent(folder.parentId, () => []).add(folder);
    }

    List<FolderTreeNode> buildTree(int? parentId, int depth) {
      final children = grouped[parentId] ?? [];
      return children.map((folder) => FolderTreeNode(
        folder: folder,
        children: buildTree(folder.id, depth + 1),
        depth: depth,
      )).toList();
    }

    return buildTree(null, 0);
  }
}