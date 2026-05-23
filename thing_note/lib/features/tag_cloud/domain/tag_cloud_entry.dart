class TagCloudEntry {
  final int? id;
  final String tagName;
  final int usageCount;
  final String? lastUsed;
  final DateTime createdAt;

  TagCloudEntry({
    this.id,
    required this.tagName,
    this.usageCount = 0,
    this.lastUsed,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'tag_name': tagName,
      'usage_count': usageCount,
      'last_used': lastUsed,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory TagCloudEntry.fromMap(Map<String, dynamic> map) {
    return TagCloudEntry(
      id: map['id'] as int?,
      tagName: map['tag_name'] as String,
      usageCount: map['usage_count'] as int? ?? 0,
      lastUsed: map['last_used'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  double get fontSize {
    if (usageCount >= 50) return 24;
    if (usageCount >= 30) return 20;
    if (usageCount >= 15) return 16;
    if (usageCount >= 5) return 14;
    return 12;
  }
}