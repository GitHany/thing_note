class VisionBoard {
  final int? id;
  final String boardName;
  final String? description;
  final String? imagePath;
  final String? goalType;
  final String? targetDate;
  final bool isActive;
  final DateTime createdAt;

  VisionBoard({
    this.id,
    required this.boardName,
    this.description,
    this.imagePath,
    this.goalType,
    this.targetDate,
    this.isActive = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'board_name': boardName,
      'description': description,
      'image_path': imagePath,
      'goal_type': goalType,
      'target_date': targetDate,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory VisionBoard.fromMap(Map<String, dynamic> map) {
    return VisionBoard(
      id: map['id'] as int?,
      boardName: map['board_name'] as String,
      description: map['description'] as String?,
      imagePath: map['image_path'] as String?,
      goalType: map['goal_type'] as String?,
      targetDate: map['target_date'] as String?,
      isActive: (map['is_active'] as int?) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  VisionBoard copyWith({
    int? id,
    String? boardName,
    String? description,
    String? imagePath,
    String? goalType,
    String? targetDate,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return VisionBoard(
      id: id ?? this.id,
      boardName: boardName ?? this.boardName,
      description: description ?? this.description,
      imagePath: imagePath ?? this.imagePath,
      goalType: goalType ?? this.goalType,
      targetDate: targetDate ?? this.targetDate,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class VisionBoardItem {
  final int? id;
  final int boardId;
  final String itemType;
  final String content;
  final String? imagePath;
  final int positionX;
  final int positionY;
  final int sortOrder;
  final DateTime createdAt;

  VisionBoardItem({
    this.id,
    required this.boardId,
    required this.itemType,
    required this.content,
    this.imagePath,
    this.positionX = 0,
    this.positionY = 0,
    this.sortOrder = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'board_id': boardId,
      'item_type': itemType,
      'content': content,
      'image_path': imagePath,
      'position_x': positionX,
      'position_y': positionY,
      'sort_order': sortOrder,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory VisionBoardItem.fromMap(Map<String, dynamic> map) {
    return VisionBoardItem(
      id: map['id'] as int?,
      boardId: map['board_id'] as int,
      itemType: map['item_type'] as String,
      content: map['content'] as String,
      imagePath: map['image_path'] as String?,
      positionX: map['position_x'] as int? ?? 0,
      positionY: map['position_y'] as int? ?? 0,
      sortOrder: map['sort_order'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
