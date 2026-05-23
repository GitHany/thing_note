import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/idle_detector/domain/idle_time_record.dart';
import 'package:thing_note/features/idle_detector/data/idle_detector_repository.dart';

/// Provider for idle detector state
final idleDetectorProvider =
    StateNotifierProvider<IdleDetectorNotifier, IdleDetectorState>((ref) {
  final repository = ref.watch(idleDetectorRepositoryProvider);
  return IdleDetectorNotifier(repository);
});

/// State for the idle detector
class IdleDetectorState {
  final List<IdleTimeRecord> records;
  final IdleTimeStats stats;
  final bool isLoading;
  final String? error;
  final IdleTimeRecord? activeIdle;

  IdleDetectorState({
    this.records = const [],
    IdleTimeStats? stats,
    this.isLoading = false,
    this.error,
    this.activeIdle,
  }) : stats = stats ?? IdleTimeStats();

  IdleDetectorState copyWith({
    List<IdleTimeRecord>? records,
    IdleTimeStats? stats,
    bool? isLoading,
    String? error,
    IdleTimeRecord? activeIdle,
    bool clearActiveIdle = false,
  }) {
    return IdleDetectorState(
      records: records ?? this.records,
      stats: stats ?? this.stats,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      activeIdle: clearActiveIdle ? null : (activeIdle ?? this.activeIdle),
    );
  }
}

/// Notifier for managing idle detector state
class IdleDetectorNotifier extends StateNotifier<IdleDetectorState> {
  final IdleDetectorRepository _repository;

  IdleDetectorNotifier(this._repository) : super(IdleDetectorState()) {
    loadRecords();
  }

  Future<void> loadRecords() async {
    state = state.copyWith(isLoading: true);
    try {
      final records = await _repository.getAllRecords(limit: 50);
      final stats = await _repository.getStats();
      state = state.copyWith(
        records: records,
        stats: stats,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> startIdle(IdleType type) async {
    final record = IdleTimeRecord(
      startedAt: DateTime.now(),
      idleType: type,
      isProductive: type.isProductiveDefault,
    );

    try {
      final id = await _repository.insert(record);
      state = state.copyWith(
        activeIdle: record.copyWith(id: id),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> endIdle({
    String? reason,
    bool? isProductive,
  }) async {
    final active = state.activeIdle;
    if (active == null) return;

    final completed = active.copyWith(
      endedAt: DateTime.now(),
      durationMinutes: DateTime.now().difference(active.startedAt).inMinutes,
      reason: reason,
      isProductive: isProductive ?? active.isProductive,
    );

    try {
      await _repository.update(completed);
      state = state.copyWith(clearActiveIdle: true);
      await loadRecords();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteRecord(int id) async {
    try {
      await _repository.delete(id);
      await loadRecords();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> updateRecord(IdleTimeRecord record) async {
    try {
      await _repository.update(record);
      await loadRecords();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

/// Main screen for the Idle Time Detector
class IdleDetectorScreen extends ConsumerStatefulWidget {
  const IdleDetectorScreen({super.key});

  @override
  ConsumerState<IdleDetectorScreen> createState() =>
      _IdleDetectorScreenState();
}

class _IdleDetectorScreenState extends ConsumerState<IdleDetectorScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(idleDetectorProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Idle Time Detector'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Tracker'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTrackerTab(state),
          _buildHistoryTab(state),
        ],
      ),
    );
  }

  Widget _buildTrackerTab(IdleDetectorState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Active Idle Session
          if (state.activeIdle != null)
            _buildActiveSessionCard(state.activeIdle!)
          else
            _buildStartIdleCard(state),

          const SizedBox(height: 16),

          // Stats Summary
          _buildStatsCard(state.stats),

          const SizedBox(height: 16),

          // Type Breakdown
          _buildTypeBreakdown(state.stats),
        ],
      ),
    );
  }

  Widget _buildActiveSessionCard(IdleTimeRecord active) {
    final duration = DateTime.now().difference(active.startedAt);

    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              '${active.idleType.icon} ${active.idleType.displayName}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              _formatDuration(duration),
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton.icon(
                  onPressed: () => _showEndIdleDialog(active),
                  icon: const Icon(Icons.stop),
                  label: const Text('End Session'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStartIdleCard(IdleDetectorState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.timer_outlined, size: 48, color: Colors.grey),
            const SizedBox(height: 8),
            const Text('No active idle session'),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: IdleType.values.map((type) {
                return ElevatedButton.icon(
                  onPressed: () => _startIdle(type),
                  icon: Text(type.icon),
                  label: Text(type.displayName),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard(IdleTimeStats stats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Statistics',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'Total Records',
                  '${stats.totalRecords}',
                  Icons.list,
                ),
                _buildStatItem(
                  'Total Minutes',
                  '${stats.totalMinutes}',
                  Icons.schedule,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'Average',
                  '${stats.averageMinutes.toStringAsFixed(1)} min',
                  Icons.analytics,
                ),
                _buildStatItem(
                  'Productive',
                  '${(stats.productiveRatio * 100).toStringAsFixed(0)}%',
                  Icons.check_circle,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey,
              ),
        ),
      ],
    );
  }

  Widget _buildTypeBreakdown(IdleTimeStats stats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Breakdown by Type',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            if (stats.totalRecords == 0)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No data yet'),
                ),
              )
            else
              ...IdleType.values.map((type) {
                final minutes = stats.minutesByType[type] ?? 0;
                final count = stats.countByType[type] ?? 0;
                final percentage = stats.totalMinutes > 0
                    ? (minutes / stats.totalMinutes * 100)
                    : 0.0;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(type.icon),
                          const SizedBox(width: 8),
                          Text(type.displayName),
                          const Spacer(),
                          Text('$count records'),
                          const SizedBox(width: 8),
                          Text('${minutes}min'),
                        ],
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: percentage / 100,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getTypeColor(type),
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTab(IdleDetectorState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.records.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No idle records yet'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.records.length,
      itemBuilder: (context, index) {
        final record = state.records[index];
        return _buildRecordCard(record);
      },
    );
  }

  Widget _buildRecordCard(IdleTimeRecord record) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getTypeColor(record.idleType).withOpacity(0.2),
          child: Text(
            record.idleType.icon,
            style: TextStyle(color: _getTypeColor(record.idleType)),
          ),
        ),
        title: Row(
          children: [
            Text(record.idleType.displayName),
            const SizedBox(width: 8),
            if (record.isProductive)
              const Icon(Icons.check_circle, color: Colors.green, size: 16),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_formatDateTime(record.startedAt)} - ${record.durationMinutes} min',
            ),
            if (record.reason != null && record.reason!.isNotEmpty)
              Text(
                record.reason!,
                style: const TextStyle(fontStyle: FontStyle.italic),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () => _confirmDelete(record),
        ),
      ),
    );
  }

  Color _getTypeColor(IdleType type) {
    switch (type) {
      case IdleType.unplanned:
        return Colors.grey;
      case IdleType.breakTime:
        return Colors.green;
      case IdleType.waiting:
        return Colors.orange;
      case IdleType.distracted:
        return Colors.red;
      case IdleType.rest:
        return Colors.blue;
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.month}/${dateTime.day} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _startIdle(IdleType type) {
    ref.read(idleDetectorProvider.notifier).startIdle(type);
  }

  void _showEndIdleDialog(IdleTimeRecord active) {
    final reasonController = TextEditingController();
    bool isProductive = active.isProductive;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('End Idle Session'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${active.idleType.icon} ${active.idleType.displayName}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Reason (optional)',
                  hintText: 'What were you doing?',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Was this productive?'),
                value: isProductive,
                onChanged: (v) => setState(() => isProductive = v),
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
                Navigator.pop(context);
                ref.read(idleDetectorProvider.notifier).endIdle(
                      reason: reasonController.text.isEmpty
                          ? null
                          : reasonController.text,
                      isProductive: isProductive,
                    );
              },
              child: const Text('End'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(IdleTimeRecord record) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Record'),
        content: const Text('Are you sure you want to delete this record?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(idleDetectorProvider.notifier).deleteRecord(record.id!);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}