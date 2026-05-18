import 'dart:async';
import 'package:flutter/material.dart';
import 'package:thing_note/core/utils/duration_formatter.dart';
import 'package:thing_note/core/utils/file_storage.dart';
import 'package:thing_note/features/media/presentation/providers/media_provider.dart';
import 'package:thing_note/features/media/presentation/widgets/audio_player.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

class AudioRecorderSection extends ConsumerStatefulWidget {
  final List<String> initialAudioPaths;
  final List<int> initialAudioDurationsSec;
  final void Function(List<String> paths, List<int> durationsSec) onAudioChanged;
  final void Function(bool isRecording)? onRecordingStateChanged;

  const AudioRecorderSection({
    super.key,
    this.initialAudioPaths = const [],
    this.initialAudioDurationsSec = const [],
    required this.onAudioChanged,
    this.onRecordingStateChanged,
  });

  @override
  ConsumerState<AudioRecorderSection> createState() =>
      AudioRecorderSectionState();
}

class AudioRecorderSectionState extends ConsumerState<AudioRecorderSection>
    with WidgetsBindingObserver {
  bool _isRecording = false;
  bool _isInitializing = false;
  Duration _recordingDuration = Duration.zero;
  Timer? _timer;
  late List<String> _audioPaths;
  late List<int> _audioDurationsSec;
  String? _lastAudioKey;
  String? _lastDurationsKey;

  bool get isRecording => _isRecording;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _audioPaths = List.from(widget.initialAudioPaths);
    _audioDurationsSec = List.from(widget.initialAudioDurationsSec);
    _lastAudioKey = widget.initialAudioPaths.join(',');
    _lastDurationsKey = widget.initialAudioDurationsSec.join(',');
  }

  @override
  void didUpdateWidget(covariant AudioRecorderSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newAudioKey = widget.initialAudioPaths.join(',');
    final newDurationsKey = widget.initialAudioDurationsSec.join(',');
    if (newAudioKey != _lastAudioKey || newDurationsKey != _lastDurationsKey) {
      _audioPaths = List.from(widget.initialAudioPaths);
      _audioDurationsSec = List.from(widget.initialAudioDurationsSec);
      _lastAudioKey = newAudioKey;
      _lastDurationsKey = newDurationsKey;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    if (_isRecording) {
      ref.read(mediaServiceProvider).stopRecording();
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused && _isRecording) {
      stopRecording();
    }
  }

  Future<bool> _checkPermission() async {
    final status = await Permission.microphone.status;
    if (status.isDenied) {
      final result = await Permission.microphone.request();
      return result.isGranted;
    }
    if (status.isPermanentlyDenied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('麦克风权限被拒绝，请在设置中开启'),
            action: SnackBarAction(
              label: '设置',
              onPressed: () => openAppSettings(),
            ),
          ),
        );
      }
      return false;
    }
    return status.isGranted;
  }

  Future<void> _startRecording() async {
    if (_isRecording || _isInitializing) return;

    final hasPermission = await _checkPermission();
    if (!hasPermission) return;

    setState(() {
      _isInitializing = true;
    });

    try {
      final path = await ref.read(mediaServiceProvider).recordAudio();
      if (path != null) {
        _timer?.cancel();
        setState(() {
          _isRecording = true;
          _isInitializing = false;
          _recordingDuration = Duration.zero;
        });
        widget.onRecordingStateChanged?.call(true);
        _timer = Timer.periodic(const Duration(seconds: 1), (_) {
          if (mounted) {
            setState(() {
              _recordingDuration += const Duration(seconds: 1);
            });
          }
        });
      } else {
        setState(() {
          _isInitializing = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('录音启动失败，请重试')),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isInitializing = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('录音失败: $e')),
        );
      }
    }
  }

  Future<void> stopRecording() async {
    if (!_isRecording) return;

    try {
      final path = await ref.read(mediaServiceProvider).stopRecording();
      _timer?.cancel();
      _timer = null;
      setState(() {
        _isRecording = false;
      });
      widget.onRecordingStateChanged?.call(false);
      if (path != null && mounted) {
        try {
          final savedPath = await FileStorage.saveAudioFile(path);
          setState(() {
            _audioPaths.add(savedPath);
            _audioDurationsSec.add(_recordingDuration.inSeconds);
          });
          widget.onAudioChanged(_audioPaths, _audioDurationsSec);
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('保存录音失败: $e')),
            );
          }
        }
      }
    } catch (e) {
      setState(() {
        _isRecording = false;
      });
      widget.onRecordingStateChanged?.call(false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('停止录音失败: $e')),
        );
      }
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
            child: Text(
              '删除',
              style: TextStyle(color: Theme.of(ctx).colorScheme.error),
            ),
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
              color: Theme.of(context).colorScheme.primaryContainer,
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
                onPressed: _isInitializing ? null : _startRecording,
                icon: _isInitializing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.mic),
                label: Text(_isInitializing ? '初始化中...' : '添加录音'),
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