/// Biometric authentication settings
class BiometricSettings {
  final bool isEnabled;
  final bool useFingerprint;
  final bool useFaceRecognition;
  final bool requireOnAppResume;
  final int autoLockMinutes;
  final DateTime? lastAuthenticated;

  BiometricSettings({
    this.isEnabled = false,
    this.useFingerprint = true,
    this.useFaceRecognition = true,
    this.requireOnAppResume = true,
    this.autoLockMinutes = 5,
    this.lastAuthenticated,
  });

  BiometricSettings copyWith({
    bool? isEnabled,
    bool? useFingerprint,
    bool? useFaceRecognition,
    bool? requireOnAppResume,
    int? autoLockMinutes,
    DateTime? lastAuthenticated,
  }) {
    return BiometricSettings(
      isEnabled: isEnabled ?? this.isEnabled,
      useFingerprint: useFingerprint ?? this.useFingerprint,
      useFaceRecognition: useFaceRecognition ?? this.useFaceRecognition,
      requireOnAppResume: requireOnAppResume ?? this.requireOnAppResume,
      autoLockMinutes: autoLockMinutes ?? this.autoLockMinutes,
      lastAuthenticated: lastAuthenticated ?? this.lastAuthenticated,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'is_enabled': isEnabled ? 1 : 0,
      'use_fingerprint': useFingerprint ? 1 : 0,
      'use_face_recognition': useFaceRecognition ? 1 : 0,
      'require_on_app_resume': requireOnAppResume ? 1 : 0,
      'auto_lock_minutes': autoLockMinutes,
      'last_authenticated': lastAuthenticated?.toIso8601String(),
    };
  }

  factory BiometricSettings.fromMap(Map<String, dynamic> map) {
    return BiometricSettings(
      isEnabled: (map['is_enabled'] as int?) == 1,
      useFingerprint: (map['use_fingerprint'] as int?) == 1,
      useFaceRecognition: (map['use_face_recognition'] as int?) == 1,
      requireOnAppResume: (map['require_on_app_resume'] as int?) == 1,
      autoLockMinutes: map['auto_lock_minutes'] as int? ?? 5,
      lastAuthenticated: map['last_authenticated'] != null
          ? DateTime.parse(map['last_authenticated'] as String)
          : null,
    );
  }
}

/// Authentication result
enum AuthResult {
  success,
  failed,
  notAvailable,
  cancelled,
  notEnrolled,
}

/// Supported biometric types
enum BiometricLockType {
  fingerprint,
  face,
  iris,
  none,
}