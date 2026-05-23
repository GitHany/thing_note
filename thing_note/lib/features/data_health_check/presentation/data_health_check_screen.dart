import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/core/database/database_provider.dart';
import 'package:thing_note/features/data_health_check/data/data_health_check_service.dart';
import 'package:thing_note/features/data_health_check/domain/health_issue.dart';

final dataHealthCheckServiceProvider = FutureProvider<DataHealthCheckService>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  return DataHealthCheckService(db);
});

class DataHealthCheckScreen extends ConsumerStatefulWidget {
  const DataHealthCheckScreen({super.key});

  @override
  ConsumerState<DataHealthCheckScreen> createState() =>
      _DataHealthCheckScreenState();
}

class _DataHealthCheckScreenState extends ConsumerState<DataHealthCheckScreen> {
  DataHealthStatus? _status;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    _runCheck();
  }

  Future<void> _runCheck() async {
    setState(() => _isChecking = true);

    try {
      final service = await ref.read(dataHealthCheckServiceProvider.future);
      final status = await service.runHealthCheck();
      setState(() => _status = status);
    } finally {
      setState(() => _isChecking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Health Check'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isChecking ? null : _runCheck,
          ),
        ],
      ),
      body: _isChecking
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Checking data health...'),
                ],
              ),
            )
          : _status == null
              ? Center(
                  child: FilledButton(
                    onPressed: _runCheck,
                    child: const Text('Run Health Check'),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _runCheck,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Health summary card
                      Card(
                        color: _status!.isHealthy
                            ? Colors.green.shade50
                            : Colors.orange.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Icon(
                                _status!.isHealthy
                                    ? Icons.check_circle
                                    : Icons.warning,
                                size: 48,
                                color: _status!.isHealthy
                                    ? Colors.green
                                    : Colors.orange,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _status!.isHealthy
                                    ? 'All Data Healthy'
                                    : 'Issues Found',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${_status!.healthyRecords}/${_status!.totalRecords} records healthy',
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Last checked: ${_status!.lastChecked}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Critical issues
                      if (_status!.criticalIssues.isNotEmpty) ...[
                        _buildIssueSection(
                          context,
                          'Critical Issues',
                          _status!.criticalIssues,
                          Colors.red,
                          Icons.error,
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Warnings
                      if (_status!.warnings.isNotEmpty) ...[
                        _buildIssueSection(
                          context,
                          'Warnings',
                          _status!.warnings,
                          Colors.orange,
                          Icons.warning,
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Info
                      if (_status!.infoMessages.isNotEmpty) ...[
                        _buildIssueSection(
                          context,
                          'Information',
                          _status!.infoMessages,
                          Colors.blue,
                          Icons.info,
                        ),
                      ],

                      if (_status!.issueCount == 0) ...[
                        const SizedBox(height: 32),
                        const Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.verified,
                                size: 64,
                                color: Colors.green,
                              ),
                              SizedBox(height: 16),
                              Text('Your data looks great!'),
                              SizedBox(height: 8),
                              Text(
                                'No issues detected.',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _buildIssueSection(
    BuildContext context,
    String title,
    List<HealthIssue> issues,
    Color color,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 8),
            Text(
              '$title (${issues.length})',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...issues.map((issue) => Card(
              child: ListTile(
                title: Text(issue.title),
                subtitle: Text(issue.description),
                trailing: issue.canAutoFix
                    ? TextButton(
                        onPressed: () async {
                          final service = await ref
                              .read(dataHealthCheckServiceProvider.future);
                          await service.fixIssue(issue);
                          _runCheck();
                        },
                        child: const Text('Fix'),
                      )
                    : null,
              ),
            )),
      ],
    );
  }
}