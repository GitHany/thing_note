import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/momentum_models.dart';
import '../data/momentum_repository.dart';

final momentumProvider = StateNotifierProvider<MomentumNotifier, MomentumState>((ref) {
  return MomentumNotifier(ref.watch(momentumRepositoryProvider));
});

class MomentumState {
  final List<GoalMomentum> momenta;
  final List<GoalMomentum> atRisk;
  final bool isLoading;
  final String? error;

  MomentumState({this.momenta = const [], this.atRisk = const [], this.isLoading = false, this.error});

  MomentumState copyWith({List<GoalMomentum>? momenta, List<GoalMomentum>? atRisk, bool? isLoading, String? error}) {
    return MomentumState(
      momenta: momenta ?? this.momenta,
      atRisk: atRisk ?? this.atRisk,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class MomentumNotifier extends StateNotifier<MomentumState> {
  final MomentumRepository _repository;

  MomentumNotifier(this._repository) : super(MomentumState()) {
    loadData();
  }

  Future<void> loadData() async {
    state = state.copyWith(isLoading: true);
    try {
      final momenta = await _repository.getAllMomentum();
      final atRisk = await _repository.getAtRiskMomentum();
      state = state.copyWith(momenta: momenta, atRisk: atRisk, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }
}

class GoalMomentumScreen extends ConsumerWidget {
  const GoalMomentumScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final momentumState = ref.watch(momentumProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Goal Momentum'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: momentumState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // At Risk Section
                  if (momentumState.atRisk.isNotEmpty) ...[
                    _buildAtRiskSection(context, momentumState.atRisk),
                    const SizedBox(height: 16),
                  ],

                  // All Momentum
                  Text('All Goals', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  ...momentumState.momenta.map((m) => _buildMomentumCard(context, m)),
                  
                  if (momentumState.momenta.isEmpty)
                    const Center(child: Text('No goal momentum data yet')),
                ],
              ),
            ),
    );
  }

  Widget _buildAtRiskSection(BuildContext context, List<GoalMomentum> atRisk) {
    return Card(
      color: Colors.red.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning, color: Colors.red),
                const SizedBox(width: 8),
                Text('At Risk (${atRisk.length})', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 8),
            ...atRisk.take(3).map((m) => ListTile(
              leading: CircularProgressIndicator(
                value: m.momentumScore / 100,
                color: Colors.red,
              ),
              title: Text('Goal #${m.goalId}'),
              subtitle: Text(m.momentumLabel),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildMomentumCard(BuildContext context, GoalMomentum momentum) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Goal #${momentum.goalId}', style: Theme.of(context).textTheme.titleMedium),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: momentum.momentumColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    momentum.momentumLabel,
                    style: TextStyle(color: momentum.momentumColor, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: momentum.momentumScore / 100,
              backgroundColor: Colors.grey[300],
              color: momentum.momentumColor,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatColumn('Streak', '${momentum.streakDays}', 'days'),
                _buildStatColumn('Weekly', '${momentum.weeklyProgress.toStringAsFixed(1)}%', 'progress'),
                _buildStatColumn('Accel', momentum.accelerationScore.toStringAsFixed(1), ''),
              ],
            ),
            if (momentum.riskFactors.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                children: momentum.riskFactors.map((f) => Chip(
                  label: Text(f, style: const TextStyle(fontSize: 10)),
                  backgroundColor: Colors.orange.withOpacity(0.2),
                )).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, String unit) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text('$label $unit', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      ],
    );
  }
}