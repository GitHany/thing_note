import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/pomodoro_task/domain/pomodoro_task.dart';

/// Pomodoro 任务列表
final pomodoroTasksProvider = FutureProvider<List<PomodoroTask>>((ref) async {
  // TODO: 从数据库获取
  return [];
});

/// 当前活动任务
final activePomodoroTaskProvider = StateProvider<PomodoroTask?>((ref) => null);

/// Pomodoro 计时器状态
final pomodoroTimerProvider = StateNotifierProvider<PomodoroTimerNotifier, PomodoroTimerState>((ref) {
  return PomodoroTimerNotifier();
});

class PomodoroTimerNotifier extends StateNotifier<PomodoroTimerState> {
  PomodoroTimerNotifier() : super(PomodoroTimerState.initial());

  void startTimer(int durationMinutes) {
    state = PomodoroTimerState(
      isRunning: true,
      remainingSeconds: durationMinutes * 60,
      totalSeconds: durationMinutes * 60,
      isCompleted: false,
    );
    _tick();
  }

  void _tick() {
    if (!state.isRunning) return;
    Future.delayed(const Duration(seconds: 1), () {
      if (state.remainingSeconds > 0 && state.isRunning) {
        state = state.copyWith(remainingSeconds: state.remainingSeconds - 1);
        _tick();
      } else if (state.remainingSeconds <= 0) {
        state = state.copyWith(isRunning: false, isCompleted: true);
      }
    });
  }

  void pause() {
    state = state.copyWith(isRunning: false);
  }

  void resume() {
    state = state.copyWith(isRunning: true);
    _tick();
  }

  void stop() {
    state = PomodoroTimerState.initial();
  }
}

class PomodoroTimerState {
  final bool isRunning;
  final int remainingSeconds;
  final int totalSeconds;
  final bool isCompleted;

  const PomodoroTimerState({
    required this.isRunning,
    required this.remainingSeconds,
    required this.totalSeconds,
    required this.isCompleted,
  });

  factory PomodoroTimerState.initial() {
    return const PomodoroTimerState(
      isRunning: false,
      remainingSeconds: 0,
      totalSeconds: 0,
      isCompleted: false,
    );
  }

  PomodoroTimerState copyWith({
    bool? isRunning,
    int? remainingSeconds,
    int? totalSeconds,
    bool? isCompleted,
  }) {
    return PomodoroTimerState(
      isRunning: isRunning ?? this.isRunning,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      totalSeconds: totalSeconds ?? this.totalSeconds,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  double get progress => totalSeconds > 0 ? remainingSeconds / totalSeconds : 0;
}

/// Pomodoro 统计
class PomodoroStats {
  final int todayPomodoros;
  final int todayMinutes;
  final int weekPomodoros;
  final double avgFocusScore;

  const PomodoroStats({
    this.todayPomodoros = 0,
    this.todayMinutes = 0,
    this.weekPomodoros = 0,
    this.avgFocusScore = 0,
  });
}

final pomodoroStatsProvider = FutureProvider<PomodoroStats>((ref) async {
  // TODO: 计算统计
  return const PomodoroStats();
});