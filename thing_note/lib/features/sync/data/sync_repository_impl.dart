import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thing_note/features/record/domain/episode_record.dart';
import 'package:thing_note/features/sync/data/sync_repository.dart';
import 'package:thing_note/features/sync/domain/sync_service.dart';

class LarkSyncRepositoryImpl implements SyncRepository {
  static const _keyLastSyncTime = 'last_sync_time';
  static const _keySyncConfig = 'sync_config';
  static const _keyPendingSync = 'pending_sync_records';

  @override
  Future<SyncResult> syncRecords(List<EpisodeRecord> records) async {
    try {
      // 序列化记录
      final jsonData = records.map((r) => _serializeRecord(r)).toList();

      // 保存到本地作为待同步队列（实际飞书 API 需要另行实现）
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyPendingSync, jsonEncode(jsonData));

      final now = DateTime.now();
      await setLastSyncTime(now);

      return SyncResult(
        status: SyncStatus.success,
        recordsUploaded: records.length,
        lastSyncTime: now,
      );
    } catch (e) {
      return SyncResult(
        status: SyncStatus.failed,
        errorMessage: e.toString(),
      );
    }
  }

  @override
  Future<DateTime?> getLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timeStr = prefs.getString(_keyLastSyncTime);
    if (timeStr == null) return null;
    return DateTime.tryParse(timeStr);
  }

  @override
  Future<void> setLastSyncTime(DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLastSyncTime, time.toIso8601String());
  }

  @override
  Future<SyncConfig> getSyncConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final configJson = prefs.getString(_keySyncConfig);
    if (configJson == null) return const SyncConfig();

    try {
      final map = jsonDecode(configJson) as Map<String, dynamic>;
      return SyncConfig(
        autoSyncEnabled: map['autoSyncEnabled'] as bool? ?? false,
        autoSyncInterval: Duration(minutes: map['autoSyncIntervalMinutes'] as int? ?? 60),
        preferredDirection: SyncDirection.values.firstWhere(
          (e) => e.name == map['preferredDirection'],
          orElse: () => SyncDirection.upload,
        ),
      );
    } catch (_) {
      return const SyncConfig();
    }
  }

  @override
  Future<void> saveSyncConfig(SyncConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySyncConfig, jsonEncode({
      'autoSyncEnabled': config.autoSyncEnabled,
      'autoSyncIntervalMinutes': config.autoSyncInterval.inMinutes,
      'preferredDirection': config.preferredDirection.name,
    }));
  }

  @override
  Future<bool> isConnected() async {
    // TODO: 实现实际的连接检查（飞书 API）
    return true;
  }

  Map<String, dynamic> _serializeRecord(EpisodeRecord record) {
    return {
      'id': record.id,
      'occurred_at': record.occurredAt.toIso8601String(),
      'duration_sec': record.durationSec,
      'note': record.note,
      'thing_name_id': record.thingNameId,
      'has_reminder': record.hasReminder,
      'latitude': record.latitude,
      'longitude': record.longitude,
      'address': record.address,
      'is_favorite': record.isFavorite,
      'repeat_type': record.repeatType,
      'created_at': record.createdAt.toIso8601String(),
      'updated_at': record.updatedAt.toIso8601String(),
    };
  }
}