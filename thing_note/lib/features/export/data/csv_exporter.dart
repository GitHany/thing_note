import 'dart:io';
import 'package:thing_note/features/export/domain/export_service.dart';
import 'package:thing_note/features/record/domain/episode_record.dart';
import 'package:thing_note/features/thing_name/domain/thing_name.dart';
import 'package:path_provider/path_provider.dart';

class CsvExporter implements ExportService {
  @override
  Future<File> export(List<EpisodeRecord> records, {List<String>? thingNames}) async {
    throw UnimplementedError('Use exportWithThingNames instead');
  }

  Future<File> exportWithThingNames(
    List<EpisodeRecord> records,
    List<ThingName> thingNameList,
  ) async {
    final thingNameMap = {for (final tn in thingNameList) tn.id: tn.name};
    final buffer = StringBuffer();

    buffer.writeln('ID,发生时间,持续时长(秒),备注,照片数量,录音数量,视频数量,事件名称,音频时长(秒),创建时间,更新时间');

    for (final record in records) {
      final note = record.note.replaceAll(',', '，');
      final thingName = thingNameMap[record.thingNameId] ?? '无';
      final audioDurations = record.audioDurationsSec.join(';');
      buffer.writeln(
        '${record.id},${record.occurredAt.toIso8601String()},${record.durationSec},$note,${record.photoPaths.length},${record.audioPaths.length},${record.videoPaths.length},$thingName,$audioDurations,${record.createdAt.toIso8601String()},${record.updatedAt.toIso8601String()}',
      );
    }

    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/exported_zips/records.csv');
    await file.parent.create(recursive: true);
    await file.writeAsString(buffer.toString());

    return file;
  }
}
