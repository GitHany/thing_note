import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../domain/energy_record_model.dart';
import '../data/energy_management_repository.dart';

final allEnergyRecordsProvider = FutureProvider.autoDispose<List<EnergyRecord>>((ref) async {
  final repo = ref.watch(energyManagementRepositoryProvider);
  return await repo.getAllRecords();
});

final todayEnergyProvider = FutureProvider.autoDispose<EnergyRecord?>((ref) async {
  final repo = ref.watch(energyManagementRepositoryProvider);
  return await repo.getTodayRecord();
});

final energyStatsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final repo = ref.watch(energyManagementRepositoryProvider);
  return await repo.getStatistics();
});

class EnergyManagementScreen extends ConsumerStatefulWidget {
  const EnergyManagementScreen({super.key});

  @override
  ConsumerState<EnergyManagementScreen> createState() => _EnergyManagementScreenState();
}

class _EnergyManagementScreenState extends ConsumerState<EnergyManagementScreen> {
  int _currentEnergy = 5;
  Timer? _timer;
  // ignore: unused_field
  final int _elapsedSeconds = 0;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(energyStatsProvider);
    final todayAsync = ref.watch(todayEnergyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Energy Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.insights),
            onPressed: () => _showEnergyInsights(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildCurrentEnergy(statsAsync),
            const SizedBox(height: 24),
            _buildQuickRecord(),
            const SizedBox(height: 24),
            _buildTodaySummary(todayAsync),
            const SizedBox(height: 24),
            _buildRecentRecords(),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentEnergy(AsyncValue<Map<String, dynamic>> statsAsync) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              'Current Energy Level',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: _getEnergyColor(_currentEnergy),
                  width: 8,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$_currentEnergy',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: _getEnergyColor(_currentEnergy),
                      ),
                    ),
                    Text(
                      '/ 10',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _getEnergyLabel(_currentEnergy),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _getEnergyColor(_currentEnergy),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(10, (index) {
                final level = index + 1;
                return GestureDetector(
                  onTap: () => setState(() => _currentEnergy = level),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: level <= _currentEnergy
                          ? _getEnergyColor(_currentEnergy)
                          : Colors.grey[300],
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickRecord() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.flash_on, color: Colors.amber),
                SizedBox(width: 8),
                Text(
                  'Quick Record',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildQuickButton('Boost', Icons.rocket_launch, Colors.green, () {
                  _recordEnergy(_currentEnergy, trigger: 'boost');
                }),
                _buildQuickButton('Food', Icons.restaurant, Colors.orange, () {
                  _recordEnergy(_currentEnergy, trigger: 'food');
                }),
                _buildQuickButton('Rest', Icons.bedtime, Colors.blue, () {
                  _recordEnergy(_currentEnergy, trigger: 'rest');
                }),
                _buildQuickButton('Exercise', Icons.fitness_center, Colors.purple, () {
                  _recordEnergy(_currentEnergy, trigger: 'exercise');
                }),
                _buildQuickButton('Coffee', Icons.coffee, Colors.brown, () {
                  _recordEnergy(_currentEnergy, trigger: 'coffee');
                }),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showFullRecordDialog(context),
                icon: const Icon(Icons.add),
                label: const Text('Full Record'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildTodaySummary(AsyncValue<EnergyRecord?> todayAsync) {
    return todayAsync.when(
      data: (today) {
        if (today == null) {
          return const SizedBox.shrink();
        }
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.today, color: Colors.blue),
                    SizedBox(width: 8),
                    Text(
                      'Today\'s Summary',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSummaryItem('Current', today.energyLevel.toString(), Icons.flash_on),
                    _buildSummaryItem('Average', _calculateAverage().toStringAsFixed(1), Icons.analytics),
                    _buildSummaryItem('Records', _getRecordCount().toString(), Icons.history),
                  ],
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      ],
    );
  }

  Widget _buildRecentRecords() {
    final recordsAsync = ref.watch(allEnergyRecordsProvider);
    return recordsAsync.when(
      data: (records) {
        if (records.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.battery_charging_full, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text('No energy records yet', style: TextStyle(color: Colors.grey[600])),
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
                const Text(
                  'Recent Records',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ...records.take(5).map((record) => _buildRecordItem(record)),
              ],
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Text('Error: $e'),
    );
  }

  Widget _buildRecordItem(EnergyRecord record) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getEnergyColor(record.energyLevel).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '${record.energyLevel}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _getEnergyColor(record.energyLevel),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getEnergyLabel(record.energyLevel),
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                if (record.trigger != null)
                  Text(
                    record.trigger!,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
              ],
            ),
          ),
          Text(
            _formatTime(record.recordedAt),
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
          ),
        ],
      ),
    );
  }

  void _showFullRecordDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Record Energy'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Energy Level: $_currentEnergy',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(labelText: 'Activity (optional)'),
            ),
            const SizedBox(height: 12),
            const TextField(
              decoration: InputDecoration(labelText: 'Note (optional)'),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _recordEnergy(_currentEnergy);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showEnergyInsights(BuildContext context) {
    final statsAsync = ref.read(energyStatsProvider);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Energy Insights',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(),
            Expanded(
              child: statsAsync.when(
                data: (stats) => SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInsightCard('Average Energy', '${stats['avg_energy']}', '📊'),
                      _buildInsightCard('Total Records', '${stats['total_records']}', '📝'),
                      _buildInsightCard('Best Time', stats['best_hour'] ?? 'N/A', '⏰'),
                      _buildInsightCard('Peak Energy', '${stats['peak_energy']}', '🔋'),
                    ],
                  ),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => Center(child: Text('Error: $e')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightCard(String title, String value, String emoji) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: Colors.grey[600])),
                Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _recordEnergy(int level, {String? trigger}) async {
    final repo = ref.read(energyManagementRepositoryProvider);
    final now = DateTime.now().toIso8601String();
    final record = EnergyRecord(
      recordedAt: now,
      energyLevel: level,
      trigger: trigger,
      createdAt: now,
    );
    await repo.insertRecord(record);
    ref.invalidate(allEnergyRecordsProvider);
    ref.invalidate(todayEnergyProvider);
    ref.invalidate(energyStatsProvider);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Energy recorded!'), backgroundColor: Colors.green),
      );
    }
  }

  Color _getEnergyColor(int level) {
    if (level >= 8) return Colors.green;
    if (level >= 6) return Colors.lightGreen;
    if (level >= 4) return Colors.yellow;
    if (level >= 2) return Colors.orange;
    return Colors.red;
  }

  String _getEnergyLabel(int level) {
    if (level >= 9) return 'Energized';
    if (level >= 7) return 'Good';
    if (level >= 5) return 'Moderate';
    if (level >= 3) return 'Low';
    return 'Exhausted';
  }

  String _formatTime(String isoTime) {
    final dt = DateTime.parse(isoTime);
    return '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }

  int _calculateAverage() => _currentEnergy;

  int _getRecordCount() => 1;
}