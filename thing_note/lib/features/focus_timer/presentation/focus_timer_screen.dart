import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/focus_timer/data/focus_timer_repository.dart';
import 'package:thing_note/features/focus_timer/domain/focus_timer_session.dart';
import 'package:thing_note/l10n/generated/app_localizations.dart';

final focusTimerProvider = Provider((ref) => ref.watch(focusTimerRepositoryProvider));

class FocusTimerScreen extends ConsumerStatefulWidget {
  const FocusTimerScreen({super.key});

  @override
  ConsumerState<FocusTimerScreen> createState() => _FocusTimerScreenState();
}

class _FocusTimerScreenState extends ConsumerState<FocusTimerScreen>
    with TickerProviderStateMixin {
  int _selectedMinutes = 25;
  int _breakMinutes = 5;
  bool _isRunning = false;
  bool _isPaused = false;
  int _remainingSeconds = 0;
  int _totalSeconds = 0;
  int _interruptionCount = 0;
  bool _isBreakTime = false;
  late AnimationController _progressController;

  Map<String, dynamic> _todayStats = {};
  List<FocusTimerSession> _recentSessions = [];

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(vsync: this);
    _loadStats();
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    final repo = ref.read(focusTimerProvider);
    _todayStats = await repo.getTodayStats();
    _recentSessions = await repo.getTodaySessions();
    setState(() {});
  }

  void _startSession() {
    setState(() {
      _isRunning = true;
      _isPaused = false;
      _isBreakTime = false;
      _totalSeconds = _selectedMinutes * 60;
      _remainingSeconds = _totalSeconds;
      _interruptionCount = 0;
    });
    _progressController.duration = Duration(seconds: _totalSeconds);
    _progressController.forward(from: 0);
    _runTimer();
  }

  void _runTimer() async {
    while (_remainingSeconds > 0 && _isRunning && !_isPaused) {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted && _isRunning && !_isPaused) {
        setState(() => _remainingSeconds--);
      }
    }
    if (_remainingSeconds == 0 && mounted) {
      _completeSession();
    }
  }

  void _pauseSession() {
    setState(() {
      _isPaused = true;
      _interruptionCount++;
    });
    _progressController.stop();
  }

  void _resumeSession() {
    setState(() => _isPaused = false);
    _progressController.forward();
    _runTimer();
  }

  void _stopSession() {
    setState(() {
      _isRunning = false;
      _isPaused = false;
      _isBreakTime = false;
      _remainingSeconds = 0;
    });
    _progressController.stop();
  }

  Future<void> _completeSession() async {
    final session = FocusTimerSession(
      title: _isBreakTime ? '休息' : '专注',
      durationMinutes: _isBreakTime ? _breakMinutes : _selectedMinutes,
      breakDuration: _breakMinutes,
      sessionType: _isBreakTime ? 'break' : 'work',
      startedAt: DateTime.now().subtract(Duration(minutes: _isBreakTime ? _breakMinutes : _selectedMinutes)),
      endedAt: DateTime.now(),
      isCompleted: true,
      interruptionCount: _interruptionCount,
    );
    await ref.read(focusTimerProvider).insert(session);
    
    if (!_isBreakTime) {
      setState(() {
        _isBreakTime = true;
        _totalSeconds = _breakMinutes * 60;
        _remainingSeconds = _totalSeconds;
      });
      _progressController.duration = Duration(seconds: _totalSeconds);
      _progressController.forward(from: 0);
      _runTimer();
    } else {
      setState(() {
        _isRunning = false;
        _isBreakTime = false;
      });
      _loadStats();
    }
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.focusTimer),
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
            _buildTimerCard(),
            const SizedBox(height: 24),
            _buildSessionHistory(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    final sessionCount = _todayStats['sessionCount'] ?? 0;
    final totalMinutes = _todayStats['totalMinutes'] ?? 0;
    final interruptions = _todayStats['totalInterruptions'] ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _StatItem(icon: Icons.check_circle, value: '$sessionCount', label: '专注次数'),
            _StatItem(icon: Icons.timer, value: '${totalMinutes}m', label: '总时长'),
            _StatItem(icon: Icons.notifications, value: '$interruptions', label: '中断次数'),
          ],
        ),
      ),
    );
  }

  Widget _buildTimerCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            if (_isRunning) ...[
              Text(
                _isBreakTime ? '休息时间' : '专注中',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: 200,
                height: 200,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _progressController,
                      builder: (context, child) {
                        final progress = _isBreakTime 
                            ? (_totalSeconds - _remainingSeconds) / _totalSeconds
                            : _progressController.value;
                        return SizedBox(
                          width: 200,
                          height: 200,
                          child: CircularProgressIndicator(
                            value: progress,
                            strokeWidth: 8,
                            backgroundColor: Colors.grey.withOpacity(0.3),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _isBreakTime ? Colors.green : Colors.blue,
                            ),
                          ),
                        );
                      },
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _formatTime(_remainingSeconds),
                          style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        if (_interruptionCount > 0)
                          Text(
                            '中断: $_interruptionCount次',
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
                  if (_isPaused)
                    FilledButton.icon(
                      onPressed: _resumeSession,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('继续'),
                    )
                  else
                    FilledButton.icon(
                      onPressed: _pauseSession,
                      icon: const Icon(Icons.pause),
                      label: const Text('暂停'),
                    ),
                  const SizedBox(width: 16),
                  OutlinedButton.icon(
                    onPressed: _stopSession,
                    icon: const Icon(Icons.stop),
                    label: const Text('结束'),
                  ),
                ],
              ),
            ] else ...[
              Text(
                '专注计时器',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('专注: '),
                  ...([15, 25, 45, 60, 90].map((minutes) {
                    final isSelected = _selectedMinutes == minutes;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: Text('$minutes'),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) setState(() => _selectedMinutes = minutes);
                        },
                      ),
                    );
                  })),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('休息: '),
                  ...([5, 10, 15].map((minutes) {
                    final isSelected = _breakMinutes == minutes;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: Text('$minutes'),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) setState(() => _breakMinutes = minutes);
                        },
                      ),
                    );
                  })),
                ],
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _startSession,
                icon: const Icon(Icons.play_arrow, size: 28),
                label: Text(
                  '开始$_selectedMinutes分钟专注',
                  style: const TextStyle(fontSize: 18),
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSessionHistory() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('今日记录', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            if (_recentSessions.isEmpty)
              const Center(child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('还没有专注记录'),
              ))
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _recentSessions.length,
                itemBuilder: (context, index) {
                  final session = _recentSessions[index];
                  return ListTile(
                    leading: Icon(
                      session.isCompleted ? Icons.check_circle : Icons.cancel,
                      color: session.isCompleted ? Colors.green : Colors.red,
                    ),
                    title: Text(session.title),
                    subtitle: Text('${session.durationMinutes}分钟 | 中断${session.interruptionCount}次'),
                    trailing: Text(_formatDate(session.startedAt)),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
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
            Text('今日统计', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.check_circle, color: Colors.green),
              title: const Text('完成次数'),
              trailing: Text('${_todayStats['sessionCount'] ?? 0}'),
            ),
            ListTile(
              leading: const Icon(Icons.timer, color: Colors.blue),
              title: const Text('总时长'),
              trailing: Text('${_todayStats['totalMinutes'] ?? 0}分钟'),
            ),
            ListTile(
              leading: const Icon(Icons.notifications, color: Colors.orange),
              title: const Text('中断次数'),
              trailing: Text('${_todayStats['totalInterruptions'] ?? 0}'),
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

  const _StatItem({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 28, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 4),
        Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}