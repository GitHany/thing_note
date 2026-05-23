import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/l10n/generated/app_localizations.dart';

class AutomationRulesScreen extends ConsumerStatefulWidget {
  const AutomationRulesScreen({super.key});

  @override
  ConsumerState<AutomationRulesScreen> createState() =>
      _AutomationRulesScreenState();
}

class _AutomationRulesScreenState
    extends ConsumerState<AutomationRulesScreen> {
  final List<_AutomationRule> _rules = [
    _AutomationRule(
      id: 1,
      name: '每日提醒',
      description: '每天早上 9:00 提醒记录',
      isEnabled: true,
      trigger: _Trigger(
        type: _TriggerType.schedule,
        config: {'time': '09:00', 'repeat': 'daily'},
      ),
      actions: [
        _Action(type: _ActionType.notification, config: {'message': '该记录今天的活动了'}),
      ],
    ),
    _AutomationRule(
      id: 2,
      name: '周报生成',
      description: '每周一早上生成周报',
      isEnabled: true,
      trigger: _Trigger(
        type: _TriggerType.schedule,
        config: {'time': '08:00', 'repeat': 'weekly', 'day': 'monday'},
      ),
      actions: [
        _Action(type: _ActionType.generateReport, config: {'type': 'weekly'}),
      ],
    ),
    _AutomationRule(
      id: 3,
      name: '位置提醒',
      description: '到达公司时开启专注模式',
      isEnabled: false,
      trigger: _Trigger(
        type: _TriggerType.location,
        config: {'location': '公司', 'event': 'enter'},
      ),
      actions: [
        _Action(type: _ActionType.startFocusMode, config: {'duration': 60}),
      ],
    ),
    _AutomationRule(
      id: 4,
      name: '数据备份',
      description: '每晚 23:00 自动备份',
      isEnabled: true,
      trigger: _Trigger(
        type: _TriggerType.schedule,
        config: {'time': '23:00', 'repeat': 'daily'},
      ),
      actions: [
        _Action(type: _ActionType.backup, config: {}),
      ],
    ),
    _AutomationRule(
      id: 5,
      name: '语音记录',
      description: '识别到"记录"关键词时启动录音',
      isEnabled: false,
      trigger: _Trigger(
        type: _TriggerType.voice,
        config: {'keyword': '记录'},
      ),
      actions: [
        _Action(type: _ActionType.startRecording, config: {}),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 600;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.automationRules),
        actions: [
          IconButton(
            icon: const Icon(Icons.play_circle_outline),
            onPressed: () => _runAllRules(),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(isWideScreen ? 24 : 16),
        children: [
          // Quick stats
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatItem(
                    icon: Icons.check_circle,
                    value: '${_rules.where((r) => r.isEnabled).length}',
                    label: '已启用',
                    color: Colors.green,
                  ),
                  _StatItem(
                    icon: Icons.pause_circle,
                    value: '${_rules.where((r) => !r.isEnabled).length}',
                    label: '已暂停',
                    color: Colors.grey,
                  ),
                  const _StatItem(
                    icon: Icons.history,
                    value: '128',
                    label: '执行次数',
                    color: Colors.blue,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Rules list
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.myRules,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              FilledButton.icon(
                onPressed: () => _showCreateRuleDialog(),
                icon: const Icon(Icons.add),
                label: const Text('创建'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...(_rules.map((rule) => _buildRuleCard(rule))),
          const SizedBox(height: 24),

          // Templates
          Text(
            AppLocalizations.of(context)!.ruleTemplates,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          _buildTemplateCard(
            icon: Icons.schedule,
            title: '定时任务',
            description: '按固定时间执行操作',
          ),
          _buildTemplateCard(
            icon: Icons.location_on,
            title: '位置触发',
            description: '进入或离开某地时触发',
          ),
          _buildTemplateCard(
            icon: Icons.record_voice_over,
            title: '语音触发',
            description: '识别到关键词时执行',
          ),
          _buildTemplateCard(
            icon: Icons.flash_on,
            title: '快捷指令',
            description: '快速执行的自动化操作',
          ),
        ],
      ),
    );
  }

  Widget _buildRuleCard(_AutomationRule rule) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _editRule(rule),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: rule.isEnabled
                          ? Colors.green.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getTriggerIcon(rule.trigger.type),
                      color: rule.isEnabled ? Colors.green : Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rule.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          rule.description,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: rule.isEnabled,
                    onChanged: (value) {
                      setState(() => rule.isEnabled = value);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.arrow_forward, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '触发: ${_getTriggerDescription(rule.trigger)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.arrow_forward, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '操作: ${_getActionDescription(rule.actions.first)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _runRule(rule),
                    icon: const Icon(Icons.play_arrow, size: 18),
                    label: const Text('执行'),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () => _editRule(rule),
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('编辑'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTemplateCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(icon),
        ),
        title: Text(title),
        subtitle: Text(description),
        trailing: const Icon(Icons.add),
        onTap: () => _showCreateRuleDialog(),
      ),
    );
  }

  IconData _getTriggerIcon(_TriggerType type) {
    switch (type) {
      case _TriggerType.schedule:
        return Icons.schedule;
      case _TriggerType.location:
        return Icons.location_on;
      case _TriggerType.voice:
        return Icons.mic;
      case _TriggerType.event:
        return Icons.event;
    }
  }

  String _getTriggerDescription(_Trigger trigger) {
    switch (trigger.type) {
      case _TriggerType.schedule:
        return '定时 ${trigger.config['time']}';
      case _TriggerType.location:
        return '位置 ${trigger.config['location']}';
      case _TriggerType.voice:
        return '语音 "${trigger.config['keyword']}"';
      case _TriggerType.event:
        return '事件触发';
    }
  }

  String _getActionDescription(_Action action) {
    switch (action.type) {
      case _ActionType.notification:
        return '发送通知';
      case _ActionType.backup:
        return '数据备份';
      case _ActionType.generateReport:
        return '生成报告';
      case _ActionType.startFocusMode:
        return '开启专注模式';
      case _ActionType.startRecording:
        return '开始录音';
    }
  }

  void _showCreateRuleDialog() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '创建自动化规则',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.schedule),
              title: const Text('定时触发'),
              subtitle: const Text('按固定时间执行'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.pop(ctx),
            ),
            ListTile(
              leading: const Icon(Icons.location_on),
              title: const Text('位置触发'),
              subtitle: const Text('到达或离开某地时'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.pop(ctx),
            ),
            ListTile(
              leading: const Icon(Icons.record_voice_over),
              title: const Text('语音触发'),
              subtitle: const Text('识别关键词时'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.pop(ctx),
            ),
            ListTile(
              leading: const Icon(Icons.flash_on),
              title: const Text('快捷指令'),
              subtitle: const Text('一键执行操作'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  void _editRule(_AutomationRule rule) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('编辑规则: ${rule.name}')),
    );
  }

  void _runRule(_AutomationRule rule) {
    setState(() {
      rule.isEnabled = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('正在执行: ${rule.name}')),
    );
  }

  void _runAllRules() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('正在执行所有启用的规则...')),
    );
  }
}

enum _TriggerType { schedule, location, voice, event }

enum _ActionType { notification, backup, generateReport, startFocusMode, startRecording }

class _AutomationRule {
  final int id;
  final String name;
  final String description;
  bool isEnabled;
  final _Trigger trigger;
  final List<_Action> actions;

  _AutomationRule({
    required this.id,
    required this.name,
    required this.description,
    required this.isEnabled,
    required this.trigger,
    required this.actions,
  });
}

class _Trigger {
  final _TriggerType type;
  final Map<String, String> config;

  _Trigger({required this.type, required this.config});
}

class _Action {
  final _ActionType type;
  final Map<String, dynamic> config;

  _Action({required this.type, required this.config});
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}