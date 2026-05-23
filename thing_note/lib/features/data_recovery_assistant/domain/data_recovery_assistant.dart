// Data Recovery Assistant Models
// 数据恢复助手功能 - 帮助你恢复误删除或丢失的数据

class RecoveryTask {
  final int? id;
  final String taskType; // 'deleted_records', 'corrupted_data', 'incomplete_backup'
  final String status; // 'scanning', 'found', 'recovering', 'completed', 'failed'
  final int foundItems;
  final int recoveredItems;
  final String? errorMessage;
  final DateTime startedAt;
  final DateTime? completedAt;

  RecoveryTask({
    this.id,
    required this.taskType,
    this.status = 'scanning',
    this.foundItems = 0,
    this.recoveredItems = 0,
    this.errorMessage,
    required this.startedAt,
    this.completedAt,
  });

  String get statusLabel {
    switch (status) {
      case 'scanning':
        return '正在扫描...';
      case 'found':
        return '发现 $foundItems 个项目';
      case 'recovering':
        return '正在恢复...';
      case 'completed':
        return '已完成';
      case 'failed':
        return '失败';
      default:
        return status;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'task_type': taskType,
      'status': status,
      'found_items': foundItems,
      'recovered_items': recoveredItems,
      'error_message': errorMessage,
      'started_at': startedAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  factory RecoveryTask.fromMap(Map<String, dynamic> map) {
    return RecoveryTask(
      id: map['id'] as int?,
      taskType: map['task_type'] as String,
      status: map['status'] as String? ?? 'scanning',
      foundItems: map['found_items'] as int? ?? 0,
      recoveredItems: map['recovered_items'] as int? ?? 0,
      errorMessage: map['error_message'] as String?,
      startedAt: DateTime.parse(map['started_at'] as String),
      completedAt: map['completed_at'] != null
          ? DateTime.parse(map['completed_at'] as String)
          : null,
    );
  }
}

class RecoverableItem {
  final int? id;
  final int originalId;
  final String itemType; // 'record', 'tag', 'thing_name', 'template'
  final String title;
  final String? preview;
  final DateTime? deletedAt;
  final String? source; // 'trash', 'backup', 'cache'
  final double recoverability; // 0-1

  RecoverableItem({
    this.id,
    required this.originalId,
    required this.itemType,
    required this.title,
    this.preview,
    this.deletedAt,
    this.source,
    this.recoverability = 0,
  });

  String get sourceLabel {
    switch (source) {
      case 'trash':
        return '回收站';
      case 'backup':
        return '备份文件';
      case 'cache':
        return '缓存';
      default:
        return '未知来源';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'original_id': originalId,
      'item_type': itemType,
      'title': title,
      'preview': preview,
      'deleted_at': deletedAt?.toIso8601String(),
      'source': source,
      'recoverability': recoverability,
    };
  }

  factory RecoverableItem.fromMap(Map<String, dynamic> map) {
    return RecoverableItem(
      id: map['id'] as int?,
      originalId: map['original_id'] as int,
      itemType: map['item_type'] as String,
      title: map['title'] as String,
      preview: map['preview'] as String?,
      deletedAt: map['deleted_at'] != null
          ? DateTime.parse(map['deleted_at'] as String)
          : null,
      source: map['source'] as String?,
      recoverability: (map['recoverability'] as num?)?.toDouble() ?? 0,
    );
  }
}

class BackupMetadata {
  final int? id;
  final String filePath;
  final DateTime createdAt;
  final int sizeBytes;
  final int recordCount;
  final String? checksum;
  final bool isValid;
  final String? errorMessage;

  BackupMetadata({
    this.id,
    required this.filePath,
    required this.createdAt,
    this.sizeBytes = 0,
    this.recordCount = 0,
    this.checksum,
    this.isValid = true,
    this.errorMessage,
  });

  String get sizeLabel {
    if (sizeBytes >= 1024 * 1024 * 1024) {
      return '${(sizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    } else if (sizeBytes >= 1024 * 1024) {
      return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    } else if (sizeBytes >= 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(2)} KB';
    }
    return '$sizeBytes B';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'file_path': filePath,
      'created_at': createdAt.toIso8601String(),
      'size_bytes': sizeBytes,
      'record_count': recordCount,
      'checksum': checksum,
      'is_valid': isValid ? 1 : 0,
      'error_message': errorMessage,
    };
  }

  factory BackupMetadata.fromMap(Map<String, dynamic> map) {
    return BackupMetadata(
      id: map['id'] as int?,
      filePath: map['file_path'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      sizeBytes: map['size_bytes'] as int? ?? 0,
      recordCount: map['record_count'] as int? ?? 0,
      checksum: map['checksum'] as String?,
      isValid: (map['is_valid'] as int?) == 1,
      errorMessage: map['error_message'] as String?,
    );
  }
}