import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:thing_note/core/utils/duration_formatter.dart';
import 'package:thing_note/l10n/generated/app_localizations.dart';

class EnhancedAudioPlayerWidget extends StatefulWidget {
  final String audioPath;
  final bool showSpeedControl;

  const EnhancedAudioPlayerWidget({
    super.key,
    required this.audioPath,
    this.showSpeedControl = true,
  });

  @override
  State<EnhancedAudioPlayerWidget> createState() => _EnhancedAudioPlayerWidgetState();
}

class _EnhancedAudioPlayerWidgetState extends State<EnhancedAudioPlayerWidget> {
  AudioPlayer? _player;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isPlaying = false;
  bool _isInitialized = false;
  bool _hasError = false;
  double _playbackSpeed = 1.0;
  StreamSubscription<Duration>? _durationSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<void>? _completionSubscription;
  StreamSubscription<PlayerState>? _stateSubscription;

  final List<double> _speedOptions = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

  @override
  void initState() {
    super.initState();
    _checkFileAndInit();
  }

  Future<void> _checkFileAndInit() async {
    final exists = await File(widget.audioPath).exists();
    if (!exists) {
      if (mounted) {
        setState(() => _hasError = true);
      }
      return;
    }
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    if (_isInitialized) return;

    try {
      _player = AudioPlayer();

      _durationSubscription = _player!.onDurationChanged.listen((duration) {
        if (mounted) {
          setState(() => _duration = duration);
        }
      });

      _positionSubscription = _player!.onPositionChanged.listen((position) {
        if (mounted) {
          setState(() => _position = position);
        }
      });

      _completionSubscription = _player!.onPlayerComplete.listen((_) {
        if (mounted) {
          setState(() {
            _isPlaying = false;
            _position = Duration.zero;
          });
        }
      });

      _stateSubscription = _player!.onPlayerStateChanged.listen((state) {
        if (mounted) {
          setState(() {
            _isPlaying = state == PlayerState.playing;
          });
        }
      });

      await _player!.setSource(DeviceFileSource(widget.audioPath));
      if (mounted) {
        setState(() => _isInitialized = true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _hasError = true);
      }
    }
  }

  @override
  void dispose() {
    _durationSubscription?.cancel();
    _positionSubscription?.cancel();
    _completionSubscription?.cancel();
    _stateSubscription?.cancel();
    _player?.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    if (_player == null || _hasError) return;

    try {
      if (_isPlaying) {
        await _player!.pause();
      } else {
        await _player!.play(DeviceFileSource(widget.audioPath));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('播放失败')),
        );
      }
    }
  }

  Future<void> _seekTo(double value) async {
    if (_player == null) return;
    final position = Duration(
      milliseconds: (_duration.inMilliseconds * value).round(),
    );
    await _player!.seek(position);
  }

  Future<void> _setPlaybackSpeed(double speed) async {
    if (_player == null) return;
    await _player!.setPlaybackRate(speed);
    if (mounted) {
      setState(() => _playbackSpeed = speed);
    }
  }

  String _getSpeedLabel(double speed) {
    if (speed == 1.0) return '1x';
    if (speed == 0.5) return '0.5x';
    if (speed == 0.75) return '0.75x';
    if (speed == 1.25) return '1.25x';
    if (speed == 1.5) return '1.5x';
    if (speed == 2.0) return '2x';
    return '${speed}x';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (_hasError) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(width: 8),
            Text(
              '音频文件不存在',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              IconButton(
                icon: _isPlaying ? const Icon(Icons.pause) : const Icon(Icons.play_arrow),
                onPressed: _isInitialized ? _togglePlay : null,
                iconSize: 28,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 2,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                  ),
                  child: Slider(
                    value: _duration.inMilliseconds > 0
                        ? (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0)
                        : 0.0,
                    onChanged: _isInitialized ? _seekTo : null,
                  ),
                ),
              ),
              if (widget.showSpeedControl) ...[
                const SizedBox(width: 8),
                _buildSpeedSelector(l10n),
              ],
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DurationFormatter.format(_position),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                ),
                Text(
                  DurationFormatter.format(_duration),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeedSelector(AppLocalizations? l10n) {
    return PopupMenuButton<double>(
      initialValue: _playbackSpeed,
      onSelected: _setPlaybackSpeed,
      tooltip: l10n?.playbackSpeed ?? 'Playback Speed',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          _getSpeedLabel(_playbackSpeed),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ),
      itemBuilder: (_) => _speedOptions.map((speed) {
        return PopupMenuItem<double>(
          value: speed,
          child: Text(_getSpeedLabel(speed)),
        );
      }).toList(),
    );
  }
}