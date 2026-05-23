import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/time_analysis/data/time_analysis_repository.dart';
import 'package:thing_note/features/time_analysis/domain/time_analysis_record.dart';
import 'package:thing_note/l10n/generated/app_localizations.dart';

final timeAnalysisProvider = Provider((ref) => ref.watch(timeAnalysisRepositoryProvider));

class TimeAnalysisScreen extends ConsumerStatefulWidget {
  const TimeAnalysisScreen({super.key});

  @override
  ConsumerState<TimeAnalysisScreen> createState() => _TimeAnalysisScreenState();
}

class _TimeAnalysisScreenState extends ConsumerState<TimeAnalysisScreen> {
  List<TimeAnalysisRecord> _records = [];
  Map<String, int> _distribution = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final repo = ref.read(timeAnalysisProvider);
    _records = await repo.getRecent(7);
    _distribution = await repo.getTimeDistribution(30);
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.timeAnalysis),
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
                  _buildTimeDistribution(),
                  const SizedBox(height: 16),
                  _buildPeakTimeCard(),
                  const SizedBox(height: 16),
                  _buildWeeklyTrend(),
                  const SizedBox(height: 16),
                  _buildInsights(),
                ],
              ),
            ),
    );
  }

  Widget _buildTimeDistribution() {
    final total = _distribution.values.fold(0, (a, b) => a + b);
    if (total == 0) return const SizedBox();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.schedule, color: Colors.blue),
                const SizedBox(width: 8),
                Text('时间分布（近30天）', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 16),
            _buildDistributionBar('上午 (6-11)', _distribution['morning'] ?? 0, total, Colors.orange),
            _buildDistributionBar('下午 (12-17)', _distribution['afternoon'] ?? 0, total, Colors.blue),
            _buildDistributionBar('晚上 (18-23)', _distribution['evening'] ?? 0, total, Colors.purple),
            _buildDistributionBar('深夜 (0-5)', _distribution['night'] ?? 0, total, Colors.indigo),
          ],
        ),
      ),
    );
  }

  Widget _buildDistributionBar(String label, int count, int total, Color color) {
    final percentage = total > 0 ? (count / total * 100).round() : 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(label)),
          Expanded(
            child: Container(
              height: 20,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: percentage / 100,
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: Text('$count ($percentage%)', textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }

  Widget _buildPeakTimeCard() {
    final counts = _distribution.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final peakTime = counts.isNotEmpty && counts.first.value > 0 ? counts.first.key : null;

    String peakLabel;
    switch (peakTime) {
      case 'morning':
        peakLabel = '上午 (6-11点)';
        break;
      case 'afternoon':
        peakLabel = '下午 (12-17点)';
        break;
      case 'evening':
        peakLabel = '晚上 (18-23点)';
        break;
      case 'night':
        peakLabel = '深夜 (0-5点)';
        break;
      default:
        peakLabel = '暂无数据';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(Icons.trending_up, size: 48, color: Colors.amber),
            const SizedBox(height: 8),
            Text(
              '最佳活跃时段',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              peakLabel,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '大多数记录在这个时间段产生',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyTrend() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.show_chart, color: Colors.green),
                const SizedBox(width: 8),
                Text('本周趋势', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 16),
            if (_records.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('暂无数据'),
                ),
              )
            else
              SizedBox(
                height: 150,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: _records.take(7).toList().reversed.map((record) {
                    final maxHeight = _records.map((r) => r.totalRecords).reduce((a, b) => a > b ? a : b);
                    final height = maxHeight > 0 ? (record.totalRecords / maxHeight * 100) : 0.0;

                    return Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          width: 30,
                          height: height.toDouble(),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          record.date.substring(5),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsights() {
    final total = _distribution.values.fold(0, (a, b) => a + b);
    if (total == 0) return const SizedBox();

    String insight;
    final evening = _distribution['evening'] ?? 0;
    final morning = _distribution['morning'] ?? 0;

    if (evening > morning * 2) {
      insight = '🌙 你是个夜猫子！大多数记录在晚上产生。';
    } else if (morning > evening) {
      insight = '☀️ 你是个早起的人！大多数记录在上午产生。';
    } else {
      insight = '⚖️ 你的记录分布比较均匀，全天都很活跃。';
    }

    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lightbulb_outline),
                const SizedBox(width: 8),
                Text('智能洞察', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            Text(insight, style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}