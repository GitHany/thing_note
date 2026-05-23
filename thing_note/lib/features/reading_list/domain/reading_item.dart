/// 书籍数据模型
class Book {
  final int? id;
  final String title;
  final String? author;
  final int? totalPages;
  final int currentPage;
  final String status;
  final String? startedAt;
  final String? finishedAt;
  final String? note;
  final DateTime createdAt;

  const Book({
    this.id,
    required this.title,
    this.author,
    this.totalPages,
    this.currentPage = 0,
    this.status = 'reading',
    this.startedAt,
    this.finishedAt,
    this.note,
    required this.createdAt,
  });

  Book copyWith({
    int? id,
    String? title,
    String? author,
    int? totalPages,
    int? currentPage,
    String? status,
    String? startedAt,
    String? finishedAt,
    String? note,
    DateTime? createdAt,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      totalPages: totalPages ?? this.totalPages,
      currentPage: currentPage ?? this.currentPage,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'author': author,
      'total_pages': totalPages,
      'current_page': currentPage,
      'status': status,
      'started_at': startedAt,
      'finished_at': finishedAt,
      'note': note,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Book.fromMap(Map<String, dynamic> map) {
    return Book(
      id: map['id'] as int?,
      title: map['title'] as String,
      author: map['author'] as String?,
      totalPages: map['total_pages'] as int?,
      currentPage: map['current_page'] as int? ?? 0,
      status: map['status'] as String? ?? 'reading',
      startedAt: map['started_at'] as String?,
      finishedAt: map['finished_at'] as String?,
      note: map['note'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  double get progressPercent {
    if (totalPages == null || totalPages == 0) return 0;
    return (currentPage / totalPages! * 100).clamp(0, 100);
  }
}

/// 文章数据模型
class Article {
  final int? id;
  final String title;
  final String? url;
  final String? source;
  final String status;
  final String? note;
  final DateTime createdAt;

  const Article({
    this.id,
    required this.title,
    this.url,
    this.source,
    this.status = 'unread',
    this.note,
    required this.createdAt,
  });

  Article copyWith({
    int? id,
    String? title,
    String? url,
    String? source,
    String? status,
    String? note,
    DateTime? createdAt,
  }) {
    return Article(
      id: id ?? this.id,
      title: title ?? this.title,
      url: url ?? this.url,
      source: source ?? this.source,
      status: status ?? this.status,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'url': url,
      'source': source,
      'status': status,
      'note': note,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Article.fromMap(Map<String, dynamic> map) {
    return Article(
      id: map['id'] as int?,
      title: map['title'] as String,
      url: map['url'] as String?,
      source: map['source'] as String?,
      status: map['status'] as String? ?? 'unread',
      note: map['note'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}