import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/pomodoro_task/data/pomodoro_task_provider.dart';
import 'package:thing_note/features/pomodoro_task/domain/pomodoro_task.dart';

class PomodoroTaskScreen extends ConsumerStatefulWidget {
  const PomodoroTaskScreen({super.key});

  @override
  ConsumerState<PomodoroTaskScreen> createState() => _PomodoroTaskScreenState();
}

class _PomodoroTaskScreenState extends ConsumerState<PomodoroTaskScreen> {
  PomodoroTask? _activeTask;
  final int _sessionMinutes = 25;
  bool _isBreak = false;

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(pomodoroTasksProvider);
    final timerState = ref.watch(pomodoroTimerProvider);
    final statsAsync = ref.watch(pomodoroStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('番茄任务'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => _showHistory(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats Bar
          statsAsync.when(
            data: (stats) => _buildStatsBar(stats),
            loading: () => const SizedBox(height: 60),
            error: (_, __) => const SizedBox(height: 60),
          ),
          const SizedBox(height: 16),

          // Timer Display
          _buildTimerDisplay(timerState),
          const SizedBox(height: 24),

          // Task List
          Expanded(
            child: tasksAsync.when(
              data: (tasks) => _buildTaskList(tasks),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTaskDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('添加任务'),
      ),
    );
  }

  Widget _buildStatsBar(PomodoroStats stats) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('今日', '${stats.todayPomodoros}个', Icons.today),
          _buildStatItem('时长', '${stats.todayMinutes}分钟', Icons.timer),
          _buildStatItem('本周', '${stats.weekPomodoros}个', Icons.date_range),
          _buildStatItem('专注', stats.avgFocusScore.toStringAsFixed(1), Icons.psychology),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.orange, size: 20),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  Widget _buildTimerDisplay(PomodoroTimerState timerState) {
    final minutes = timerState.remainingSeconds ~/ 60;
    final seconds = timerState.remainingSeconds % 60;

    return Center(
      child: Column(
        children: [
          if (_activeTask != null) ...[
            Text(
              _activeTask!.title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _isBreak ? '休息时间' : '专注中',
              style: TextStyle(color: _isBreak ? Colors.green : Colors.orange),
            ),
          ],
          const SizedBox(height: 16),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 200,
                height: 200,
                child: CircularProgressIndicator(
                  value: timerState.progress,
                  strokeWidth: 8,
                  backgroundColor: Colors.grey.shade300,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _isBreak ? Colors.green : Colors.orange,
                  ),
                ),
              ),
              Column(
                children: [
                  Text(
                    '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                  if (_activeTask != null)
                    Text(
                      '${_activeTask!.completedPomodoros}/${_activeTask!.estimatedPomodoros} 番茄',
                      style: const TextStyle(color: Colors.grey),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (timerState.isRunning)
                IconButton(
                  onPressed: () => ref.read(pomodoroTimerProvider.notifier).pause(),
                  icon: const Icon(Icons.pause_circle, size: 48),
                )
              else if (timerState.remainingSeconds > 0)
                IconButton(
                  onPressed: () => ref.read(pomodoroTimerProvider.notifier).resume(),
                  icon: const Icon(Icons.play_circle, size: 48),
                )
              else
                IconButton(
                  onPressed: () => _startTimer(),
                  icon: const Icon(Icons.play_circle, size: 48),
                ),
              IconButton(
                onPressed: () {
                  ref.read(pomodoroTimerProvider.notifier).stop();
                  setState(() {
                    _activeTask = null;
                    _isBreak = false;
                  });
                },
                icon: const Icon(Icons.stop_circle, size: 48),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList(List<PomodoroTask> tasks) {
    if (tasks.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.task_alt, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('暂无任务，点击右下角添加'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getPriorityColor(task.priority),
              child: Text('${task.completedPomodoros}/${task.estimatedPomodoros}'),
            ),
            title: Text(task.title),
            subtitle: LinearProgressIndicator(value: task.progress),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'start') {
                  setState(() => _activeTask = task);
                  _startTimer();
                } else if (value == 'delete') {
                  // Delete task
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'start', child: Text('开始')),
                const PopupMenuItem(value: 'edit', child: Text('编辑')),
                const PopupMenuItem(value: 'delete', child: Text('删除')),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getPriorityColor(PomodoroPriority priority) {
    switch (priority) {
      case PomodoroPriority.low:
        return Colors.green;
      case PomodoroPriority.medium:
        return Colors.blue;
      case PomodoroPriority.high:
        return Colors.orange;
      case PomodoroPriority.urgent:
        return Colors.red;
    }
  }

  void _startTimer() {
    ref.read(pomodoroTimerProvider.notifier).startTimer(_isBreak ? 5 : _sessionMinutes);
  }

  void _showAddTaskDialog(BuildContext context) {
    final titleController = TextEditingController();
    int estimate = 1;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('添加任务'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: '任务名称',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('预估番茄:'),
                  const Spacer(),
                  IconButton(
                    onPressed: () => setState(() => estimate--),
                    icon: const Icon(Icons.remove),
                  ),
                  Text('$estimate'),
                  IconButton(
                    onPressed: () => setState(() => estimate++),
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.isNotEmpty) {
                  // Save task
                  Navigator.pop(context);
                }
              },
              child: const Text('添加'),
            ),
          ],
        ),
      ),
    );
  }

  void _showHistory(BuildContext context) {
    // TODO: Navigate to history screen
  }
}