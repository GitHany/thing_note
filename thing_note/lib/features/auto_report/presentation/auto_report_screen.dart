import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/auto_report/data/auto_report_service.dart';
import 'package:thing_note/features/auto_report/domain/report_config.dart';

class AutoReportScreen extends ConsumerStatefulWidget {
  const AutoReportScreen({super.key});

  @override
  ConsumerState<AutoReportScreen> createState() => _AutoReportScreenState();
}

class _AutoReportScreenState extends ConsumerState<AutoReportScreen> {
  ReportType _selectedType = ReportType.weekly;
  DateTimeRange? _dateRange;
  GeneratedReport? _report;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _initializeDateRange();
  }

  void _initializeDateRange() {
    final now = DateTime.now();
    _dateRange = DateTimeRange(
      start: now.subtract(const Duration(days: 7)),
      end: now,
    );
  }

  Future<void> _generateReport() async {
    if (_dateRange == null) return;

    setState(() => _isGenerating = true);

    try {
      final service = ref.read(autoReportServiceProvider);
      final config = ReportConfig(
        type: _selectedType,
        startDate: _dateRange!.start,
        endDate: _dateRange!.end,
      );

      // For now, generate with empty data - in production would fetch from DB
      final report = await service.generateReport(
        config: config,
        records: [],
        thingNames: [],
        tags: [],
      );

      setState(() => _report = report);
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auto Report'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Report type selection
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Report Type',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: ReportType.values.map((type) {
                        return ChoiceChip(
                          label: Text(_getTypeLabel(type)),
                          selected: _selectedType == type,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedType = type;
                                _applyDatePreset(type);
                              });
                            }
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Date range selection
            Card(
              child: ListTile(
                leading: const Icon(Icons.date_range),
                title: const Text('Date Range'),
                subtitle: _dateRange != null
                    ? Text(
                        '${_dateRange!.start.month}/${_dateRange!.start.day} - ${_dateRange!.end.month}/${_dateRange!.end.day}')
                    : const Text('Select range'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final range = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                    initialDateRange: _dateRange,
                  );
                  if (range != null) {
                    setState(() => _dateRange = range);
                  }
                },
              ),
            ),
            const SizedBox(height: 16),

            // Generate button
            FilledButton.icon(
              onPressed: _isGenerating ? null : _generateReport,
              icon: _isGenerating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome),
              label: Text(_isGenerating ? 'Generating...' : 'Generate Report'),
            ),
            const SizedBox(height: 24),

            // Generated report
            if (_report != null) _buildReportView(),
          ],
        ),
      ),
    );
  }

  Widget _buildReportView() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _report!.title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Divider(),
            Text(_report!.content),
            if (_report!.statistics.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Statistics',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ..._report!.statistics.entries.map((e) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(e.key),
                        Text(e.value.toString(),
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  )),
            ],
            if (_report!.insights.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Insights',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ..._report!.insights.map((insight) => ListTile(
                    leading: const Icon(Icons.lightbulb, color: Colors.amber),
                    title: Text(insight),
                    contentPadding: EdgeInsets.zero,
                  )),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () {
                    // Share report
                  },
                  icon: const Icon(Icons.share),
                  label: const Text('Share'),
                ),
                TextButton.icon(
                  onPressed: () {
                    // Export report
                  },
                  icon: const Icon(Icons.download),
                  label: const Text('Export'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getTypeLabel(ReportType type) {
    switch (type) {
      case ReportType.daily:
        return 'Daily';
      case ReportType.weekly:
        return 'Weekly';
      case ReportType.monthly:
        return 'Monthly';
      case ReportType.custom:
        return 'Custom';
    }
  }

  void _applyDatePreset(ReportType type) {
    final now = DateTime.now();
    setState(() {
      switch (type) {
        case ReportType.daily:
          _dateRange = DateTimeRange(start: now, end: now);
          break;
        case ReportType.weekly:
          _dateRange = DateTimeRange(
            start: now.subtract(const Duration(days: 7)),
            end: now,
          );
          break;
        case ReportType.monthly:
          _dateRange = DateTimeRange(
            start: DateTime(now.year, now.month, 1),
            end: now,
          );
          break;
        case ReportType.custom:
          break;
      }
    });
  }
}