/// File manager entry representing a file or directory
class FileManagerEntry {
  final String name;
  final String path;
  final bool isDirectory;
  final int? size;
  final DateTime? modifiedAt;

  FileManagerEntry({
    required this.name,
    required this.path,
    required this.isDirectory,
    this.size,
    this.modifiedAt,
  });

  String get formattedSize {
    if (isDirectory) return '--';
    if (size == null) return '--';

    if (size! < 1024) return '$size B';
    if (size! < 1024 * 1024) return '${(size! / 1024).toStringAsFixed(1)} KB';
    if (size! < 1024 * 1024 * 1024) {
      return '${(size! / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(size! / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

/// File storage statistics
class FileStorageStats {
  final int totalSize;
  final int fileCount;
  final int photoCount;
  final int videoCount;
  final int audioCount;
  final int documentCount;
  final int backupCount;

  FileStorageStats({
    required this.totalSize,
    required this.fileCount,
    required this.photoCount,
    required this.videoCount,
    required this.audioCount,
    required this.documentCount,
    required this.backupCount,
  });

  String get formattedTotalSize {
    if (totalSize < 1024) return '$totalSize B';
    if (totalSize < 1024 * 1024) return '${(totalSize / 1024).toStringAsFixed(1)} KB';
    if (totalSize < 1024 * 1024 * 1024) {
      return '${(totalSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(totalSize / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}