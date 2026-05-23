import 'package:thing_note/features/record/domain/episode_record.dart';
import 'package:thing_note/features/record_link/domain/record_link.dart';

abstract class RecordRepository {
  Future<List<EpisodeRecord>> getAll();
  Future<EpisodeRecord?> getById(int id);
  Future<EpisodeRecord> create(EpisodeRecord record);
  Future<EpisodeRecord> update(EpisodeRecord record);
  Future<void> delete(int id);
  Future<void> deleteAll();
  Future<List<EpisodeRecord>> getReminderRecords();
  Future<int> getReminderCount();
  Future<List<EpisodeRecord>> getFavoriteRecords();
  Future<int> getFavoriteCount();
  Future<List<EpisodeRecord>> search(String query);
  Future<List<EpisodeRecord>> getRecordsByTag(int tagId);
  
  // Record links
  Future<List<RecordLink>> getLinksForRecord(int recordId);
  Future<List<EpisodeRecord>> getLinkedRecords(int recordId);
  Future<RecordLink> createLink(int recordIdA, int recordIdB);
  Future<void> deleteLink(int linkId);
  Future<void> deleteLinkByRecords(int recordIdA, int recordIdB);
}
