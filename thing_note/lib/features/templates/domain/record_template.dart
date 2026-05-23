class RecordTemplate {
  final int? id;
  final String name;
  final int? defaultThingNameId;
  final int defaultDurationSec;
  final String defaultNote;
  final bool hasReminder;
  final List<int>? tagIds;
  final DateTime createdAt;

  const RecordTemplate({
    this.id,
    required this.name,
    this.defaultThingNameId,
    this.defaultDurationSec = 0,
    this.defaultNote = '',
    this.hasReminder = false,
    this.tagIds,
    required this.createdAt,
  });

  RecordTemplate copyWith({
    int? id,
    String? name,
    int? defaultThingNameId,
    int? defaultDurationSec,
    String? defaultNote,
    bool? hasReminder,
    List<int>? tagIds,
    DateTime? createdAt,
  }) {
    return RecordTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      defaultThingNameId: defaultThingNameId ?? this.defaultThingNameId,
      defaultDurationSec: defaultDurationSec ?? this.defaultDurationSec,
      defaultNote: defaultNote ?? this.defaultNote,
      hasReminder: hasReminder ?? this.hasReminder,
      tagIds: tagIds ?? this.tagIds,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'default_thing_name_id': defaultThingNameId,
      'default_duration_sec': defaultDurationSec,
      'default_note': defaultNote,
      'has_reminder': hasReminder ? 1 : 0,
      'tag_ids': tagIds?.join(',') ?? '',
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory RecordTemplate.fromMap(Map<String, dynamic> map) {
    return RecordTemplate(
      id: map['id'] as int?,
      name: map['name'] as String,
      defaultThingNameId: map['default_thing_name_id'] as int?,
      defaultDurationSec: map['default_duration_sec'] as int? ?? 0,
      defaultNote: map['default_note'] as String? ?? '',
      hasReminder: (map['has_reminder'] as int? ?? 0) == 1,
      tagIds: (map['tag_ids'] as String?)?.isNotEmpty == true
          ? (map['tag_ids'] as String).split(',').map((e) => int.parse(e)).toList()
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}