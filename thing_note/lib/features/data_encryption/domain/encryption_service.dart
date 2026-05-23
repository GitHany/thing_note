import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:pointycastle/export.dart';

/// Encryption service for secure data storage
class EncryptionService {
  static const int _keyLength = 32; // 256 bits
  static const int _ivLength = 16; // 128 bits

  /// Generate a secure encryption key from passphrase
  static Uint8List deriveKey(String passphrase, Uint8List salt) {
    final pbkdf2 = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64))
      ..init(Pbkdf2Parameters(salt, 10000, _keyLength));

    return pbkdf2.process(Uint8List.fromList(utf8.encode(passphrase)));
  }

  /// Generate a random salt
  static Uint8List generateSalt() {
    final random = Random.secure();
    return Uint8List.fromList(
      List.generate(_ivLength, (_) => random.nextInt(256)),
    );
  }

  /// Generate a random IV
  static Uint8List generateIV() {
    final random = Random.secure();
    return Uint8List.fromList(
      List.generate(_ivLength, (_) => random.nextInt(256)),
    );
  }

  /// Encrypt data with AES-GCM
  static Uint8List encrypt(Uint8List data, Uint8List key) {
    final iv = generateIV();
    final cipher = GCMBlockCipher(AESEngine())
      ..init(
        true,
        AEADParameters(
          KeyParameter(key),
          128,
          iv,
          Uint8List(0),
        ),
      );

    final cipherText = cipher.process(data);
    final result = Uint8List(iv.length + cipherText.length);
    result.setAll(0, iv);
    result.setAll(iv.length, cipherText);

    return result;
  }

  /// Decrypt data with AES-GCM
  static Uint8List? decrypt(Uint8List encryptedData, Uint8List key) {
    if (encryptedData.length < _ivLength + 16) return null;

    final iv = encryptedData.sublist(0, _ivLength);
    final cipherText = encryptedData.sublist(_ivLength);

    final cipher = GCMBlockCipher(AESEngine())
      ..init(
        false,
        AEADParameters(
          KeyParameter(key),
          128,
          iv,
          Uint8List(0),
        ),
      );

    try {
      return cipher.process(cipherText);
    } catch (e) {
      return null;
    }
  }

  /// Encrypt a string
  static String encryptString(String plainText, Uint8List key) {
    final encrypted = encrypt(Uint8List.fromList(utf8.encode(plainText)), key);
    return base64.encode(encrypted);
  }

  /// Decrypt a string
  static String? decryptString(String encryptedText, Uint8List key) {
    try {
      final encrypted = base64.decode(encryptedText);
      final decrypted = decrypt(Uint8List.fromList(encrypted), key);
      if (decrypted == null) return null;
      return utf8.decode(decrypted);
    } catch (e) {
      return null;
    }
  }
}

/// Data encryption status
class EncryptionStatus {
  final bool isEnabled;
  final DateTime? lastEncrypted;
  final int encryptedFields;

  EncryptionStatus({
    required this.isEnabled,
    this.lastEncrypted,
    this.encryptedFields = 0,
  });
}