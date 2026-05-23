import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/smart_weekly_planner/data/weekly_planner_repository.dart';
import 'package:thing_note/features/smart_weekly_planner/domain/weekly_plan.dart';

final weeklyPlannerRepoProvider = Provider((ref) => WeeklyPlannerRepository(ref));

class SmartWeeklyPlannerScreen extends ConsumerStatefulWidget {
  const SmartWeeklyPlannerScreen({super.key});

  @override
  ConsumerState<SmartWeeklyPlannerScreen> createState() => _SmartWeeklyPlannerScreenState();
}

class _SmartWeeklyPlannerScreenState extends ConsumerState<SmartWeeklyPlannerScreen> {
  int _selectedDay = DateTime.now().weekday;
  List<WeeklyPlan> _plans = [];
  bool _isLoading = true;

  final _dayNames = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    setState(() => _isLoading = true);
    final repo = ref.read(weeklyPlannerRepoProvider);
    _plans = await repo.getPlansByDay(_selectedDay);
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('智能周计划'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildDaySelector(),
          Expanded(child: _buildPlanList()),
        ],
      ),
    );
  }

  Widget _buildDaySelector() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 7,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, index) {
          final day = index + 1;
          final isSelected = day == _selectedDay;
          final isToday = day == DateTime.now().weekday;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedDay = day);
                _loadPlans();
              },
              child: Container(
                width: 50,
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : isToday
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _dayNames[index],
                      style: TextStyle(
                        color: isSelected ? Colors.white : null,
                        fontWeight: isToday ? FontWeight.bold : null,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlanList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_plans.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.event_note, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('这一天没有计划'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _showAddDialog,
              icon: const Icon(Icons.add),
              label: const Text('添加计划'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _plans.length,
      itemBuilder: (context, index) {
        final plan = _plans[index];
        return _PlanCard(
          plan: plan,
          onToggle: () => _toggleComplete(plan),
          onDelete: () => _deletePlan(plan.id!),
        );
      },
    );
  }

  void _showAddDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    String priority = 'medium';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('添加周计划'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: '计划标题'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: '描述（可选）'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: priority,
                decoration: const InputDecoration(labelText: '优先级'),
                items: const [
                  DropdownMenuItem(value: 'low', child: Text('🟢 低')),
                  DropdownMenuItem(value: 'medium', child: Text('🟡 中')),
                  DropdownMenuItem(value: 'high', child: Text('🟠 高')),
                  DropdownMenuItem(value: 'urgent', child: Text('🔴 紧急')),
                ],
                onChanged: (v) => priority = v!,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              if (titleController.text.trim().isEmpty) return;
              final repo = ref.read(weeklyPlannerRepoProvider);
              await repo.insertPlan(WeeklyPlan(
                title: titleController.text.trim(),
                description: descController.text.trim().isEmpty ? null : descController.text.trim(),
                dayOfWeek: _selectedDay,
                priority: priority,
                createdAt: DateTime.now(),
              ));
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              _loadPlans();
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleComplete(WeeklyPlan plan) async {
    final repo = ref.read(weeklyPlannerRepoProvider);
    await repo.toggleComplete(plan.id!, !plan.isCompleted);
    _loadPlans();
  }

  Future<void> _deletePlan(int id) async {
    final repo = ref.read(weeklyPlannerRepoProvider);
    await repo.deletePlan(id);
    _loadPlans();
  }
}

class _PlanCard extends StatelessWidget {
  final WeeklyPlan plan;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _PlanCard({
    required this.plan,
    required this.onToggle,
    required this.onDelete,
  });

  Color _getPriorityColor() {
    switch (plan.priority) {
      case 'urgent':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Checkbox(
          value: plan.isCompleted,
          onChanged: (_) => onToggle(),
        ),
        title: Text(
          plan.title,
          style: TextStyle(
            decoration: plan.isCompleted ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (plan.description != null) Text(plan.description!),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _getPriorityColor(),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(plan.priority),
              ],
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: onDelete,
        ),
      ),
    );
  }
}