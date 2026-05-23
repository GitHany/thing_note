import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/daily_routine/data/daily_routine_repository.dart';
import 'package:thing_note/features/daily_routine/domain/daily_routine.dart';
import 'package:thing_note/l10n/generated/app_localizations.dart';

final dailyRoutineProvider = dailyRoutineRepositoryProvider;

class DailyRoutineScreen extends ConsumerStatefulWidget {
  const DailyRoutineScreen({super.key});

  @override
  ConsumerState<DailyRoutineScreen> createState() => _DailyRoutineScreenState();
}

class _DailyRoutineScreenState extends ConsumerState<DailyRoutineScreen> {
  List<DailyRoutine> _routines = [];
  int _completionRate = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final repo = ref.read(dailyRoutineProvider);
    _routines = await repo.getActiveRoutines();
    _completionRate = await repo.getTodayCompletionRate();
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.dailyRoutine),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddRoutineDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildProgressCard(),
                    const SizedBox(height: 16),
                    _buildRoutinesList(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProgressCard() {
    return Card(
      color: _completionRate >= 80
          ? Colors.green.withOpacity(0.1)
          : _completionRate >= 50
              ? Colors.orange.withOpacity(0.1)
              : Colors.red.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 100,
                  height: 100,
                  child: CircularProgressIndicator(
                    value: _completionRate / 100,
                    strokeWidth: 8,
                    backgroundColor: Colors.grey.withOpacity(0.3),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _completionRate >= 80
                          ? Colors.green
                          : _completionRate >= 50
                              ? Colors.orange
                              : Colors.red,
                    ),
                  ),
                ),
                Text(
                  '$_completionRate%',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '今日完成率',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              _completionRate >= 80
                  ? '🎉 太棒了！'
                  : _completionRate >= 50
                      ? '💪 再接再厉'
                      : '🚀 加油完成',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoutinesList() {
    if (_routines.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Icon(Icons.schedule, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('还没有日常routine'),
              const SizedBox(height: 8),
              const Text('创建你的日常routine来养成好习惯'),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _showAddRoutineDialog,
                icon: const Icon(Icons.add),
                label: const Text('添加Routine'),
              ),
            ],
          ),
        ),
      );
    }

    // Group routines by time slot
    final morning = _routines.where((r) => r.timeSlot == 'morning').toList();
    final afternoon = _routines.where((r) => r.timeSlot == 'afternoon').toList();
    final evening = _routines.where((r) => r.timeSlot == 'evening').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (morning.isNotEmpty) _buildTimeSection('🌅 早上', morning),
        if (afternoon.isNotEmpty) _buildTimeSection('☀️ 下午', afternoon),
        if (evening.isNotEmpty) _buildTimeSection('🌙 晚上', evening),
      ],
    );
  }

  Widget _buildTimeSection(String title, List<DailyRoutine> routines) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ...routines.map((routine) => _buildRoutineItem(routine)),
          ],
        ),
      ),
    );
  }

  Widget _buildRoutineItem(DailyRoutine routine) {
    return FutureBuilder<bool>(
      future: ref.read(dailyRoutineProvider).isCompletedToday(routine.id!),
      builder: (context, snapshot) {
        final isCompleted = snapshot.data ?? false;

        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Checkbox(
            value: isCompleted,
            onChanged: (value) async {
              if (value == true) {
                final today = DateTime.now().toIso8601String().split('T')[0];
                await ref.read(dailyRoutineProvider).completeRoutine(routine.id!, today);
                _loadData();
              }
            },
          ),
          title: Text(
            routine.name,
            style: TextStyle(
              decoration: isCompleted ? TextDecoration.lineThrough : null,
              color: isCompleted ? Colors.grey : null,
            ),
          ),
          subtitle: Text('${routine.durationMinutes}分钟'),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _deleteRoutine(routine.id!),
          ),
        );
      },
    );
  }

  void _showAddRoutineDialog() {
    final nameController = TextEditingController();
    String selectedTimeSlot = 'morning';
    int duration = 30;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('添加Routine'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Routine名称',
                    hintText: '例如：晨练、冥想、阅读',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedTimeSlot,
                  decoration: const InputDecoration(
                    labelText: '时间段',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'morning', child: Text('早上')),
                    DropdownMenuItem(value: 'afternoon', child: Text('下午')),
                    DropdownMenuItem(value: 'evening', child: Text('晚上')),
                  ],
                  onChanged: (value) => setDialogState(() => selectedTimeSlot = value!),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('时长: '),
                    Expanded(
                      child: Slider(
                        value: duration.toDouble(),
                        min: 5,
                        max: 120,
                        divisions: 23,
                        label: '$duration分钟',
                        onChanged: (value) => setDialogState(() => duration = value.round()),
                      ),
                    ),
                    Text('$duration分钟'),
                  ],
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
                if (nameController.text.isEmpty) return;
                final routine = DailyRoutine(
                  name: nameController.text,
                  timeSlot: selectedTimeSlot,
                  durationMinutes: duration,
                );
                await ref.read(dailyRoutineProvider).insertRoutine(routine);
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                _loadData();
              },
              child: const Text('添加'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteRoutine(int id) async {
    await ref.read(dailyRoutineProvider).deleteRoutine(id);
    _loadData();
  }
}