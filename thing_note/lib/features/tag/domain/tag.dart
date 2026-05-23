class Tag {
  final int? id;
  final String name;
  final String color;
  final DateTime createdAt;

  const Tag({
    this.id,
    required this.name,
    this.color = '#607D8B',
    required this.createdAt,
  });

  Tag copyWith({
    int? id,
    String? name,
    String? color,
    DateTime? createdAt,
  }) {
    return Tag(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'color': color,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Tag.fromMap(Map<String, dynamic> map) {
    return Tag(
      id: map['id'] as int?,
      name: map['name'] as String,
      color: map['color'] as String? ?? '#607D8B',
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Tag && other.id == id && other.name == name && other.color == color;
  }

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ color.hashCode;

  @override
  String toString() => 'Tag(id: $id, name: $name, color: $color)';
}