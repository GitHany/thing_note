import 'package:thing_note/features/tag/domain/tag.dart';

abstract class TagRepository {
  Future<List<Tag>> getAllTags();
  Future<Tag?> getTagById(int id);
  Future<int> createTag(Tag tag);
  Future<void> updateTag(Tag tag);
  Future<void> deleteTag(int id);
  Future<List<Tag>> getTagsForRecord(int recordId);
  Future<void> setTagsForRecord(int recordId, List<int> tagIds);
  Future<void> addTagToRecord(int recordId, int tagId);
  Future<void> removeTagFromRecord(int recordId, int tagId);
  Future<Map<int, List<Tag>>> getTagsForRecords(List<int> recordIds);
}