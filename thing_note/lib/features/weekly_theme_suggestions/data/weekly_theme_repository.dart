import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';
import 'package:thing_note/features/weekly_theme_suggestions/presentation/weekly_theme_suggestions_screen.dart';

final weeklyThemeRepositoryProvider = Provider<WeeklyThemeRepository>((ref) {
  return WeeklyThemeRepository(ref.watch(databaseProvider.future));
});

class WeeklyThemeRepository {
  final Future<Database> _dbFuture;

  WeeklyThemeRepository(this._dbFuture);

  Future<Database> get _db => _dbFuture;

  Future<List<WeeklyTheme>> getAllThemes() async {
    final db = await _db;
    final results = await db.query('weekly_themes', orderBy: 'start_date DESC');
    return results.map((e) => WeeklyTheme.fromMap(e)).toList();
  }

  Future<WeeklyTheme?> getCurrentTheme() async {
    final db = await _db;
    final results = await db.query(
      'weekly_themes',
      where: 'is_active = ?',
      whereArgs: [1],
      limit: 1,
    );

    if (results.isEmpty) return null;
    return WeeklyTheme.fromMap(results.first);
  }

  Future<int> createTheme(WeeklyTheme theme) async {
    final db = await _db;

    await db.update('weekly_themes', {'is_active': 0});

    return await db.insert('weekly_themes', {
      'theme_name': theme.themeName,
      'color_scheme': theme.colorScheme,
      'background_image': theme.backgroundImage,
      'start_date': theme.startDate.toIso8601String(),
      'end_date': theme.endDate?.toIso8601String(),
      'is_active': theme.isActive ? 1 : 0,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> initializeDefaultThemes() async {
    final db = await _db;
    final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM weekly_themes')) ?? 0;

    if (count == 0) {
      final now = DateTime.now();
      final defaults = [
        WeeklyTheme(
          themeName: '专注提升',
          colorScheme: '0xFF2196F3,0xFF1565C0',
          startDate: now.subtract(const Duration(days: 7)),
          endDate: now,
          isActive: false,
        ),
        WeeklyTheme(
          themeName: '健康生活',
          colorScheme: '0xFF4CAF50,0xFF2E7D32',
          startDate: now,
          endDate: now.add(const Duration(days: 7)),
          isActive: true,
        ),
      ];

      for (final theme in defaults) {
        await db.insert('weekly_themes', {
          'theme_name': theme.themeName,
          'color_scheme': theme.colorScheme,
          'start_date': theme.startDate.toIso8601String(),
          'end_date': theme.endDate?.toIso8601String(),
          'is_active': theme.isActive ? 1 : 0,
          'created_at': DateTime.now().toIso8601String(),
        });
      }
    }
  }
}