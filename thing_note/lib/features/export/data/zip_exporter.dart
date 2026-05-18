import 'dart:io';
import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:thing_note/features/record/domain/episode_record.dart';
import 'package:thing_note/features/thing_name/domain/thing_name.dart';

class ZipExporter {
  static Future<File> exportRecords({
    required List<EpisodeRecord> records,
    required List<ThingName> thingNames,
    void Function(int current, int total)? onProgress,
  }) async {
    final archive = Archive();
    final total = records.length;

    final thingNameMap = {for (final tn in thingNames) tn.id: tn.name};

    for (int i = 0; i < records.length; i++) {
      final record = records[i];
      final folderName = 'record_${record.id}_${record.occurredAt.toIso8601String().replaceAll(':', '-')}';

      final infoBuffer = StringBuffer();
      infoBuffer.writeln('ID: ${record.id}');
      infoBuffer.writeln('发生时间: ${record.occurredAt.toIso8601String()}');
      infoBuffer.writeln('持续时长: ${record.durationSec}秒');
      infoBuffer.writeln('备注: ${record.note}');
      infoBuffer.writeln('事件名称: ${thingNameMap[record.thingNameId] ?? "无"}');
      infoBuffer.writeln('创建时间: ${record.createdAt.toIso8601String()}');
      infoBuffer.writeln('更新时间: ${record.updatedAt.toIso8601String()}');

      if (record.audioDurationsSec.isNotEmpty) {
        infoBuffer.writeln('音频时长(秒): ${record.audioDurationsSec.join(",")}');
      }

      final infoData = utf8.encode(infoBuffer.toString());
      archive.addFile(ArchiveFile('$folderName/info.txt', infoData.length, infoData));

      for (int j = 0; j < record.photoPaths.length; j++) {
        final photoFile = File(record.photoPaths[j]);
        if (await photoFile.exists()) {
          final photoData = await photoFile.readAsBytes();
          final ext = photoFile.path.split('.').last;
          archive.addFile(ArchiveFile('$folderName/photos/photo_$j.$ext', photoData.length, photoData));
        }
      }

      for (int j = 0; j < record.audioPaths.length; j++) {
        final audioFile = File(record.audioPaths[j]);
        if (await audioFile.exists()) {
          final audioData = await audioFile.readAsBytes();
          final ext = audioFile.path.split('.').last;
          archive.addFile(ArchiveFile('$folderName/audios/audio_$j.$ext', audioData.length, audioData));
        }
      }

      onProgress?.call(i + 1, total);
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
