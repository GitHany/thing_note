import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/workflow_automation/domain/workflow_rule.dart';

class WorkflowAutomationScreen extends ConsumerStatefulWidget {
  const WorkflowAutomationScreen({super.key});

  @override
  ConsumerState<WorkflowAutomationScreen> createState() =>
      _WorkflowAutomationScreenState();
}

class _WorkflowAutomationScreenState
    extends ConsumerState<WorkflowAutomationScreen> {
  final List<WorkflowRule> _rules = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadRules();
  }

  Future<void> _loadRules() async {
    setState(() => _isLoading = true);
    // In production, load from repository
    setState(() => _isLoading = false);
  }

  Future<void> _createRule() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => _CreateRuleDialog(),
    );

    if (result == true) {
      _loadRules();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workflow Automation'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _createRule,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _rules.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.auto_fix_high, size: 64),
                      const SizedBox(height: 16),
                      const Text('No workflows yet'),
                      const SizedBox(height: 8),
                      FilledButton.icon(
                        onPressed: _createRule,
                        icon: const Icon(Icons.add),
                        label: const Text('Create Workflow'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _rules.length,
                  itemBuilder: (context, index) {
                    final rule = _rules[index];
                    return Card(
                      child: ListTile(
                        leading: Switch(
                          value: rule.isEnabled,
                          onChanged: (value) {
                            // Toggle rule
                          },
                        ),
                        title: Text(rule.name),
                        subtitle: Text(rule.trigger.name),
                        trailing: IconButton(
                          icon: const Icon(Icons.more_vert),
                          onPressed: () {
                            // Show options
                          },
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

class _CreateRuleDialog extends StatefulWidget {
  @override
  State<_CreateRuleDialog> createState() => _CreateRuleDialogState();
}

class _CreateRuleDialogState extends State<_CreateRuleDialog> {
  final _nameController = TextEditingController();
  WorkflowTriggerType _triggerType = WorkflowTriggerType.recordCreated;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Workflow'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Workflow Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<WorkflowTriggerType>(
              value: _triggerType,
              decoration: const InputDecoration(
                labelText: 'Trigger',
                border: OutlineInputBorder(),
              ),
              items: WorkflowTriggerType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(_getTriggerName(type)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _triggerType = value!);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (_nameController.text.isEmpty) return;
            Navigator.pop(context, true);
          },
          child: const Text('Create'),
        ),
      ],
    );
  }

  String _getTriggerName(WorkflowTriggerType type) {
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
        return 'Location Change';
      case WorkflowTriggerType.manual:
        return 'Manual';
    }
  }
}