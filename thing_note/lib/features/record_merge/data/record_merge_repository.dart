import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/features/record_merge/domain/record_merge.dart';

class RecordMergeRepository {
  final Database db;

  RecordMergeRepository(this.db);

  Future<List<Map<String, dynamic>>> getRecordsByIds(List<int> ids) async {
    if (ids.isEmpty) return [];
    final placeholders = ids.map((_) => '?').join(',');
    return await db.query(
      'episode_records',
      where: 'id IN ($placeholders)',
      whereArgs: ids,
    );
  }

  Future<Map<String, dynamic>?> getRecordById(int id) async {
    final maps = await db.query(
      'episode_records',
      where: 'id = ?',
      whereArgs: [id],
    );
    return maps.isNotEmpty ? maps.first : null;
  }

  Future<List<String>> getTagsForRecord(int recordId) async {
    final maps = await db.rawQuery('''
      SELECT tag_name FROM record_tags
      WHERE record_id = ?
    ''', [recordId]);
    return maps.map((m) => m['tag_name'] as String).toList();
  }

  Future<void> mergeRecords(RecordMergeConfig config, MergeResult result) async {
    await db.transaction((txn) async {
      final target = await getRecordById(config.targetRecordId);
      if (target == null) return;

      // Build merged note
      String mergedNote = target['note'] as String;
      if (config.notePrefix != null) {
        mergedNote = '${config.notePrefix}\n$mergedNote';
      }

      // Merge photos
      final List<String> photos = List<String>.from(jsonDecode(target['photo_paths'] as String? ?? '[]'));
      // Merge audio
      final List<String> audio = List<String>.from(jsonDecode(target['audio_paths'] as String? ?? '[]'));
      // Merge video
      final List<String> video = List<String>.from(jsonDecode(target['video_paths'] as String? ?? '[]'));
      // Merge documents
      final List<String> documents = List<String>.from(jsonDecode(target['document_paths'] as String? ?? '[]'));

      // Process source records
      for (final sourceId in config.sourceRecordIds) {
        final source = await getRecordById(sourceId);
        if (source == null) continue;

        if (config.keepPhotos) {
          final sourcePhotos = List<String>.from(jsonDecode(source['photo_paths'] as String? ?? '[]'));
          photos.addAll(sourcePhotos);
        }

        if (config.keepAudio) {
          final sourceAudio = List<String>.from(jsonDecode(source['audio_paths'] as String? ?? '[]'));
          audio.addAll(sourceAudio);
        }

        if (config.keepVideo) {
          final sourceVideo = List<String>.from(jsonDecode(source['video_paths'] as String? ?? '[]'));
          video.addAll(sourceVideo);
        }

        if (config.keepDocuments) {
          final sourceDocs = List<String>.from(jsonDecode(source['document_paths'] as String? ?? '[]'));
          documents.addAll(sourceDocs);
        }

        // Merge tags
        if (config.mergeTags) {
          final sourceTags = await getTagsForRecord(sourceId);
          for (final tag in sourceTags) {
            await txn.insert(
              'record_tags',
              {
                'record_id': config.targetRecordId,
                'tag_name': tag,
                'added_at': DateTime.now().toIso8601String(),
              },
              conflictAlgorithm: ConflictAlgorithm.ignore,
            );
          }
        }
      }

      // Update target record
      final updates = <String, dynamic>{
        'photo_paths': jsonEncode(photos),
        'audio_paths': jsonEncode(audio),
        'video_paths': jsonEncode(video),
        'document_paths': jsonEncode(documents),
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (config.mergeLocation && target['latitude'] != null) {
        // Keep target location
      }

      await txn.update(
        'episode_records',
        updates,
        where: 'id = ?',
        whereArgs: [config.targetRecordId],
      );

      // Delete source records (but keep them in merge history)
      for (final sourceId in config.sourceRecordIds) {
        await txn.delete(
          'episode_records',
          where: 'id = ?',
          whereArgs: [sourceId],
        );
      }

      // Save merge history
      await txn.insert('merge_history', {
        'target_record_id': config.targetRecordId,
        'source_record_ids': jsonEncode(config.sourceRecordIds),
        'photos_count': result.photosAdded,
        'audio_count': result.audioAdded,
        'video_count': result.videoAdded,
        'documents_count': result.documentsAdded,
        'merged_at': result.mergedAt.toIso8601String(),
      });
    });
  }

  Future<List<Map<String, dynamic>>> getMergeHistory() async {
    return await db.query(
      'merge_history',
      orderBy: 'merged_at DESC',
      limit: 50,
    );
  }

  Future<MergePreview> generatePreview(int targetId, List<int> sourceIds) async {
    final target = await getRecordById(targetId);
    final sources = await getRecordsByIds(sourceIds);

    int totalPhotos = 0, totalAudio = 0, totalVideo = 0, totalDocuments = 0;
    final tags = <String>{};
    double? latitude;
    // Note: longitude could be added if needed for full geolocation support

    for (final source in sources) {
      totalPhotos += (jsonDecode(source['photo_paths'] as String? ?? '[]') as List).length;
      totalAudio += (jsonDecode(source['audio_paths'] as String? ?? '[]') as List).length;
      totalVideo += (jsonDecode(source['video_paths'] as String? ?? '[]') as List).length;
      totalDocuments += (jsonDecode(source['document_paths'] as String? ?? '[]') as List).length;

      final sourceTags = await getTagsForRecord(source['id'] as int);
      tags.addAll(sourceTags);

      if (latitude == null && source['latitude'] != null) {
        latitude = source['latitude'] as double;
      }
    }

    return MergePreview(
      targetRecordId: targetId,
      targetNote: target?['note'] as String? ?? '',
      sourceRecordIds: sourceIds,
      totalPhotos: totalPhotos,
      totalAudio: totalAudio,
      totalVideo: totalVideo,
      totalDocuments: totalDocuments,
      tagsToMerge: tags.toList(),
      targetLatitude: target?['latitude'] as double?,
      targetLongitude: target?['longitude'] as double?,
    );
  }
}