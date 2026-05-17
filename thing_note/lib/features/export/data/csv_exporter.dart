import 'dart:io';
import 'package:thing_note/features/export/domain/export_service.dart';
import 'package:thing_note/features/record/domain/episode_record.dart';
import 'package:path_provider/path_provider.dart';

class CsvExporter implements ExportService {
  @override
  Future<File> export(List<EpisodeRecord> records, {List<String>? thingNames}) async {
    final buffer = StringBuffer();

    buffer.writeln('ID,发生时间,持续时长(秒),备注,照片数量,录音数量,事件名称ID,创建时间,更新时间');

    for (final record in records) {
      final note = record.note.replaceAll(',', '，');
      buffer.writeln(
        '${record.id},${record.occurredAt.toIso8601String()},${record.durationSec},$note,${record.photoPaths.length},${record.audioPaths.length},${record.thingNameId ?? ''},${record.createdAt.toIso8601String()},${record.updatedAt.toIso8601String()}',
      );
    }

    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/exported_zips/records.csv');
    await file.parent.create(recursive: true);
    await file.writeAsString(buffer.toString());

    return file;
  }
}
