/// Weekly Theme Model
class WeeklyTheme {
  final int? id;
  final String themeName;
  final String? colorScheme;
  final String? backgroundImage;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isActive;
  final DateTime createdAt;

  WeeklyTheme({
    this.id,
    required this.themeName,
    this.colorScheme,
    this.backgroundImage,
    required this.startDate,
    this.endDate,
    this.isActive = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'theme_name': themeName,
      'color_scheme': colorScheme,
      'background_image': backgroundImage,
      'start_date': _formatDate(startDate),
      'end_date': endDate != null ? _formatDate(endDate!) : null,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory WeeklyTheme.fromMap(Map<String, dynamic> map) {
    return WeeklyTheme(
      id: map['id'] as int?,
      themeName: map['theme_name'] as String,
      colorScheme: map['color_scheme'] as String?,
      backgroundImage: map['background_image'] as String?,
      startDate: DateTime.parse(map['start_date'] as String),
      endDate: map['end_date'] != null
          ? DateTime.parse(map['end_date'] as String)
          : null,
      isActive: (map['is_active'] as int?) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  WeeklyTheme copyWith({
    int? id,
    String? themeName,
    String? colorScheme,
    String? backgroundImage,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return WeeklyTheme(
      id: id ?? this.id,
      themeName: themeName ?? this.themeName,
      colorScheme: colorScheme ?? this.colorScheme,
      backgroundImage: backgroundImage ?? this.backgroundImage,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  static List<WeeklyTheme> get suggestedThemes => [
    WeeklyTheme(
      themeName: '专注周',
      colorScheme: '#2196F3',
      startDate: DateTime.now(),
    ),
    WeeklyTheme(
      themeName: '健康周',
      colorScheme: '#4CAF50',
      startDate: DateTime.now(),
    ),
    WeeklyTheme(
      themeName: '学习周',
      colorScheme: '#FF9800',
      startDate: DateTime.now(),
    ),
    WeeklyTheme(
      themeName: '创意周',
      colorScheme: '#9C27B0',
      startDate: DateTime.now(),
    ),
    WeeklyTheme(
      themeName: '社交周',
      colorScheme: '#E91E63',
      startDate: DateTime.now(),
    ),
  ];
}