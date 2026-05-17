import 'dart:async';
import 'package:flutter/material.dart';
import 'package:thing_note/core/utils/duration_formatter.dart';
import 'package:thing_note/core/utils/file_storage.dart';
import 'package:thing_note/features/media/presentation/providers/media_provider.dart';
import 'package:thing_note/features/media/presentation/widgets/audio_player.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AudioRecorderSection extends ConsumerStatefulWidget {
  final List<String> initialAudioPaths;
  final List<int> initialAudioDurationsSec;
  final void Function(List<String> paths, List<int> durationsSec) onAudioChanged;

  const AudioRecorderSection({
    super.key,
    this.initialAudioPaths = const [],
    this.initialAudioDurationsSec = const [],
    required this.onAudioChanged,
  });

  @override
  ConsumerState<AudioRecorderSection> createState() =>
      AudioRecorderSectionState();
}

class AudioRecorderSectionState extends ConsumerState<AudioRecorderSection> {
  bool _isRecording = false;
  Duration _recordingDuration = Duration.zero;
  Timer? _timer;
  late List<String> _audioPaths;
  late List<int> _audioDurationsSec;

  bool get isRecording => _isRecording;

  @override
  void initState() {
    super.initState();
    _audioPaths = List.from(widget.initialAudioPaths);
    _audioDurationsSec = List.from(widget.initialAudioDurationsSec);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _startRecording() async {
    final path = await ref.read(mediaServiceProvider).recordAudio();
    if (path != null) {
      setState(() {
        _isRecording = true;
        _recordingDuration = Duration.zero;
      });
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() {
          _recordingDuration += const Duration(seconds: 1);
        });
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('请允许录音权限')),
          );
        }
      });
    }
  }

  Future<void> stopRecording() async {
    if (!_isRecording) return;

    final path = await ref.read(mediaServiceProvider).stopRecording();
    _timer?.cancel();
    _timer = null;
    setState(() {
      _isRecording = false;
    });
    if (path != null) {
      final savedPath = await FileStorage.saveAudioFile(path);
      setState(() {
        _audioPaths.add(savedPath);
        _audioDurationsSec.add(_recordingDuration.inSeconds);
      });
      widget.onAudioChanged(_audioPaths, _audioDurationsSec);
    }
  }

  Future<void> _removeAudio(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这段录音吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      setState(() {
        _audioPaths.removeAt(index);
        _audioDurationsSec.removeAt(index);
      });
      widget.onAudioChanged(_audioPaths, _audioDurationsSec);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '录音',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        if (_isRecording)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.fiber_manual_record, color: Colors.red, size: 16),
                const SizedBox(width: 8),
                Text(
                  DurationFormatter.format(_recordingDuration),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontFeatures: [const FontFeature.tabularFigures()],
                      ),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: stopRecording,
                  icon: const Icon(Icons.stop),
                  label: const Text('停止'),
                ),
              ],
            ),
          )
        else
          Row(
            children: [
              FilledButton.icon(
                onPressed: _startRecording,
                icon: const Icon(Icons.mic),
                label: const Text('添加录音'),
              ),
            ],
          ),
        const SizedBox(height: 12),
        ..._audioPaths.asMap().entries.map((entry) {
          final index = entry.key;
          final path = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: AudioPlayerWidget(audioPath: path),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _removeAudio(index),
                  color: Theme.of(context).colorScheme.error,
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}