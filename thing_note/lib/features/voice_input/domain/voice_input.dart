/// Voice input result
class VoiceInputResult {
  final int? id;
  final String transcribedText;
  final double confidence;
  final bool used;
  final DateTime createdAt;

  VoiceInputResult({
    this.id,
    required this.transcribedText,
    this.confidence = 1.0,
    this.used = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'transcribed_text': transcribedText,
      'confidence': confidence,
      'used': used ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory VoiceInputResult.fromMap(Map<String, dynamic> map) {
    return VoiceInputResult(
      id: map['id'] as int?,
      transcribedText: map['transcribed_text'] as String,
      confidence: (map['confidence'] as num?)?.toDouble() ?? 1.0,
      used: (map['used'] as int?) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  VoiceInputResult copyWith({
    int? id,
    String? transcribedText,
    double? confidence,
    bool? used,
    DateTime? createdAt,
  }) {
    return VoiceInputResult(
      id: id ?? this.id,
      transcribedText: transcribedText ?? this.transcribedText,
      confidence: confidence ?? this.confidence,
      used: used ?? this.used,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Voice input state
enum VoiceInputState {
  idle,
  listening,
  processing,
  success,
  error,
}

/// Voice input configuration
class VoiceInputConfig {
  final String language;
  final bool continuousMode;
  final int maxDurationSeconds;
  final bool autoSend;

  VoiceInputConfig({
    this.language = 'zh-CN',
    this.continuousMode = false,
    this.maxDurationSeconds = 60,
    this.autoSend = false,
  });
}