import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';

final mediaGalleryRepositoryProvider = Provider<MediaGalleryRepository>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return MediaGalleryRepository(dbAsync);
});

class MediaGalleryRepository {
  final AsyncValue<Database> _dbAsync;

  MediaGalleryRepository(this._dbAsync);

  Future<Database> get _db async {
    final db = _dbAsync.value;
    if (db == null) throw Exception('Database not initialized');
    return db;
  }

  Future<List<Map<String, dynamic>>> getAllMedia() async {
    final db = await _db;
    return db.query('media_gallery', orderBy: 'created_at DESC');
  }

  Future<List<Map<String, dynamic>>> getMediaByType(String type) async {
    final db = await _db;
    return db.query(
      'media_gallery',
      where: 'file_type = ?',
      whereArgs: [type],
      orderBy: 'created_at DESC',
    );
  }

  Future<int> insertMedia(Map<String, dynamic> media) async {
    final db = await _db;
    return db.insert('media_gallery', media);
  }

  Future<int> deleteMedia(int id) async {
    final db = await _db;
    return db.delete('media_gallery', where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, int>> getStorageStats() async {
    final db = await _db;
    final result = await db.rawQuery('SELECT SUM(file_size) as total FROM media_gallery');
    final total = result.isNotEmpty ? result[0]['total'] as int? ?? 0 : 0;

    final images = await db.query('media_gallery', where: 'file_type = ?', whereArgs: ['image']);
    final videos = await db.query('media_gallery', where: 'file_type = ?', whereArgs: ['video']);

    return {
      'total': total,
      'images': images.length,
      'videos': videos.length,
    };
  }
}
