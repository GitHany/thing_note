import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/core/database/database_provider.dart';
import 'package:thing_note/features/smart_dashboard/domain/smart_dashboard.dart';

class SmartDashboardRepository {
  final Ref _ref;

  SmartDashboardRepository(this._ref);

  Future<List<SmartDashboardConfig>> getAllConfigs() async {
    final db = await _ref.read(databaseProvider.future);
    final result = await db.query(
      'smart_dashboard_configs',
      orderBy: 'created_at DESC',
    );
    return result.map((e) => SmartDashboardConfig.fromMap(e)).toList();
  }

  Future<SmartDashboardConfig?> getActiveConfig() async {
    final db = await _ref.read(databaseProvider.future);
    final result = await db.query(
      'smart_dashboard_configs',
      where: 'is_active = 1',
      limit: 1,
    );
    if (result.isEmpty) return null;
    return SmartDashboardConfig.fromMap(result.first);
  }

  Future<int> insertConfig(SmartDashboardConfig config) async {
    final db = await _ref.read(databaseProvider.future);
    return db.insert('smart_dashboard_configs', config.toMap()..remove('id'));
  }

  Future<int> updateConfig(SmartDashboardConfig config) async {
    final db = await _ref.read(databaseProvider.future);
    return db.update(
      'smart_dashboard_configs',
      config.toMap()..['updated_at'] = DateTime.now().toIso8601String(),
      where: 'id = ?',
      whereArgs: [config.id],
    );
  }

  Future<int> deleteConfig(int id) async {
    final db = await _ref.read(databaseProvider.future);
    return db.delete('smart_dashboard_configs', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> setActiveConfig(int id) async {
    final db = await _ref.read(databaseProvider.future);
    await db.update('smart_dashboard_configs', {'is_active': 0});
    return db.update(
      'smart_dashboard_configs',
      {'is_active': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> updateWidgetOrder(int id, List<String> order) async {
    final db = await _ref.read(databaseProvider.future);
    return db.update(
      'smart_dashboard_configs',
      {
        'widget_order': jsonEncode(order),
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> initDefaultConfig() async {
    final db = await _ref.read(databaseProvider.future);
    final count = await db.rawQuery('SELECT COUNT(*) as cnt FROM smart_dashboard_configs');
    if ((count.first['cnt'] as int) == 0) {
      await insertConfig(SmartDashboardConfig(
        name: '默认',
        widgetOrder: ['todayOverview', 'recordCount', 'habitProgress', 'moodTrend', 'goalProgress'],
        createdAt: DateTime.now(),
      ));
    }
  }
}