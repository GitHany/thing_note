import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:thing_note/l10n/generated/app_localizations.dart';

class EnhancedVideoPlayerWidget extends StatefulWidget {
  final String videoPath;
  final bool autoPlay;

  const EnhancedVideoPlayerWidget({
    super.key,
    required this.videoPath,
    this.autoPlay = false,
  });

  @override
  State<EnhancedVideoPlayerWidget> createState() => _EnhancedVideoPlayerWidgetState();
}

class _EnhancedVideoPlayerWidgetState extends State<EnhancedVideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  bool _showControls = true;
  double _playbackSpeed = 1.0;
  double _currentPosition = 0;
  double _totalDuration = 1;

  final List<double> _speedOptions = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    try {
      _controller = VideoPlayerController.file(File(widget.videoPath))
        ..initialize().then((_) {
          if (mounted) {
            setState(() {
              _isInitialized = true;
              _totalDuration = _controller.value.duration.inMilliseconds.toDouble();
            });
            if (widget.autoPlay) {
              _controller.play();
            }
          }
        }).catchError((error) {
          if (mounted) {
            setState(() => _hasError = true);
          }
        });

      _controller.addListener(() {
        if (mounted) {
          setState(() {
            _currentPosition = _controller.value.position.inMilliseconds.toDouble();
          });
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() => _hasError = true);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlay() {
    if (!_isInitialized) return;
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
      } else {
        _controller.play();
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  void _seekTo(double value) {
    final position = Duration(milliseconds: (value * _totalDuration).round());
    _controller.seekTo(position);
  }

  void _setPlaybackSpeed(double speed) async {
    await _controller.setPlaybackSpeed(speed);
    if (mounted) {
      setState(() => _playbackSpeed = speed);
    }
  }

  void _toggleFullscreen() {
    // In a real app, this would enter/exit fullscreen mode
    // For now, just toggle system UI
    if (_showControls) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    _toggleControls();
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
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
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error, size: 48),
              const SizedBox(height: 16),
              Text(
                l10n?.loadFailed('') ?? 'Failed to load video',
                style: const TextStyle(color: Colors.white54),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isInitialized) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return GestureDetector(
      onTap: _toggleControls,
      child: Container(
        color: Colors.black,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Video
            AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: VideoPlayer(_controller),
            ),

            // Controls overlay
            if (_showControls) ...[
              // Semi-transparent background
              Positioned.fill(
                child: Container(color: Colors.black26),
              ),

              // Center play button
              IconButton(
                icon: Icon(
                  _controller.value.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                  size: 72,
                  color: Colors.white,
                ),
                onPressed: _togglePlay,
              ),

              // Bottom controls
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Progress bar
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 4,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                          activeTrackColor: Theme.of(context).colorScheme.primary,
                          inactiveTrackColor: Colors.white30,
                          thumbColor: Theme.of(context).colorScheme.primary,
                        ),
                        child: Slider(
                          value: _totalDuration > 0
                              ? (_currentPosition / _totalDuration).clamp(0.0, 1.0)
                              : 0.0,
                          onChanged: _seekTo,
                        ),
                      ),

                      // Bottom row with time, speed, and fullscreen
                      Row(
                        children: [
                          Text(
                            _formatDuration(_controller.value.position),
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '/ ${_formatDuration(_controller.value.duration)}',
                            style: const TextStyle(color: Colors.white54, fontSize: 12),
                          ),
                          const Spacer(),
                          // Speed button
                          PopupMenuButton<double>(
                            initialValue: _playbackSpeed,
                            onSelected: _setPlaybackSpeed,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white24,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _getSpeedLabel(_playbackSpeed),
                                style: const TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            ),
                            itemBuilder: (_) => _speedOptions.map((speed) {
                              return PopupMenuItem<double>(
                                value: speed,
                                child: Text(_getSpeedLabel(speed)),
                              );
                            }).toList(),
                          ),
                          const SizedBox(width: 8),
                          // Fullscreen button
                          IconButton(
                            icon: const Icon(Icons.fullscreen, color: Colors.white),
                            onPressed: _toggleFullscreen,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}