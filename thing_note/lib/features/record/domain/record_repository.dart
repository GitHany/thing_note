import 'package:thing_note/features/record/domain/episode_record.dart';

abstract class RecordRepository {
  Future<List<EpisodeRecord>> getAll();
  Future<EpisodeRecord?> getById(int id);
  Future<EpisodeRecord> create(EpisodeRecord record);
  Future<EpisodeRecord> update(EpisodeRecord record);
  Future<void> delete(int id);
  Future<void> deleteAll();
  Future<List<EpisodeRecord>> getReminderRecords();
  Future<int> getReminderCount();
}
