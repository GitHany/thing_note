import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Quick Actions Hub Configuration
final quickActionsConfigProvider = StateNotifierProvider<QuickActionsConfigNotifier, List<QuickActionConfig>>((ref) {
  return QuickActionsConfigNotifier();
});

class QuickActionConfig {
  final String id;
  final String title;
  final IconData icon;
  final Color color;
  final String route;
  final bool isEnabled;
  final int order;

  QuickActionConfig({
    required this.id,
    required this.title,
    required this.icon,
    required this.color,
    required this.route,
    this.isEnabled = true,
    required this.order,
  });

  QuickActionConfig copyWith({
    String? id,
    String? title,
    IconData? icon,
    Color? color,
    String? route,
    bool? isEnabled,
    int? order,
  }) {
    return QuickActionConfig(
      id: id ?? this.id,
      title: title ?? this.title,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      route: route ?? this.route,
      isEnabled: isEnabled ?? this.isEnabled,
      order: order ?? this.order,
    );
  }
}

class QuickActionsConfigNotifier extends StateNotifier<List<QuickActionConfig>> {
  QuickActionsConfigNotifier() : super([
    QuickActionConfig(id: '1', title: '新建记录', icon: Icons.add_circle, color: Colors.blue, route: '/record/new', order: 0),
    QuickActionConfig(id: '2', title: '快速拍照', icon: Icons.camera_alt, color: Colors.green, route: '/quick-photo-capture', order: 1),
    QuickActionConfig(id: '3', title: '语音记录', icon: Icons.mic, color: Colors.red, route: '/voice-recorder', order: 2),
    QuickActionConfig(id: '4', title: '快速搜索', icon: Icons.search, color: Colors.purple, route: '/search', order: 3),
    QuickActionConfig(id: '5', title: '日历视图', icon: Icons.calendar_today, color: Colors.orange, route: '/calendar', order: 4),
    QuickActionConfig(id: '6', title: '收藏夹', icon: Icons.star, color: Colors.amber, route: '/record-favorites', order: 5),
    QuickActionConfig(id: '7', title: '智能提醒', icon: Icons.notifications, color: Colors.teal, route: '/smart-reminder-v2', order: 6),
    QuickActionConfig(id: '8', title: '数据备份', icon: Icons.backup, color: Colors.indigo, route: '/enhanced-backup', order: 7),
    QuickActionConfig(id: '9', title: '统计报告', icon: Icons.bar_chart, color: Colors.pink, route: '/statistics', order: 8),
    QuickActionConfig(id: '10', title: '习惯打卡', icon: Icons.check_circle, color: Colors.cyan, route: '/habits', order: 9),
    QuickActionConfig(id: '11', title: '目标管理', icon: Icons.flag, color: Colors.lime, route: '/goals', order: 10),
    QuickActionConfig(id: '12', title: '设置', icon: Icons.settings, color: Colors.grey, route: '/settings', order: 11),
  ]);

  void reorderActions(int oldIndex, int newIndex) {
    final actions = [...state];
    final item = actions.removeAt(oldIndex);
    actions.insert(newIndex, item);
    state = actions.asMap().entries.map((e) => e.value.copyWith(order: e.key)).toList();
  }

  void toggleAction(String id) {
    state = [
      for (final action in state)
        if (action.id == id) action.copyWith(isEnabled: !action.isEnabled) else action,
    ];
  }

  void addAction(QuickActionConfig action) {
    state = [...state, action];
  }

  void removeAction(String id) {
    state = state.where((a) => a.id != id).toList();
  }
}

// Available actions for adding
final availableActionsProvider = [
  {'id': '13', 'title': '番茄钟', 'icon': Icons.timer, 'color': Colors.red, 'route': '/focus-mode'},
  {'id': '14', 'title': '每日复盘', 'icon': Icons.replay, 'color': Colors.blue, 'route': '/daily-reflection'},
  {'id': '15', 'title': '周报', 'icon': Icons.summarize, 'color': Colors.green, 'route': '/weekly-review'},
  {'id': '16', 'title': '数据分析', 'icon': Icons.analytics, 'color': Colors.orange, 'route': '/advanced-analytics'},
  {'id': '17', 'title': '标签管理', 'icon': Icons.label, 'color': Colors.purple, 'route': '/settings/tags'},
  {'id': '18', 'title': '隐私模式', 'icon': Icons.visibility_off, 'color': Colors.grey, 'route': '/privacy-mode'},
  {'id': '19', 'title': '导入数据', 'icon': Icons.upload, 'color': Colors.teal, 'route': '/importer'},
  {'id': '20', 'title': '导出数据', 'icon': Icons.download, 'color': Colors.indigo, 'route': '/data-export'},
];

class QuickActionsHubScreen extends ConsumerStatefulWidget {
  const QuickActionsHubScreen({super.key});

  @override
  ConsumerState<QuickActionsHubScreen> createState() => _QuickActionsHubScreenState();
}

class _QuickActionsHubScreenState extends ConsumerState<QuickActionsHubScreen> {
  bool _isEditMode = false;

  @override
  Widget build(BuildContext context) {
    final actions = ref.watch(quickActionsConfigProvider);
    final enabledActions = actions.where((a) => a.isEnabled).toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    return Scaffold(
      appBar: AppBar(
        title: const Text('快捷操作中心'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(_isEditMode ? Icons.check : Icons.edit),
            onPressed: () {
              setState(() {
                _isEditMode = !_isEditMode;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildQuickStats(),
          Expanded(
            child: _isEditMode
                ? _buildEditMode(actions)
                : _buildNormalMode(enabledActions),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(child: _buildStatCard('今日记录', '12', Colors.blue)),
          const SizedBox(width: 8),
          Expanded(child: _buildStatCard('本周目标', '80%', Colors.green)),
          const SizedBox(width: 8),
          Expanded(child: _buildStatCard('连续打卡', '7天', Colors.orange)),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNormalMode(List<QuickActionConfig> actions) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.9,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        return _buildActionCard(action);
      },
    );
  }

  Widget _buildActionCard(QuickActionConfig action) {
    return InkWell(
      onTap: () => context.push(action.route),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: action.color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: action.color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(action.icon, size: 32, color: action.color),
            const SizedBox(height: 8),
            Text(
              action.title,
              style: TextStyle(
                fontSize: 12,
                color: action.color,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditMode(List<QuickActionConfig> actions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            '拖动排序，长按开关启用/禁用',
            style: TextStyle(color: Theme.of(context).colorScheme.outline),
          ),
        ),
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: actions.length,
            onReorder: (oldIndex, newIndex) {
              ref.read(quickActionsConfigProvider.notifier).reorderActions(oldIndex, newIndex);
            },
            itemBuilder: (context, index) {
              final action = actions[index];
              return Card(
                key: ValueKey(action.id),
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: action.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(action.icon, color: action.color),
                  ),
                  title: Text(action.title),
                  subtitle: Text(action.route),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value: action.isEnabled,
                        onChanged: (value) {
                          ref.read(quickActionsConfigProvider.notifier).toggleAction(action.id);
                        },
                      ),
                      const Icon(Icons.drag_handle),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showAddActionDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('添加快捷方式'),
            ),
          ),
        ),
      ],
    );
  }

  void _showAddActionDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '添加快捷方式',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: availableActionsProvider.length,
                itemBuilder: (context, index) {
                  final action = availableActionsProvider[index];
                  return ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (action['color'] as Color).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(action['icon'] as IconData, color: action['color'] as Color),
                    ),
                    title: Text(action['title'] as String),
                    trailing: IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: () {
                        ref.read(quickActionsConfigProvider.notifier).addAction(
                          QuickActionConfig(
                            id: action['id'] as String,
                            title: action['title'] as String,
                            icon: action['icon'] as IconData,
                            color: action['color'] as Color,
                            route: action['route'] as String,
                            order: ref.read(quickActionsConfigProvider).length,
                          ),
                        );
                        Navigator.pop(context);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
