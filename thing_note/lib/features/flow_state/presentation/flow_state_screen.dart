import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/flow_state/data/flow_state_repository.dart';
import 'package:thing_note/features/flow_state/domain/flow_state.dart';

class FlowStateScreen extends ConsumerStatefulWidget {
  const FlowStateScreen({super.key});

  @override
  ConsumerState<FlowStateScreen> createState() => _FlowStateScreenState();
}

class _FlowStateScreenState extends ConsumerState<FlowStateScreen> {
  bool _isFlowActive = false;
  DateTime? _flowStartTime;
  int _distractionCount = 0;
  int _elapsedSeconds = 0;
  Timer? _timer;

  Map<String, dynamic> _todayStats = {};
  List<FlowState> _recentFlowStates = [];
  FlowState? _activeFlowState;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    final repo = ref.read(flowStateRepositoryProvider);
    _todayStats = await repo.getTodayStats();
    _recentFlowStates = await repo.getTodayFlowStates();
    _activeFlowState = await repo.getActiveFlowState();

    if (_activeFlowState != null) {
      _isFlowActive = true;
      _flowStartTime = _activeFlowState!.startedAt;
      _distractionCount = _activeFlowState!.distractionCount;
      _elapsedSeconds = DateTime.now().difference(_flowStartTime!).inSeconds;
      _startTimer();
    }

    if (mounted) setState(() {});
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && _isFlowActive) {
        setState(() {
          _elapsedSeconds++;
        });
      }
    });
  }

  void _startFlow() {
    setState(() {
      _isFlowActive = true;
      _flowStartTime = DateTime.now();
      _distractionCount = 0;
      _elapsedSeconds = 0;
    });
    _startTimer();
  }

  void _addDistraction() {
    if (!_isFlowActive) return;
    setState(() {
      _distractionCount++;
    });
  }

  Future<void> _endFlow() async {
    if (!_isFlowActive || _flowStartTime == null) return;

    final endTime = DateTime.now();
    final durationMinutes = endTime.difference(_flowStartTime!).inMinutes;

    // Show dialog to rate focus and add note
    final result = await _showEndFlowDialog(durationMinutes);
    if (result == null) return;

    final focusRating = result['rating'] as int;
    final note = result['note'] as String?;

    final flowState = FlowState(
      startedAt: _flowStartTime!,
      endedAt: endTime,
      durationMinutes: durationMinutes,
      focusRating: focusRating,
      distractionCount: _distractionCount,
      linkedRecordId: _activeFlowState?.linkedRecordId,
      note: note,
      createdAt: _activeFlowState?.createdAt ?? DateTime.now(),
    );

    final repo = ref.read(flowStateRepositoryProvider);

    if (_activeFlowState != null) {
      // Update existing active flow state
      await repo.update(flowState.copyWith(id: _activeFlowState!.id));
    } else {
      // Insert new completed flow state
      await repo.insert(flowState);
    }

    _timer?.cancel();
    setState(() {
      _isFlowActive = false;
      _flowStartTime = null;
      _distractionCount = 0;
      _elapsedSeconds = 0;
      _activeFlowState = null;
    });

    _loadData();
  }

  Future<Map<String, dynamic>?> _showEndFlowDialog(int durationMinutes) async {
    int selectedRating = 3;
    final noteController = TextEditingController();

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('结束心流'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('专注时长: ${_formatDuration(durationMinutes)}'),
            Text('分心次数: $_distractionCount次'),
            const SizedBox(height: 16),
            const Text('专注度评分'),
            const SizedBox(height: 8),
            StatefulBuilder(
              builder: (context, setDialogState) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final rating = index + 1;
                    return IconButton(
                      icon: Icon(
                        rating <= selectedRating
                            ? Icons.star
                            : Icons.star_border,
                        color: Colors.amber,
                        size: 32,
                      ),
                      onPressed: () {
                        setDialogState(() {
                          selectedRating = rating;
                        });
                      },
                    );
                  }),
                );
              },
            ),
            const SizedBox(height: 8),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                labelText: '会话备注',
                hintText: '记录本次心流的感受...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, {
              'rating': selectedRating,
              'note': noteController.text.isEmpty ? null : noteController.text,
            }),
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) {
      return '$minutes分钟';
    }
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    return '$hours小时${remainingMinutes > 0 ? '$remainingMinutes分钟' : ''}';
  }

  String _formatTimer(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('心流追踪'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => _showHistory(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStatsCard(),
            const SizedBox(height: 24),
            _buildFlowCard(),
            const SizedBox(height: 24),
            _buildRecentFlowStates(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    final sessionCount = _todayStats['sessionCount'] ?? 0;
    final totalMinutes = _todayStats['totalMinutes'] ?? 0;
    final avgFocusRating = (_todayStats['avgFocusRating'] ?? 0.0) as double;
    final totalDistractions = _todayStats['totalDistractions'] ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _StatItem(
              icon: Icons.check_circle,
              value: '$sessionCount',
              label: '会话数',
            ),
            _StatItem(
              icon: Icons.timer,
              value: totalMinutes >= 60
                  ? '${(totalMinutes / 60).toStringAsFixed(1)}h'
                  : '${totalMinutes}m',
              label: '总时长',
            ),
            _StatItem(
              icon: Icons.star,
              value: avgFocusRating > 0
                  ? avgFocusRating.toStringAsFixed(1)
                  : '-',
              label: '平均专注度',
            ),
            _StatItem(
              icon: Icons.notifications,
              value: '$totalDistractions',
              label: '分心次数',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlowCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            if (_isFlowActive) ...[
              Text(
                '心流进行中',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: 200,
                height: 200,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 200,
                      height: 200,
                      child: CircularProgressIndicator(
                        strokeWidth: 8,
                        backgroundColor: Colors.grey.withOpacity(0.3),
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(Colors.purple),
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _formatTimer(_elapsedSeconds),
                          style: Theme.of(context)
                              .textTheme
                              .displayMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        if (_distractionCount > 0)
                          Text(
                            '分心: $_distractionCount次',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FilledButton.icon(
                    onPressed: _addDistraction,
                    icon: const Icon(Icons.add_alert),
                    label: const Text('分心了'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton.icon(
                    onPressed: _endFlow,
                    icon: const Icon(Icons.stop),
                    label: const Text('结束'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                ],
              ),
            ] else ...[
              Text(
                '深度工作/心流状态',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                '记录你的专注时间和分心次数',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                    ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _startFlow,
                icon: const Icon(Icons.play_arrow, size: 28),
                label: const Text(
                  '开始心流',
                  style: TextStyle(fontSize: 18),
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRecentFlowStates() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '今日记录',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            if (_recentFlowStates.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('还没有心流记录'),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _recentFlowStates.length,
                itemBuilder: (context, index) {
                  final flow = _recentFlowStates[index];
                  return ListTile(
                    leading: Icon(
                      Icons.psychology,
                      color: _getRatingColor(flow.focusRating),
                    ),
                    title: Text(flow.focusRatingLabel),
                    subtitle: Text(
                      '${flow.formattedDuration} | 分心${flow.distractionCount}次',
                    ),
                    trailing: Text(_formatTime(flow.startedAt)),
                    onTap: () => _showFlowDetail(flow),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Color _getRatingColor(int rating) {
    switch (rating) {
      case 1:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.yellow.shade700;
      case 4:
        return Colors.lightGreen;
      case 5:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showFlowDetail(FlowState flow) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '心流详情',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.timer, color: Colors.purple),
              title: const Text('专注时长'),
              trailing: Text(flow.formattedDuration),
            ),
            ListTile(
              leading: const Icon(Icons.star, color: Colors.amber),
              title: const Text('专注度'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...List.generate(
                    5,
                    (index) => Icon(
                      index < flow.focusRating
                          ? Icons.star
                          : Icons.star_border,
                      color: Colors.amber,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.notifications, color: Colors.orange),
              title: const Text('分心次数'),
              trailing: Text('${flow.distractionCount}次'),
            ),
            ListTile(
              leading: const Icon(Icons.access_time, color: Colors.blue),
              title: const Text('开始时间'),
              trailing: Text(_formatDateTime(flow.startedAt)),
            ),
            if (flow.endedAt != null)
              ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: const Text('结束时间'),
                trailing: Text(_formatDateTime(flow.endedAt!)),
              ),
            if (flow.note != null && flow.note!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '备注',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(flow.note!),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showHistory() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '今日统计',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.check_circle, color: Colors.green),
              title: const Text('完成会话'),
              trailing: Text('${_todayStats['sessionCount'] ?? 0}'),
            ),
            ListTile(
              leading: const Icon(Icons.timer, color: Colors.purple),
              title: const Text('总时长'),
              trailing: Text(
                _formatDuration(_todayStats['totalMinutes'] ?? 0),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.star, color: Colors.amber),
              title: const Text('平均专注度'),
              trailing: Text(
                (_todayStats['avgFocusRating'] ?? 0.0).toStringAsFixed(1),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.notifications, color: Colors.orange),
              title: const Text('分心次数'),
              trailing: Text('${_todayStats['totalDistractions'] ?? 0}'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 28, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}