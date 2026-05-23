import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/mood_heatmap/data/mood_heatmap_repository.dart';
import 'package:thing_note/features/mood_heatmap/domain/mood_heatmap_data.dart';
import 'package:thing_note/l10n/generated/app_localizations.dart';

final moodHeatmapProvider = Provider((ref) => ref.watch(moodHeatmapRepositoryProvider));

class MoodHeatmapScreen extends ConsumerStatefulWidget {
  const MoodHeatmapScreen({super.key});

  @override
  ConsumerState<MoodHeatmapScreen> createState() => _MoodHeatmapScreenState();
}

class _MoodHeatmapScreenState extends ConsumerState<MoodHeatmapScreen> {
  int _selectedYear = DateTime.now().year;
  List<MoodHeatmapData> _data = [];
  Map<String, double> _monthlyAverages = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final repo = ref.read(moodHeatmapProvider);
    await repo.syncFromMoodEntries();
    _data = await repo.getByYear(_selectedYear);
    _monthlyAverages = await repo.getMonthlyAverages(_selectedYear);
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.moodHeatmap),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildYearSelector(),
                  const SizedBox(height: 16),
                  _buildYearOverview(),
                  const SizedBox(height: 16),
                  _buildHeatmapGrid(),
                  const SizedBox(height: 16),
                  _buildLegend(),
                ],
              ),
            ),
    );
  }

  Widget _buildYearSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () {
                setState(() => _selectedYear--);
                _loadData();
              },
            ),
            Text(
              '$_selectedYear',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () {
                setState(() => _selectedYear++);
                _loadData();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildYearOverview() {
    if (_monthlyAverages.isEmpty) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.sentiment_neutral, size: 48, color: Colors.grey),
            SizedBox(height: 8),
            Text('还没有情绪数据'),
            SizedBox(height: 8),
            Text('记录你的情绪后会显示年度概览'),
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
            Text('月度情绪平均', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            SizedBox(
              height: 80,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(12, (month) {
                  final avg = _monthlyAverages[month.toString()] ?? 0.0;
                  return Column(
                    children: [
                      Container(
                        width: 20,
                        height: 50 * (avg / 5),
                        decoration: BoxDecoration(
                          color: _getMoodColor(avg.round()),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('$month', style: Theme.of(context).textTheme.bodySmall),
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

  Widget _buildHeatmapGrid() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('情绪热力图', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
              ),
              itemCount: 365,
              itemBuilder: (context, index) {
                final dayOfYear = index + 1;
                final date = DateTime(_selectedYear).add(Duration(days: dayOfYear - 1));
                if (date.year != _selectedYear) {
                  return const SizedBox();
                }

                final entry = _data.where((e) =>
                    e.month == date.month && e.day == date.day).firstOrNull;
                final moodLevel = entry?.moodLevel ?? 0;

                return Container(
                  decoration: BoxDecoration(
                    color: moodLevel > 0
                        ? _getMoodColor(moodLevel).withOpacity(0.5)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Center(
                    child: Text(
                      '${date.day}',
                      style: TextStyle(
                        fontSize: 8,
                        color: moodLevel > 0 ? Colors.white : Colors.grey,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('情绪等级', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _LegendItem(color: Colors.red, label: '很差'),
                _LegendItem(color: Colors.orange, label: '较差'),
                _LegendItem(color: Colors.yellow, label: '一般'),
                _LegendItem(color: Colors.lightGreen, label: '不错'),
                _LegendItem(color: Colors.green, label: '很好'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getMoodColor(int level) {
    switch (level) {
      case 1: return Colors.red;
      case 2: return Colors.orange;
      case 3: return Colors.yellow;
      case 4: return Colors.lightGreen;
      case 5: return Colors.green;
      default: return Colors.grey;
    }
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}