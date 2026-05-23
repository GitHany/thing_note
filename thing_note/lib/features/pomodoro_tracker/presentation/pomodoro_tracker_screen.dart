import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models.dart';
import '../data/provider.dart';

class PomodoroTrackerScreen extends ConsumerStatefulWidget {
  const PomodoroTrackerScreen({super.key});

  @override
  ConsumerState<PomodoroTrackerScreen> createState() => _PomodoroTrackerScreenState();
}

class _PomodoroTrackerScreenState extends ConsumerState<PomodoroTrackerScreen> {
  PomodoroSession? _activeSession;
  int _completedPomodoros = 0;
  int _remainingSeconds = 0;
  bool _isRunning = false;
  bool _isBreak = false;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startSession(PomodoroPreset preset) {
    setState(() {
      _activeSession = PomodoroSession(
        name: preset.name,
        durationMinutes: preset.workMinutes,
        breakMinutes: preset.shortBreakMinutes,
        longBreakMinutes: preset.longBreakMinutes,
        sessionsBeforeLongBreak: preset.sessions,
      );
      _remainingSeconds = preset.workMinutes * 60;
      _completedPomodoros = 0;
      _isBreak = false;
      _isRunning = true;
    });
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        _onTimerComplete();
      }
    });
  }

  void _onTimerComplete() {
    _timer?.cancel();
    if (_isBreak) {
      setState(() {
        _isBreak = false;
        _remainingSeconds = (_activeSession?.durationMinutes ?? 25) * 60;
      });
      _startTimer();
    } else {
      _completedPomodoros++;
      final sessionsBeforeLong = _activeSession?.sessionsBeforeLongBreak ?? 4;
      if (_completedPomodoros % sessionsBeforeLong == 0) {
        setState(() {
          _isBreak = true;
          _remainingSeconds = (_activeSession?.longBreakMinutes ?? 15) * 60;
        });
      } else {
        setState(() {
          _isBreak = true;
          _remainingSeconds = (_activeSession?.breakMinutes ?? 5) * 60;
        });
      }
      _startTimer();
    }
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() => _isRunning = false);
  }

  void _resumeTimer() {
    setState(() => _isRunning = true);
    _startTimer();
  }

  void _stopSession() {
    _timer?.cancel();
    if (_activeSession != null && _completedPomodoros > 0) {
      final totalMinutes = (_activeSession!.durationMinutes * _completedPomodoros) +
        (_isBreak ? 0 : _remainingSeconds ~/ 60);
      ref.read(pomodoroSessionsProvider.notifier).completeSession(
        _activeSession!.id!,
        _completedPomodoros,
        totalMinutes,
      );
    }
    setState(() {
      _activeSession = null;
      _completedPomodoros = 0;
      _remainingSeconds = 0;
      _isRunning = false;
      _isBreak = false;
    });
  }

  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final todayCount = ref.watch(todayPomodoroCountProvider);

    if (_activeSession != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(_isBreak ? 'Break Time 🎉' : 'Focus Time 🍅'),
          leading: IconButton(
            icon: const Icon(Icons.stop),
            onPressed: _stopSession,
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _isBreak ? 'Take a break!' : 'Stay focused!',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: 250,
                height: 250,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 250,
                      height: 250,
                      child: CircularProgressIndicator(
                        value: _isBreak
                          ? _remainingSeconds / ((_completedPomodoros % _activeSession!.sessionsBeforeLongBreak) == 0
                            ? _activeSession!.longBreakMinutes : _activeSession!.breakMinutes) * 60
                          : _remainingSeconds / (_activeSession!.durationMinutes * 60),
                        strokeWidth: 12,
                        backgroundColor: Colors.grey.shade300,
                        valueColor: AlwaysStoppedAnimation(_isBreak ? Colors.green : Colors.orange),
                      ),
                    ),
                    Text(
                      _formatTime(_remainingSeconds),
                      style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              Text(
                'Pomodoros: $_completedPomodoros / ${_activeSession!.sessionsBeforeLongBreak}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FilledButton.icon(
                    onPressed: _isRunning ? _pauseTimer : _resumeTimer,
                    icon: Icon(_isRunning ? Icons.pause : Icons.play_arrow),
                    label: Text(_isRunning ? 'Pause' : 'Resume'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pomodoro Tracker'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Chip(
                label: Text('Today: $todayCount 🍅'),
                backgroundColor: Colors.orange.shade100,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Start a Session',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          ...PomodoroPreset.defaults.map((preset) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: const Icon(Icons.timer, color: Colors.orange),
              title: Text(preset.name),
              subtitle: Text('${preset.workMinutes}min work / ${preset.shortBreakMinutes}min break'),
              trailing: FilledButton(
                onPressed: () => _startSession(preset),
                child: const Text('Start'),
              ),
            ),
          )),
          const SizedBox(height: 24),
          Text(
            'Recent Sessions',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          _RecentSessionsList(),
        ],
      ),
    );
  }
}

class _RecentSessionsList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(pomodoroSessionsProvider);
    final recentSessions = sessions.take(10).toList();

    if (recentSessions.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('No sessions yet. Start your first pomodoro!'),
        ),
      );
    }

    return Column(
      children: recentSessions.map((session) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.orange.shade100,
              child: Text('${session.completedPomodoros}'),
            ),
            title: Text(session.name),
            subtitle: Text('${session.totalMinutes} min • ${session.startedAt.toString().substring(0, 16)}'),
            trailing: session.completedAt != null
              ? const Icon(Icons.check_circle, color: Colors.green)
              : null,
          ),
        );
      }).toList(),
    );
  }
}