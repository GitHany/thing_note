import 'dart:math';
import 'package:flutter/material.dart';

class GeneratedPassword {
  final int? id;
  final String password;
  final int strengthScore;
  final int length;
  final bool hasUppercase;
  final bool hasNumbers;
  final bool hasSymbols;
  final String createdAt;

  GeneratedPassword({
    this.id,
    required this.password,
    required this.strengthScore,
    required this.length,
    required this.hasUppercase,
    required this.hasNumbers,
    required this.hasSymbols,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'password': password,
      'strength_score': strengthScore,
      'length': length,
      'has_uppercase': hasUppercase ? 1 : 0,
      'has_numbers': hasNumbers ? 1 : 0,
      'has_symbols': hasSymbols ? 1 : 0,
      'created_at': createdAt,
    };
  }

  factory GeneratedPassword.fromMap(Map<String, dynamic> map) {
    return GeneratedPassword(
      id: map['id'] as int?,
      password: map['password'] as String,
      strengthScore: map['strength_score'] as int,
      length: map['length'] as int,
      hasUppercase: (map['has_uppercase'] as int?) == 1,
      hasNumbers: (map['has_numbers'] as int?) == 1,
      hasSymbols: (map['has_symbols'] as int?) == 1,
      createdAt: map['created_at'] as String,
    );
  }

  String get strengthLabel {
    if (strengthScore < 25) return '弱';
    if (strengthScore < 50) return '中等';
    if (strengthScore < 75) return '强';
    return '极强';
  }

  double get strengthProgress => strengthScore / 100;

  static Color getStrengthColor(int score) {
    if (score < 25) return Colors.red;
    if (score < 50) return Colors.orange;
    if (score < 75) return Colors.lightGreen;
    return Colors.green;
  }
}

class PasswordGeneratorOptions {
  final int length;
  final bool includeUppercase;
  final bool includeLowercase;
  final bool includeNumbers;
  final bool includeSymbols;

  const PasswordGeneratorOptions({
    this.length = 16,
    this.includeUppercase = true,
    this.includeLowercase = true,
    this.includeNumbers = true,
    this.includeSymbols = true,
  });

  PasswordGeneratorOptions copyWith({
    int? length,
    bool? includeUppercase,
    bool? includeLowercase,
    bool? includeNumbers,
    bool? includeSymbols,
  }) {
    return PasswordGeneratorOptions(
      length: length ?? this.length,
      includeUppercase: includeUppercase ?? this.includeUppercase,
      includeLowercase: includeLowercase ?? this.includeLowercase,
      includeNumbers: includeNumbers ?? this.includeNumbers,
      includeSymbols: includeSymbols ?? this.includeSymbols,
    );
  }
}

class PasswordGenerator {
  static const String _lowercase = 'abcdefghijklmnopqrstuvwxyz';
  static const String _uppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  static const String _numbers = '0123456789';
  static const String _symbols = '!@#\$%^&*()_+-=[]{}|;:,.<>?';

  static GeneratedPassword generate(PasswordGeneratorOptions options) {
    String chars = '';
    if (options.includeLowercase) chars += _lowercase;
    if (options.includeUppercase) chars += _uppercase;
    if (options.includeNumbers) chars += _numbers;
    if (options.includeSymbols) chars += _symbols;

    if (chars.isEmpty) {
      chars = _lowercase + _numbers;
    }

    final random = Random.secure();
    final password = List.generate(
      options.length,
      (_) => chars[random.nextInt(chars.length)],
    ).join();

    // Calculate strength
    int strength = 0;

    // Length contribution (up to 30 points)
    strength += (options.length * 2).clamp(0, 30);

    // Character variety contribution (up to 40 points)
    if (options.includeUppercase) strength += 10;
    if (options.includeLowercase) strength += 10;
    if (options.includeNumbers) strength += 10;
    if (options.includeSymbols) strength += 10;

    // Entropy bonus (up to 30 points)
    final charSetSize = chars.length;
    final entropy = options.length * (log(charSetSize) / log(2));
    if (entropy >= 60) {
      strength += 30;
    } else if (entropy >= 40) {
      strength += 20;
    } else if (entropy >= 25) {
      strength += 10;
    }

    return GeneratedPassword(
      password: password,
      strengthScore: strength.clamp(0, 100),
      length: options.length,
      hasUppercase: options.includeUppercase,
      hasNumbers: options.includeNumbers,
      hasSymbols: options.includeSymbols,
      createdAt: DateTime.now().toIso8601String(),
    );
  }

  static List<String> suggestPasswords(PasswordGeneratorOptions options) {
    final suggestions = <String>[];
    
    // Generate multiple options
    for (int i = 0; i < 3; i++) {
      suggestions.add(generate(options).password);
    }
    
    return suggestions;
  }

  static bool validatePassword(String password) {
    if (password.length < 8) return false;
    
    bool hasUpper = false, hasLower = false, hasDigit = false, hasSpecial = false;
    
    for (final char in password.split('')) {
      if (char.contains(RegExp(r'[A-Z]'))) hasUpper = true;
      if (char.contains(RegExp(r'[a-z]'))) hasLower = true;
      if (char.contains(RegExp(r'[0-9]'))) hasDigit = true;
      if (char.contains(RegExp(r'[!@#$%^&*()_+\-=\[\]{}|;:,.<>?]'))) hasSpecial = true;
    }
    
    final int types = [hasUpper, hasLower, hasDigit, hasSpecial].where((t) => t).length;
    
    return types >= 2;
  }
}
