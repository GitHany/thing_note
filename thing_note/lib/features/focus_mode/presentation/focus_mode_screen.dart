import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/focus_mode/data/focus_repository.dart';
import 'package:thing_note/features/focus_mode/domain/focus_session.dart';

class FocusModeScreen extends ConsumerStatefulWidget {
  const FocusModeScreen({super.key});

  @override
  ConsumerState<FocusModeScreen> createState() => _FocusModeScreenState();
}

class _FocusModeScreenState extends ConsumerState<FocusModeScreen> {
  Timer? _timer;
  int _remainingSeconds = 0;
  bool _isRunning = false;
  FocusSession? _currentSession;
  int _selectedMinutes = 25;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer(int minutes) {
    setState(() {
      _selectedMinutes = minutes;
      _remainingSeconds = minutes * 60;
      _isRunning = true;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        _completeSession();
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() => _isRunning = false);
  }

  void _resumeTimer() {
    setState(() => _isRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        _completeSession();
      }
    });
  }

  Future<void> _completeSession() async {
    _timer?.cancel();
    if (_currentSession != null) {
      await ref.read(focusSessionsProvider.notifier).completeSession(_currentSession!.id!);
    }
    
    setState(() {
      _isRunning = false;
      _remainingSeconds = 0;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('专注完成！休息一下吧 🎉'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _cancelTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _remainingSeconds = 0;
      _currentSession = null;
    });
  }

  String get _formattedTime {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  double get _progress {
    if (_selectedMinutes == 0) return 0;
    return 1 - (_remainingSeconds / (_selectedMinutes * 60));
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(focusStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('专注模式'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => _showHistoryDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStatsCard(statsAsync),
          Expanded(
            child: _remainingSeconds > 0 || _isRunning
                ? _buildActiveTimer()
                : _buildTimerSelector(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(AsyncValue<FocusStats> statsAsync) {
    return statsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (stats) => Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem('今日', '${stats.todayMinutes}分钟', '${stats.todaySessions}次'),
            _buildStatItem('本周', '${stats.weekMinutes}分钟', '${stats.weekSessions}次'),
            _buildStatItem('本月', '${stats.monthMinutes}分钟', '${stats.monthSessions}次'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String minutes, String sessions) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 4),
        Text(minutes, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Text(sessions, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildTimerSelector() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            '选择专注时长',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildPresetButton(25),
              const SizedBox(width: 16),
              _buildPresetButton(50),
              const SizedBox(width: 16),
              _buildPresetButton(90),
            ],
          ),
          const SizedBox(height: 32),
          const Text('自定义时长', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 8),
          SizedBox(
            width: 200,
            child: Slider(
              value: _selectedMinutes.toDouble(),
              min: 5,
              max: 120,
              divisions: 23,
              label: '$_selectedMinutes 分钟',
              onChanged: (value) => setState(() => _selectedMinutes = value.round()),
            ),
          ),
          Text('$_selectedMinutes 分钟', style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () async {
              _currentSession = await ref.read(focusSessionsProvider.notifier).startSession(
                '专注 $_selectedMinutes 分钟',
                _selectedMinutes,
              );
              _startTimer(_selectedMinutes);
            },
            icon: const Icon(Icons.play_arrow),
            label: const Text('开始专注'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetButton(int minutes) {
    final isSelected = _selectedMinutes == minutes;
    return GestureDetector(
      onTap: () => setState(() => _selectedMinutes = minutes),
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor : Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$minutes',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
            Text(
              '分钟',
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? Colors.white70 : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveTimer() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 250,
                height: 250,
                child: CircularProgressIndicator(
                  value: _progress,
                  strokeWidth: 12,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
                ),
              ),
              Column(
                children: [
                  Text(
                    _formattedTime,
                    style: const TextStyle(fontSize: 56, fontWeight: FontWeight.bold),
                  ),
                  if (_currentSession != null)
                    Text(
                      _currentSession!.title,
                      style: const TextStyle(color: Colors.grey),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 48),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isRunning)
                ElevatedButton.icon(
                  onPressed: _pauseTimer,
                  icon: const Icon(Icons.pause),
                  label: const Text('暂停'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                )
              else
                ElevatedButton.icon(
                  onPressed: _resumeTimer,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('继续'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              const SizedBox(width: 16),
              TextButton.icon(
                onPressed: _cancelTimer,
                icon: const Icon(Icons.stop),
                label: const Text('结束'),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showHistoryDialog(BuildContext context) {
    final sessionsAsync = ref.read(focusSessionsProvider);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('专注历史'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: sessionsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('错误: $e')),
            data: (sessions) {
              final completed = sessions.where((s) => s.isCompleted).toList();
              if (completed.isEmpty) {
                return const Center(child: Text('暂无专注记录'));
              }
              return ListView.builder(
                itemCount: completed.length,
                itemBuilder: (context, index) {
                  final session = completed[index];
                  return ListTile(
                    leading: const Icon(Icons.timer),
                    title: Text(session.title),
                    subtitle: Text('${session.durationMinutes}分钟 • ${_formatDate(session.startedAt)}'),
                    trailing: session.isCompleted
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : null,
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}