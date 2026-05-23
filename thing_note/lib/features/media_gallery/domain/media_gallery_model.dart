/// Media Gallery Item model
class MediaGalleryItem {
  final int? id;
  final String filePath;
  final String fileType;
  final String? thumbnailPath;
  final int fileSize;
  final int? width;
  final int? height;
  final int? linkedRecordId;
  final int? albumId;
  final DateTime createdAt;

  static const fileTypes = ['image', 'video'];

  MediaGalleryItem({
    this.id,
    required this.filePath,
    required this.fileType,
    this.thumbnailPath,
    this.fileSize = 0,
    this.width,
    this.height,
    this.linkedRecordId,
    this.albumId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isImage => fileType == 'image';
  bool get isVideo => fileType == 'video';

  String get fileSizeFormatted {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'file_path': filePath,
      'file_type': fileType,
      'thumbnail_path': thumbnailPath,
      'file_size': fileSize,
      'width': width,
      'height': height,
      'linked_record_id': linkedRecordId,
      'album_id': albumId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory MediaGalleryItem.fromMap(Map<String, dynamic> map) {
    return MediaGalleryItem(
      id: map['id'] as int?,
      filePath: map['file_path'] as String,
      fileType: map['file_type'] as String,
      thumbnailPath: map['thumbnail_path'] as String?,
      fileSize: map['file_size'] as int? ?? 0,
      width: map['width'] as int?,
      height: map['height'] as int?,
      linkedRecordId: map['linked_record_id'] as int?,
      albumId: map['album_id'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

/// Media Album model
class MediaAlbum {
  final int? id;
  final String name;
  final String? coverPath;
  final int itemCount;
  final DateTime createdAt;

  MediaAlbum({
    this.id,
    required this.name,
    this.coverPath,
    this.itemCount = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'cover_path': coverPath,
      'item_count': itemCount,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory MediaAlbum.fromMap(Map<String, dynamic> map) {
    return MediaAlbum(
      id: map['id'] as int?,
      name: map['name'] as String,
      coverPath: map['cover_path'] as String?,
      itemCount: map['item_count'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}