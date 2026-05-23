import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/prediction_models.dart';
import '../data/prediction_repository.dart';

final moodPredictionProvider = StateNotifierProvider<MoodPredictionNotifier, MoodPredictionState>((ref) {
  return MoodPredictionNotifier(ref.watch(moodPredictionRepositoryProvider));
});

class MoodPredictionState {
  final List<MoodPrediction> predictions;
  final List<MoodPrediction> history;
  final bool isLoading;
  final String? error;

  MoodPredictionState({
    this.predictions = const [],
    this.history = const [],
    this.isLoading = false,
    this.error,
  });

  MoodPredictionState copyWith({
    List<MoodPrediction>? predictions,
    List<MoodPrediction>? history,
    bool? isLoading,
    String? error,
  }) {
    return MoodPredictionState(
      predictions: predictions ?? this.predictions,
      history: history ?? this.history,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class MoodPredictionNotifier extends StateNotifier<MoodPredictionState> {
  final MoodPredictionRepository _repository;

  MoodPredictionNotifier(this._repository) : super(MoodPredictionState()) {
    loadData();
  }

  Future<void> loadData() async {
    state = state.copyWith(isLoading: true);
    try {
      final predictions = await _repository.getUpcomingPredictions();
      final history = await _repository.getHistoryWithAccuracy();
      state = state.copyWith(predictions: predictions, history: history, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> generatePrediction() async {
    try {
      final prediction = await _repository.generatePrediction(DateTime.now());
      await _repository.insert(prediction);
      await loadData();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> recordActualMood(int actualMood) async {
    try {
      await _repository.recordActualMood(DateTime.now(), actualMood);
      await loadData();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

final predictionAccuracyProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return await ref.watch(moodPredictionRepositoryProvider).getPredictionAccuracy();
});

class MoodPredictionScreen extends ConsumerStatefulWidget {
  const MoodPredictionScreen({super.key});

  @override
  ConsumerState<MoodPredictionScreen> createState() => _MoodPredictionScreenState();
}

class _MoodPredictionScreenState extends ConsumerState<MoodPredictionScreen> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(moodPredictionProvider);
    final accuracyAsync = ref.watch(predictionAccuracyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mood Prediction'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Accuracy Stats
            accuracyAsync.when(
              data: (accuracy) => _buildAccuracyCard(accuracy),
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Error: $e'),
            ),
            const SizedBox(height: 16),

            // Today's Prediction
            _buildTodayPrediction(),
            const SizedBox(height: 16),

            // Upcoming Predictions
            Text('Upcoming Week', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...state.predictions.map((p) => _buildPredictionCard(p)),

            const SizedBox(height: 16),

            // History
            Text('Recent Predictions', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...state.history.take(10).map((h) => _buildHistoryItem(h)),

            const SizedBox(height: 16),

            // Generate New Prediction
            ElevatedButton.icon(
              onPressed: () => ref.read(moodPredictionProvider.notifier).generatePrediction(),
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Generate New Prediction'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccuracyCard(Map<String, dynamic> accuracy) {
    final avgAccuracy = (accuracy['avg_accuracy'] as num?)?.toDouble() ?? 0;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Prediction Accuracy', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            Text(
              '${avgAccuracy.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: avgAccuracy >= 80 ? Colors.green : avgAccuracy >= 60 ? Colors.blue : Colors.orange,
              ),
            ),
            const SizedBox(height: 8),
            Text('${accuracy['total_predictions'] ?? 0} predictions recorded'),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayPrediction() {
    final today = DateTime.now();
    final todayStr = today.toIso8601String().split('T')[0];
    final todayPred = ref.read(moodPredictionProvider).predictions
        .where((p) => p.predictedDate.toIso8601String().split('T')[0] == todayStr)
        .firstOrNull;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Today\'s Prediction', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            if (todayPred != null) ...[
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: todayPred.predictionColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Center(
                      child: Text(
                        '${todayPred.predictedMoodLevel}',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: todayPred.predictionColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(todayPred.predictionLabel, style: const TextStyle(fontSize: 24)),
                      Text('Confidence: ${(todayPred.confidenceScore * 100).toStringAsFixed(0)}%'),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (todayPred.factors.isNotEmpty)
                Wrap(
                  spacing: 8,
                  children: todayPred.factors.map((f) => Chip(label: Text(f))).toList(),
                ),
            ] else ...[
              const Text('No prediction for today. Generate one!'),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Actual mood: '),
                for (int i = 1; i <= 5; i++)
                  IconButton(
                    icon: Icon(
                      Icons.circle,
                      color: Colors.grey[400],
                      size: 20,
                    ),
                    onPressed: () {
                      ref.read(moodPredictionProvider.notifier).recordActualMood(i);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Recorded mood: $i')),
                      );
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPredictionCard(MoodPrediction prediction) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: prediction.predictionColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Text(
              '${prediction.predictedMoodLevel}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: prediction.predictionColor,
              ),
            ),
          ),
        ),
        title: Text(_formatDate(prediction.predictedDate)),
        subtitle: Text(prediction.predictionLabel),
        trailing: Text(
          '${(prediction.confidenceScore * 100).toStringAsFixed(0)}%',
          style: TextStyle(color: Colors.grey[600]),
        ),
      ),
    );
  }

  Widget _buildHistoryItem(MoodPrediction history) {
    final wasCorrect = history.predictionAccuracy != null && history.predictionAccuracy! >= 60;
    return ListTile(
      leading: Icon(
        wasCorrect ? Icons.check_circle : Icons.cancel,
        color: wasCorrect ? Colors.green : Colors.red,
      ),
      title: Text(_formatDate(history.predictedDate)),
      subtitle: Text(
        'Predicted: ${history.predictedMoodLevel} → Actual: ${history.actualMoodLevel ?? '?'}',
      ),
      trailing: history.predictionAccuracy != null
          ? Text('${history.predictionAccuracy!.toStringAsFixed(0)}%')
          : null,
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return 'Today';
    }
    if (date.year == now.year && date.month == now.month && date.day == now.day + 1) {
      return 'Tomorrow';
    }
    return '${date.month}/${date.day}';
  }
}