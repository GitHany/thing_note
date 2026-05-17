import 'dart:io';
import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:thing_note/features/record/domain/episode_record.dart';

class ZipExporter {
  static Future<File> exportRecords({
    required List<EpisodeRecord> records,
    required List<String> thingNames,
  }) async {
    final archive = Archive();

    for (final record in records) {
      final folderName = 'record_${record.id}_${record.occurredAt.toIso8601String().replaceAll(':', '-')}';

      final infoBuffer = StringBuffer();
      infoBuffer.writeln('ID: ${record.id}');
      infoBuffer.writeln('发生时间: ${record.occurredAt.toIso8601String()}');
      infoBuffer.writeln('持续时长: ${record.durationSec}秒');
      infoBuffer.writeln('备注: ${record.note}');
      infoBuffer.writeln('事件名称ID: ${record.thingNameId ?? "无"}');
      infoBuffer.writeln('创建时间: ${record.createdAt.toIso8601String()}');
      infoBuffer.writeln('更新时间: ${record.updatedAt.toIso8601String()}');

      final infoData = utf8.encode(infoBuffer.toString());
      archive.addFile(ArchiveFile('$folderName/info.txt', infoData.length, infoData));

      for (int i = 0; i < record.photoPaths.length; i++) {
        final photoFile = File(record.photoPaths[i]);
        if (await photoFile.exists()) {
          final photoData = await photoFile.readAsBytes();
          final ext = photoFile.path.split('.').last;
          archive.addFile(ArchiveFile('$folderName/photos/photo_$i.$ext', photoData.length, photoData));
        }
      }

      for (int i = 0; i < record.audioPaths.length; i++) {
        final audioFile = File(record.audioPaths[i]);
        if (await audioFile.exists()) {
          final audioData = await audioFile.readAsBytes();
          final ext = audioFile.path.split('.').last;
          archive.addFile(ArchiveFile('$folderName/audios/audio_$i.$ext', audioData.length, audioData));
        }
      }
    }

    final zipData = ZipEncoder().encode(archive);
    if (zipData == null) {
      throw Exception('Failed to create zip archive');
    }

    final tempDir = await getTemporaryDirectory();
    final zipDir = Directory('${tempDir.path}/exported_zips');
    if (!await zipDir.exists()) {
      await zipDir.create(recursive: true);
    }

    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').replaceAll('.', '-');
    final zipFile = File('${zipDir.path}/export_$timestamp.zip');
    await zipFile.writeAsBytes(zipData);

    return zipFile;
  }
}
