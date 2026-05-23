import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/core/database/database_provider.dart';
import 'package:thing_note/features/weekly_focus/data/weekly_focus_provider.dart';
import 'package:thing_note/features/weekly_focus/domain/weekly_focus_models.dart';

class WeeklyFocusScreen extends ConsumerStatefulWidget {
  const WeeklyFocusScreen({super.key});

  @override
  ConsumerState<WeeklyFocusScreen> createState() => _WeeklyFocusScreenState();
}

class _WeeklyFocusScreenState extends ConsumerState<WeeklyFocusScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentAsync = ref.watch(currentWeekFocusProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('每周聚焦'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => _tabController.animateTo(1),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '本周主题'),
            Tab(text: '历史记录'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Current Week Focus
          currentAsync.when(
            data: (focusWithGoals) {
              if (focusWithGoals == null) {
                return _buildNoFocusState();
              }
              return _buildCurrentFocusView(focusWithGoals);
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
          // History
          _buildHistoryTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateFocusDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('设置主题'),
      ),
    );
  }

  Widget _buildNoFocusState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.center_focus_strong,
            size: 80,
            color: Colors.grey.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            '本周还没有设置主题',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '设置一个本周聚焦主题，让生活更有方向',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showCreateFocusDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('设置本周主题'),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentFocusView(WeeklyFocusWithGoals focusWithGoals) {
    final focus = focusWithGoals.focus;
    final goals = focusWithGoals.goals;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(currentWeekFocusProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFocusHeader(focus, focusWithGoals.overallProgress),
            const SizedBox(height: 24),
            Text(
              '本周目标',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            if (goals.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.flag_outlined, size: 48, color: Colors.grey),
                        const SizedBox(height: 8),
                        const Text('还没有目标'),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () => _showAddGoalDialog(context, focus.id!),
                          icon: const Icon(Icons.add),
                          label: const Text('添加目标'),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              ...goals.map((goal) => _GoalCard(goal: goal)),
            const SizedBox(height: 8),
            Center(
              child: OutlinedButton.icon(
                onPressed: () => _showAddGoalDialog(context, focus.id!),
                icon: const Icon(Icons.add),
                label: const Text('添加目标'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFocusHeader(WeeklyFocus focus, double progress) {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = now.add(Duration(days: 7 - now.weekday));

    return Card(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              Color(focus.color).withOpacity(0.8),
              Color(focus.color),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '第${focus.weekNumber}周',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white),
                  onPressed: () => _showEditFocusDialog(context, focus),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              focus.title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            if (focus.description != null) ...[
              const SizedBox(height: 8),
              Text(
                focus.description!,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  '${weekStart.month}/${weekStart.day} - ${weekEnd.month}/${weekEnd.day}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                Text(
                  '${progress.toStringAsFixed(0)}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress / 100,
              backgroundColor: Colors.white.withOpacity(0.3),
              valueColor: const AlwaysStoppedAnimation(Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTab() {
    final allAsync = ref.watch(allWeeklyFocusesProvider);
    
    return allAsync.when(
      data: (focuses) {
        if (focuses.isEmpty) {
          return const Center(child: Text('暂无历史记录'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: focuses.length,
          itemBuilder: (context, index) {
            final focus = focuses[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Color(focus.color),
                  child: Text(
                    '${focus.weekNumber}',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
                title: Text(focus.title),
                subtitle: Text('${focus.year}年 第${focus.weekNumber}周'),
                trailing: Chip(
                  label: Text(
                    focus.status == 'completed' ? '已完成' : '进行中',
                    style: const TextStyle(fontSize: 10),
                  ),
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  void _showCreateFocusDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    String selectedTheme = '工作';
    int selectedColor = 0xFF2196F3;

    final now = DateTime.now();
    final weekNumber = ((now.difference(DateTime(now.year, 1, 1)).inDays + DateTime(now.year, 1, 1).weekday) / 7).ceil();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('第$weekNumber周主题'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: '主题名称',
                    hintText: '例如：专注健康',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: '描述（可选）'),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedTheme,
                  decoration: const InputDecoration(labelText: '主题类别'),
                  items: ['工作', '健康', '学习', '社交', '创意', '其他'].map((t) {
                    return DropdownMenuItem(value: t, child: Text(t));
                  }).toList(),
                  onChanged: (v) => setState(() => selectedTheme = v!),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  children: [
                    0xFF2196F3,
                    0xFF4CAF50,
                    0xFFFF9800,
                    0xFF9C27B0,
                    0xFFE91E63,
                    0xFF00BCD4,
                  ].map((color) {
                    return GestureDetector(
                      onTap: () => setState(() => selectedColor = color),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Color(color),
                          shape: BoxShape.circle,
                          border: selectedColor == color
                              ? Border.all(color: Colors.black, width: 2)
                              : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () async {
                if (titleController.text.isEmpty) return;
                final db = await ref.read(databaseProvider.future);
                final focus = WeeklyFocus(
                  weekNumber: weekNumber,
                  year: now.year,
                  title: titleController.text,
                  description: descController.text.isEmpty ? null : descController.text,
                  theme: selectedTheme,
                  color: selectedColor,
                  status: 'active',
                );
                await db.insert('weekly_focuses', focus.toMap());
                if (mounted) {
                  Navigator.pop(context);
                  ref.invalidate(currentWeekFocusProvider);
                }
              },
              child: const Text('创建'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditFocusDialog(BuildContext context, WeeklyFocus focus) {
    final titleController = TextEditingController(text: focus.title);
    final descController = TextEditingController(text: focus.description ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('编辑主题'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: '主题名称'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: '描述'),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              final db = await ref.read(databaseProvider.future);
              await db.update(
                'weekly_focuses',
                {
                  'title': titleController.text,
                  'description': descController.text.isEmpty ? null : descController.text,
                  'updated_at': DateTime.now().toIso8601String(),
                },
                where: 'id = ?',
                whereArgs: [focus.id],
              );
              if (mounted) {
                Navigator.pop(context);
                ref.invalidate(currentWeekFocusProvider);
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _showAddGoalDialog(BuildContext context, int focusId) {
    final titleController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加目标'),
        content: TextField(
          controller: titleController,
          decoration: const InputDecoration(
            labelText: '目标标题',
            hintText: '例如：每天运动30分钟',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              if (titleController.text.isEmpty) return;
              final db = await ref.read(databaseProvider.future);
              await db.insert('weekly_goals', {
                'focus_id': focusId,
                'title': titleController.text,
                'created_at': DateTime.now().toIso8601String(),
              });
              if (mounted) {
                Navigator.pop(context);
                ref.invalidate(currentWeekFocusProvider);
              }
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }
}

class _GoalCard extends ConsumerWidget {
  final WeeklyGoal goal;

  const _GoalCard({required this.goal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: GestureDetector(
          onTap: () async {
            final db = await ref.read(databaseProvider.future);
            final isCompleted = (await db.query(
              'weekly_goals',
              where: 'id = ?',
              whereArgs: [goal.id],
            )).first['is_completed'] == 1;
            
            await db.update(
              'weekly_goals',
              {
                'is_completed': isCompleted ? 0 : 1,
                'progress': isCompleted ? 0 : 100,
              },
              where: 'id = ?',
              whereArgs: [goal.id],
            );
            ref.invalidate(currentWeekFocusProvider);
          },
          child: Icon(
            goal.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
            color: goal.isCompleted ? Colors.green : Colors.grey,
          ),
        ),
        title: Text(
          goal.title,
          style: TextStyle(
            decoration: goal.isCompleted ? TextDecoration.lineThrough : null,
            color: goal.isCompleted ? Colors.grey : null,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 50,
              child: LinearProgressIndicator(
                value: goal.progress / 100,
                backgroundColor: Colors.grey.shade200,
              ),
            ),
            const SizedBox(width: 8),
            Text('${goal.progress}%'),
          ],
        ),
      ),
    );
  }
}