import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/exercise_tracker/data/exercise_repository.dart';

class ExerciseTrackerScreen extends ConsumerStatefulWidget {
  const ExerciseTrackerScreen({super.key});

  @override
  ConsumerState<ExerciseTrackerScreen> createState() => _ExerciseTrackerScreenState();
}

class _ExerciseTrackerScreenState extends ConsumerState<ExerciseTrackerScreen> {
  @override
  Widget build(BuildContext context) {
    final exercisesAsync = ref.watch(exerciseRecordsProvider);
    final types = ref.watch(exerciseTypesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('运动记录'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: _showWeeklyStats,
          ),
        ],
      ),
      body: exercisesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('错误: $e')),
        data: (exercises) {
          if (exercises.isEmpty) {
            return _buildEmptyState();
          }
          return _buildExerciseList(exercises, types.value ?? []);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddExerciseDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.fitness_center, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('暂无运动记录', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 8),
          const Text('记录你的每一次运动，保持健康', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddExerciseDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('添加运动'),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseList(List<ExerciseRecord> exercises, List<ExerciseType> types) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: exercises.length,
      itemBuilder: (context, index) {
        final exercise = exercises[index];
        final type = types.firstWhere(
          (t) => t.name == exercise.exerciseType,
          orElse: () => ExerciseType(name: exercise.exerciseType, createdAt: DateTime.now()),
        );
        return _ExerciseCard(exercise: exercise, type: type);
      },
    );
  }

  void _showWeeklyStats() async {
    final repository = ref.read(exerciseRepositoryProvider);
    final stats = await repository.getWeeklyStats();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('本周运动统计', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            _StatRow(label: '运动次数', value: '${stats['total_exercises']}'),
            _StatRow(label: '总时长', value: '${stats['total_minutes']} 分钟'),
            _StatRow(label: '消耗卡路里', value: '${stats['total_calories']} kcal'),
            _StatRow(label: '总距离', value: '${stats['total_distance']} km'),
          ],
        ),
      ),
    );
  }

  void _showAddExerciseDialog(BuildContext context) {
    final types = ref.read(exerciseTypesProvider).value ?? [];
    String selectedType = types.isNotEmpty ? types.first.name : '跑步';
    int durationMinutes = 30;
    int caloriesBurned = 150;
    double distanceKm = 0;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('添加运动'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(labelText: '运动类型'),
                  items: types.map((t) => DropdownMenuItem(
                    value: t.name,
                    child: Row(
                      children: [
                        Text(t.icon ?? ''),
                        const SizedBox(width: 8),
                        Text(t.name),
                      ],
                    ),
                  )).toList(),
                  onChanged: (v) => setState(() {
                    selectedType = v!;
                    final type = types.firstWhere((t) => t.name == v);
                    caloriesBurned = (durationMinutes * type.caloriesPerMinute).round();
                  }),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('时长: '),
                    Expanded(
                      child: Slider(
                        value: durationMinutes.toDouble(),
                        min: 5,
                        max: 180,
                        divisions: 35,
                        label: '$durationMinutes 分钟',
                        onChanged: (v) => setState(() {
                          durationMinutes = v.round();
                          final type = types.firstWhere((t) => t.name == selectedType, orElse: () => types.first);
                          caloriesBurned = (durationMinutes * type.caloriesPerMinute).round();
                        }),
                      ),
                    ),
                    Text('$durationMinutes min'),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('消耗: '),
                    Expanded(
                      child: Slider(
                        value: caloriesBurned.toDouble(),
                        min: 0,
                        max: 1000,
                        divisions: 100,
                        label: '$caloriesBurned kcal',
                        onChanged: (v) => setState(() => caloriesBurned = v.round()),
                      ),
                    ),
                    Text('$caloriesBurned kcal'),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: const InputDecoration(
                    labelText: '距离 (km)',
                    hintText: '可选',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => distanceKm = double.tryParse(v) ?? 0,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                final record = ExerciseRecord(
                  exerciseType: selectedType,
                  durationMinutes: durationMinutes,
                  caloriesBurned: caloriesBurned,
                  distanceKm: distanceKm,
                  occurredAt: DateTime.now(),
                  createdAt: DateTime.now(),
                );
                ref.read(exerciseRecordsProvider.notifier).addExercise(record);
                Navigator.pop(context);
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExerciseCard extends ConsumerWidget {
  final ExerciseRecord exercise;
  final ExerciseType type;

  const _ExerciseCard({required this.exercise, required this.type});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showDetail(context, ref),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Color(int.parse(type.color?.replaceFirst('#', '0xFF') ?? '0xFF4CAF50')).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(type.icon ?? '🏃', style: const TextStyle(fontSize: 24)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.exerciseType,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${exercise.durationMinutes} 分钟  •  ${exercise.caloriesBurned} kcal',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    if (exercise.distanceKm > 0)
                      Text(
                        '${exercise.distanceKm} km',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatDate(exercise.occurredAt),
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(exercise.occurredAt),
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}';
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showDetail(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(type.icon ?? '', style: const TextStyle(fontSize: 32)),
                const SizedBox(width: 12),
                Text(exercise.exerciseType, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 24),
            _DetailRow(icon: Icons.timer, label: '时长', value: '${exercise.durationMinutes} 分钟'),
            _DetailRow(icon: Icons.local_fire_department, label: '消耗', value: '${exercise.caloriesBurned} kcal'),
            if (exercise.distanceKm > 0)
              _DetailRow(icon: Icons.straighten, label: '距离', value: '${exercise.distanceKm} km'),
            if (exercise.avgPace != null)
              _DetailRow(icon: Icons.speed, label: '配速', value: '${exercise.avgPace} /km'),
            if (exercise.avgHeartRate != null)
              _DetailRow(icon: Icons.favorite, label: '心率', value: '${exercise.avgHeartRate} bpm'),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      ref.read(exerciseRecordsProvider.notifier).deleteExercise(exercise.id!);
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('删除'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final dynamic value;

  const _StatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text('$value', style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(color: Colors.grey[600])),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}