/// Workflow automation rule
class WorkflowRule {
  final int? id;
  final String name;
  final String description;
  final WorkflowTrigger trigger;
  final List<WorkflowAction> actions;
  final bool isEnabled;
  final DateTime? lastTriggered;
  final DateTime createdAt;

  WorkflowRule({
    this.id,
    required this.name,
    this.description = '',
    required this.trigger,
    required this.actions,
    this.isEnabled = true,
    this.lastTriggered,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'trigger': trigger.toMap(),
      'actions': actions.map((a) => a.toMap()).toList(),
      'is_enabled': isEnabled ? 1 : 0,
      'last_triggered': lastTriggered?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}

/// Workflow trigger types
enum WorkflowTriggerType {
  time,
  recordCreated,
  recordUpdated,
  tagAdded,
  locationChange,
  manual,
}

/// Workflow trigger
class WorkflowTrigger {
  final WorkflowTriggerType type;
  final Map<String, dynamic>? parameters;

  WorkflowTrigger({
    required this.type,
    this.parameters,
  });

  String get name {
    switch (type) {
      case WorkflowTriggerType.time:
        return 'Time-based';
      case WorkflowTriggerType.recordCreated:
        return 'Record Created';
      case WorkflowTriggerType.recordUpdated:
        return 'Record Updated';
      case WorkflowTriggerType.tagAdded:
        return 'Tag Added';
      case WorkflowTriggerType.locationChange:
        return 'Location Changed';
      case WorkflowTriggerType.manual:
        return 'Manual';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'parameters': parameters,
    };
  }
}

/// Workflow action types
enum WorkflowActionType {
  setReminder,
  addTag,
  setPriority,
  sendNotification,
  moveToProject,
  updateStatus,
}

/// Workflow action
class WorkflowAction {
  final WorkflowActionType type;
  final Map<String, dynamic>? parameters;

  WorkflowAction({
    required this.type,
    this.parameters,
  });

  String get name {
    switch (type) {
      case WorkflowActionType.setReminder:
        return 'Set Reminder';
      case WorkflowActionType.addTag:
        return 'Add Tag';
      case WorkflowActionType.setPriority:
        return 'Set Priority';
      case WorkflowActionType.sendNotification:
        return 'Send Notification';
      case WorkflowActionType.moveToProject:
        return 'Move to Project';
      case WorkflowActionType.updateStatus:
        return 'Update Status';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'parameters': parameters,
    };
  }
}