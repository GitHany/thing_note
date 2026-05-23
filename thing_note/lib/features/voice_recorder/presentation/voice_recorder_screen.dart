import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/voice_recorder/data/voice_recorder_service.dart';
import 'package:thing_note/features/voice_recorder/domain/voice_entry.dart';

class VoiceRecorderScreen extends ConsumerStatefulWidget {
  const VoiceRecorderScreen({super.key});

  @override
  ConsumerState<VoiceRecorderScreen> createState() => _VoiceRecorderScreenState();
}

class _VoiceRecorderScreenState extends ConsumerState<VoiceRecorderScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Recorder'),
      ),
      body: const Center(
        child: Text('Voice Recorder Screen - Placeholder'),
      ),
    );
  }
}

class VoiceRecorderWidget extends ConsumerStatefulWidget {
  final Function(VoiceEntry)? onRecordingComplete;

  const VoiceRecorderWidget({super.key, this.onRecordingComplete});

  @override
  ConsumerState<VoiceRecorderWidget> createState() => _VoiceRecorderWidgetState();
}

class _VoiceRecorderWidgetState extends ConsumerState<VoiceRecorderWidget> {
  final _service = VoiceRecorderService();
  RecordingState _state = RecordingState.idle;
  int _recordingSeconds = 0;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    // Permission check handled by service
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _formatDuration(_recordingSeconds),
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (_state == RecordingState.recording ||
                  _state == RecordingState.paused)
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    await _service.cancelRecording();
                    setState(() {
                      _state = RecordingState.idle;
                      _recordingSeconds = 0;
                    });
                  },
                ),
              IconButton.filled(
                icon: Icon(
                  _state == RecordingState.recording
                      ? Icons.pause
                      : Icons.mic,
                ),
                onPressed: () async {
                  if (_state == RecordingState.idle) {
                    await _service.startRecording();
                    setState(() => _state = RecordingState.recording);
                  } else if (_state == RecordingState.recording) {
                    await _service.pauseRecording();
                    setState(() => _state = RecordingState.paused);
                  } else if (_state == RecordingState.paused) {
                    await _service.resumeRecording();
                    setState(() => _state = RecordingState.recording);
                  }
                },
              ),
              if (_state == RecordingState.recording ||
                  _state == RecordingState.paused)
                IconButton.filled(
                  icon: const Icon(Icons.stop),
                  onPressed: () async {
                    final entry = await _service.stopRecording();
                    if (entry != null) {
                      widget.onRecordingComplete?.call(entry);
                    }
                    setState(() {
                      _state = RecordingState.idle;
                      _recordingSeconds = 0;
                    });
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}