import 'dart:io';
import 'package:thing_note/features/record/domain/episode_record.dart';

abstract class ExportService {
  Future<File> export(List<EpisodeRecord> records, {List<String>? thingNames});
}
