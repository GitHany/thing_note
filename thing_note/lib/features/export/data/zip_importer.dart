import 'dart:io';
import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:thing_note/core/utils/file_storage.dart';
import 'package:thing_note/features/record/domain/episode_record.dart';

enum ConflictResolution {
  skip,
  overwrite,
  skipAll,
  overwriteAll,
}

class ConflictInfo {
  final EpisodeRecord existingRecord;
  final EpisodeRecord importedRecord;

  ConflictInfo({
    required this.existingRecord,
    required this.importedRecord,
  });
}

class ImportedRecordData {
  final int? id;
  final DateTime occurredAt;
  final int durationSec;
  final String note;
  final List<String> photoPaths;
  final List<String> audioPaths;
  final List<int> audioDurationsSec;
  final int? thingNameId;
  final DateTime createdAt;
  final DateTime updatedAt;

  ImportedRecordData({
    this.id,
    required this.occurredAt,
    required this.durationSec,
    required this.note,
    required this.photoPaths,
    required this.audioPaths,
    required this.audioDurationsSec,
    this.thingNameId,
    required this.createdAt,
    required this.updatedAt,
  });
}

class ZipImporter {
  static Future<List<ImportedRecordData>> parseZip(File zipFile) async {
    final bytes = await zipFile.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    final List<ImportedRecordData> records = [];
    final Map<String, ArchiveFile> fileMap = {};

    for (final file in archive) {
      fileMap[file.name] = file;
    }

    final infoFiles = archive.files.where((f) => f.name.endsWith('info.txt')).toList();

    for (final infoFile in infoFiles) {
      final content = utf8.decode(infoFile.content as List<int>);
      final record = _parseInfoFile(content, infoFile.name, archive);
      if (record != null) {
        records.add(record);
      }
    }

    return records;
  }

  static ImportedRecordData? _parseInfoFile(String content, String infoFileName, Archive archive) {
    final Map<String, String> lines = {};
    for (final line in content.split('\n')) {
      final parts = line.split(': ');
      if (parts.length >= 2) {
        lines[parts[0].trim()] = parts.sublist(1).join(': ').trim();
      }
    }

    final recordIdStr = lines['ID'];
    final occurredAtStr = lines['发生时间'];
    final durationSecStr = lines['持续时长'];
    final note = lines['备注'] ?? '';
    final thingNameIdStr = lines['事件名称ID'];
    final createdAtStr = lines['创建时间'];
    final updatedAtStr = lines['更新时间'];

    if (occurredAtStr == null || durationSecStr == null || createdAtStr == null || updatedAtStr == null) {
      return null;
    }

    int? id;
    if (recordIdStr != null && recordIdStr != '无') {
      id = int.tryParse(recordIdStr);
    }

    int? thingNameId;
    if (thingNameIdStr != null && thingNameIdStr != '无') {
      thingNameId = int.tryParse(thingNameIdStr);
    }

    final folderPath = infoFileName.substring(0, infoFileName.lastIndexOf('/'));

    final List<String> photoPaths = [];
    final List<String> audioPaths = [];

    final photosDir = '$folderPath/photos/';
    final audiosDir = '$folderPath/audios/';

    for (final file in archive.files) {
      if (file.name.startsWith(photosDir) && !file.isFile) {
        photoPaths.add(file.name);
      } else if (file.name.startsWith(audiosDir) && !file.isFile) {
        audioPaths.add(file.name);
      }
    }

    return ImportedRecordData(
      id: id,
      occurredAt: DateTime.parse(occurredAtStr),
      durationSec: int.parse(durationSecStr.replaceAll('秒', '')),
      note: note,
      photoPaths: photoPaths,
      audioPaths: audioPaths,
      audioDurationsSec: List.filled(audioPaths.length, 0),
      thingNameId: thingNameId,
      createdAt: DateTime.parse(createdAtStr),
      updatedAt: DateTime.parse(updatedAtStr),
    );
  }

  static Future<List<String>> extractFiles(
    ImportedRecordData recordData,
    File zipFile,
    int? newRecordId,
  ) async {
    final bytes = await zipFile.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    final fileMap = <String, ArchiveFile>{};
    for (final file in archive.files) {
      fileMap[file.name] = file;
    }

    final List<String> savedPhotoPaths = [];
    final List<String> savedAudioPaths = [];

    for (int i = 0; i < recordData.photoPaths.length; i++) {
      final relativePath = recordData.photoPaths[i];
      final archiveFile = fileMap[relativePath];
      if (archiveFile != null) {
        final ext = relativePath.split('.').last;
        final savedPath = await FileStorage.savePhotoBytes(
          archiveFile.content as List<int>,
          ext,
        );
        savedPhotoPaths.add(savedPath);
      }
    }

    for (int i = 0; i < recordData.audioPaths.length; i++) {
      final relativePath = recordData.audioPaths[i];
      final archiveFile = fileMap[relativePath];
      if (archiveFile != null) {
        final ext = relativePath.split('.').last;
        final savedPath = await FileStorage.saveAudioBytes(
          archiveFile.content as List<int>,
          ext,
        );
        savedAudioPaths.add(savedPath);
      }
    }

    return [...savedPhotoPaths, ...savedAudioPaths];
  }

  static EpisodeRecord toEpisodeRecord(
    ImportedRecordData data, {
    List<String>? savedPhotoPaths,
    List<String>? savedAudioPaths,
  }) {
    return EpisodeRecord(
      occurredAt: data.occurredAt,
      durationSec: data.durationSec,
      note: data.note,
      photoPaths: savedPhotoPaths ?? data.photoPaths,
      audioPaths: savedAudioPaths ?? data.audioPaths,
      audioDurationsSec: data.audioDurationsSec,
      thingNameId: data.thingNameId,
      createdAt: data.createdAt,
      updatedAt: data.updatedAt,
    );
  }
}
