import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/core/database/database_provider.dart';
import 'package:sqflite/sqflite.dart';

class TagHierarchy {
  final int? id;
  final int tagId;
  final int? parentTagId;
  final int sortOrder;

  TagHierarchy({
    this.id,
    required this.tagId,
    this.parentTagId,
    this.sortOrder = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tag_id': tagId,
      'parent_tag_id': parentTagId,
      'sort_order': sortOrder,
    };
  }

  factory TagHierarchy.fromMap(Map<String, dynamic> map) {
    return TagHierarchy(
      id: map['id'] as int?,
      tagId: map['tag_id'] as int,
      parentTagId: map['parent_tag_id'] as int?,
      sortOrder: map['sort_order'] as int? ?? 0,
    );
  }

  TagHierarchy copyWith({
    int? id,
    int? tagId,
    int? parentTagId,
    int? sortOrder,
  }) {
    return TagHierarchy(
      id: id ?? this.id,
      tagId: tagId ?? this.tagId,
      parentTagId: parentTagId ?? this.parentTagId,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}

class TagWithHierarchy {
  final int id;
  final String name;
  final String color;
  final int? parentId;
  final List<TagWithHierarchy> children;
  final int level;
  final int sortOrder;

  TagWithHierarchy({
    required this.id,
    required this.name,
    required this.color,
    this.parentId,
    this.children = const [],
    this.level = 0,
    this.sortOrder = 0,
  });

  TagWithHierarchy copyWith({
    int? id,
    String? name,
    String? color,
    int? parentId,
    List<TagWithHierarchy>? children,
    int? level,
    int? sortOrder,
  }) {
    return TagWithHierarchy(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      parentId: parentId ?? this.parentId,
      children: children ?? this.children,
      level: level ?? this.level,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}

class TagHierarchyRepository {
  final Database _db;

  TagHierarchyRepository(this._db);

  Future<int> insert(TagHierarchy hierarchy) async {
    return _db.insert('tag_hierarchies', hierarchy.toMap()..remove('id'));
  }

  Future<int> update(TagHierarchy hierarchy) async {
    return _db.update(
      'tag_hierarchies',
      hierarchy.toMap(),
      where: 'id = ?',
      whereArgs: [hierarchy.id],
    );
  }

  Future<int> delete(int id) async {
    return _db.delete('tag_hierarchies', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<TagHierarchy>> getAll() async {
    final results = await _db.query('tag_hierarchies', orderBy: 'sort_order ASC');
    return results.map((e) => TagHierarchy.fromMap(e)).toList();
  }

  Future<List<TagWithHierarchy>> getTagTree() async {
    // Get all tags
    final tags = await _db.query('tags');
    // Get all hierarchies
    final hierarchies = await getAll();

    // Build hierarchy map
    final hierarchyMap = <int, TagHierarchy>{};
    for (final h in hierarchies) {
      if (h.id != null) {
        hierarchyMap[h.tagId] = h;
      }
    }

    // Build tag map
    final tagMap = <int, TagWithHierarchy>{};
    for (final tag in tags) {
      final h = hierarchyMap[tag['id']];
      tagMap[tag['id'] as int] = TagWithHierarchy(
        id: tag['id'] as int,
        name: tag['name'] as String,
        color: tag['color'] as String? ?? '#607D8B',
        parentId: h?.parentTagId,
        sortOrder: h?.sortOrder ?? 0,
      );
    }

    // Build tree
    final roots = <TagWithHierarchy>[];
    for (final tag in tagMap.values) {
      if (tag.parentId == null) {
        roots.add(tag);
      } else {
        final parent = tagMap[tag.parentId];
        if (parent != null) {
          tagMap[tag.parentId!] = parent.copyWith(
            children: [...parent.children, tag],
          );
        }
      }
    }

    // Sort and assign levels
    List<TagWithHierarchy> sortWithChildren(List<TagWithHierarchy> tags, int level) {
      return tags.map((tag) {
        final sortedChildren = tag.children.isEmpty
            ? <TagWithHierarchy>[]
            : sortWithChildren(tag.children, level + 1);
        return tag.copyWith(
          level: level,
          children: sortedChildren,
        );
      }).toList()..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    }

    return sortWithChildren(roots, 0);
  }

  Future<void> setParent(int tagId, int? parentTagId) async {
    final existing = await _db.query(
      'tag_hierarchies',
      where: 'tag_id = ?',
      whereArgs: [tagId],
    );

    if (existing.isEmpty) {
      await insert(TagHierarchy(
        tagId: tagId,
        parentTagId: parentTagId,
      ));
    } else {
      await _db.update(
        'tag_hierarchies',
        {'parent_tag_id': parentTagId},
        where: 'tag_id = ?',
        whereArgs: [tagId],
      );
    }
  }

  Future<void> reorder(int tagId, int newOrder) async {
    await _db.update(
      'tag_hierarchies',
      {'sort_order': newOrder},
      where: 'tag_id = ?',
      whereArgs: [tagId],
    );
  }
}

final tagHierarchyRepositoryProvider = Provider<TagHierarchyRepository>((ref) {
  final db = ref.watch(databaseProvider).requireValue;
  return TagHierarchyRepository(db);
});

final tagTreeProvider = FutureProvider<List<TagWithHierarchy>>((ref) async {
  final repo = ref.watch(tagHierarchyRepositoryProvider);
  return repo.getTagTree();
});