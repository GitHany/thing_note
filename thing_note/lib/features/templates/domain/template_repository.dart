import 'package:thing_note/features/templates/domain/record_template.dart';

abstract class TemplateRepository {
  Future<List<RecordTemplate>> getAll();
  Future<RecordTemplate?> getById(int id);
  Future<int> create(RecordTemplate template);
  Future<void> update(RecordTemplate template);
  Future<void> delete(int id);
}