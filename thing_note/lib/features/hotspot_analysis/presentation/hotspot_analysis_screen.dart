import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:thing_note/features/hotspot_analysis/data/hotspot_analysis_service.dart';
import 'package:thing_note/features/hotspot_analysis/domain/hotspot_analysis.dart';

class HotspotAnalysisScreen extends ConsumerStatefulWidget {
  const HotspotAnalysisScreen({super.key});

  @override
  ConsumerState<HotspotAnalysisScreen> createState() =>
      _HotspotAnalysisScreenState();
}

class _HotspotAnalysisScreenState extends ConsumerState<HotspotAnalysisScreen> {
  HotspotAnalysis? _analysis;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _analyze();
  }

  Future<void> _analyze() async {
    setState(() => _isLoading = true);

    try {
      final service = ref.read(hotspotAnalysisServiceProvider);
      // In production, fetch records from database
      final analysis = await service.analyzeHotspots([]);
      setState(() => _analysis = analysis);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hotspot Analysis'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _analyze,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _analysis == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.location_off, size: 64),
                      const SizedBox(height: 16),
                      const Text('Not enough data to analyze'),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _analyze,
                        child: const Text('Analyze Now'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Pattern summary
                      if (_analysis!.dominantPattern != null)
                        Card(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          child: ListTile(
                            leading: const Icon(Icons.auto_awesome),
                            title: Text(_analysis!.dominantPattern!),
                            subtitle: const Text('Based on your recording patterns'),
                          ),
                        ),
                      const SizedBox(height: 16),

                      // Time hotspots chart
                      Text(
                        'Recording Time Distribution',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 200,
                        child: _buildTimeChart(),
                      ),
                      const SizedBox(height: 24),

                      // Location hotspots
                      if (_analysis!.locations.isNotEmpty) ...[
                        Text(
                          'Favorite Locations',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        ...(_analysis!.locations.take(5).map((loc) => Card(
                              child: ListTile(
                                leading: CircleAvatar(
                                  child: Text('${loc.recordCount}'),
                                ),
                                title: Text(loc.address ?? 'Unknown location'),
                                subtitle: Text(
                                  '${loc.latitude.toStringAsFixed(3)}, '
                                  '${loc.longitude.toStringAsFixed(3)}',
                                ),
                              ),
                            ))),
                        const SizedBox(height: 24),
                      ],

                      // Suggestions
                      _buildSuggestions(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildTimeChart() {
    if (_analysis!.timeSlots.isEmpty) {
      return const Center(child: Text('No time data'));
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: _analysis!.timeSlots.first.recordCount.toDouble() * 1.2,
        barGroups: _analysis!.timeSlots.map((slot) {
          return BarChartGroupData(
            x: slot.hour,
            barRods: [
              BarChartRodData(
                toY: slot.recordCount.toDouble(),
                color: Theme.of(context).colorScheme.primary,
                width: 16,
              ),
            ],
          );
        }).toList(),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final hour = value.toInt();
                return Text(
                  '${hour}h',
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
      ),
    );
  }

  Widget _buildSuggestions() {
    final service = ref.read(hotspotAnalysisServiceProvider);
    final suggestions = service.generateSuggestions(_analysis!);

    if (suggestions.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lightbulb, color: Colors.amber),
                const SizedBox(width: 8),
                Text(
                  'Suggestions',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...suggestions.map((s) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text('• $s'),
                )),
          ],
        ),
      ),
    );
  }
}