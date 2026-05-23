import 'dart:convert';
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thing_note/features/data_encryption/domain/encryption_service.dart';

class EncryptionRepository {
  static const _keyEnabled = 'encryption_enabled';
  static const _keySalt = 'encryption_salt';
  static const _keyEncryptedFields = 'encrypted_fields';

  final SharedPreferences _prefs;
  Uint8List? _cachedKey;

  EncryptionRepository(this._prefs);

  bool get isEnabled => _prefs.getBool(_keyEnabled) ?? false;

  Uint8List? getEncryptionKey(String passphrase) {
    if (_cachedKey != null) return _cachedKey;

    final saltStr = _prefs.getString(_keySalt);
    if (saltStr == null) return null;

    final salt = base64.decode(saltStr);
    _cachedKey = EncryptionService.deriveKey(passphrase, Uint8List.fromList(salt));
    return _cachedKey;
  }

  Future<void> enableEncryption(String passphrase) async {
    final salt = EncryptionService.generateSalt();
    final key = EncryptionService.deriveKey(passphrase, Uint8List.fromList(salt));

    await _prefs.setBool(_keyEnabled, true);
    await _prefs.setString(_keySalt, base64.encode(salt));

    _cachedKey = key;
  }

  Future<void> disableEncryption() async {
    await _prefs.remove(_keyEnabled);
    await _prefs.remove(_keySalt);
    _cachedKey = null;
  }

  Future<void> changePassphrase(String oldPassphrase, String newPassphrase) async {
    if (!isEnabled) return;

    final oldKey = getEncryptionKey(oldPassphrase);
    if (oldKey == null) throw Exception('Invalid old passphrase');

    // Generate new key
    final newSalt = EncryptionService.generateSalt();
    final newKey = EncryptionService.deriveKey(newPassphrase, Uint8List.fromList(newSalt));

    // Update salt
    await _prefs.setString(_keySalt, base64.encode(newSalt));
    _cachedKey = newKey;
  }

  int getEncryptedFieldsCount() {
    return _prefs.getStringList(_keyEncryptedFields)?.length ?? 0;
  }

  Future<void> markFieldEncrypted(String fieldName) async {
    final fields = _prefs.getStringList(_keyEncryptedFields) ?? [];
    if (!fields.contains(fieldName)) {
      fields.add(fieldName);
      await _prefs.setStringList(_keyEncryptedFields, fields);
    }
  }

  EncryptionStatus getStatus() {
    return EncryptionStatus(
      isEnabled: isEnabled,
      encryptedFields: getEncryptedFieldsCount(),
    );
  }
}