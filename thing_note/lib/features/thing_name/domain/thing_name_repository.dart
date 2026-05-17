import 'package:thing_note/features/thing_name/domain/thing_name.dart';

abstract class ThingNameRepository {
  Future<List<ThingName>> getAll();
  Future<ThingName?> getById(int id);
  Future<ThingName> create(ThingName thingName);
  Future<void> update(ThingName thingName);
  Future<void> delete(int id);
  Stream<List<ThingName>> watchAll();
}
