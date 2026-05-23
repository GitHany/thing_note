import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/micro_goal_models.dart';
import '../data/micro_goal_repository.dart';

final microGoalProvider = StateNotifierProvider<MicroGoalNotifier, MicroGoalState>((ref) {
  return MicroGoalNotifier(ref.watch(microGoalRepositoryProvider));
});

class MicroGoalState {
  final List<MicroGoal> pending;
  final List<MicroGoal> completed;
  final bool isLoading;
  final String? error;

  MicroGoalState({this.pending = const [], this.completed = const [], this.isLoading = false, this.error});

  MicroGoalState copyWith({List<MicroGoal>? pending, List<MicroGoal>? completed, bool? isLoading, String? error}) {
    return MicroGoalState(
      pending: pending ?? this.pending,
      completed: completed ?? this.completed,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class MicroGoalNotifier extends StateNotifier<MicroGoalState> {
  final MicroGoalRepository _repository;

  MicroGoalNotifier(this._repository) : super(MicroGoalState()) {
    loadData();
  }

  Future<void> loadData() async {
    state = state.copyWith(isLoading: true);
    try {
      final pending = await _repository.getPending();
      final completed = await _repository.getCompleted();
      state = state.copyWith(pending: pending, completed: completed, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> add(MicroGoal goal) async {
    try {
      await _repository.insert(goal);
      await loadData();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> complete(int id, int actualMinutes) async {
    try {
      await _repository.complete(id, actualMinutes);
      await loadData();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> delete(int id) async {
    try {
      await _repository.delete(id);
      await loadData();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

final microGoalStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return await ref.watch(microGoalRepositoryProvider).getStats();
});

class MicroGoalsScreen extends ConsumerStatefulWidget {
  const MicroGoalsScreen({super.key});

  @override
  ConsumerState<MicroGoalsScreen> createState() => _MicroGoalsScreenState();
}

class _MicroGoalsScreenState extends ConsumerState<MicroGoalsScreen> {
  final _titleController = TextEditingController();
  int _estimatedMinutes = 5;
  final int _priority = 1;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(microGoalProvider);
    final statsAsync = ref.watch(microGoalStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Micro Goals'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats
            statsAsync.when(
              data: (stats) => _buildStats(stats),
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Error: $e'),
            ),
            const SizedBox(height: 16),

            // Add Goal
            _buildAddForm(),
            const SizedBox(height: 16),

            // Pending Goals
            Text('To Do (${state.pending.length})', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...state.pending.map((g) => _buildGoalCard(g, false)),
            
            const SizedBox(height: 16),

            // Completed Goals
            Text('Done (${state.completed.length})', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...state.completed.take(5).map((g) => _buildGoalCard(g, true)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStats(Map<String, dynamic> stats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem('Pending', '${stats['pending'] ?? 0}'),
            _buildStatItem('Done', '${stats['completed'] ?? 0}'),
            _buildStatItem('Avg Time', '${(stats['avg_time'] as num?)?.toStringAsFixed(0) ?? '0'}m'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildAddForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Quick Add', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: 'What needs to be done?',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Time: '),
                Expanded(
                  child: Slider(
                    value: _estimatedMinutes.toDouble(),
                    min: 1, max: 30, divisions: 29,
                    label: '$_estimatedMinutes min',
                    onChanged: (v) => setState(() => _estimatedMinutes = v.round()),
                  ),
                ),
                Text('$_estimatedMinutes min'),
              ],
            ),
            ElevatedButton(
              onPressed: _addGoal,
              child: const Text('Add Goal'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalCard(MicroGoal goal, bool isCompleted) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isCompleted ? Colors.green.withOpacity(0.1) : null,
      child: ListTile(
        leading: IconButton(
          icon: Icon(isCompleted ? Icons.check_circle : Icons.radio_button_unchecked),
          color: isCompleted ? Colors.green : Colors.grey,
          onPressed: isCompleted ? null : () => _completeGoal(goal),
        ),
        title: Text(goal.title),
        subtitle: Text('${goal.estimatedMinutes} min${isCompleted ? ' - Done!' : ''}'),
        trailing: isCompleted 
            ? null 
            : IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => ref.read(microGoalProvider.notifier).delete(goal.id!),
              ),
      ),
    );
  }

  void _addGoal() {
    if (_titleController.text.isEmpty) return;
    final goal = MicroGoal(
      title: _titleController.text,
      estimatedMinutes: _estimatedMinutes,
      priority: _priority,
    );
    ref.read(microGoalProvider.notifier).add(goal);
    _titleController.clear();
  }

  void _completeGoal(MicroGoal goal) {
    showDialog(
      context: context,
      builder: (context) {
        int actualMinutes = goal.estimatedMinutes;
        return AlertDialog(
          title: const Text('Complete Goal'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Actual time spent:'),
              Slider(
                value: actualMinutes.toDouble(),
                min: 1, max: 60,
                divisions: 59,
                label: '$actualMinutes min',
                onChanged: (v) => actualMinutes = v.round(),
              ),
              Text('$actualMinutes minutes'),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                ref.read(microGoalProvider.notifier).complete(goal.id!, actualMinutes);
                Navigator.pop(context);
              },
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
  }

  void _showAddDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16, right: 16, top: 16,
        ),
        child: _buildAddForm(),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }
}