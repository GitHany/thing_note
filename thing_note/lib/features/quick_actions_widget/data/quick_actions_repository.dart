import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/features/quick_actions_widget/domain/quick_action.dart';
import 'package:thing_note/core/database/database_provider.dart';

final quickActionsRepositoryProvider = Provider((ref) => QuickActionsRepository(ref: ref));

class QuickActionsRepository {
  final Ref _ref;

  QuickActionsRepository({required Ref ref}) : _ref = ref;

  Future<Database> get _db async {
    final db = await _ref.read(databaseProvider.future);
    return db;
  }

  Future<void> initDefaultActions() async {
    final db = await _db;
    
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM quick_actions'),
    );
    
    if (count != null && count > 0) return;

    final defaultActions = [
      QuickAction(
        name: '快速记录',
        icon: '📝',
        color: '#2196F3',
        actionType: 'quick_record',
        order: 0,
        createdAt: DateTime.now(),
      ),
      QuickAction(
        name: '语音记录',
        icon: '🎤',
        color: '#4CAF50',
        actionType: 'voice_record',
        order: 1,
        createdAt: DateTime.now(),
      ),
      QuickAction(
        name: '拍照记录',
        icon: '📷',
        color: '#FF9800',
        actionType: 'camera_record',
        order: 2,
        createdAt: DateTime.now(),
      ),
      QuickAction(
        name: '今日统计',
        icon: '📊',
        color: '#9C27B0',
        actionType: 'navigation',
        actionConfig: '/statistics',
        order: 3,
        createdAt: DateTime.now(),
      ),
      QuickAction(
        name: '日历',
        icon: '📅',
        color: '#E91E63',
        actionType: 'navigation',
        actionConfig: '/calendar',
        order: 4,
        createdAt: DateTime.now(),
      ),
    ];

    for (final action in defaultActions) {
      await db.insert('quick_actions', action.toMap());
    }
  }

  Future<List<QuickAction>> getAllActions() async {
    final db = await _db;
    final results = await db.query(
      'quick_actions',
      orderBy: 'action_order ASC',
    );
    return results.map((e) => QuickAction.fromMap(e)).toList();
  }

  Future<List<QuickAction>> getEnabledActions() async {
    final db = await _db;
    final results = await db.query(
      'quick_actions',
      where: 'is_enabled = 1',
      orderBy: 'action_order ASC',
    );
    return results.map((e) => QuickAction.fromMap(e)).toList();
  }

  Future<int> insertAction(QuickAction action) async {
    final db = await _db;
    return await db.insert('quick_actions', action.toMap());
  }

  Future<int> updateAction(QuickAction action) async {
    final db = await _db;
    return await db.update(
      'quick_actions',
      action.toMap(),
      where: 'id = ?',
      whereArgs: [action.id],
    );
  }

  Future<int> deleteAction(int id) async {
    final db = await _db;
    return await db.delete(
      'quick_actions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> reorderActions(List<int> orderedIds) async {
    final db = await _db;
    for (int i = 0; i < orderedIds.length; i++) {
      await db.update(
        'quick_actions',
        {'action_order': i},
        where: 'id = ?',
        whereArgs: [orderedIds[i]],
      );
    }
  }

  Future<void> toggleAction(int id) async {
    final db = await _db;
    await db.rawUpdate(
      'UPDATE quick_actions SET is_enabled = CASE WHEN is_enabled = 1 THEN 0 ELSE 1 END WHERE id = ?',
      [id],
    );
  }

  Future<void> incrementUseCount(int id) async {
    final db = await _db;
    await db.rawUpdate(
      'UPDATE quick_actions SET use_count = use_count + 1 WHERE id = ?',
      [id],
    );
  }
}