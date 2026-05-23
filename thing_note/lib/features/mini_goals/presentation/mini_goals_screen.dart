import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final miniGoalsProvider = StateNotifierProvider<MiniGoalsNotifier, List<MiniGoal>>((ref) {
  return MiniGoalsNotifier();
});

class MiniGoalsNotifier extends StateNotifier<List<MiniGoal>> {
  MiniGoalsNotifier() : super([]);

  void addGoal(MiniGoal goal) {
    state = [...state, goal];
  }

  void completeGoal(int id) {
    state = state.map((g) {
      if (g.id == id) {
        return g.copyWith(
          status: 'completed',
          completedAt: DateTime.now().toIso8601String(),
          actualMinutes: g.estimatedMinutes,
        );
      }
      return g;
    }).toList();
  }

  void removeGoal(int id) {
    state = state.where((g) => g.id != id).toList();
  }

  int get completedCount => state.where((g) => g.status == 'completed').length;
  int get pendingCount => state.where((g) => g.status == 'pending').length;
  int get totalEstimatedMinutes => state.fold(0, (sum, g) => sum + g.estimatedMinutes);
}

class MiniGoal {
  final int id;
  final String title;
  final String? description;
  final int estimatedMinutes;
  final int? actualMinutes;
  final int priority;
  final String status;
  final String? category;
  final String? completedAt;
  final String createdAt;

  MiniGoal({
    required this.id,
    required this.title,
    this.description,
    this.estimatedMinutes = 5,
    this.actualMinutes,
    this.priority = 1,
    this.status = 'pending',
    this.category,
    this.completedAt,
    required this.createdAt,
  });

  MiniGoal copyWith({
    int? id,
    String? title,
    String? description,
    int? estimatedMinutes,
    int? actualMinutes,
    int? priority,
    String? status,
    String? category,
    String? completedAt,
    String? createdAt,
  }) {
    return MiniGoal(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      actualMinutes: actualMinutes ?? this.actualMinutes,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      category: category ?? this.category,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class MiniGoalsScreen extends ConsumerStatefulWidget {
  const MiniGoalsScreen({super.key});

  @override
  ConsumerState<MiniGoalsScreen> createState() => _MiniGoalsScreenState();
}

class _MiniGoalsScreenState extends ConsumerState<MiniGoalsScreen> {
  int _nextId = 1;

  @override
  Widget build(BuildContext context) {
    final goals = ref.watch(miniGoalsProvider);
    final stats = ref.read(miniGoalsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mini Goals'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => _showCompletedGoals(context, goals),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStats(goals, stats),
          Expanded(
            child: goals.isEmpty
                ? _buildEmptyState()
                : _buildGoalsList(goals),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddGoalDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('New Goal'),
      ),
    );
  }

  Widget _buildStats(List<MiniGoal> goals, MiniGoalsNotifier notifier) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatColumn(
                icon: Icons.pending_actions,
                value: '${notifier.pendingCount}',
                label: 'Pending',
                color: Colors.orange,
              ),
              _buildStatColumn(
                icon: Icons.check_circle,
                value: '${notifier.completedCount}',
                label: 'Done',
                color: Colors.green,
              ),
              _buildStatColumn(
                icon: Icons.timer,
                value: '${notifier.totalEstimatedMinutes}m',
                label: 'Total Time',
                color: Colors.blue,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatColumn({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.flag, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No mini goals yet',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Add quick 5-15 minute tasks',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsList(List<MiniGoal> goals) {
    final pending = goals.where((g) => g.status == 'pending').toList()
      ..sort((a, b) => a.priority.compareTo(b.priority));
    final completed = goals.where((g) => g.status == 'completed').toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (pending.isNotEmpty) ...[
          const Text(
            'Pending',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...pending.map((g) => _buildGoalCard(g)),
        ],
        if (completed.isNotEmpty) ...[
          const SizedBox(height: 24),
          Row(
            children: [
              const Text(
                'Completed Today',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text(
                '${completed.length} goals',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...completed.take(5).map((g) => _buildCompletedGoalCard(g)),
        ],
      ],
    );
  }

  Widget _buildGoalCard(MiniGoal goal) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _getPriorityColor(goal.priority).withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              '${goal.estimatedMinutes}m',
              style: TextStyle(
                color: _getPriorityColor(goal.priority),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
        title: Text(goal.title),
        subtitle: goal.description != null ? Text(goal.description!) : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.check, color: Colors.green),
              onPressed: () => _completeGoal(goal.id),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _removeGoal(goal.id),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletedGoalCard(MiniGoal goal) {
    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      color: Colors.grey[100],
      child: ListTile(
        leading: const Icon(Icons.check_circle, color: Colors.green),
        title: Text(
          goal.title,
          style: const TextStyle(decoration: TextDecoration.lineThrough),
        ),
        subtitle: Text('${goal.actualMinutes ?? goal.estimatedMinutes} min'),
      ),
    );
  }

  Color _getPriorityColor(int priority) {
    switch (priority) {
      case 1: return Colors.red;
      case 2: return Colors.orange;
      case 3: return Colors.blue;
      default: return Colors.grey;
    }
  }

  void _showAddGoalDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    int estimatedMinutes = 5;
    int priority = 2;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('New Mini Goal'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Goal',
                    hintText: 'What do you want to do?',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: 'Description (optional)'),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Estimated Time:'),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: () {
                        if (estimatedMinutes > 1) {
                          setState(() => estimatedMinutes -= 5);
                        }
                      },
                    ),
                    Text(
                      '$estimatedMinutes min',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        if (estimatedMinutes < 60) {
                          setState(() => estimatedMinutes += 5);
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Priority:'),
                    const Spacer(),
                    ...List.generate(3, (i) {
                      final p = i + 1;
                      return GestureDetector(
                        onTap: () => setState(() => priority = p),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getPriorityColor(p).withOpacity(priority == p ? 0.3 : 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: priority == p
                                ? Border.all(color: _getPriorityColor(p), width: 2)
                                : null,
                          ),
                          child: Text(
                            p == 1 ? 'High' : p == 2 ? 'Medium' : 'Low',
                            style: TextStyle(color: _getPriorityColor(p)),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.isNotEmpty) {
                  final goal = MiniGoal(
                    id: _nextId++,
                    title: titleController.text,
                    description: descController.text.isEmpty ? null : descController.text,
                    estimatedMinutes: estimatedMinutes,
                    priority: priority,
                    createdAt: DateTime.now().toIso8601String(),
                  );
                  ref.read(miniGoalsProvider.notifier).addGoal(goal);
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCompletedGoals(BuildContext context, List<MiniGoal> goals) {
    final completed = goals.where((g) => g.status == 'completed').toList();
    
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Completed Goals',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: completed.isEmpty
                ? const Center(child: Text('No completed goals'))
                : ListView.builder(
                    itemCount: completed.length,
                    itemBuilder: (context, index) {
                      final goal = completed[index];
                      return ListTile(
                        leading: const Icon(Icons.check_circle, color: Colors.green),
                        title: Text(goal.title),
                        subtitle: Text('${goal.actualMinutes ?? goal.estimatedMinutes} min'),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _completeGoal(int id) {
    ref.read(miniGoalsProvider.notifier).completeGoal(id);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Goal completed! 🎉'), backgroundColor: Colors.green),
    );
  }

  void _removeGoal(int id) {
    ref.read(miniGoalsProvider.notifier).removeGoal(id);
  }
}