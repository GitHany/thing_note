/// 会议数据模型
class Meeting {
  final int? id;
  final String title;
  final String? template;
  final String date;
  final int? durationMinutes;
  final List<String> participants;
  final String? agenda;
  final String? notes;
  final String? decisions;
  final String? actionItems;
  final DateTime createdAt;

  const Meeting({
    this.id,
    required this.title,
    this.template,
    required this.date,
    this.durationMinutes,
    this.participants = const [],
    this.agenda,
    this.notes,
    this.decisions,
    this.actionItems,
    required this.createdAt,
  });

  Meeting copyWith({
    int? id,
    String? title,
    String? template,
    String? date,
    int? durationMinutes,
    List<String>? participants,
    String? agenda,
    String? notes,
    String? decisions,
    String? actionItems,
    DateTime? createdAt,
  }) {
    return Meeting(
      id: id ?? this.id,
      title: title ?? this.title,
      template: template ?? this.template,
      date: date ?? this.date,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      participants: participants ?? this.participants,
      agenda: agenda ?? this.agenda,
      notes: notes ?? this.notes,
      decisions: decisions ?? this.decisions,
      actionItems: actionItems ?? this.actionItems,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'template': template,
      'date': date,
      'duration_minutes': durationMinutes,
      'participants': participants.join(','),
      'agenda': agenda,
      'notes': notes,
      'decisions': decisions,
      'action_items': actionItems,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Meeting.fromMap(Map<String, dynamic> map) {
    final participantsStr = map['participants'] as String? ?? '';
    return Meeting(
      id: map['id'] as int?,
      title: map['title'] as String,
      template: map['template'] as String?,
      date: map['date'] as String,
      durationMinutes: map['duration_minutes'] as int?,
      participants: participantsStr.isEmpty ? [] : participantsStr.split(','),
      agenda: map['agenda'] as String?,
      notes: map['notes'] as String?,
      decisions: map['decisions'] as String?,
      actionItems: map['action_items'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

/// 会议模板
class MeetingTemplate {
  final int? id;
  final String name;
  final String? agendaTemplate;
  final int defaultDuration;
  final DateTime createdAt;

  const MeetingTemplate({
    this.id,
    required this.name,
    this.agendaTemplate,
    this.defaultDuration = 60,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'agenda_template': agendaTemplate,
      'default_duration': defaultDuration,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory MeetingTemplate.fromMap(Map<String, dynamic> map) {
    return MeetingTemplate(
      id: map['id'] as int?,
      name: map['name'] as String,
      agendaTemplate: map['agenda_template'] as String?,
      defaultDuration: map['default_duration'] as int? ?? 60,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}