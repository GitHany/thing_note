import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/energy_models.dart';
import '../data/energy_repository.dart';

final energyProvider = StateNotifierProvider<EnergyNotifier, EnergyState>((ref) {
  return EnergyNotifier(ref.watch(energyRepositoryProvider));
});

class EnergyState {
  final List<EnergyPattern> patterns;
  final bool isLoading;
  final String? error;

  EnergyState({this.patterns = const [], this.isLoading = false, this.error});

  EnergyState copyWith({List<EnergyPattern>? patterns, bool? isLoading, String? error}) {
    return EnergyState(
      patterns: patterns ?? this.patterns,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class EnergyNotifier extends StateNotifier<EnergyState> {
  final EnergyRepository _repository;

  EnergyNotifier(this._repository) : super(EnergyState()) {
    loadPatterns();
  }

  Future<void> loadPatterns() async {
    state = state.copyWith(isLoading: true);
    try {
      final patterns = await _repository.getAllPatterns();
      state = state.copyWith(patterns: patterns, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> logEnergy(EnergyPattern pattern) async {
    try {
      await _repository.insert(pattern);
      await loadPatterns();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

final peakTimesProvider = FutureProvider<List<PeakEnergyTime>>((ref) async {
  return await ref.watch(energyRepositoryProvider).getPeakTimes();
});

class EnergyPatternsScreen extends ConsumerStatefulWidget {
  const EnergyPatternsScreen({super.key});

  @override
  ConsumerState<EnergyPatternsScreen> createState() => _EnergyPatternsScreenState();
}

class _EnergyPatternsScreenState extends ConsumerState<EnergyPatternsScreen> {
  int _currentHour = DateTime.now().hour;
  int _energyLevel = 3;
  int _dayOfWeek = DateTime.now().weekday;

  @override
  Widget build(BuildContext context) {
    final energyState = ref.watch(energyProvider);
    final peakTimesAsync = ref.watch(peakTimesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Energy Patterns'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Peak Times
            peakTimesAsync.when(
              data: (times) => _buildPeakTimes(times),
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Error: $e'),
            ),
            const SizedBox(height: 16),

            // Energy Timeline
            _buildEnergyTimeline(energyState.patterns),
            const SizedBox(height: 16),

            // Log Current Energy
            _buildLogForm(),
          ],
        ),
      ),
    );
  }

  Widget _buildPeakTimes(List<PeakEnergyTime> times) {
    if (times.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(Icons.insights, size: 48, color: Colors.grey),
              SizedBox(height: 8),
              Text('Log more energy data to see patterns'),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your Peak Hours', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            ...times.asMap().entries.map((e) {
              final index = e.key;
              final time = e.value;
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getPeakColor(index),
                  child: Text('${index + 1}'),
                ),
                title: Text('${_formatHour(time.hour)} - ${time.avgEnergy.toStringAsFixed(1)} energy'),
                subtitle: Text(time.recommendation),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildEnergyTimeline(List<EnergyPattern> patterns) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('24-Hour Energy Map', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            SizedBox(
              height: 100,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(24, (hour) {
                  final pattern = patterns.where((p) => p.hourOfDay == hour).firstOrNull;
                  final energy = pattern?.energyLevel.toDouble() ?? 2;
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        width: 10,
                        height: energy * 18,
                        decoration: BoxDecoration(
                          color: _getEnergyColor(energy.toInt()),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        hour % 6 == 0 ? '$hour' : '',
                        style: const TextStyle(fontSize: 10),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Log Current Energy', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Hour: '),
                Expanded(
                  child: Slider(
                    value: _currentHour.toDouble(),
                    min: 0,
                    max: 23,
                    divisions: 23,
                    label: _formatHour(_currentHour),
                    onChanged: (v) => setState(() => _currentHour = v.round()),
                  ),
                ),
                Text(_formatHour(_currentHour)),
              ],
            ),
            Row(
              children: [
                const Text('Day: '),
                Expanded(
                  child: Slider(
                    value: _dayOfWeek.toDouble(),
                    min: 1,
                    max: 7,
                    divisions: 6,
                    label: _getDayName(_dayOfWeek),
                    onChanged: (v) => setState(() => _dayOfWeek = v.round()),
                  ),
                ),
                Text(_getDayName(_dayOfWeek)),
              ],
            ),
            Row(
              children: [
                const Text('Energy Level: '),
                Expanded(
                  child: Slider(
                    value: _energyLevel.toDouble(),
                    min: 1,
                    max: 5,
                    divisions: 4,
                    label: '$_energyLevel',
                    onChanged: (v) => setState(() => _energyLevel = v.round()),
                  ),
                ),
                Text('$_energyLevel'),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _logEnergy,
              child: const Text('Log Energy'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatHour(int hour) {
    if (hour == 0) return '12 AM';
    if (hour < 12) return '$hour AM';
    if (hour == 12) return '12 PM';
    return '${hour - 12} PM';
  }

  String _getDayName(int day) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[day - 1];
  }

  Color _getEnergyColor(int level) {
    switch (level) {
      case 5: return Colors.green;
      case 4: return Colors.lightGreen;
      case 3: return Colors.yellow;
      case 2: return Colors.orange;
      default: return Colors.red;
    }
  }

  Color _getPeakColor(int index) {
    switch (index) {
      case 0: return Colors.green;
      case 1: return Colors.blue;
      case 2: return Colors.orange;
      default: return Colors.grey;
    }
  }

  void _logEnergy() {
    final pattern = EnergyPattern(
      hourOfDay: _currentHour,
      dayOfWeek: _dayOfWeek,
      energyLevel: _energyLevel,
      lastRecorded: DateTime.now(),
    );
    ref.read(energyProvider.notifier).logEnergy(pattern);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Energy logged!')));
  }
}