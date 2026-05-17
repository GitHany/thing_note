import 'package:thing_note/features/thing_name/domain/thing_name.dart';
import 'package:thing_note/features/thing_name/domain/thing_name_repository.dart';
import 'package:sqflite/sqflite.dart';

class ThingNameRepositoryImpl implements ThingNameRepository {
  final Database database;

  ThingNameRepositoryImpl(this.database);

  ThingName _fromMap(Map<String, dynamic> map) {
    return ThingName(
      id: map['id'] as int?,
      name: map['name'] as String,
      remark: map['remark'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> _toMap(ThingName thingName) {
    return {
      'id': thingName.id,
      'name': thingName.name,
      'remark': thingName.remark,
      'created_at': thingName.createdAt.toIso8601String(),
    };
  }

  @override
  Future<List<ThingName>> getAll() async {
    final maps = await database.query(
      'thing_names',
      orderBy: 'created_at ASC',
    );
    return maps.map(_fromMap).toList();
  }

  @override
  Future<ThingName?> getById(int id) async {
    final maps = await database.query(
      'thing_names',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return _fromMap(maps.first);
  }

  @override
  Future<ThingName> create(ThingName thingName) async {
    final map = _toMap(thingName);
    map.remove('id');
    final id = await database.insert('thing_names', map);
    return thingName.copyWith(id: id);
  }

  @override
  Future<void> update(ThingName thingName) async {
    final map = _toMap(thingName);
    map.remove('id');
    await database.update(
      'thing_names',
      map,
      where: 'id = ?',
      whereArgs: [thingName.id],
    );
  }

  @override
  Future<void> delete(int id) async {
    await database.delete(
      'thing_names',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Stream<List<ThingName>> watchAll() async* {
    final initial = await getAll();
    yield initial;
  }
}
