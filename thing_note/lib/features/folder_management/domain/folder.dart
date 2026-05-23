/// Folder model for organizing records
class Folder {
  final int? id;
  final String name;
  final String color;
  final String? icon;
  final int? parentId;
  final int sortOrder;
  final DateTime createdAt;
  final int recordCount;

  Folder({
    this.id,
    required this.name,
    this.color = '#607D8B',
    this.icon,
    this.parentId,
    this.sortOrder = 0,
    required this.createdAt,
    this.recordCount = 0,
  });

  Folder copyWith({
    int? id,
    String? name,
    String? color,
    String? icon,
    int? parentId,
    int? sortOrder,
    DateTime? createdAt,
    int? recordCount,
  }) {
    return Folder(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      parentId: parentId ?? this.parentId,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      recordCount: recordCount ?? this.recordCount,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'color': color,
      'icon': icon,
      'parent_id': parentId,
      'sort_order': sortOrder,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Folder.fromMap(Map<String, dynamic> map, {int recordCount = 0}) {
    return Folder(
      id: map['id'] as int?,
      name: map['name'] as String,
      color: map['color'] as String? ?? '#607D8B',
      icon: map['icon'] as String?,
      parentId: map['parent_id'] as int?,
      sortOrder: map['sort_order'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
      recordCount: recordCount,
    );
  }
}

/// Folder tree node for hierarchical display
class FolderTreeNode {
  final Folder folder;
  final List<FolderTreeNode> children;
  final int depth;

  FolderTreeNode({
    required this.folder,
    this.children = const [],
    this.depth = 0,
  });
}