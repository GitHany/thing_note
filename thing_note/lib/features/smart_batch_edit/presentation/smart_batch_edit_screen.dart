import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/smart_batch_edit/data/batch_edit_service.dart';
import 'package:thing_note/features/smart_batch_edit/domain/batch_edit_models.dart';

class SmartBatchEditScreen extends ConsumerStatefulWidget {
  const SmartBatchEditScreen({super.key});

  @override
  ConsumerState<SmartBatchEditScreen> createState() => _SmartBatchEditScreenState();
}

class _SmartBatchEditScreenState extends ConsumerState<SmartBatchEditScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<EditCondition> _conditions = [];
  List<EditAction> _actions = [];
  List<Map<String, dynamic>>? _previewResults;
  int? _matchingCount;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('智能批量编辑'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => _showHistoryDialog(context),
            tooltip: '编辑历史',
          ),
          IconButton(
            icon: const Icon(Icons.rule),
            onPressed: () => _showRulesDialog(context),
            tooltip: '管理规则',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '条件'),
            Tab(text: '动作'),
            Tab(text: '预览'),
          ],
        ),
      ),
      body: Column(
        children: [
          // 条件/动作数量显示
          Container(
            padding: const EdgeInsets.all(12),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _InfoChip(
                  icon: Icons.filter_list,
                  label: '条件',
                  count: _conditions.length,
                  onTap: () => _tabController.animateTo(0),
                ),
                _InfoChip(
                  icon: Icons.flash_on,
                  label: '动作',
                  count: _actions.length,
                  onTap: () => _tabController.animateTo(1),
                ),
                _InfoChip(
                  icon: Icons.find_in_page,
                  label: '匹配',
                  count: _matchingCount ?? 0,
                  onTap: () => _tabController.animateTo(2),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _ConditionsTab(onConditionsChanged: (conditions) {
                  setState(() => _conditions = conditions);
                  _updatePreview();
                }),
                _ActionsTab(onActionsChanged: (actions) {
                  setState(() => _actions = actions);
                }),
                _PreviewTab(results: _previewResults ?? [], matchingCount: _matchingCount ?? 0),
              ],
            ),
          ),
          // 底部操作按钮
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity( 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _conditions.isEmpty ? null : () => _executePreview(),
                      child: const Text('预览'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: (_conditions.isEmpty || _actions.isEmpty || _matchingCount == null || _matchingCount == 0)
                          ? null
                          : () => _executeEdit(context),
                      child: const Text('执行'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _updatePreview() async {
    if (_conditions.isEmpty) {
      setState(() {
        _previewResults = null;
        _matchingCount = null;
      });
      return;
    }

    final service = ref.read(smartBatchEditServiceProvider);
    final count = await service.countMatchingRecords(_conditions);
    setState(() {
      _matchingCount = count;
    });
  }

  Future<void> _executePreview() async {
    if (_conditions.isEmpty) return;

    final service = ref.read(smartBatchEditServiceProvider);
    final results = await service.previewEdit(
      conditions: _conditions,
      actions: _actions.isEmpty ? [EditAction(type: 'none', value: null)] : _actions,
    );

    setState(() {
      _previewResults = results;
    });

    _tabController.animateTo(2);
  }

  void _executeEdit(BuildContext context) async {
    if (_conditions.isEmpty || _actions.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认执行'),
        content: Text('即将修改 $_matchingCount 条记录，是否继续？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确认'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final service = ref.read(smartBatchEditServiceProvider);
      final count = await service.executeEdit(
        conditions: _conditions,
        actions: _actions,
        editType: 'manual',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已修改 $count 条记录')),
        );

        setState(() {
          _conditions.clear();
          _actions.clear();
          _previewResults = null;
          _matchingCount = null;
        });
      }
    }
  }

  void _showHistoryDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => _HistorySheet(scrollController: scrollController),
      ),
    );
  }

  void _showRulesDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => _RulesSheet(scrollController: scrollController),
      ),
    );
  }
}

/// 条件标签页
class _ConditionsTab extends StatefulWidget {
  final Function(List<EditCondition>) onConditionsChanged;

  const _ConditionsTab({required this.onConditionsChanged});

  @override
  State<_ConditionsTab> createState() => _ConditionsTabState();
}

class _ConditionsTabState extends State<_ConditionsTab> {
  final List<EditCondition> _conditions = [];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: _conditions.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.filter_list, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('暂无筛选条件'),
                      SizedBox(height: 8),
                      Text(
                        '添加条件来筛选要编辑的记录',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _conditions.length,
                  itemBuilder: (context, index) {
                    final condition = _conditions[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Icon(_getFieldIcon(condition.field)),
                        title: Text(_getFieldLabel(condition.field)),
                        subtitle: Text('${_getOperatorLabel(condition.operator)} ${condition.value}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () {
                            setState(() {
                              _conditions.removeAt(index);
                            });
                            widget.onConditionsChanged(_conditions);
                          },
                        ),
                      ),
                    );
                  },
                ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _AddConditionChip(
                label: '时间',
                icon: Icons.calendar_today,
                onTap: () => _showAddConditionDialog('date'),
              ),
              _AddConditionChip(
                label: '事情类型',
                icon: Icons.category,
                onTap: () => _showAddConditionDialog('thing_name'),
              ),
              _AddConditionChip(
                label: '时长',
                icon: Icons.timer,
                onTap: () => _showAddConditionDialog('duration'),
              ),
              _AddConditionChip(
                label: '标签',
                icon: Icons.label,
                onTap: () => _showAddConditionDialog('tag'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showAddConditionDialog(String field) {
    showDialog(
      context: context,
      builder: (context) => _AddConditionDialog(
        field: field,
        onAdd: (condition) {
          setState(() {
            _conditions.add(condition);
          });
          widget.onConditionsChanged(_conditions);
        },
      ),
    );
  }

  IconData _getFieldIcon(String field) {
    switch (field) {
      case 'date':
        return Icons.calendar_today;
      case 'thing_name':
        return Icons.category;
      case 'duration':
        return Icons.timer;
      case 'tag':
        return Icons.label;
      case 'has_reminder':
        return Icons.notifications;
      default:
        return Icons.filter;
    }
  }

  String _getFieldLabel(String field) {
    switch (field) {
      case 'date':
        return '日期';
      case 'thing_name':
        return '事情类型';
      case 'duration':
        return '时长';
      case 'tag':
        return '标签';
      case 'has_reminder':
        return '有提醒';
      default:
        return field;
    }
  }

  String _getOperatorLabel(String operator) {
    switch (operator) {
      case 'equals':
        return '等于';
      case 'contains':
        return '包含';
      case 'greater_than':
        return '大于';
      case 'less_than':
        return '小于';
      case 'between':
        return '介于';
      default:
        return operator;
    }
  }
}

/// 动作标签页
class _ActionsTab extends StatefulWidget {
  final Function(List<EditAction>) onActionsChanged;

  const _ActionsTab({required this.onActionsChanged});

  @override
  State<_ActionsTab> createState() => _ActionsTabState();
}

class _ActionsTabState extends State<_ActionsTab> {
  final List<EditAction> _actions = [];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: _actions.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.flash_on, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('暂无编辑动作'),
                      SizedBox(height: 8),
                      Text(
                        '添加动作来批量修改记录',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _actions.length,
                  itemBuilder: (context, index) {
                    final action = _actions[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Icon(_getActionIcon(action.type)),
                        title: Text(_getActionLabel(action.type)),
                        subtitle: Text('${action.value}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () {
                            setState(() {
                              _actions.removeAt(index);
                            });
                            widget.onActionsChanged(_actions);
                          },
                        ),
                      ),
                    );
                  },
                ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _AddConditionChip(
                label: '设置类型',
                icon: Icons.category,
                onTap: () => _showAddActionDialog('set_thing_name'),
              ),
              _AddConditionChip(
                label: '添加标签',
                icon: Icons.label,
                onTap: () => _showAddActionDialog('add_tag'),
              ),
              _AddConditionChip(
                label: '移除标签',
                icon: Icons.label_off,
                onTap: () => _showAddActionDialog('remove_tag'),
              ),
              _AddConditionChip(
                label: '设置提醒',
                icon: Icons.notifications,
                onTap: () => _showAddActionDialog('set_reminder'),
              ),
              _AddConditionChip(
                label: '调整时间',
                icon: Icons.schedule,
                onTap: () => _showAddActionDialog('adjust_time'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showAddActionDialog(String type) {
    showDialog(
      context: context,
      builder: (context) => _AddActionDialog(
        type: type,
        onAdd: (action) {
          setState(() {
            _actions.add(action);
          });
          widget.onActionsChanged(_actions);
        },
      ),
    );
  }

  IconData _getActionIcon(String type) {
    switch (type) {
      case 'set_thing_name':
        return Icons.category;
      case 'add_tag':
        return Icons.label;
      case 'remove_tag':
        return Icons.label_off;
      case 'set_reminder':
        return Icons.notifications;
      case 'adjust_time':
        return Icons.schedule;
      default:
        return Icons.flash_on;
    }
  }

  String _getActionLabel(String type) {
    switch (type) {
      case 'set_thing_name':
        return '设置事情类型';
      case 'add_tag':
        return '添加标签';
      case 'remove_tag':
        return '移除标签';
      case 'set_reminder':
        return '设置提醒';
      case 'adjust_time':
        return '调整时间';
      default:
        return type;
    }
  }
}

/// 预览标签页
class _PreviewTab extends StatelessWidget {
  final List<Map<String, dynamic>> results;
  final int matchingCount;

  const _PreviewTab({required this.results, required this.matchingCount});

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.preview, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('暂无预览数据'),
            SizedBox(height: 8),
            Text(
              '设置条件和动作后点击"预览"查看结果',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.blue.withOpacity( 0.1),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.blue),
              const SizedBox(width: 8),
              Text('将修改 $matchingCount 条记录'),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: results.length,
            itemBuilder: (context, index) {
              final record = results[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.withOpacity( 0.1),
                    child: Text('${index + 1}'),
                  ),
                  title: Text(record['note'] as String? ?? '无内容'),
                  subtitle: Text(
                    '${record['thing_name'] ?? '默认'} • ${record['occurred_at']}',
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// 添加条件对话框
class _AddConditionDialog extends StatefulWidget {
  final String field;
  final Function(EditCondition) onAdd;

  const _AddConditionDialog({required this.field, required this.onAdd});

  @override
  State<_AddConditionDialog> createState() => _AddConditionDialogState();
}

class _AddConditionDialogState extends State<_AddConditionDialog> {
  String _operator = 'equals';
  final _valueController = TextEditingController();
  final _value2Controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('添加${_getFieldLabel(widget.field)}条件'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            value: _operator,
            decoration: const InputDecoration(labelText: '条件'),
            items: _getOperatorItems(widget.field),
            onChanged: (value) => setState(() => _operator = value!),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _valueController,
            decoration: InputDecoration(
              labelText: widget.field == 'date' ? '日期 (YYYY-MM-DD)' : '值',
            ),
          ),
          if (_operator == 'between') ...[
            const SizedBox(height: 16),
            TextField(
              controller: _value2Controller,
              decoration: const InputDecoration(
                labelText: '结束日期 (YYYY-MM-DD)',
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () {
            widget.onAdd(EditCondition(
              field: widget.field,
              operator: _operator,
              value: _valueController.text,
              value2: _operator == 'between' ? _value2Controller.text : null,
            ));
            Navigator.pop(context);
          },
          child: const Text('添加'),
        ),
      ],
    );
  }

  String _getFieldLabel(String field) {
    switch (field) {
      case 'date':
        return '日期';
      case 'thing_name':
        return '事情类型';
      case 'duration':
        return '时长';
      case 'tag':
        return '标签';
      default:
        return field;
    }
  }

  List<DropdownMenuItem<String>> _getOperatorItems(String field) {
    final operators = <DropdownMenuItem<String>>[
      const DropdownMenuItem(value: 'equals', child: Text('等于')),
      const DropdownMenuItem(value: 'contains', child: Text('包含')),
    ];

    if (field == 'date' || field == 'duration') {
      operators.add(const DropdownMenuItem(value: 'greater_than', child: Text('大于')));
      operators.add(const DropdownMenuItem(value: 'less_than', child: Text('小于')));
    }

    if (field == 'date') {
      operators.add(const DropdownMenuItem(value: 'between', child: Text('介于')));
    }

    return operators;
  }
}

/// 添加动作对话框
class _AddActionDialog extends StatefulWidget {
  final String type;
  final Function(EditAction) onAdd;

  const _AddActionDialog({required this.type, required this.onAdd});

  @override
  State<_AddActionDialog> createState() => _AddActionDialogState();
}

class _AddActionDialogState extends State<_AddActionDialog> {
  final _valueController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_getActionLabel(widget.type)),
      content: TextField(
        controller: _valueController,
        decoration: InputDecoration(
          labelText: _getValueLabel(widget.type),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () {
            widget.onAdd(EditAction(
              type: widget.type,
              value: _valueController.text,
            ));
            Navigator.pop(context);
          },
          child: const Text('添加'),
        ),
      ],
    );
  }

  String _getActionLabel(String type) {
    switch (type) {
      case 'set_thing_name':
        return '设置事情类型';
      case 'add_tag':
        return '添加标签';
      case 'remove_tag':
        return '移除标签';
      case 'set_reminder':
        return '设置提醒';
      case 'adjust_time':
        return '调整时间';
      default:
        return type;
    }
  }

  String _getValueLabel(String type) {
    switch (type) {
      case 'set_thing_name':
        return '事情类型名称';
      case 'add_tag':
        return '标签名称';
      case 'remove_tag':
        return '标签名称';
      case 'set_reminder':
        return '提醒时间 (YYYY-MM-DD HH:mm)';
      case 'adjust_time':
        return '调整分钟数 (正数提前，负数延后)';
      default:
        return '值';
    }
  }
}

/// 历史记录底部面板
class _HistorySheet extends ConsumerWidget {
  final ScrollController scrollController;

  const _HistorySheet({required this.scrollController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(batchEditHistoryProvider);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Text(
                '编辑历史',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: historyAsync.when(
            data: (history) => history.isEmpty
                ? const Center(child: Text('暂无编辑历史'))
                : ListView.builder(
                    controller: scrollController,
                    itemCount: history.length,
                    itemBuilder: (context, index) {
                      final item = history[index];
                      return ListTile(
                        leading: const Icon(Icons.edit),
                        title: Text('修改了 ${item.recordsAffected} 条记录'),
                        subtitle: Text(item.editType),
                        trailing: Text(
                          _formatDate(item.performedAt),
                          style: const TextStyle(color: Colors.grey),
                        ),
                      );
                    },
                  ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('加载失败: $e')),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day} ${date.hour}:${date.minute}';
  }
}

/// 规则管理底部面板
class _RulesSheet extends ConsumerWidget {
  final ScrollController scrollController;

  const _RulesSheet({required this.scrollController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rulesAsync = ref.watch(batchEditRulesProvider);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Text(
                '管理规则',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => _showAddRuleDialog(context, ref),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: rulesAsync.when(
            data: (rules) => rules.isEmpty
                ? const Center(child: Text('暂无规则'))
                : ListView.builder(
                    controller: scrollController,
                    itemCount: rules.length,
                    itemBuilder: (context, index) {
                      final rule = rules[index];
                      return ListTile(
                        leading: Icon(
                          rule.isEnabled ? Icons.check_circle : Icons.pause_circle,
                          color: rule.isEnabled ? Colors.green : Colors.grey,
                        ),
                        title: Text(rule.name),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.toggle_on),
                              onPressed: () async {
                                final service = ref.read(smartBatchEditServiceProvider);
                                await service.toggleRule(rule.id!, !rule.isEnabled);
                                ref.invalidate(batchEditRulesProvider);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () async {
                                final service = ref.read(smartBatchEditServiceProvider);
                                await service.deleteRule(rule.id!);
                                ref.invalidate(batchEditRulesProvider);
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('加载失败: $e')),
          ),
        ),
      ],
    );
  }

  void _showAddRuleDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final service = ref.read(smartBatchEditServiceProvider);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('添加规则'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: '规则名称',
            hintText: '例如：自动标记工作',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                await service.addRule(BatchEditRule(
                  name: nameController.text,
                  conditions: '',
                  actions: '',
                ));
                ref.invalidate(batchEditRulesProvider);
                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }
}

/// 信息芯片
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final VoidCallback onTap;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity( 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: Colors.blue),
            const SizedBox(width: 4),
            Text('$label: '),
            Text(
              '$count',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

/// 添加条件按钮芯片
class _AddConditionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _AddConditionChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text('+$label'),
      onPressed: onTap,
    );
  }
}