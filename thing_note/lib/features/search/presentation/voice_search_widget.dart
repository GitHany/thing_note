import 'dart:async';
import 'package:flutter/material.dart';
import 'package:thing_note/l10n/generated/app_localizations.dart';

/// Voice search widget - provides voice input for search
class VoiceSearchDialog extends StatefulWidget {
  final Function(String text) onResult;
  final VoidCallback onCancel;

  const VoiceSearchDialog({
    super.key,
    required this.onResult,
    required this.onCancel,
  });

  @override
  State<VoiceSearchDialog> createState() => _VoiceSearchDialogState();
}

class _VoiceSearchDialogState extends State<VoiceSearchDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  bool _isListening = false;
  String _statusText = '';
  final List<String> _transcript = [];
  Timer? _cancelTimer;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _startListening();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _cancelTimer?.cancel();
    super.dispose();
  }

  Future<void> _startListening() async {
    setState(() {
      _isListening = true;
      _statusText = '正在聆听...';
    });

    // Simulate speech recognition
    // In production, use speech_to_text package
    _cancelTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _isListening) {
        _finishListening();
      }
    });
  }

  Future<void> _finishListening() async {
    setState(() {
      _isListening = false;
      _statusText = '识别完成';
    });

    // Simulate recognized text
    await Future.delayed(const Duration(milliseconds: 500));

    // For demo, use a sample result
    final recognizedText = _generateSampleRecognition();

    if (mounted) {
      widget.onResult(recognizedText);
    }
  }

  String _generateSampleRecognition() {
    // This is a placeholder. In production, use real speech-to-text
    // For now, return a sample based on time of day
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return '工作日志';
    } else if (hour < 18) {
      return '会议记录';
    } else {
      return '学习笔记';
    }
  }

  void _onButtonPressed() {
    if (_isListening) {
      _cancelTimer?.cancel();
      _finishListening();
    } else {
      _startListening();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            Text(
              l10n.voiceSearch,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),

            // Animation circle
            ScaleTransition(
              scale: _pulseAnimation,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isListening
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
                child: Icon(
                  _isListening ? Icons.mic : Icons.mic_off,
                  size: 48,
                  color: _isListening
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Status text
            Text(
              _statusText,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 8),

            // Hint text
            Text(
              _isListening
                  ? '请说出要搜索的关键词'
                  : '点击麦克风开始语音输入',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
            const SizedBox(height: 24),

            // Transcript preview (if any)
            if (_transcript.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _transcript.join(' '),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: widget.onCancel,
                  child: Text(l10n.cancel),
                ),
                FilledButton.icon(
                  icon: Icon(_isListening ? Icons.stop : Icons.mic),
                  label: Text(_isListening ? '停止' : '开始'),
                  onPressed: _onButtonPressed,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Voice search button widget (can be used inline)
class VoiceSearchButton extends StatefulWidget {
  final Function(String text) onResult;

  const VoiceSearchButton({
    super.key,
    required this.onResult,
  });

  @override
  State<VoiceSearchButton> createState() => _VoiceSearchButtonState();
}

class _VoiceSearchButtonState extends State<VoiceSearchButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _isListening
              ? Theme.of(context).colorScheme.error.withOpacity(0.1)
              : Colors.transparent,
        ),
        child: Icon(
          _isListening ? Icons.stop : Icons.mic,
          color: _isListening
              ? Theme.of(context).colorScheme.error
              : Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      onPressed: () async {
        if (_isListening) {
          setState(() => _isListening = false);
          _controller.stop();
        } else {
          setState(() => _isListening = true);
          _controller.repeat(reverse: true);

          // Simulate voice recognition
          await Future.delayed(const Duration(seconds: 2));
          if (mounted) {
            setState(() => _isListening = false);
            _controller.stop();
            widget.onResult('语音搜索结果'); // Placeholder
          }
        }
      },
    );
  }
}