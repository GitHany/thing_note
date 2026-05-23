import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/core/database/database_provider.dart';
import 'package:thing_note/features/custom_theme/domain/custom_theme.dart';

class CustomThemeRepository {
  final Ref _ref;

  CustomThemeRepository(this._ref);

  Future<List<CustomTheme>> getAllThemes() async {
    final db = await _ref.read(databaseProvider.future);
    final result = await db.query(
      'custom_themes',
      orderBy: 'created_at DESC',
    );
    return result.map((e) => CustomTheme.fromMap(e)).toList();
  }

  Future<CustomTheme?> getActiveTheme() async {
    final db = await _ref.read(databaseProvider.future);
    final result = await db.query(
      'custom_themes',
      where: 'is_active = 1',
      limit: 1,
    );
    if (result.isEmpty) return null;
    return CustomTheme.fromMap(result.first);
  }

  Future<int> insertTheme(CustomTheme theme) async {
    final db = await _ref.read(databaseProvider.future);
    return db.insert('custom_themes', theme.toMap()..remove('id'));
  }

  Future<int> updateTheme(CustomTheme theme) async {
    final db = await _ref.read(databaseProvider.future);
    return db.update(
      'custom_themes',
      theme.toMap(),
      where: 'id = ?',
      whereArgs: [theme.id],
    );
  }

  Future<int> deleteTheme(int id) async {
    final db = await _ref.read(databaseProvider.future);
    return db.delete('custom_themes', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> setActiveTheme(int id) async {
    final db = await _ref.read(databaseProvider.future);

    // First, deactivate all themes
    await db.update('custom_themes', {'is_active': 0});

    // Then activate the selected one
    return db.update(
      'custom_themes',
      {'is_active': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deactivateAll() async {
    final db = await _ref.read(databaseProvider.future);
    return db.update('custom_themes', {'is_active': 0});
  }
}