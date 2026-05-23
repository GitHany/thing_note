class ReadingSession {
  final int? id;
  final String bookTitle;
  final String? bookAuthor;
  final int startPage;
  final int endPage;
  final int pagesRead;
  final int durationMinutes;
  final DateTime sessionDate;
  final String readingType;
  final String? note;
  final int? linkedRecordId;
  final DateTime createdAt;

  ReadingSession({
    this.id,
    required this.bookTitle,
    this.bookAuthor,
    this.startPage = 0,
    this.endPage = 0,
    this.pagesRead = 0,
    this.durationMinutes = 0,
    required this.sessionDate,
    this.readingType = 'book',
    this.note,
    this.linkedRecordId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'book_title': bookTitle,
      'book_author': bookAuthor,
      'start_page': startPage,
      'end_page': endPage,
      'pages_read': pagesRead,
      'duration_minutes': durationMinutes,
      'session_date': sessionDate.toIso8601String(),
      'reading_type': readingType,
      'note': note,
      'linked_record_id': linkedRecordId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ReadingSession.fromMap(Map<String, dynamic> map) {
    return ReadingSession(
      id: map['id'] as int?,
      bookTitle: map['book_title'] as String,
      bookAuthor: map['book_author'] as String?,
      startPage: map['start_page'] as int? ?? 0,
      endPage: map['end_page'] as int? ?? 0,
      pagesRead: map['pages_read'] as int? ?? 0,
      durationMinutes: map['duration_minutes'] as int? ?? 0,
      sessionDate: DateTime.parse(map['session_date'] as String),
      readingType: map['reading_type'] as String? ?? 'book',
      note: map['note'] as String?,
      linkedRecordId: map['linked_record_id'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  ReadingSession copyWith({
    int? id,
    String? bookTitle,
    String? bookAuthor,
    int? startPage,
    int? endPage,
    int? pagesRead,
    int? durationMinutes,
    DateTime? sessionDate,
    String? readingType,
    String? note,
    int? linkedRecordId,
    DateTime? createdAt,
  }) {
    return ReadingSession(
      id: id ?? this.id,
      bookTitle: bookTitle ?? this.bookTitle,
      bookAuthor: bookAuthor ?? this.bookAuthor,
      startPage: startPage ?? this.startPage,
      endPage: endPage ?? this.endPage,
      pagesRead: pagesRead ?? this.pagesRead,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      sessionDate: sessionDate ?? this.sessionDate,
      readingType: readingType ?? this.readingType,
      note: note ?? this.note,
      linkedRecordId: linkedRecordId ?? this.linkedRecordId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
