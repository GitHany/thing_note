import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/features/smart_shortcut/domain/smart_shortcut.dart';
import 'package:thing_note/core/database/database_provider.dart';

final smartShortcutRepositoryProvider = Provider((ref) => SmartShortcutRepository(ref));

class SmartShortcutRepository {
  final Ref _ref;

  SmartShortcutRepository(this._ref);

  Future<Database> get _db async {
    final db = await _ref.read(databaseProvider.future);
    return db;
  }

  Future<List<SmartShortcut>> getAllShortcuts() async {
    final db = await _db;
    final results = await db.query('smart_shortcuts', orderBy: 'use_count DESC, created_at DESC');
    return results.map((e) => SmartShortcut.fromMap(e)).toList();
  }

  Future<List<SmartShortcut>> getEnabledShortcuts() async {
    final db = await _db;
    final results = await db.query(
      'smart_shortcuts',
      where: 'is_enabled = 1',
      orderBy: 'use_count DESC',
    );
    return results.map((e) => SmartShortcut.fromMap(e)).toList();
  }

  Future<int> insertShortcut(SmartShortcut shortcut) async {
    final db = await _db;
    return await db.insert('smart_shortcuts', shortcut.toMap());
  }

  Future<int> updateShortcut(SmartShortcut shortcut) async {
    final db = await _db;
    return await db.update(
      'smart_shortcuts',
      shortcut.toMap(),
      where: 'id = ?',
      whereArgs: [shortcut.id],
    );
  }

  Future<int> deleteShortcut(int id) async {
    final db = await _db;
    return await db.delete(
      'smart_shortcuts',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> toggleShortcut(int id) async {
    final db = await _db;
    await db.rawUpdate(
      'UPDATE smart_shortcuts SET is_enabled = CASE WHEN is_enabled = 1 THEN 0 ELSE 1 END WHERE id = ?',
      [id],
    );
  }

  Future<void> incrementUseCount(int id) async {
    final db = await _db;
    await db.rawUpdate(
      'UPDATE smart_shortcuts SET use_count = use_count + 1 WHERE id = ?',
      [id],
    );
  }

  Future<void> initDefaultShortcuts() async {
    final db = await _db;
    
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM smart_shortcuts'),
    );
    
    if (count != null && count > 0) return;

    final defaults = [
      SmartShortcut(
        name: '新建记录',
        icon: '📝',
        actionType: 'navigate',
        actionConfig: '/record/new',
        triggerType: 'gesture',
        triggerConfig: 'double_tap',
        createdAt: DateTime.now(),
      ),
      SmartShortcut(
        name: '快速拍照',
        icon: '📷',
        actionType: 'quick_action',
        actionConfig: 'camera',
        triggerType: 'button',
        triggerConfig: 'quick_capture',
        createdAt: DateTime.now(),
      ),
      SmartShortcut(
        name: '语音记录',
        icon: '🎤',
        actionType: 'navigate',
        actionConfig: '/voice-recorder',
        triggerType: 'button',
        triggerConfig: 'long_press',
        createdAt: DateTime.now(),
      ),
      SmartShortcut(
        name: '查看统计',
        icon: '📊',
        actionType: 'navigate',
        actionConfig: '/statistics',
        triggerType: 'gesture',
        triggerConfig: 'swipe_right',
        createdAt: DateTime.now(),
      ),
    ];

    for (final shortcut in defaults) {
      await db.insert('smart_shortcuts', shortcut.toMap());
    }
  }
}