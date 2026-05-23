import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/pomodoro_timer/data/pomodoro_repository.dart';
import 'package:thing_note/features/pomodoro_timer/domain/pomodoro_session.dart';

class PomodoroTimerScreen extends ConsumerStatefulWidget {
  const PomodoroTimerScreen({super.key});

  @override
  ConsumerState<PomodoroTimerScreen> createState() => _PomodoroTimerScreenState();
}

class _PomodoroTimerScreenState extends ConsumerState<PomodoroTimerScreen> {
  bool _isRunning = false;
  int _remainingSeconds = 25 * 60;
  int _focusMinutes = 25;
  final int _breakMinutes = 5;
  Timer? _timer;
  String _phase = 'focus'; // focus / break / long_break

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final todayAsync = ref.watch(pomodoroTodayProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('番茄钟'),
        actions: [
          PopupMenuButton(
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 15, child: Text('15分钟专注')),
              const PopupMenuItem(value: 25, child: Text('25分钟专注')),
              const PopupMenuItem(value: 50, child: Text('50分钟专注')),
              const PopupMenuItem(value: 90, child: Text('90分钟专注')),
            ],
            onSelected: (minutes) {
              setState(() {
                _focusMinutes = minutes;
                _remainingSeconds = minutes * 60;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('$_focusMinutes分钟', style: const TextStyle(fontSize: 14)),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // 阶段指示器
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _PhaseChip(label: '专注', isActive: _phase == 'focus', color: Colors.red),
                _PhaseChip(label: '短休息', isActive: _phase == 'break', color: Colors.green),
              ],
            ),
            const SizedBox(height: 32),
            // 计时器
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 220,
                  height: 220,
                  child: CircularProgressIndicator(
                    value: _phase == 'break'
                        ? 0
                        : 1 - (_remainingSeconds / (_focusMinutes * 60)),
                    strokeWidth: 8,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation(
                      _phase == 'break' ? Colors.green : Colors.red.shade400,
                    ),
                  ),
                ),
                Column(
                  children: [
                    Text(
                      _formatTime(_remainingSeconds),
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: _phase == 'break' ? Colors.green : Colors.red.shade700,
                      ),
                    ),
                    Text(
                      _phase == 'focus' ? '专注中' : '休息中',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),
            // 控制按钮
            if (!_isRunning)
              ElevatedButton.icon(
                onPressed: _startTimer,
                icon: const Icon(Icons.play_arrow),
                label: const Text('开始'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 14),
                ),
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: _pauseTimer,
                    icon: const Icon(Icons.pause),
                    label: const Text('暂停'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: _resetTimer,
                    icon: const Icon(Icons.stop),
                    label: const Text('重置'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                  ),
                ],
              ),
            const SizedBox(height: 24),
            // 今日统计
            todayAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (e, st) => const SizedBox.shrink(),
              data: (stats) => _buildTodayStats(stats),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayStats(PomodoroStats stats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('今日番茄统计', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(label: '完成番茄', value: '${stats.totalSessions}个'),
                _StatItem(label: '专注时间', value: '${stats.totalFocusMinutes}分钟'),
                _StatItem(label: '完成轮次', value: '${stats.completedRounds}轮'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _startTimer() {
    setState(() => _isRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _onTimerComplete();
        }
      });
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() => _isRunning = false);
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _remainingSeconds = _focusMinutes * 60;
      _phase = 'focus';
    });
  }

  void _onTimerComplete() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      if (_phase == 'focus') {
        _phase = 'break';
        _remainingSeconds = _breakMinutes * 60;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 专注完成！休息一下吧'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        _phase = 'focus';
        _remainingSeconds = _focusMinutes * 60;
      }
    });
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

class _PhaseChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final Color color;
  const _PhaseChip({required this.label, required this.isActive, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: isActive ? color : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: TextStyle(color: isActive ? Colors.white : Colors.grey)),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  const _StatItem({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
