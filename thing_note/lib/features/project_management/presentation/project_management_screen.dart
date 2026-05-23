import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/l10n/generated/app_localizations.dart';

class ProjectManagementScreen extends ConsumerStatefulWidget {
  const ProjectManagementScreen({super.key});

  @override
  ConsumerState<ProjectManagementScreen> createState() =>
      _ProjectManagementScreenState();
}

class _ProjectManagementScreenState
    extends ConsumerState<ProjectManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _viewMode = 'board';

  final List<_Project> _projects = [
    _Project(
      id: 1,
      name: '产品开发',
      description: '新产品功能开发',
      color: Colors.blue,
      progress: 0.65,
      taskCount: 12,
      completedTaskCount: 8,
    ),
    _Project(
      id: 2,
      name: '市场推广',
      description: 'Q1营销计划',
      color: Colors.green,
      progress: 0.40,
      taskCount: 8,
      completedTaskCount: 3,
    ),
  ];

  final List<_Task> _tasks = [
    _Task(
      id: 1,
      title: '完成 UI 设计',
      status: _TaskStatus.todo,
      priority: _TaskPriority.high,
      dueDate: DateTime.now().add(const Duration(days: 2)),
    ),
    _Task(
      id: 2,
      title: '开发后端 API',
      status: _TaskStatus.inProgress,
      priority: _TaskPriority.high,
      dueDate: DateTime.now().add(const Duration(days: 5)),
    ),
    _Task(
      id: 3,
      title: '编写测试文档',
      status: _TaskStatus.done,
      priority: _TaskPriority.medium,
      dueDate: DateTime.now().subtract(const Duration(days: 1)),
    ),
    _Task(
      id: 4,
      title: '性能优化',
      status: _TaskStatus.todo,
      priority: _TaskPriority.low,
      dueDate: DateTime.now().add(const Duration(days: 10)),
    ),
  ];

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
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 600;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.projectManagement),
        actions: [
          IconButton(
            icon: Icon(_viewMode == 'board' ? Icons.view_list : Icons.view_kanban),
            onPressed: () =>
                setState(() => _viewMode = _viewMode == 'board' ? 'list' : 'board'),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateProjectDialog(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '项目'),
            Tab(text: '看板'),
            Tab(text: '时间线'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Projects tab
          ListView(
            padding: EdgeInsets.all(isWideScreen ? 24 : 16),
            children: [
              ...(_projects.map((project) => _buildProjectCard(project))),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => _showCreateProjectDialog(),
                icon: const Icon(Icons.add),
                label: const Text('创建新项目'),
              ),
            ],
          ),

          // Board tab
          _viewMode == 'board' ? _buildKanbanBoard() : _buildListView(),

          // Timeline tab
          _buildTimelineView(),
        ],
      ),
    );
  }

  Widget _buildProjectCard(_Project project) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _openProject(project),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: project.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      project.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () {},
                  ),
                ],
              ),
              Text(
                project.description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: project.progress,
                      backgroundColor:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('${(project.progress * 100).toInt()}%'),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.task, size: 16),
                  const SizedBox(width: 4),
                  Text('${project.completedTaskCount}/${project.taskCount}'),
                  const SizedBox(width: 16),
                  const Icon(Icons.calendar_today, size: 16),
                  const SizedBox(width: 4),
                  Text(_formatDate(DateTime.now())),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKanbanBoard() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildKanbanColumn(
            title: '待办',
            color: Colors.grey,
            tasks: _tasks.where((t) => t.status == _TaskStatus.todo).toList(),
          ),
          const SizedBox(width: 16),
          _buildKanbanColumn(
            title: '进行中',
            color: Colors.blue,
            tasks: _tasks.where((t) => t.status == _TaskStatus.inProgress).toList(),
          ),
          const SizedBox(width: 16),
          _buildKanbanColumn(
            title: '已完成',
            color: Colors.green,
            tasks: _tasks.where((t) => t.status == _TaskStatus.done).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildKanbanColumn({
    required String title,
    required Color color,
    required List<_Task> tasks,
  }) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${tasks.length}',
                  style: TextStyle(color: color, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...(tasks.map((task) => _buildTaskCard(task))),
          const SizedBox(height: 8),
          InkWell(
            onTap: () => _addTask(title),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add, size: 18),
                  SizedBox(width: 4),
                  Text('添加任务'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(_Task task) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _openTask(task),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      task.title,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  _buildPriorityBadge(task.priority),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(task.dueDate),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityBadge(_TaskPriority priority) {
    Color color;
    String label;
    switch (priority) {
      case _TaskPriority.high:
        color = Colors.red;
        label = '高';
        break;
      case _TaskPriority.medium:
        color = Colors.orange;
        label = '中';
        break;
      case _TaskPriority.low:
        color = Colors.green;
        label = '低';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10),
      ),
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _tasks.length,
      itemBuilder: (context, index) {
        final task = _tasks[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Checkbox(
              value: task.status == _TaskStatus.done,
              onChanged: (value) {},
            ),
            title: Text(
              task.title,
              style: TextStyle(
                decoration:
                    task.status == _TaskStatus.done ? TextDecoration.lineThrough : null,
              ),
            ),
            subtitle: Text(_formatDate(task.dueDate)),
            trailing: _buildPriorityBadge(task.priority),
            onTap: () => _openTask(task),
          ),
        );
      },
    );
  }

  Widget _buildTimelineView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          for (int i = 0; i < _tasks.length; i++) ...[
            _buildTimelineItem(i, _tasks[i]),
          ],
        ],
      ),
    );
  }

  Widget _buildTimelineItem(int index, _Task task) {
    final isLast = index == _tasks.length - 1;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _getStatusColor(task.status),
                  shape: BoxShape.circle,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(task.dueDate),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(_TaskStatus status) {
    switch (status) {
      case _TaskStatus.todo:
        return Colors.grey;
      case _TaskStatus.inProgress:
        return Colors.blue;
      case _TaskStatus.done:
        return Colors.green;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}';
  }

  void _openProject(_Project project) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('打开项目: ${project.name}')),
    );
  }

  void _openTask(_Task task) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('打开任务: ${task.title}')),
    );
  }

  void _addTask(String status) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('添加任务到 $status')),
    );
  }

  void _showCreateProjectDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('创建项目'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: '项目名称',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              maxLines: 2,
              decoration: InputDecoration(
                labelText: '描述',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('创建'),
          ),
        ],
      ),
    );
  }
}

enum _TaskStatus { todo, inProgress, done }

enum _TaskPriority { high, medium, low }

class _Project {
  final int id;
  final String name;
  final String description;
  final Color color;
  final double progress;
  final int taskCount;
  final int completedTaskCount;

  _Project({
    required this.id,
    required this.name,
    required this.description,
    required this.color,
    required this.progress,
    required this.taskCount,
    required this.completedTaskCount,
  });
}

class _Task {
  final int id;
  final String title;
  final _TaskStatus status;
  final _TaskPriority priority;
  final DateTime dueDate;

  _Task({
    required this.id,
    required this.title,
    required this.status,
    required this.priority,
    required this.dueDate,
  });
}