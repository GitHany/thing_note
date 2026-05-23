import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:thing_note/core/utils/duration_formatter.dart';

class AudioPlayerWidget extends StatefulWidget {
  final String audioPath;
  final bool showWaveform;

  const AudioPlayerWidget({
    super.key,
    required this.audioPath,
    this.showWaveform = false,
  });

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  AudioPlayer? _player;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isPlaying = false;
  bool _isInitialized = false;
  bool _hasError = false;
  StreamSubscription<Duration>? _durationSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<void>? _completionSubscription;
  StreamSubscription<PlayerState>? _stateSubscription;

  // Simulated waveform data (in production, this would be computed from actual audio data)
  List<double>? _waveformData;
  double _playbackSpeed = 1.0;

  @override
  void initState() {
    super.initState();
    _checkFileAndInit();
    if (widget.showWaveform) {
      _generateWaveformData();
    }
  }

  void _generateWaveformData() {
    // Generate pseudo-random waveform based on audio path hash
    final random = math.Random(widget.audioPath.hashCode);
    _waveformData = List.generate(50, (index) {
      // Create a natural-looking waveform pattern
      final base = 0.3 + random.nextDouble() * 0.4;
      final variation = math.sin(index * 0.3) * 0.2;
      return (base + variation).clamp(0.1, 1.0);
    });
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
    setState(() {
      _playbackSpeed = speed;
    });
    await _player!.setPlaybackRate(speed);
  }

  @override
  Widget build(BuildContext context) {
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

    if (widget.showWaveform && _waveformData != null) {
      return _buildWaveformPlayer(context);
    }

    return _buildBasicPlayer(context);
  }

  Widget _buildBasicPlayer(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          IconButton(
            icon: _isPlaying
                ? const Icon(Icons.pause)
                : const Icon(Icons.play_arrow),
            onPressed: _isInitialized ? _togglePlay : null,
            iconSize: 28,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 2,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 6,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 12,
                    ),
                  ),
                  child: Slider(
                    value: _duration.inMilliseconds > 0
                        ? (_position.inMilliseconds / _duration.inMilliseconds)
                            .clamp(0.0, 1.0)
                        : 0.0,
                    onChanged: _isInitialized ? _seekTo : null,
                  ),
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
          ),
        ],
      ),
    );
  }

  Widget _buildWaveformPlayer(BuildContext context) {
    final progress = _duration.inMilliseconds > 0
        ? (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;
    final progressIndex = (_waveformData!.length * progress).round();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Waveform visualization
          SizedBox(
            height: 48,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: List.generate(_waveformData!.length, (index) {
                final isPlayed = index <= progressIndex;
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      _seekTo(index / _waveformData!.length);
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      height: 48 * _waveformData![index],
                      decoration: BoxDecoration(
                        color: isPlayed
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.primary.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 12),
          // Controls row
          Row(
            children: [
              // Play/Pause button
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: _isPlaying
                      ? Icon(
                          Icons.pause,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        )
                      : Icon(
                          Icons.play_arrow,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                  onPressed: _isInitialized ? _togglePlay : null,
                ),
              ),
              const SizedBox(width: 12),
              // Time display
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DurationFormatter.format(_position),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          DurationFormatter.format(_duration),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Progress slider
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 2,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 6,
                        ),
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 12,
                        ),
                      ),
                      child: Slider(
                        value: progress,
                        onChanged: _isInitialized ? _seekTo : null,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Playback speed button
              PopupMenuButton<double>(
                tooltip: '播放速度',
                onSelected: _setPlaybackSpeed,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _playbackSpeed != 1.0
                        ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                        : Theme.of(context).colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _playbackSpeed != 1.0
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outline.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.speed,
                        size: 16,
                        color: _playbackSpeed != 1.0
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${_playbackSpeed}x',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: _playbackSpeed != 1.0
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.onSurface,
                              fontWeight: _playbackSpeed != 1.0 ? FontWeight.bold : FontWeight.normal,
                            ),
                      ),
                    ],
                  ),
                ),
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 0.5, child: Text('0.5x')),
                  const PopupMenuItem(value: 0.75, child: Text('0.75x')),
                  const PopupMenuItem(value: 1.0, child: Text('1.0x')),
                  const PopupMenuItem(value: 1.25, child: Text('1.25x')),
                  const PopupMenuItem(value: 1.5, child: Text('1.5x')),
                  const PopupMenuItem(value: 2.0, child: Text('2.0x')),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}