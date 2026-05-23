import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/productivity_models.dart';
import '../data/productivity_repository.dart';

final productivityProvider = StateNotifierProvider<ProductivityNotifier, ProductivityState>((ref) {
  return ProductivityNotifier(ref.watch(productivityRepositoryProvider));
});

class ProductivityState {
  final DailyProductivityScore? todayScore;
  final bool isLoading;
  final String? error;

  ProductivityState({this.todayScore, this.isLoading = false, this.error});

  ProductivityState copyWith({DailyProductivityScore? todayScore, bool? isLoading, String? error}) {
    return ProductivityState(
      todayScore: todayScore ?? this.todayScore,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class ProductivityNotifier extends StateNotifier<ProductivityState> {
  final ProductivityRepository _repository;

  ProductivityNotifier(this._repository) : super(ProductivityState()) {
    loadTodayScore();
  }

  Future<void> loadTodayScore() async {
    state = state.copyWith(isLoading: true);
    try {
      final score = await _repository.getScoreByDate(DateTime.now());
      state = state.copyWith(todayScore: score, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> updateScore(DailyProductivityScore score) async {
    try {
      await _repository.insertOrUpdate(score);
      await loadTodayScore();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

final avgScoresProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return await ref.watch(productivityRepositoryProvider).getAverageScores();
});

class ProductivityScoreScreen extends ConsumerStatefulWidget {
  const ProductivityScoreScreen({super.key});

  @override
  ConsumerState<ProductivityScoreScreen> createState() => _ProductivityScoreScreenState();
}

class _ProductivityScoreScreenState extends ConsumerState<ProductivityScoreScreen> {
  int _focusScore = 3;
  int _energyScore = 3;
  int _outputScore = 3;
  int _tasksCompleted = 0;
  final int _tasksPlanned = 5;
  int _deepWorkMinutes = 0;
  final int _interruptions = 0;

  @override
  Widget build(BuildContext context) {
    final prodState = ref.watch(productivityProvider);
    final avgAsync = ref.watch(avgScoresProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Productivity Score'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Today's Score
            _buildTodayScore(prodState.todayScore),
            const SizedBox(height: 16),

            // Averages
            avgAsync.when(
              data: (avgs) => _buildAverages(avgs),
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Error: $e'),
            ),
            const SizedBox(height: 16),

            // Score Input
            _buildScoreInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayScore(DailyProductivityScore? score) {
    final overall = score?.overallScore ?? 0;
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text("Today's Score", style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Text(
              overall > 0 ? overall.toStringAsFixed(1) : '--',
              style: TextStyle(
                fontSize: 64,
                fontWeight: FontWeight.bold,
                color: _getScoreColor(overall),
              ),
            ),
            const SizedBox(height: 8),
            Text(_getScoreLabel(overall), style: const TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }

  Widget _buildAverages(Map<String, dynamic> avgs) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildAvgItem('Overall', avgs['avg_overall'] as num? ?? 0, 'focus'),
            _buildAvgItem('Focus', avgs['avg_focus'] as num? ?? 0, 'energy'),
            _buildAvgItem('Energy', avgs['avg_energy'] as num? ?? 0, 'output'),
            _buildAvgItem('Output', avgs['avg_output'] as num? ?? 0, 'work'),
          ],
        ),
      ),
    );
  }

  Widget _buildAvgItem(String label, num value, String icon) {
    return Column(
      children: [
        Icon(_getIcon(icon), color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 4),
        Text(value.toStringAsFixed(1), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      ],
    );
  }

  Widget _buildScoreInput() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Log Your Day', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            _buildScoreSlider('Focus', _focusScore, (v) => setState(() => _focusScore = v)),
            _buildScoreSlider('Energy', _energyScore, (v) => setState(() => _energyScore = v)),
            _buildScoreSlider('Output', _outputScore, (v) => setState(() => _outputScore = v)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      const Text('Tasks Done'),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: () => setState(() => _tasksCompleted = _tasksCompleted > 0 ? _tasksCompleted - 1 : 0),
                          ),
                          Text('$_tasksCompleted', style: const TextStyle(fontSize: 24)),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () => setState(() => _tasksCompleted++),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      const Text('Deep Work (min)'),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: () => setState(() => _deepWorkMinutes = _deepWorkMinutes > 0 ? _deepWorkMinutes - 15 : 0),
                          ),
                          Text('$_deepWorkMinutes', style: const TextStyle(fontSize: 24)),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () => setState(() => _deepWorkMinutes += 15),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _saveScore,
              child: const Text('Save Score'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreSlider(String label, int value, Function(int) onChanged) {
    return Row(
      children: [
        SizedBox(width: 80, child: Text(label)),
        Expanded(
          child: Slider(
            value: value.toDouble(),
            min: 1,
            max: 5,
            divisions: 4,
            label: '$value',
            onChanged: (v) => onChanged(v.round()),
          ),
        ),
        Text('$value', style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 4) return Colors.green;
    if (score >= 3) return Colors.blue;
    if (score >= 2) return Colors.orange;
    return Colors.red;
  }

  String _getScoreLabel(double score) {
    if (score >= 4) return 'Excellent';
    if (score >= 3) return 'Good';
    if (score >= 2) return 'Average';
    if (score > 0) return 'Low';
    return 'Not Logged';
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'focus': return Icons.center_focus_strong;
      case 'energy': return Icons.bolt;
      case 'output': return Icons.trending_up;
      default: return Icons.work;
    }
  }

  void _saveScore() {
    final overall = (_focusScore + _energyScore + _outputScore) / 3;
    final score = DailyProductivityScore(
      date: DateTime.now(),
      focusScore: _focusScore,
      energyScore: _energyScore,
      outputScore: _outputScore,
      overallScore: overall,
      completedTasks: _tasksCompleted,
      plannedTasks: _tasksPlanned,
      deepWorkMinutes: _deepWorkMinutes,
      interruptionCount: _interruptions,
    );
    ref.read(productivityProvider.notifier).updateScore(score);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Productivity score saved!')),
    );
  }
}