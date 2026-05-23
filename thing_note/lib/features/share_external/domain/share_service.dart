import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/core/database/database_provider.dart';
import 'package:sqflite/sqflite.dart';

class ShareDestination {
  final int? id;
  final String name;
  final String type; // 'email' | 'twitter' | 'facebook' | 'weibo' | 'notion' | 'api'
  final String? config;
  final bool isEnabled;
  final DateTime createdAt;

  ShareDestination({
    this.id,
    required this.name,
    required this.type,
    this.config,
    this.isEnabled = true,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'config': config,
      'is_enabled': isEnabled ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ShareDestination.fromMap(Map<String, dynamic> map) {
    return ShareDestination(
      id: map['id'] as int?,
      name: map['name'] as String,
      type: map['type'] as String,
      config: map['config'] as String?,
      isEnabled: (map['is_enabled'] as int?) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  ShareDestination copyWith({
    int? id,
    String? name,
    String? type,
    String? config,
    bool? isEnabled,
    DateTime? createdAt,
  }) {
    return ShareDestination(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      config: config ?? this.config,
      isEnabled: isEnabled ?? this.isEnabled,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class ShareRecordResult {
  final bool success;
  final String? message;
  final String? url;

  ShareRecordResult({required this.success, this.message, this.url});
}

class ShareService {
  Future<ShareRecordResult> shareToEmail(String subject, String content) async {
    // Mock implementation - would use share_plus
    return ShareRecordResult(
      success: true,
      message: '邮件发送成功',
    );
  }

  Future<ShareRecordResult> shareToTwitter(String content) async {
    // Mock implementation
    return ShareRecordResult(
      success: true,
      message: '已分享到 Twitter',
    );
  }

  Future<ShareRecordResult> shareToWeibo(String content) async {
    // Mock implementation
    return ShareRecordResult(
      success: true,
      message: '已分享到微博',
    );
  }

  Future<ShareRecordResult> shareToNotion(String content, String? pageId) async {
    // Mock implementation
    return ShareRecordResult(
      success: true,
      message: '已同步到 Notion',
      url: 'https://notion.so/page/$pageId',
    );
  }

  Future<ShareRecordResult> shareViaApi(String endpoint, Map<String, dynamic> data) async {
    // Mock implementation
    return ShareRecordResult(
      success: true,
      message: 'API 同步成功',
    );
  }
}

class ShareRepository {
  final Database _db;

  ShareRepository(this._db);

  Future<int> insert(ShareDestination destination) async {
    return _db.insert('share_destinations', destination.toMap()..remove('id'));
  }

  Future<int> update(ShareDestination destination) async {
    return _db.update(
      'share_destinations',
      destination.toMap(),
      where: 'id = ?',
      whereArgs: [destination.id],
    );
  }

  Future<int> delete(int id) async {
    return _db.delete('share_destinations', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<ShareDestination>> getAll() async {
    final results = await _db.query('share_destinations', orderBy: 'created_at DESC');
    return results.map((e) => ShareDestination.fromMap(e)).toList();
  }

  Future<List<ShareDestination>> getEnabled() async {
    final results = await _db.query(
      'share_destinations',
      where: 'is_enabled = ?',
      whereArgs: [1],
    );
    return results.map((e) => ShareDestination.fromMap(e)).toList();
  }
}

final shareServiceProvider = Provider<ShareService>((ref) {
  return ShareService();
});

final shareRepositoryProvider = Provider<ShareRepository>((ref) {
  final db = ref.watch(databaseProvider).requireValue;
  return ShareRepository(db);
});

final shareDestinationsProvider = FutureProvider<List<ShareDestination>>((ref) async {
  final repo = ref.watch(shareRepositoryProvider);
  return repo.getAll();
});