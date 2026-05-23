import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:thing_note/l10n/generated/app_localizations.dart';
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
            content: Text(AppLocalizations.of(context)!.microphonePermissionDenied),
            action: SnackBarAction(
              label: AppLocalizations.of(context)!.settings,
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
            SnackBar(content: Text(AppLocalizations.of(context)!.saveFailed('recording failed'))),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isInitializing = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.saveFailed(e.toString()))),
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
              SnackBar(content: Text(AppLocalizations.of(context)!.saveFailed(e.toString()))),
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
          SnackBar(content: Text(AppLocalizations.of(context)!.saveFailed(e.toString()))),
        );
      }
    }
  }

  Future<void> _pickAudioFromFile() async {
    if (_isRecording) return;
    try {
      final files = await ref.read(mediaServiceProvider).pickAudioFromFiles();
      if (files.isEmpty) return;

      for (final file in files) {
        final path = file.path;
        int durationSec = 0;
        try {
          final player = AudioPlayer();
          await player.setSource(DeviceFileSource(path));
          final duration = await player.getDuration();
          durationSec = (duration?.inSeconds ?? 0);
          if (durationSec == 0) {
            final completer = Completer<int>();
            final sub = player.onDurationChanged.listen((d) {
              if (!completer.isCompleted) {
                completer.complete(d.inSeconds);
              }
            });
            durationSec = await completer.future.timeout(
              const Duration(seconds: 3),
              onTimeout: () => 0,
            );
            await sub.cancel();
          }
          await player.dispose();
        } catch (_) {
          durationSec = 0;
        }

        setState(() {
          _audioPaths.add(path);
          _audioDurationsSec.add(durationSec);
        });
      }
      widget.onAudioChanged(_audioPaths, _audioDurationsSec);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.pickAudioFailed(e.toString()))),
        );
      }
    }
  }

  Future<void> _removeAudio(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(ctx)!.confirmDelete),
        content: Text(AppLocalizations.of(ctx)!.confirmDeleteRecord),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(AppLocalizations.of(ctx)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              AppLocalizations.of(ctx)!.delete,
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
    final screenWidth = MediaQuery.of(context).size.width;
    // Responsive audio list item height
    final itemHeight = screenWidth > 600 ? 60.0 : 56.0;
    const itemSpacing = 10.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.audios,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 10),
        if (_isRecording)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.fiber_manual_record, color: Colors.red, size: 18),
                const SizedBox(width: 10),
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
                  label: Text(AppLocalizations.of(context)!.stopRecording),
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
                label: Text(_isInitializing ? AppLocalizations.of(context)!.loading : AppLocalizations.of(context)!.startRecording),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: _pickAudioFromFile,
                icon: const Icon(Icons.audio_file),
                label: Text(AppLocalizations.of(context)!.addAudioFromFile),
              ),
            ],
          ),
        const SizedBox(height: 14),
        if (_audioPaths.isNotEmpty)
          _AudioList(
            audioPaths: _audioPaths,
            audioDurationsSec: _audioDurationsSec,
            onRemove: _removeAudio,
            itemHeight: itemHeight,
            itemSpacing: itemSpacing,
          ),
      ],
    );
  }
}

class _AudioList extends StatelessWidget {
  final List<String> audioPaths;
  final List<int> audioDurationsSec;
  final void Function(int index) onRemove;
  final double itemHeight;
  final double itemSpacing;

  const _AudioList({
    required this.audioPaths,
    required this.audioDurationsSec,
    required this.onRemove,
    this.itemHeight = 56.0,
    this.itemSpacing = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    const int maxVisibleItems = 5;
    final bool needsScroll = audioPaths.length > maxVisibleItems;
    final double listHeight = needsScroll
        ? maxVisibleItems * (itemHeight + itemSpacing)
        : audioPaths.length * (itemHeight + itemSpacing);

    return SizedBox(
      height: listHeight,
      child: ListView.separated(
        physics: needsScroll
            ? const AlwaysScrollableScrollPhysics()
            : const NeverScrollableScrollPhysics(),
        itemCount: audioPaths.length,
        separatorBuilder: (_, __) => SizedBox(height: itemSpacing),
        itemBuilder: (context, index) {
          return SizedBox(
            height: itemHeight,
            child: Row(
              children: [
                Expanded(
                  child: AudioPlayerWidget(audioPath: audioPaths[index]),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => onRemove(index),
                  color: Theme.of(context).colorScheme.error,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
