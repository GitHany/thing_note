class ScreenTimeEntry {
  final int? id;
  final String date;
  final int durationMinutes;
  final String category;
  final String? appName;
  final String? note;
  final String createdAt;

  ScreenTimeEntry({
    this.id,
    required this.date,
    required this.durationMinutes,
    required this.category,
    this.appName,
    this.note,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'duration_minutes': durationMinutes,
      'category': category,
      'app_name': appName,
      'note': note,
      'created_at': createdAt,
    };
  }

  factory ScreenTimeEntry.fromMap(Map<String, dynamic> map) {
    return ScreenTimeEntry(
      id: map['id'] as int?,
      date: map['date'] as String,
      durationMinutes: map['duration_minutes'] as int,
      category: map['category'] as String,
      appName: map['app_name'] as String?,
      note: map['note'] as String?,
      createdAt: map['created_at'] as String,
    );
  }

  ScreenTimeEntry copyWith({
    int? id,
    String? date,
    int? durationMinutes,
    String? category,
    String? appName,
    String? note,
    String? createdAt,
  }) {
    return ScreenTimeEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      category: category ?? this.category,
      appName: appName ?? this.appName,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static const List<String> categories = [
    '社交',
    '视频',
    '游戏',
    '工作',
    '阅读',
    '购物',
    '音乐',
    '其他',
  ];
}