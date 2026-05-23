import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';
import 'package:thing_note/features/templates/domain/record_template.dart';
import 'package:thing_note/features/templates/domain/template_repository.dart';

final templateRepositoryProvider = FutureProvider<TemplateRepository>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  return TemplateRepositoryImpl(db);
});

class TemplateRepositoryImpl implements TemplateRepository {
  final Database _db;

  TemplateRepositoryImpl(this._db);

  @override
  Future<List<RecordTemplate>> getAll() async {
    final maps = await _db.query('record_templates', orderBy: 'created_at DESC');
    return maps.map((map) => RecordTemplate.fromMap(map)).toList();
  }

  @override
  Future<RecordTemplate?> getById(int id) async {
    final maps = await _db.query(
      'record_templates',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return RecordTemplate.fromMap(maps.first);
  }

  @override
  Future<int> create(RecordTemplate template) async {
    final map = template.toMap();
    map.remove('id');
    return await _db.insert('record_templates', map);
  }

  @override
  Future<void> update(RecordTemplate template) async {
    if (template.id == null) return;
    final map = template.toMap();
    map.remove('id');
    await _db.update(
      'record_templates',
      map,
      where: 'id = ?',
      whereArgs: [template.id],
    );
  }

  @override
  Future<void> delete(int id) async {
    await _db.delete(
      'record_templates',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}