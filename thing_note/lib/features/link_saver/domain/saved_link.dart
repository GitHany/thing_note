/// 链接收藏数据模型
class SavedLink {
  final int? id;
  final String url;
  final String? title;
  final String? description;
  final String? thumbnail;
  final String status;
  final String? note;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const SavedLink({
    this.id,
    required this.url,
    this.title,
    this.description,
    this.thumbnail,
    this.status = 'unread',
    this.note,
    required this.createdAt,
    this.updatedAt,
  });

  SavedLink copyWith({
    int? id,
    String? url,
    String? title,
    String? description,
    String? thumbnail,
    String? status,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SavedLink(
      id: id ?? this.id,
      url: url ?? this.url,
      title: title ?? this.title,
      description: description ?? this.description,
      thumbnail: thumbnail ?? this.thumbnail,
      status: status ?? this.status,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'url': url,
      'title': title,
      'description': description,
      'thumbnail': thumbnail,
      'status': status,
      'note': note,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory SavedLink.fromMap(Map<String, dynamic> map) {
    return SavedLink(
      id: map['id'] as int?,
      url: map['url'] as String,
      title: map['title'] as String?,
      description: map['description'] as String?,
      thumbnail: map['thumbnail'] as String?,
      status: map['status'] as String? ?? 'unread',
      note: map['note'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }
}