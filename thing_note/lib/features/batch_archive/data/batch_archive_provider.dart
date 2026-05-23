// Batch Archive System feature
// Version: 1.0
// Description: 批量归档系统，自动或手动归档旧数据以优化性能

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/core/database/database_provider.dart';

// Batch Archive Provider
final archiveConfigProvider = FutureProvider<ArchiveConfig>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  
  final List<Map<String, dynamic>> maps = await db.query(
    'archive_config',
    limit: 1,
  );
  
  if (maps.isNotEmpty) {
    return ArchiveConfig.fromMap(maps.first);
  }
  
  return ArchiveConfig.defaultConfig();
});

final archiveJobsProvider = FutureProvider<List<ArchiveJob>>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  
  final List<Map<String, dynamic>> maps = await db.query(
    'archive_jobs',
    orderBy: 'created_at DESC',
  );
  
  return maps.map((map) => ArchiveJob.fromMap(map)).toList();
});

final archiveStatsProvider = FutureProvider<ArchiveStats>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  
  // Count archived records
  final archived = await db.rawQuery('''
    SELECT COUNT(*) as count FROM episode_records WHERE is_archived = 1
  ''');
  
  // Count active records
  final active = await db.rawQuery('''
    SELECT COUNT(*) as count FROM episode_records WHERE is_archived = 0 OR is_archived IS NULL
  ''');
  
  // Get total storage used by archived records
  final storage = await db.rawQuery('''
    SELECT SUM(photo_size + audio_size + video_size) as total FROM archived_records
  ''');
  
  // Get archive jobs count
  final jobs = await db.query('archive_jobs');
  
  return ArchiveStats(
    archivedCount: (archived.first['count'] as int?) ?? 0,
    activeCount: (active.first['count'] as int?) ?? 0,
    totalStorageBytes: (storage.first['total'] as int?) ?? 0,
    totalJobs: jobs.length,
  );
});

class ArchiveConfig {
  final int? id;
  final bool autoArchiveEnabled;
  final int autoArchiveAfterDays;
  final List<String> excludeCategories;
  final int batchSize;
  final bool compressMedia;
  final int compressionQuality;

  ArchiveConfig({
    this.id,
    this.autoArchiveEnabled = false,
    this.autoArchiveAfterDays = 365,
    this.excludeCategories = const [],
    this.batchSize = 100,
    this.compressMedia = true,
    this.compressionQuality = 70,
  });

  factory ArchiveConfig.fromMap(Map<String, dynamic> map) {
    return ArchiveConfig(
      id: map['id'] as int?,
      autoArchiveEnabled: (map['auto_archive_enabled'] as int?) == 1,
      autoArchiveAfterDays: map['auto_archive_days'] as int? ?? 365,
      excludeCategories: (map['exclude_categories'] as String?)?.split(',') ?? [],
      batchSize: map['batch_size'] as int? ?? 100,
      compressMedia: (map['compress_media'] as int?) == 1,
      compressionQuality: map['compression_quality'] as int? ?? 70,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'auto_archive_enabled': autoArchiveEnabled ? 1 : 0,
      'auto_archive_days': autoArchiveAfterDays,
      'exclude_categories': excludeCategories.join(','),
      'batch_size': batchSize,
      'compress_media': compressMedia ? 1 : 0,
      'compression_quality': compressionQuality,
    };
  }

  factory ArchiveConfig.defaultConfig() {
    return ArchiveConfig();
  }
}

class ArchiveJob {
  final int? id;
  final String name;
  final String type;
  final DateTime createdAt;
  final DateTime? completedAt;
  final int recordsAffected;
  final int storageFreed;
  final String status;
  final String? error;

  ArchiveJob({
    this.id,
    required this.name,
    required this.type,
    required this.createdAt,
    this.completedAt,
    this.recordsAffected = 0,
    this.storageFreed = 0,
    this.status = 'pending',
    this.error,
  });

  factory ArchiveJob.fromMap(Map<String, dynamic> map) {
    return ArchiveJob(
      id: map['id'] as int?,
      name: map['name'] as String,
      type: map['type'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      completedAt: map['completed_at'] != null
          ? DateTime.parse(map['completed_at'] as String)
          : null,
      recordsAffected: map['records_affected'] as int? ?? 0,
      storageFreed: map['storage_freed'] as int? ?? 0,
      status: map['status'] as String? ?? 'pending',
      error: map['error'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type,
      'created_at': createdAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'records_affected': recordsAffected,
      'storage_freed': storageFreed,
      'status': status,
      'error': error,
    };
  }

  IconData get icon {
    switch (type) {
      case 'auto':
        return Icons.auto_awesome;
      case 'manual':
        return Icons.handyman;
      case 'scheduled':
        return Icons.schedule;
      default:
        return Icons.archive;
    }
  }

  Color get statusColor {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'running':
        return Colors.blue;
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

class ArchiveStats {
  final int archivedCount;
  final int activeCount;
  final int totalStorageBytes;
  final int totalJobs;

  ArchiveStats({
    required this.archivedCount,
    required this.activeCount,
    required this.totalStorageBytes,
    required this.totalJobs,
  });

  String get formattedStorage {
    if (totalStorageBytes < 1024) {
      return '${totalStorageBytes}B';
    } else if (totalStorageBytes < 1024 * 1024) {
      return '${(totalStorageBytes / 1024).toStringAsFixed(1)}KB';
    } else if (totalStorageBytes < 1024 * 1024 * 1024) {
      return '${(totalStorageBytes / 1024 / 1024).toStringAsFixed(1)}MB';
    } else {
      return '${(totalStorageBytes / 1024 / 1024 / 1024).toStringAsFixed(1)}GB';
    }
  }

  int get totalRecords => archivedCount + activeCount;
  double get archivePercent => totalRecords > 0 ? archivedCount / totalRecords * 100 : 0;
}

// Archive Filters
class ArchiveFilters {
  static String byDateRange(DateTime start, DateTime end) => '''
    occurred_at >= '${start.toIso8601String()}' AND occurred_at <= '${end.toIso8601String()}'
  ''';

  static String byCategory(String category) => '''
    thing_name_id IN (SELECT id FROM thing_names WHERE name = '$category')
  ''';

  static String byTag(String tag) => '''
    id IN (SELECT record_id FROM record_tags WHERE tag_name = '$tag')
  ''';

  static String olderThan(int days) => '''
    occurred_at <= datetime('now', '-$days days')
  ''';

  static const noMedia = '''
    photo_paths = '[]' AND audio_paths = '[]' AND video_paths = '[]'
  ''';

  static const noLocation = 'latitude IS NULL AND longitude IS NULL';
}