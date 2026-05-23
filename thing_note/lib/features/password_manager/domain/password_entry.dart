import 'dart:convert';

/// 密码记录数据模型
class PasswordEntry {
  final int? id;
  final String title;
  final String? username;
  final String encryptedPassword;
  final String? url;
  final String? note;
  final String? category;
  final String color;
  final bool isFavorite;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PasswordEntry({
    this.id,
    required this.title,
    this.username,
    required this.encryptedPassword,
    this.url,
    this.note,
    this.category,
    this.color = '#607D8B',
    this.isFavorite = false,
    required this.createdAt,
    required this.updatedAt,
  });

  PasswordEntry copyWith({
    int? id,
    String? title,
    String? username,
    String? encryptedPassword,
    String? url,
    String? note,
    String? category,
    String? color,
    bool? isFavorite,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PasswordEntry(
      id: id ?? this.id,
      title: title ?? this.title,
      username: username ?? this.username,
      encryptedPassword: encryptedPassword ?? this.encryptedPassword,
      url: url ?? this.url,
      note: note ?? this.note,
      category: category ?? this.category,
      color: color ?? this.color,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'username': username,
      'encrypted_password': encryptedPassword,
      'url': url,
      'note': note,
      'category': category,
      'color': color,
      'is_favorite': isFavorite ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory PasswordEntry.fromMap(Map<String, dynamic> map) {
    return PasswordEntry(
      id: map['id'] as int?,
      title: map['title'] as String,
      username: map['username'] as String?,
      encryptedPassword: map['encrypted_password'] as String,
      url: map['url'] as String?,
      note: map['note'] as String?,
      category: map['category'] as String?,
      color: map['color'] as String? ?? '#607D8B',
      isFavorite: (map['is_favorite'] as int?) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}

/// 密码加密服务 - 使用简单的Base64编码作为占位符
/// 实际生产环境应使用更安全的加密方案
class PasswordEncryptionService {
  /// 加密密码（简化版本，实际生产应使用AES等强加密）
  static String encrypt(String plainText, String masterPassword) {
    // 使用 masterPassword 作为简单异或密钥
    final keyBytes = utf8.encode(masterPassword);
    final textBytes = utf8.encode(plainText);
    final encrypted = <int>[];
    
    for (var i = 0; i < textBytes.length; i++) {
      encrypted.add(textBytes[i] ^ keyBytes[i % keyBytes.length]);
    }
    
    return base64.encode(encrypted);
  }

  /// 解密密码
  static String decrypt(String encryptedText, String masterPassword) {
    try {
      final keyBytes = utf8.encode(masterPassword);
      final encryptedBytes = base64.decode(encryptedText);
      final decrypted = <int>[];
      
      for (var i = 0; i < encryptedBytes.length; i++) {
        decrypted.add(encryptedBytes[i] ^ keyBytes[i % keyBytes.length]);
      }
      
      return utf8.decode(decrypted);
    } catch (e) {
      return '';
    }
  }
}