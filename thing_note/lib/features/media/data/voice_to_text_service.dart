import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Voice to text service using platform channels
/// This is a simplified implementation that uses speech recognition
class VoiceToTextService {
  static const _channel = MethodChannel('thing_note/voice_to_text');

  bool _isListening = false;
  String _lastRecognizedText = '';
  Function(String)? _onResult;
  Function(String)? _onError;

  bool get isListening => _isListening;
  String get lastRecognizedText => _lastRecognizedText;

  /// Check if speech recognition is available on this device
  Future<bool> isAvailable() async {
    try {
      final result = await _channel.invokeMethod<bool>('isAvailable');
      return result ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      // Platform channel not implemented, speech-to-text not available
      return false;
    }
  }

  /// Start listening for speech input
  Future<bool> startListening({
    Function(String)? onResult,
    Function(String)? onError,
    String locale = 'zh_CN',
  }) async {
    if (_isListening) return false;

    try {
      _onResult = onResult;
      _onError = onError;

      final available = await isAvailable();
      if (!available) {
        onError?.call('speech_to_text_unavailable');
        return false;
      }

      _isListening = true;

      _channel.setMethodCallHandler((call) async {
        if (call.method == 'onResult') {
          final text = call.arguments as String?;
          if (text != null && text.isNotEmpty) {
            _lastRecognizedText = text;
            _onResult?.call(text);
          }
        } else if (call.method == 'onError') {
          final error = call.arguments as String? ?? 'unknown_error';
          _onError?.call(error);
          _isListening = false;
        } else if (call.method == 'onDone') {
          _isListening = false;
        }
      });

      await _channel.invokeMethod('startListening', {'locale': locale});
      return true;
    } on PlatformException catch (e) {
      _isListening = false;
      _onError?.call(e.message ?? 'unknown_error');
      return false;
    }
  }

  /// Stop listening
  Future<void> stopListening() async {
    if (!_isListening) return;

    try {
      await _channel.invokeMethod('stopListening');
    } on PlatformException {
      // Ignore errors when stopping
    }

    _isListening = false;
  }

  /// Cancel listening
  Future<void> cancelListening() async {
    if (!_isListening) return;

    try {
      await _channel.invokeMethod('cancelListening');
    } on PlatformException {
      // Ignore errors when cancelling
    }

    _isListening = false;
    _lastRecognizedText = '';
  }

  void dispose() {
    cancelListening();
    _onResult = null;
    _onError = null;
  }
}

/// Simple voice-to-text UI widget that provides basic functionality
/// Note: Full implementation requires platform-specific code
class VoiceToTextWidget extends StatefulWidget {
  final Function(String text) onResult;
  final Function(String error)? onError;
  final String? buttonText;

  const VoiceToTextWidget({
    super.key,
    required this.onResult,
    this.onError,
    this.buttonText,
  });

  @override
  State<VoiceToTextWidget> createState() => _VoiceToTextWidgetState();
}

class _VoiceToTextWidgetState extends State<VoiceToTextWidget> {
  final _voiceService = VoiceToTextService();
  bool _isListening = false;
  String _recognizedText = '';
  bool _isAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkAvailability();
  }

  Future<void> _checkAvailability() async {
    final available = await _voiceService.isAvailable();
    if (mounted) {
      setState(() => _isAvailable = available);
    }
  }

  void _toggleListening() async {
    if (_isListening) {
      await _voiceService.stopListening();
      if (mounted) {
        setState(() => _isListening = false);
      }
    } else {
      final started = await _voiceService.startListening(
        onResult: (text) {
          if (mounted) {
            setState(() => _recognizedText = text);
          }
        },
        onError: (error) {
          if (mounted) {
            setState(() => _isListening = false);
            widget.onError?.call(error);
          }
        },
      );
      if (mounted) {
        setState(() => _isListening = started);
      }
    }
  }

  void _submitResult() {
    if (_recognizedText.isNotEmpty) {
      widget.onResult(_recognizedText);
      setState(() => _recognizedText = '');
    }
  }

  @override
  void dispose() {
    _voiceService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAvailable) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(
            _isListening ? Icons.mic : Icons.mic_none,
            color: _isListening ? Colors.red : null,
          ),
          onPressed: _toggleListening,
          tooltip: widget.buttonText ?? 'Voice to Text',
        ),
        if (_isListening || _recognizedText.isNotEmpty) ...[
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _recognizedText.isNotEmpty ? _submitResult : null,
            tooltip: 'Use text',
          ),
          if (_isListening)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ],
    );
  }
}