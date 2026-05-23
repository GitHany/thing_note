import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:thing_note/features/voice_recorder/data/voice_recorder_repository.dart';
import 'package:thing_note/features/voice_recorder/domain/voice_entry.dart';

final voiceRecorderServiceProvider = Provider<VoiceRecorderService>((ref) {
  return VoiceRecorderService();
});

final voiceEntriesProvider = FutureProvider<List<VoiceEntry>>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  final repo = VoiceRecorderRepository(db);
  return repo.getAll();
});

final databaseProvider = FutureProvider<dynamic>((ref) async {
  // This will be provided by the app
  throw UnimplementedError('databaseProvider should be provided by app');
});

class VoiceRecorderService {
  final AudioRecorder _recorder = AudioRecorder();
  RecordingState _state = RecordingState.idle;
  DateTime? _recordingStartTime;
  int _pausedDuration = 0;
  DateTime? _pauseStartTime;

  RecordingState get state => _state;

  Future<bool> hasPermission() async {
    return await _recorder.hasPermission();
  }

  Future<void> startRecording() async {
    if (_state == RecordingState.recording) return;

    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      throw Exception('Microphone permission not granted');
    }

    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = '${dir.path}/voice_$timestamp.m4a';

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      ),
      path: path,
    );

    _state = RecordingState.recording;
    _recordingStartTime = DateTime.now();
    _pausedDuration = 0;
  }

  Future<void> pauseRecording() async {
    if (_state != RecordingState.recording) return;
    await _recorder.pause();
    _state = RecordingState.paused;
    _pauseStartTime = DateTime.now();
  }

  Future<void> resumeRecording() async {
    if (_state != RecordingState.paused) return;
    await _recorder.resume();
    if (_pauseStartTime != null) {
      _pausedDuration +=
          DateTime.now().difference(_pauseStartTime!).inSeconds;
    }
    _pauseStartTime = null;
    _state = RecordingState.recording;
  }

  Future<VoiceEntry?> stopRecording({String? title}) async {
    if (_state != RecordingState.recording && _state != RecordingState.paused) {
      return null;
    }

    final path = await _recorder.stop();
    if (path == null) return null;

    int totalDuration = 0;
    if (_recordingStartTime != null) {
      totalDuration = DateTime.now().difference(_recordingStartTime!).inSeconds - _pausedDuration;
    }

    final file = File(path);
    if (!await file.exists()) return null;

    return VoiceEntry(
      title: title ?? 'Voice ${DateTime.now().toString().substring(0, 16)}',
      filePath: path,
      durationSec: totalDuration,
      createdAt: _recordingStartTime ?? DateTime.now(),
    );
  }

  Future<void> cancelRecording() async {
    final path = await _recorder.stop();
    if (path != null) {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    }
    _resetState();
  }

  void _resetState() {
    _state = RecordingState.idle;
    _recordingStartTime = null;
    _pausedDuration = 0;
    _pauseStartTime = null;
  }

  Future<void> dispose() async {
    await _recorder.dispose();
  }
}