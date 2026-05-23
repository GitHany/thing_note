import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thing_note/features/biometric_lock/domain/biometric_settings.dart';

final biometricRepositoryProvider = Provider((ref) => BiometricRepository());

class BiometricRepository {
  static const String _keyEnabled = 'biometric_enabled';
  static const String _keyFingerprint = 'biometric_fingerprint';
  static const String _keyFaceRecognition = 'biometric_face';
  static const String _keyRequireOnResume = 'biometric_require_resume';
  static const String _keyAutoLockMinutes = 'biometric_auto_lock_minutes';
  static const String _keyLastAuth = 'biometric_last_auth';

  Future<SharedPreferences> get _prefs async =>
      await SharedPreferences.getInstance();

  Future<BiometricSettings> getSettings() async {
    final prefs = await _prefs;
    return BiometricSettings(
      isEnabled: prefs.getBool(_keyEnabled) ?? false,
      useFingerprint: prefs.getBool(_keyFingerprint) ?? true,
      useFaceRecognition: prefs.getBool(_keyFaceRecognition) ?? true,
      requireOnAppResume: prefs.getBool(_keyRequireOnResume) ?? true,
      autoLockMinutes: prefs.getInt(_keyAutoLockMinutes) ?? 5,
      lastAuthenticated: prefs.getString(_keyLastAuth) != null
          ? DateTime.parse(prefs.getString(_keyLastAuth)!)
          : null,
    );
  }

  Future<void> saveSettings(BiometricSettings settings) async {
    final prefs = await _prefs;
    await prefs.setBool(_keyEnabled, settings.isEnabled);
    await prefs.setBool(_keyFingerprint, settings.useFingerprint);
    await prefs.setBool(_keyFaceRecognition, settings.useFaceRecognition);
    await prefs.setBool(_keyRequireOnResume, settings.requireOnAppResume);
    await prefs.setInt(_keyAutoLockMinutes, settings.autoLockMinutes);
    if (settings.lastAuthenticated != null) {
      await prefs.setString(
        _keyLastAuth,
        settings.lastAuthenticated!.toIso8601String(),
      );
    }
  }

  Future<void> updateLastAuthenticated() async {
    final prefs = await _prefs;
    await prefs.setString(
      _keyLastAuth,
      DateTime.now().toIso8601String(),
    );
  }

  Future<bool> isLockRequired() async {
    final settings = await getSettings();
    if (!settings.isEnabled) return false;

    if (settings.lastAuthenticated == null) return true;

    final diff = DateTime.now().difference(settings.lastAuthenticated!);
    return diff.inMinutes >= settings.autoLockMinutes;
  }

  Future<void> clearSettings() async {
    final prefs = await _prefs;
    await prefs.remove(_keyEnabled);
    await prefs.remove(_keyFingerprint);
    await prefs.remove(_keyFaceRecognition);
    await prefs.remove(_keyRequireOnResume);
    await prefs.remove(_keyAutoLockMinutes);
    await prefs.remove(_keyLastAuth);
  }
}