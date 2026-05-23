import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/habit_brick_model.dart';
import '../data/habit_bricks_repository.dart';

final allBricksProvider = FutureProvider.autoDispose<List<HabitBrick>>((ref) async {
  final repo = ref.watch(habitBricksRepositoryProvider);
  return await repo.getAllBricks();
});

class HabitBricksScreen extends ConsumerStatefulWidget {
  const HabitBricksScreen({super.key});

  @override
  ConsumerState<HabitBricksScreen> createState() => _HabitBricksScreenState();
}

class _HabitBricksScreenState extends ConsumerState<HabitBricksScreen> {
  @override
  Widget build(BuildContext context) {
    final bricksAsync = ref.watch(allBricksProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Habit Bricks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddBrickDialog(context),
          ),
        ],
      ),
      body: bricksAsync.when(
        data: (bricks) => bricks.isEmpty
            ? _buildEmptyState()
            : _buildBrickList(bricks),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddBrickDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('New Brick'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.layers, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No habit bricks yet',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Break down your big habits into daily bricks',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildBrickList(List<HabitBrick> bricks) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bricks.length,
      itemBuilder: (context, index) {
        final brick = bricks[index];
        return _buildBrickCard(brick);
      },
    );
  }

  Widget _buildBrickCard(HabitBrick brick) {
    return FutureBuilder<Map<String, dynamic>>(
      future: ref.read(habitBricksRepositoryProvider).getBrickStatistics(brick.id!),
      builder: (context, snapshot) {
        final stats = snapshot.data ?? {};
        final streak = snapshot.hasData 
            ? _calculateStreak(brick.id!, stats)
            : 0;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
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
                        color: Colors.blue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.layers, color: Colors.blue),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            brick.habitName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (brick.description != null)
                            Text(
                              brick.description!,
                              style: TextStyle(color: Colors.grey[600], fontSize: 12),
                            ),
                        ],
                      ),
                    ),
                    PopupMenuButton(
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'edit', child: Text('Edit')),
                        const PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                      onSelected: (value) {
                        if (value == 'edit') {
                          _showEditBrickDialog(context, brick);
                        } else if (value == 'delete') {
                          _deleteBrick(brick);
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatColumn(
                      icon: Icons.today,
                      value: '${brick.targetBricksPerDay}',
                      label: 'Daily Target',
                      color: Colors.blue,
                    ),
                    _buildStatColumn(
                      icon: Icons.local_fire_department,
                      value: '$streak',
                      label: 'Streak',
                      color: Colors.orange,
                    ),
                    _buildStatColumn(
                      icon: Icons.check_circle,
                      value: '${stats['total_completed_days'] ?? 0}',
                      label: 'Total Days',
                      color: Colors.green,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildBrickProgress(brick),
              ],
            ),
          ),
        );
      },
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
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildBrickProgress(HabitBrick brick) {
    return FutureBuilder<BrickProgress?>(
      future: ref.read(habitBricksRepositoryProvider).getTodayProgress(brick.id!),
      builder: (context, snapshot) {
        final progress = snapshot.data;
        final completed = progress?.completedBricks ?? 0;
        final target = brick.targetBricksPerDay;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Today\'s Progress',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                Text(
                  '$completed / $target ${brick.brickUnit}${target > 1 ? 's' : ''}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: completed / target,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                completed >= target ? Colors.green : Colors.blue,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: completed < target 
                        ? () => _completeBrick(brick, completed)
                        : null,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Brick'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _completeAllBricks(brick, target),
                    icon: const Icon(Icons.check),
                    label: const Text('Complete All'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _showAddBrickDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    int targetPerDay = 1;
    String brickUnit = 'task';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('New Habit Brick'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Habit Name',
                    hintText: 'e.g., Morning Exercise',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Daily Target:'),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: targetPerDay > 1 
                          ? () => setState(() => targetPerDay--) 
                          : null,
                    ),
                    Text(
                      '$targetPerDay',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () => setState(() => targetPerDay++),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: brickUnit,
                  decoration: const InputDecoration(labelText: 'Brick Unit'),
                  items: ['task', 'page', 'minute', 'rep', 'step']
                      .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => brickUnit = value);
                  },
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
                if (nameController.text.isNotEmpty) {
                  _createBrick(
                    nameController.text,
                    descController.text,
                    targetPerDay,
                    brickUnit,
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditBrickDialog(BuildContext context, HabitBrick brick) {
    final nameController = TextEditingController(text: brick.habitName);
    final descController = TextEditingController(text: brick.description);
    int targetPerDay = brick.targetBricksPerDay;
    String brickUnit = brick.brickUnit;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Habit Brick'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Habit Name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Daily Target:'),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: targetPerDay > 1 
                          ? () => setState(() => targetPerDay--) 
                          : null,
                    ),
                    Text(
                      '$targetPerDay',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () => setState(() => targetPerDay++),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: brickUnit,
                  decoration: const InputDecoration(labelText: 'Brick Unit'),
                  items: ['task', 'page', 'minute', 'rep', 'step']
                      .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => brickUnit = value);
                  },
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
                if (nameController.text.isNotEmpty) {
                  _updateBrick(
                    brick.copyWith(
                      habitName: nameController.text,
                      description: descController.text.isEmpty ? null : descController.text,
                      targetBricksPerDay: targetPerDay,
                      brickUnit: brickUnit,
                    ),
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createBrick(
    String name,
    String description,
    int targetPerDay,
    String brickUnit,
  ) async {
    final repo = ref.read(habitBricksRepositoryProvider);
    final brick = HabitBrick(
      habitName: name,
      description: description.isEmpty ? null : description,
      targetBricksPerDay: targetPerDay,
      brickUnit: brickUnit,
      createdAt: DateTime.now().toIso8601String(),
    );
    await repo.insertBrick(brick);
    ref.invalidate(allBricksProvider);
  }

  Future<void> _updateBrick(HabitBrick brick) async {
    final repo = ref.read(habitBricksRepositoryProvider);
    await repo.updateBrick(brick);
    ref.invalidate(allBricksProvider);
  }

  Future<void> _deleteBrick(HabitBrick brick) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Brick?'),
        content: Text('Are you sure you want to delete "${brick.habitName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      final repo = ref.read(habitBricksRepositoryProvider);
      await repo.deleteBrick(brick.id!);
      ref.invalidate(allBricksProvider);
    }
  }

  Future<void> _completeBrick(HabitBrick brick, int current) async {
    final repo = ref.read(habitBricksRepositoryProvider);
    final today = DateTime.now().toIso8601String().split('T')[0];
    
    final progress = BrickProgress(
      brickId: brick.id!,
      recordDate: today,
      completedBricks: current + 1,
      totalBricks: brick.targetBricksPerDay,
      createdAt: DateTime.now().toIso8601String(),
    );
    
    await repo.saveProgress(progress);
    ref.invalidate(allBricksProvider);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Brick completed! Keep going!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _completeAllBricks(HabitBrick brick, int target) async {
    final repo = ref.read(habitBricksRepositoryProvider);
    final today = DateTime.now().toIso8601String().split('T')[0];
    
    final progress = BrickProgress(
      brickId: brick.id!,
      recordDate: today,
      completedBricks: target,
      totalBricks: target,
      createdAt: DateTime.now().toIso8601String(),
    );
    
    await repo.saveProgress(progress);
    ref.invalidate(allBricksProvider);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All bricks completed for today! 🎉'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  int _calculateStreak(int brickId, Map<String, dynamic> stats) {
    // Simple streak calculation based on total completed days
    return stats['total_completed_days'] as int? ?? 0;
  }
}