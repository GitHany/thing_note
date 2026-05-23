import 'dart:convert';
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/features/data_import/domain/import_config.dart';

class DataImportRepository {
  final Database db;

  DataImportRepository(this.db);

  Future<ImportPreview> previewImport(String filePath, ImportSourceType sourceType) async {
    final file = File(filePath);
    final content = await file.readAsString();

    int recordCount = 0;
    int photoCount = 0;
    int audioCount = 0;
    int videoCount = 0;
    int documentCount = 0;
    final tags = <String>{};
    final thingNames = <String>{};
    String? minDate, maxDate;

    switch (sourceType) {
      case ImportSourceType.json:
      case ImportSourceType.thingNoteBackup:
        final data = jsonDecode(content);
        final List<dynamic> records = data is List ? data : (data['records'] ?? []);
        recordCount = records.length;

        for (final r in records) {
          if (r is Map) {
            minDate = minDate ?? r['occurred_at']?.toString();
            maxDate = maxDate ?? r['occurred_at']?.toString();

            final photos = r['photo_paths'];
            if (photos is List) photoCount += photos.length;
            final audio = r['audio_paths'];
            if (audio is List) audioCount += audio.length;
            final video = r['video_paths'];
            if (video is List) videoCount += video.length;
            final docs = r['document_paths'];
            if (docs is List) documentCount += docs.length;

            final tagsList = r['tags'];
            if (tagsList is List) {
              for (final tag in tagsList) {
                if (tag is String) tags.add(tag);
              }
            }

            final thingName = r['thing_name'];
            if (thingName is String && thingName.isNotEmpty) {
              thingNames.add(thingName);
            }
          }
        }
        break;

      case ImportSourceType.csv:
        final lines = content.split('\n').where((l) => l.trim().isNotEmpty).toList();
        if (lines.isNotEmpty) recordCount = lines.length - 1; // subtract header
        break;

      default:
        break;
    }

    return ImportPreview(
      recordCount: recordCount,
      photoCount: photoCount,
      audioCount: audioCount,
      videoCount: videoCount,
      documentCount: documentCount,
      tagsToCreate: tags.toList(),
      thingNamesToCreate: thingNames.toList(),
      dateRange: minDate != null && maxDate != null ? '$minDate - $maxDate' : null,
    );
  }

  Future<ImportResult> importRecords(ImportConfig config) async {
    final startTime = DateTime.now();
    final List<String> errors = [];
    final List<int> importedIds = [];

    try {
      final file = File(config.filePath);
      final content = await file.readAsString();

      List<Map<String, dynamic>> records = [];

      switch (config.sourceType) {
        case ImportSourceType.json:
        case ImportSourceType.thingNoteBackup:
          final data = jsonDecode(content);
          records = data is List
              ? List<Map<String, dynamic>>.from(data)
              : List<Map<String, dynamic>>.from(data['records'] ?? []);
          break;

        case ImportSourceType.csv:
          records = _parseCsv(content);
          break;

        default:
          throw Exception('Unsupported import source type');
      }

      for (final record in records) {
        try {
          final id = await _insertRecord(record, config);
          if (id != null) importedIds.add(id);
        } catch (e) {
          errors.add('Error importing record ${record['id']}: $e');
        }
      }

      return ImportResult(
        totalRecords: records.length,
        successCount: importedIds.length,
        failedCount: records.length - importedIds.length,
        errors: errors,
        importedRecordIds: importedIds,
        duration: DateTime.now().difference(startTime),
      );
    } catch (e) {
      return ImportResult(
        totalRecords: 0,
        successCount: 0,
        failedCount: 0,
        errors: ['Import failed: $e'],
        duration: DateTime.now().difference(startTime),
      );
    }
  }

  List<Map<String, dynamic>> _parseCsv(String content) {
    final List<Map<String, dynamic>> records = [];
    final lines = content.split('\n').where((l) => l.trim().isNotEmpty).toList();

    if (lines.isEmpty) return records;

    final headers = lines.first.split(',').map((h) => h.trim()).toList();

    for (int i = 1; i < lines.length; i++) {
      final values = _parseCsvLine(lines[i]);
      if (values.length != headers.length) continue;

      final record = <String, dynamic>{};
      for (int j = 0; j < headers.length; j++) {
        record[headers[j]] = values[j];
      }
      records.add(record);
    }

    return records;
  }

  List<String> _parseCsvLine(String line) {
    final List<String> values = [];
    var current = StringBuffer();
    var inQuotes = false;

    for (final char in line.split('')) {
      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == ',' && !inQuotes) {
        values.add(current.toString().trim());
        current = StringBuffer();
      } else {
        current.write(char);
      }
    }
    values.add(current.toString().trim());

    return values;
  }

  Future<int?> _insertRecord(Map<String, dynamic> record, ImportConfig config) async {
    final now = DateTime.now().toIso8601String();

    // Handle thing name
    int? thingNameId;
    final thingName = record['thing_name'] ?? record['thingName'] ?? record['category'];
    if (thingName != null && thingName.toString().isNotEmpty) {
      if (config.createMissingThingNames) {
        final existing = await db.query(
          'thing_names',
          where: 'name = ?',
          whereArgs: [thingName.toString()],
        );
        if (existing.isEmpty) {
          thingNameId = await db.insert('thing_names', {
            'name': thingName.toString(),
            'created_at': now,
          });
        } else {
          thingNameId = existing.first['id'] as int;
        }
      }
    }

    // Parse media paths
    List<String> photos = [];
    final photoData = record['photo_paths'] ?? record['photos'];
    if (photoData is String) {
      try {
        photos = List<String>.from(jsonDecode(photoData));
      } catch (_) {}
    } else if (photoData is List) {
      photos = List<String>.from(photoData);
    }

    final map = {
      'occurred_at': record['occurred_at'] ?? record['date'] ?? record['timestamp'] ?? now,
      'duration_sec': record['duration_sec'] ?? record['duration'] ?? 0,
      'note': record['note'] ?? record['content'] ?? record['description'] ?? '',
      'photo_paths': jsonEncode(photos),
      'audio_paths': jsonEncode(record['audio_paths'] ?? record['audio'] ?? []),
      'video_paths': jsonEncode(record['video_paths'] ?? []),
      'document_paths': jsonEncode(record['document_paths'] ?? []),
      'thing_name_id': thingNameId,
      'created_at': now,
      'updated_at': now,
      if (config.importLocation) ...{
        'latitude': record['latitude'] ?? record['lat'],
        'longitude': record['longitude'] ?? record['lng'],
        'address': record['address'] ?? record['location'],
      },
    };

    final id = await db.insert('episode_records', map);

    // Handle tags
    if (config.createMissingTags) {
      final tags = record['tags'] ?? record['tag_list'];
      if (tags is List) {
        for (final tag in tags) {
          if (tag is String) {
            await db.insert(
              'record_tags',
              {
                'record_id': id,
                'tag_name': tag,
                'added_at': now,
              },
              conflictAlgorithm: ConflictAlgorithm.ignore,
            );
          }
        }
      } else if (tags is String) {
        for (final tag in tags.split(',')) {
          await db.insert(
            'record_tags',
            {
              'record_id': id,
              'tag_name': tag.trim(),
              'added_at': now,
            },
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
        }
      }
    }

    return id;
  }

  Future<List<ImportTemplate>> getTemplates() async {
    final maps = await db.query('import_templates', orderBy: 'name ASC');
    return maps.map((m) => ImportTemplate.fromMap(m)).toList();
  }

  Future<int> saveTemplate(ImportTemplate template) async {
    return await db.insert('import_templates', template.toMap());
  }
}