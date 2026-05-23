import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 备份条目
class BackupEntry {
  final String id;
  final String name;
  final DateTime createdAt;
  final int sizeBytes;
  final int recordCount;
  final int mediaCount;
  final bool isEncrypted;
  final String? checksum;

  const BackupEntry({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.sizeBytes,
    required this.recordCount,
    required this.mediaCount,
    this.isEncrypted = false,
    this.checksum,
  });

  String get formattedSize {
    if (sizeBytes < 1024 * 1024) return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// 备份配置
class BackupConfig {
  final bool autoBackup;
  final String frequency; // daily, weekly, monthly
  final int maxBackups;
  final bool includeMedia;
  final bool encryptBackup;

  const BackupConfig({
    this.autoBackup = true,
    this.frequency = 'daily',
    this.maxBackups = 10,
    this.includeMedia = true,
    this.encryptBackup = false,
  });
}

/// 智能备份恢复 Provider
final smartBackupProvider = StateNotifierProvider<SmartBackupNotifier, AsyncValue<List<BackupEntry>>>((ref) {
  return SmartBackupNotifier();
});

class SmartBackupNotifier extends StateNotifier<AsyncValue<List<BackupEntry>>> {
  SmartBackupNotifier() : super(const AsyncValue.loading());

  Future<void> loadBackups() async {
    state = const AsyncValue.loading();
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      state = AsyncValue.data([
        BackupEntry(id: '1', name: '备份 2024-01-15', createdAt: DateTime.now().subtract(const Duration(days: 7)), sizeBytes: 52428800, recordCount: 1000, mediaCount: 500),
        BackupEntry(id: '2', name: '备份 2024-01-22', createdAt: DateTime.now().subtract(const Duration(days: 1)), sizeBytes: 52428800, recordCount: 1200, mediaCount: 550, isEncrypted: true),
      ]);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> createBackup() async {
    // 实现备份逻辑
    await Future.delayed(const Duration(seconds: 2));
    await loadBackups();
  }

  Future<void> restoreBackup(String id) async {
    // 实现恢复逻辑
    await Future.delayed(const Duration(seconds: 3));
  }
}

/// 备份配置 Provider
final backupConfigProvider = StateNotifierProvider<BackupConfigNotifier, BackupConfig>((ref) {
  return BackupConfigNotifier();
});

class BackupConfigNotifier extends StateNotifier<BackupConfig> {
  BackupConfigNotifier() : super(const BackupConfig());

  void updateConfig(BackupConfig config) => state = config;
}