import 'dart:io';
import 'dart:convert';
import 'dart:isolate';
import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:thing_note/features/record/domain/episode_record.dart';
import 'package:thing_note/features/thing_name/domain/thing_name.dart';

const _noCompressExtensions = {
  '.mp4', '.mov', '.avi', '.mkv', '.flv', '.wmv', '.webm',
  '.mp3', '.aac', '.m4a', '.ogg', '.flac', '.wav', '.wma',
  '.jpg', '.jpeg', '.png', '.gif', '.webp',
};

bool _shouldStore(String filePath) {
  final ext = filePath.contains('.') ? '.${filePath.split('.').last.toLowerCase()}' : '';
  return _noCompressExtensions.contains(ext);
}

class _ExportParams {
  final List<Map<String, dynamic>> records;
  final Map<int?, String> thingNameMap;
  final String outputPath;
  final SendPort sendPort;

  _ExportParams({
    required this.records,
    required this.thingNameMap,
    required this.outputPath,
    required this.sendPort,
  });
}

class _ProgressMessage {
  final String type;
  final String? logMessage;
  final String? path;
  final String? error;
  final List<String>? logs;

  _ProgressMessage({
    required this.type,
    this.logMessage,
    this.path,
    this.error,
    this.logs,
  });

  Map<String, dynamic> toMap() => {
    'type': type,
    if (logMessage != null) 'logMessage': logMessage,
    if (path != null) 'path': path,
    if (error != null) 'error': error,
    if (logs != null) 'logs': logs,
  };
}

void _exportRecordsInIsolate(_ExportParams params) {
  try {
    final archive = Archive();
    final records = params.records;
    final thingNameMap = params.thingNameMap;
    final sendPort = params.sendPort;

    final logs = <String>[];
    void addLog(String message) {
      logs.add(message);
      sendPort.send(_ProgressMessage(
        type: 'log',
        logMessage: message,
        logs: List.from(logs),
      ).toMap());
    }

    for (int i = 0; i < records.length; i++) {
      final r = records[i];
      final recordId = r['id'] as int?;
      final occurredAt = r['occurredAt'] as String;
      final folderName = 'record_${recordId}_${occurredAt.replaceAll(':', '-')}';

      addLog('📝 正在添加记录 ${i + 1}/${records.length} 的信息...');

      final infoBuffer = StringBuffer();
      infoBuffer.writeln('ID: $recordId');
      infoBuffer.writeln('发生时间: $occurredAt');
      infoBuffer.writeln('持续时长: ${r['durationSec']}秒');
      infoBuffer.writeln('备注: ${r['note']}');
      infoBuffer.writeln('事件名称: ${thingNameMap[r['thingNameId']] ?? "无"}');
      infoBuffer.writeln('创建时间: ${r['createdAt']}');
      infoBuffer.writeln('更新时间: ${r['updatedAt']}');

      final audioDurations = r['audioDurationsSec'] as List;
      if (audioDurations.isNotEmpty) {
        infoBuffer.writeln('音频时长(秒): ${audioDurations.join(",")}');
      }

      final videoPaths = r['videoPaths'] as List;
      if (videoPaths.isNotEmpty) {
        infoBuffer.writeln('视频数量: ${videoPaths.length}');
      }

      final infoData = utf8.encode(infoBuffer.toString());
      archive.addFile(ArchiveFile('$folderName/info.txt', infoData.length, infoData));

      final photoPaths = r['photoPaths'] as List;
      if (photoPaths.isNotEmpty) {
        addLog('📷 正在添加照片 (${photoPaths.length}张)...');
        for (int j = 0; j < photoPaths.length; j++) {
          final photoFile = File(photoPaths[j] as String);
          if (photoFile.existsSync()) {
            final photoData = photoFile.readAsBytesSync();
            final ext = photoFile.path.split('.').last;
            final filePath = '$folderName/photos/photo_$j.$ext';
            if (_shouldStore(photoFile.path)) {
              archive.addFile(ArchiveFile.noCompress(filePath, photoData.length, photoData));
            } else {
              archive.addFile(ArchiveFile(filePath, photoData.length, photoData));
            }
          }
        }
        addLog('✅ 照片添加完成 (${photoPaths.length}张)');
      }

      final audioPaths = r['audioPaths'] as List;
      if (audioPaths.isNotEmpty) {
        addLog('🎤 正在添加录音 (${audioPaths.length}个)...');
        for (int j = 0; j < audioPaths.length; j++) {
          final audioFile = File(audioPaths[j] as String);
          if (audioFile.existsSync()) {
            final audioData = audioFile.readAsBytesSync();
            final ext = audioFile.path.split('.').last;
            final filePath = '$folderName/audios/audio_$j.$ext';
            archive.addFile(ArchiveFile.noCompress(filePath, audioData.length, audioData));
          }
        }
        addLog('✅ 录音添加完成 (${audioPaths.length}个)');
      }

      if (videoPaths.isNotEmpty) {
        addLog('🎬 正在添加视频 (${videoPaths.length}个)...');
        for (int j = 0; j < videoPaths.length; j++) {
          final videoFile = File(videoPaths[j] as String);
          if (videoFile.existsSync()) {
            final videoData = videoFile.readAsBytesSync();
            final ext = videoFile.path.split('.').last;
            final filePath = '$folderName/videos/video_$j.$ext';
            archive.addFile(ArchiveFile.noCompress(filePath, videoData.length, videoData));
          }
        }
        addLog('✅ 视频添加完成 (${videoPaths.length}个)');
      }
    }

    addLog('📦 正在压缩...');

    final zipData = ZipEncoder().encode(archive);

    if (zipData == null) {
      sendPort.send(_ProgressMessage(type: 'error', error: 'Failed to create zip archive').toMap());
      return;
    }

    addLog('✅ 压缩完成');

    addLog('💾 正在保存文件...');

    final zipDir = Directory('${params.outputPath}/thing_note/exported_zips');
    if (!zipDir.existsSync()) {
      zipDir.createSync(recursive: true);
    }

    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').replaceAll('.', '-');
    final exportFile = File('${zipDir.path}/export_$timestamp.zip');
    exportFile.writeAsBytesSync(zipData);

    addLog('✅ 文件保存完成');

    sendPort.send(_ProgressMessage(
      type: 'done',
      path: exportFile.path,
      logs: logs,
    ).toMap());
  } catch (e) {
    params.sendPort.send(_ProgressMessage(type: 'error', error: e.toString()).toMap());
  }
}

class ZipExporter {
  static Future<File> exportRecords({
    required List<EpisodeRecord> records,
    required List<ThingName> thingNames,
    void Function(int current, int total)? onProgress,
    void Function(String log)? onLog,
  }) async {
    final tempDir = await getApplicationDocumentsDirectory();

    final receivePort = ReceivePort();

    final recordsMaps = records.map((r) => {
      'id': r.id,
      'occurredAt': r.occurredAt.toIso8601String(),
      'durationSec': r.durationSec,
      'note': r.note,
      'photoPaths': r.photoPaths,
      'audioPaths': r.audioPaths,
      'audioDurationsSec': r.audioDurationsSec,
      'videoPaths': r.videoPaths,
      'thingNameId': r.thingNameId,
      'createdAt': r.createdAt.toIso8601String(),
      'updatedAt': r.updatedAt.toIso8601String(),
    }).toList();

    final thingNameMap = {for (final tn in thingNames) tn.id: tn.name};

    await Isolate.spawn(
      _exportRecordsInIsolate,
      _ExportParams(
        records: recordsMaps,
        thingNameMap: thingNameMap,
        outputPath: tempDir.path,
        sendPort: receivePort.sendPort,
      ),
    );

    File? resultFile;
    String? errorMessage;

    await for (final msg in receivePort) {
      final data = msg as Map<String, dynamic>;
      final type = data['type'] as String;

      if (type == 'log') {
        final logMessage = data['logMessage'] as String?;
        if (logMessage != null) {
          onLog?.call(logMessage);
        }
      } else if (type == 'progress') {
        onProgress?.call(data['current'] as int, data['total'] as int);
      } else if (type == 'done') {
        resultFile = File(data['path'] as String);
        receivePort.close();
        break;
      } else if (type == 'error') {
        errorMessage = data['error'] as String;
        receivePort.close();
        break;
      }
    }

    if (errorMessage != null) {
      throw Exception(errorMessage);
    }

    if (resultFile == null) {
      throw Exception('Export failed: no result');
    }

    return resultFile;
  }
}