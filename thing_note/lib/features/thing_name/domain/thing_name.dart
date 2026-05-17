class ThingName {
  final int? id;
  final String name;
  final String? remark;
  final DateTime createdAt;

  const ThingName({
    this.id,
    required this.name,
    this.remark,
    required this.createdAt,
  });

  ThingName copyWith({
    int? id,
    String? name,
    String? remark,
    DateTime? createdAt,
  }) {
    return ThingName(
      id: id ?? this.id,
      name: name ?? this.name,
      remark: remark ?? this.remark,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
