import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/custom_dashboard/domain/dashboard_widget.dart';

class CustomDashboardScreen extends ConsumerStatefulWidget {
  const CustomDashboardScreen({super.key});

  @override
  ConsumerState<CustomDashboardScreen> createState() => _CustomDashboardScreenState();
}

class _CustomDashboardScreenState extends ConsumerState<CustomDashboardScreen> {
  List<DashboardWidget> _widgets = [];
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _loadDefaultWidgets();
  }

  void _loadDefaultWidgets() {
    _widgets = [
      const DashboardWidget(id: 1, type: WidgetType.stats, title: '今日统计', position: 0),
      const DashboardWidget(id: 2, type: WidgetType.habit, title: '习惯打卡', position: 1),
      const DashboardWidget(id: 3, type: WidgetType.quickAction, title: '快捷操作', position: 2),
      const DashboardWidget(id: 4, type: WidgetType.todo, title: '待办事项', position: 3),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('自定义仪表盘'),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.check : Icons.edit),
            onPressed: () => setState(() => _isEditing = !_isEditing),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddWidgetDialog(context),
          ),
        ],
      ),
      body: _isEditing ? _buildEditMode() : _buildViewMode(),
    );
  }

  Widget _buildEditMode() {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.grey),
              SizedBox(width: 8),
              Text('拖拽调整顺序，点击删除移除组件'),
            ],
          ),
        ),
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _widgets.length,
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (newIndex > oldIndex) newIndex--;
                final widget = _widgets.removeAt(oldIndex);
                _widgets.insert(newIndex, widget);
              });
            },
            itemBuilder: (context, index) {
              final widget = _widgets[index];
              return Card(
                key: ValueKey(widget.id),
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(WidgetType.getIcon(widget.type)),
                  title: Text(widget.title ?? WidgetType.getTitle(widget.type)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.drag_handle),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          setState(() => _widgets.removeAt(index));
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildViewMode() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: _widgets.map((widget) => _buildWidgetCard(widget)).toList(),
      ),
    );
  }

  Widget _buildWidgetCard(DashboardWidget widget) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(WidgetType.getIcon(widget.type), color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  widget.title ?? WidgetType.getTitle(widget.type),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildWidgetContent(widget),
          ],
        ),
      ),
    );
  }

  Widget _buildWidgetContent(DashboardWidget widget) {
    switch (widget.type) {
      case WidgetType.stats:
        return _buildStatsWidget();
      case WidgetType.habit:
        return _buildHabitWidget();
      case WidgetType.quickAction:
        return _buildQuickActionWidget();
      case WidgetType.todo:
        return _buildTodoWidget();
      default:
        return const Text('组件内容');
    }
  }

  Widget _buildStatsWidget() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatItem('记录', '12', Icons.edit_note),
        _buildStatItem('习惯', '5/7', Icons.check_circle),
        _buildStatItem('目标', '3', Icons.flag),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 24, color: Theme.of(context).primaryColor),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildHabitWidget() {
    final habits = ['喝水', '运动', '阅读'];
    return Column(
      children: habits.map((h) => CheckboxListTile(
        value: false,
        onChanged: (v) {},
        title: Text(h),
        dense: true,
      )).toList(),
    );
  }

  Widget _buildQuickActionWidget() {
    final actions = [
      ('新建记录', Icons.add, Colors.blue),
      ('计时器', Icons.timer, Colors.orange),
      ('搜索', Icons.search, Colors.green),
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: actions.map((a) => Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: a.$3.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(a.$2, color: a.$3),
          ),
          const SizedBox(height: 4),
          Text(a.$1, style: const TextStyle(fontSize: 12)),
        ],
      )).toList(),
    );
  }

  Widget _buildTodoWidget() {
    return Column(
      children: [
        CheckboxListTile(value: true, onChanged: (v) {}, title: const Text('已完成任务'), dense: true),
        CheckboxListTile(value: false, onChanged: (v) {}, title: const Text('待办任务'), dense: true),
      ],
    );
  }

  void _showAddWidgetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加组件'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildWidgetOption(WidgetType.stats, '统计卡片', Icons.bar_chart),
            _buildWidgetOption(WidgetType.habit, '习惯打卡', Icons.check_circle),
            _buildWidgetOption(WidgetType.quickAction, '快捷操作', Icons.flash_on),
            _buildWidgetOption(WidgetType.todo, '待办事项', Icons.list),
            _buildWidgetOption(WidgetType.chart, '图表', Icons.pie_chart),
            _buildWidgetOption(WidgetType.weather, '天气', Icons.wb_sunny),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }

  Widget _buildWidgetOption(String type, String title, IconData icon) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: () {
        setState(() {
          _widgets.add(DashboardWidget(
            type: type,
            title: title,
            position: _widgets.length,
          ));
        });
        Navigator.pop(context);
      },
    );
  }
}