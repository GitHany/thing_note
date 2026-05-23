class LinkPreview {
  final int? id;
  final String url;
  final String? title;
  final String? description;
  final String? imageUrl;
  final String? siteName;
  final DateTime? fetchedAt;
  final DateTime createdAt;

  LinkPreview({
    this.id,
    required this.url,
    this.title,
    this.description,
    this.imageUrl,
    this.siteName,
    this.fetchedAt,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get hasData => title != null || description != null;
  bool get isStale {
    if (fetchedAt == null) return true;
    final daysSinceFetch = DateTime.now().difference(fetchedAt!).inDays;
    return daysSinceFetch > 7;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'url': url,
      'title': title,
      'description': description,
      'image_url': imageUrl,
      'site_name': siteName,
      'fetched_at': fetchedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory LinkPreview.fromMap(Map<String, dynamic> map) {
    return LinkPreview(
      id: map['id'] as int?,
      url: map['url'] as String,
      title: map['title'] as String?,
      description: map['description'] as String?,
      imageUrl: map['image_url'] as String?,
      siteName: map['site_name'] as String?,
      fetchedAt: map['fetched_at'] != null
          ? DateTime.parse(map['fetched_at'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  LinkPreview copyWith({
    int? id,
    String? url,
    String? title,
    String? description,
    String? imageUrl,
    String? siteName,
    DateTime? fetchedAt,
    DateTime? createdAt,
  }) {
    return LinkPreview(
      id: id ?? this.id,
      url: url ?? this.url,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      siteName: siteName ?? this.siteName,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
