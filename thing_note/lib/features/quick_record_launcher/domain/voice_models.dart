import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 快捷录音条目
class VoiceEntry {
  final String id;
  final String? title;
  final String filePath;
  final int durationSeconds;
  final DateTime createdAt;
  final int? linkedRecordId;
  final bool isFavorite;

  const VoiceEntry({
    required this.id,
    this.title,
    required this.filePath,
    required this.durationSeconds,
    required this.createdAt,
    this.linkedRecordId,
    this.isFavorite = false,
  });

  String get formattedDuration {
    final minutes = durationSeconds ~/ 60;
    final seconds = durationSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

/// 录音状态
enum RecordingState { idle, recording, paused }

/// 快捷录音启动器 Provider
final quickRecorderProvider = StateNotifierProvider<QuickRecorderNotifier, AsyncValue<RecordingState>>((ref) {
  return QuickRecorderNotifier();
});

class QuickRecorderNotifier extends StateNotifier<AsyncValue<RecordingState>> {
  QuickRecorderNotifier() : super(const AsyncValue.data(RecordingState.idle));

  int _recordedSeconds = 0;
  int get recordedSeconds => _recordedSeconds;

  Future<void> startRecording() async {
    _recordedSeconds = 0;
    state = const AsyncValue.data(RecordingState.recording);
  }

  void pauseRecording() {
    state = const AsyncValue.data(RecordingState.paused);
  }

  void resumeRecording() {
    state = const AsyncValue.data(RecordingState.recording);
  }

  Future<VoiceEntry?> stopRecording() async {
    if (_recordedSeconds < 3) {
      state = const AsyncValue.data(RecordingState.idle);
      return null;
    }

    state = const AsyncValue.data(RecordingState.idle);
    return VoiceEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      filePath: '/path/to/recording.m4a',
      durationSeconds: _recordedSeconds,
      createdAt: DateTime.now(),
    );
  }

  void incrementTime() {
    _recordedSeconds++;
  }

  void cancelRecording() {
    _recordedSeconds = 0;
    state = const AsyncValue.data(RecordingState.idle);
  }
}

/// 最近录音列表
final recentRecordingsProvider = FutureProvider<List<VoiceEntry>>((ref) async {
  await Future.delayed(const Duration(milliseconds: 200));
  return [
    VoiceEntry(id: '1', title: '会议要点', filePath: '/path/1.m4a', durationSeconds: 125, createdAt: DateTime.now().subtract(const Duration(hours: 1))),
    VoiceEntry(id: '2', title: '灵感', filePath: '/path/2.m4a', durationSeconds: 45, createdAt: DateTime.now().subtract(const Duration(days: 1)), isFavorite: true),
  ];
});