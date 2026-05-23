import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';
import 'package:thing_note/features/smart_batch_edit/domain/batch_edit_models.dart';

/// 智能批量编辑服务 Provider
final smartBatchEditServiceProvider = Provider<SmartBatchEditService>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return SmartBatchEditService(dbAsync);
});

/// 批量编辑规则列表 Provider
final batchEditRulesProvider = FutureProvider<List<BatchEditRule>>((ref) async {
  final service = ref.watch(smartBatchEditServiceProvider);
  return service.getRules();
});

/// 批量编辑历史 Provider
final batchEditHistoryProvider = FutureProvider<List<BatchEditHistory>>((ref) async {
  final service = ref.watch(smartBatchEditServiceProvider);
  return service.getHistory();
});

/// 匹配的记录数 Provider
final matchingRecordsCountProvider = FutureProvider.family<int, List<EditCondition>>((ref, conditions) async {
  final service = ref.watch(smartBatchEditServiceProvider);
  return service.countMatchingRecords(conditions);
});

class SmartBatchEditService {
  final AsyncValue<Database> _dbAsync;

  SmartBatchEditService(this._dbAsync);

  Future<Database> get _db async {
    final db = _dbAsync.value;
    if (db == null) throw Exception('Database not initialized');
    return db;
  }

  /// 获取所有规则
  Future<List<BatchEditRule>> getRules() async {
    final db = await _db;
    final maps = await db.query('batch_edit_rules', orderBy: 'created_at DESC');
    return maps.map((m) => BatchEditRule.fromMap(m)).toList();
  }

  /// 添加规则
  Future<int> addRule(BatchEditRule rule) async {
    final db = await _db;
    return db.insert('batch_edit_rules', rule.toMap()..remove('id'));
  }

  /// 更新规则
  Future<int> updateRule(BatchEditRule rule) async {
    final db = await _db;
    return db.update(
      'batch_edit_rules',
      rule.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [rule.id],
    );
  }

  /// 删除规则
  Future<int> deleteRule(int id) async {
    final db = await _db;
    return db.delete('batch_edit_rules', where: 'id = ?', whereArgs: [id]);
  }

  /// 启用/禁用规则
  Future<int> toggleRule(int id, bool enabled) async {
    final db = await _db;
    return db.update(
      'batch_edit_rules',
      {'is_enabled': enabled ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 获取历史记录
  Future<List<BatchEditHistory>> getHistory({int limit = 50}) async {
    final db = await _db;
    final maps = await db.query(
      'batch_edit_history',
      orderBy: 'performed_at DESC',
      limit: limit,
    );
    return maps.map((m) => BatchEditHistory.fromMap(m)).toList();
  }

  /// 执行批量编辑预览
  Future<List<Map<String, dynamic>>> previewEdit({
    required List<EditCondition> conditions,
    required List<EditAction> actions,
  }) async {
    final db = await _db;
    final whereClause = _buildWhereClause(conditions);
    final whereArgs = _buildWhereArgs(conditions);

    final records = await db.rawQuery('''
      SELECT r.*, tn.name as thing_name
      FROM episode_records r
      LEFT JOIN thing_names tn ON r.thing_name_id = tn.id
      WHERE $whereClause
    ''', whereArgs);

    return records;
  }

  /// 执行批量编辑
  Future<int> executeEdit({
    required List<EditCondition> conditions,
    required List<EditAction> actions,
    String? editType,
  }) async {
    final db = await _db;
    final whereClause = _buildWhereClause(conditions);
    final whereArgs = _buildWhereArgs(conditions);

    // 获取匹配的记录
    final records = await db.rawQuery('''
      SELECT r.id
      FROM episode_records r
      LEFT JOIN thing_names tn ON r.thing_name_id = tn.id
      WHERE $whereClause
    ''', whereArgs);

    int affectedCount = 0;

    for (final record in records) {
      final recordId = record['id'] as int;

      for (final action in actions) {
        switch (action.type) {
          case 'set_thing_name':
            final thingName = action.value as String;
            final thing = await db.query(
              'thing_names',
              where: 'name = ?',
              whereArgs: [thingName],
            );
            if (thing.isNotEmpty) {
              await db.update(
                'episode_records',
                {'thing_name_id': thing.first['id'], 'updated_at': DateTime.now().toIso8601String()},
                where: 'id = ?',
                whereArgs: [recordId],
              );
              affectedCount++;
            }
            break;

          case 'add_tag':
            final tag = action.value as String;
            await db.insert('record_tags', {
              'record_id': recordId,
              'tag_name': tag,
              'added_at': DateTime.now().toIso8601String(),
            });
            affectedCount++;
            break;

          case 'remove_tag':
            final tag = action.value as String;
            await db.delete(
              'record_tags',
              where: 'record_id = ? AND tag_name = ?',
              whereArgs: [recordId, tag],
            );
            affectedCount++;
            break;

          case 'set_reminder':
            final reminderTime = action.value as String;
            await db.insert('enhanced_reminders', {
              'record_id': recordId,
              'remind_at': reminderTime,
              'reminder_type': 'once',
              'created_at': DateTime.now().toIso8601String(),
            });
            await db.update(
              'episode_records',
              {'has_reminder': 1},
              where: 'id = ?',
              whereArgs: [recordId],
            );
            affectedCount++;
            break;

          case 'adjust_time':
            final minutes = action.value as int;
            final record = await db.query(
              'episode_records',
              where: 'id = ?',
              whereArgs: [recordId],
            );
            if (record.isNotEmpty) {
              final originalTime = DateTime.parse(record.first['occurred_at'] as String);
              final newTime = originalTime.add(Duration(minutes: minutes));
              await db.update(
                'episode_records',
                {
                  'occurred_at': newTime.toIso8601String(),
                  'updated_at': DateTime.now().toIso8601String(),
                },
                where: 'id = ?',
                whereArgs: [recordId],
              );
              affectedCount++;
            }
            break;
        }
      }
    }

    // 记录历史
    await db.insert('batch_edit_history', {
      'records_affected': affectedCount,
      'edit_type': editType ?? 'custom',
      'performed_at': DateTime.now().toIso8601String(),
    });

    return affectedCount;
  }

  /// 计算匹配的记录数
  Future<int> countMatchingRecords(List<EditCondition> conditions) async {
    final db = await _db;
    final whereClause = _buildWhereClause(conditions);
    final whereArgs = _buildWhereArgs(conditions);

    final result = await db.rawQuery('''
      SELECT COUNT(*) as count
      FROM episode_records r
      LEFT JOIN thing_names tn ON r.thing_name_id = tn.id
      WHERE $whereClause
    ''', whereArgs);

    return result.first['count'] as int? ?? 0;
  }

  String _buildWhereClause(List<EditCondition> conditions) {
    if (conditions.isEmpty) return '1=1';

    final clauses = <String>[];
    for (final condition in conditions) {
      switch (condition.field) {
        case 'date':
          if (condition.operator == 'between' && condition.value2 != null) {
            clauses.add("DATE(r.occurred_at) BETWEEN '${condition.value}' AND '${condition.value2}'");
          } else if (condition.operator == 'greater_than') {
            clauses.add("DATE(r.occurred_at) > '${condition.value}'");
          } else if (condition.operator == 'less_than') {
            clauses.add("DATE(r.occurred_at) < '${condition.value}'");
          } else {
            clauses.add("DATE(r.occurred_at) = '${condition.value}'");
          }
          break;

        case 'thing_name':
          if (condition.operator == 'equals') {
            clauses.add("tn.name = '${condition.value}'");
          } else if (condition.operator == 'contains') {
            clauses.add("tn.name LIKE '%${condition.value}%'");
          }
          break;

        case 'duration':
          if (condition.operator == 'greater_than') {
            clauses.add('r.duration_sec > ${condition.value * 60}');
          } else if (condition.operator == 'less_than') {
            clauses.add('r.duration_sec < ${condition.value * 60}');
          }
          break;

        case 'tag':
          if (condition.operator == 'contains') {
            clauses.add("EXISTS (SELECT 1 FROM record_tags rt WHERE rt.record_id = r.id AND rt.tag_name LIKE '%${condition.value}%')");
          }
          break;

        case 'has_reminder':
          clauses.add('r.has_reminder = ${condition.value == true ? 1 : 0}');
          break;
      }
    }

    return clauses.join(' AND ');
  }

  List<dynamic> _buildWhereArgs(List<EditCondition> conditions) {
    return [];
  }

  /// 撤销最后一次批量编辑
  Future<bool> undoLastEdit() async {
    final db = await _db;
    final history = await db.query(
      'batch_edit_history',
      orderBy: 'performed_at DESC',
      limit: 1,
    );

    if (history.isEmpty) return false;

    // 注意：撤销功能需要更复杂的实现，这里只是示例
    await db.delete(
      'batch_edit_history',
      where: 'id = ?',
      whereArgs: [history.first['id']],
    );

    return true;
  }
}