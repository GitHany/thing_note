class ContactEntry {
  final int? id;
  final String name;
  final String? phone;
  final String? email;
  final String? company;
  final String? role;
  final String? address;
  final String? note;
  final String? birthday;
  final String? group;
  final bool isFavorite;
  final String createdAt;
  final String? updatedAt;

  ContactEntry({
    this.id,
    required this.name,
    this.phone,
    this.email,
    this.company,
    this.role,
    this.address,
    this.note,
    this.birthday,
    this.group,
    this.isFavorite = false,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'company': company,
      'role': role,
      'address': address,
      'note': note,
      'birthday': birthday,
      'group_name': group,
      'is_favorite': isFavorite ? 1 : 0,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory ContactEntry.fromMap(Map<String, dynamic> map) {
    return ContactEntry(
      id: map['id'] as int?,
      name: map['name'] as String,
      phone: map['phone'] as String?,
      email: map['email'] as String?,
      company: map['company'] as String?,
      role: map['role'] as String?,
      address: map['address'] as String?,
      note: map['note'] as String?,
      birthday: map['birthday'] as String?,
      group: map['group_name'] as String?,
      isFavorite: (map['is_favorite'] as int? ?? 0) == 1,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String?,
    );
  }

  ContactEntry copyWith({
    int? id,
    String? name,
    String? phone,
    String? email,
    String? company,
    String? role,
    String? address,
    String? note,
    String? birthday,
    String? group,
    bool? isFavorite,
    String? createdAt,
    String? updatedAt,
  }) {
    return ContactEntry(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      company: company ?? this.company,
      role: role ?? this.role,
      address: address ?? this.address,
      note: note ?? this.note,
      birthday: birthday ?? this.birthday,
      group: group ?? this.group,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static List<String> get defaultGroups => [
    '家人', '朋友', '同事', '客户', '老师', '医生', '其他',
  ];
}