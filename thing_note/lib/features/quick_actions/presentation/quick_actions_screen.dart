import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class QuickActionsScreen extends ConsumerStatefulWidget {
  const QuickActionsScreen({super.key});

  @override
  ConsumerState<QuickActionsScreen> createState() => _QuickActionsScreenState();
}

class _QuickActionsScreenState extends ConsumerState<QuickActionsScreen> {
  final List<Map<String, dynamic>> _actions = [
    {'type': 'record', 'name': '新建记录', 'icon': Icons.add_circle, 'color': Colors.blue, 'enabled': true},
    {'type': 'search', 'name': '快速搜索', 'icon': Icons.search, 'color': Colors.green, 'enabled': true},
    {'type': 'calendar', 'name': '日历视图', 'icon': Icons.calendar_today, 'color': Colors.orange, 'enabled': true},
    {'type': 'stats', 'name': '统计数据', 'icon': Icons.bar_chart, 'color': Colors.purple, 'enabled': false},
    {'type': 'reminder', 'name': '提醒管理', 'icon': Icons.notifications, 'color': Colors.red, 'enabled': true},
    {'type': 'backup', 'name': '数据备份', 'icon': Icons.backup, 'color': Colors.teal, 'enabled': true},
    {'type': 'export', 'name': '数据导出', 'icon': Icons.download, 'color': Colors.indigo, 'enabled': false},
    {'type': 'settings', 'name': '设置', 'icon': Icons.settings, 'color': Colors.grey, 'enabled': true},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('快捷操作面板'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _enterEditMode(),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildQuickStats(),
          Expanded(
            child: _buildActionsGrid(),
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

  Widget _buildActionsGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.9,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _actions.length,
      itemBuilder: (context, index) {
        final action = _actions[index];
        return _buildActionItem(action);
      },
    );
  }

  Widget _buildActionItem(Map<String, dynamic> action) {
    final color = action['color'] as Color;
    final isEnabled = action['enabled'] as bool;

    return GestureDetector(
      onTap: isEnabled ? () => _executeAction(action) : null,
      child: Card(
        color: isEnabled
            ? color.withOpacity(0.1)
            : Colors.grey.withOpacity(0.1),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              action['icon'] as IconData,
              size: 32,
              color: isEnabled ? color : Colors.grey,
            ),
            const SizedBox(height: 8),
            Text(
              action['name'] as String,
              style: TextStyle(
                fontSize: 12,
                color: isEnabled ? color : Colors.grey,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _executeAction(Map<String, dynamic> action) {
    final type = action['type'] as String;
    switch (type) {
      case 'record':
        context.go('/record/new');
        break;
      case 'search':
        context.go('/search');
        break;
      case 'calendar':
        context.go('/calendar');
        break;
      case 'stats':
        context.go('/statistics');
        break;
      case 'reminder':
        context.go('/smart-reminder-v2');
        break;
      case 'backup':
        context.go('/incremental-backup');
        break;
      case 'export':
        context.go('/data-export-hub');
        break;
      case 'settings':
        context.go('/settings');
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('执行: ${action['name']}')),
        );
    }
  }

  void _enterEditMode() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '编辑快捷操作',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text('拖动排序，长按编辑'),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: ReorderableListView.builder(
                itemCount: _actions.length,
                itemBuilder: (context, index) {
                  final action = _actions[index];
                  return ListTile(
                    key: ValueKey(action['type']),
                    leading: Icon(action['icon'] as IconData),
                    title: Text(action['name'] as String),
                    trailing: const Icon(Icons.drag_handle),
                  );
                },
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) newIndex--;
                    final item = _actions.removeAt(oldIndex);
                    _actions.insert(newIndex, item);
                  });
                },
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('完成'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}