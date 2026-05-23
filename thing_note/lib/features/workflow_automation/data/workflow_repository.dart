import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/features/workflow_automation/domain/workflow_rule.dart';

class WorkflowRepository {
  final Database db;

  WorkflowRepository(this.db);

  Future<int> insert(WorkflowRule rule) async {
    final map = {
      'name': rule.name,
      'description': rule.description,
      'trigger': jsonEncode(rule.trigger.toMap()),
      'actions': jsonEncode(rule.actions.map((a) => a.toMap()).toList()),
      'is_enabled': rule.isEnabled ? 1 : 0,
      'last_triggered': rule.lastTriggered?.toIso8601String(),
      'created_at': rule.createdAt.toIso8601String(),
    };
    return db.insert('workflow_rules', map);
  }

  Future<void> update(WorkflowRule rule) async {
    if (rule.id == null) return;
    await db.update(
      'workflow_rules',
      {
        'name': rule.name,
        'description': rule.description,
        'trigger': jsonEncode(rule.trigger.toMap()),
        'actions': jsonEncode(rule.actions.map((a) => a.toMap()).toList()),
        'is_enabled': rule.isEnabled ? 1 : 0,
        'last_triggered': rule.lastTriggered?.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [rule.id],
    );
  }

  Future<void> delete(int id) async {
    await db.delete('workflow_rules', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<WorkflowRule>> getAll() async {
    final List<Map<String, dynamic>> maps = await db.query(
      'workflow_rules',
      orderBy: 'created_at DESC',
    );
    return maps.map(_mapToRule).toList();
  }

  Future<List<WorkflowRule>> getEnabled() async {
    final List<Map<String, dynamic>> maps = await db.query(
      'workflow_rules',
      where: 'is_enabled = ?',
      whereArgs: [1],
    );
    return maps.map(_mapToRule).toList();
  }

  WorkflowRule _mapToRule(Map<String, dynamic> map) {
    final triggerMap = jsonDecode(map['trigger'] as String);
    final actionsList = jsonDecode(map['actions'] as String) as List;

    return WorkflowRule(
      id: map['id'] as int?,
      name: map['name'] as String,
      description: map['description'] as String? ?? '',
      trigger: WorkflowTrigger(
        type: WorkflowTriggerType.values.firstWhere(
          (t) => t.name == triggerMap['type'],
          orElse: () => WorkflowTriggerType.manual,
        ),
        parameters: triggerMap['parameters'] as Map<String, dynamic>?,
      ),
      actions: actionsList.map((a) {
        return WorkflowAction(
          type: WorkflowActionType.values.firstWhere(
            (t) => t.name == a['type'],
            orElse: () => WorkflowActionType.sendNotification,
          ),
          parameters: a['parameters'] as Map<String, dynamic>?,
        );
      }).toList(),
      isEnabled: (map['is_enabled'] as int) == 1,
      lastTriggered: map['last_triggered'] != null
          ? DateTime.parse(map['last_triggered'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

class WorkflowService {
  /// Execute a workflow rule
  Future<void> execute(WorkflowRule rule, Map<String, dynamic> context) async {
    // In production, this would execute each action
    // For now, just log the execution
    debugPrint('Executing workflow: ${rule.name}');
    for (final action in rule.actions) {
      debugPrint('  Action: ${action.name}');
    }
  }

  /// Check if trigger conditions are met
  Future<bool> checkTrigger(WorkflowTrigger trigger, Map<String, dynamic> context) async {
    switch (trigger.type) {
      case WorkflowTriggerType.recordCreated:
        return context.containsKey('new_record');
      case WorkflowTriggerType.recordUpdated:
        return context.containsKey('updated_record');
      case WorkflowTriggerType.tagAdded:
        return context.containsKey('tag');
      case WorkflowTriggerType.manual:
        return true;
      default:
        return false;
    }
  }
}