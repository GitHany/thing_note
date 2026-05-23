class CustomTheme {
  final int? id;
  final String name;
  final String primaryColor;
  final String? secondaryColor;
  final String? backgroundColor;
  final String? textColor;
  final String? accentColor;
  final bool isDarkMode;
  final bool isActive;
  final DateTime createdAt;

  CustomTheme({
    this.id,
    required this.name,
    required this.primaryColor,
    this.secondaryColor,
    this.backgroundColor,
    this.textColor,
    this.accentColor,
    this.isDarkMode = false,
    this.isActive = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'primary_color': primaryColor,
      'secondary_color': secondaryColor,
      'background_color': backgroundColor,
      'text_color': textColor,
      'accent_color': accentColor,
      'is_dark_mode': isDarkMode ? 1 : 0,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory CustomTheme.fromMap(Map<String, dynamic> map) {
    return CustomTheme(
      id: map['id'] as int?,
      name: map['name'] as String,
      primaryColor: map['primary_color'] as String,
      secondaryColor: map['secondary_color'] as String?,
      backgroundColor: map['background_color'] as String?,
      textColor: map['text_color'] as String?,
      accentColor: map['accent_color'] as String?,
      isDarkMode: (map['is_dark_mode'] as int?) == 1,
      isActive: (map['is_active'] as int?) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  CustomTheme copyWith({
    int? id,
    String? name,
    String? primaryColor,
    String? secondaryColor,
    String? backgroundColor,
    String? textColor,
    String? accentColor,
    bool? isDarkMode,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return CustomTheme(
      id: id ?? this.id,
      name: name ?? this.name,
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      textColor: textColor ?? this.textColor,
      accentColor: accentColor ?? this.accentColor,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}