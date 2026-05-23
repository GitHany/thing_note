// Reflection Templates feature
// Version: 1.0
// Description: 回顾模板系统，提供结构化的反思框架

class ReflectionTemplate {
  final int? id;
  final String name;
  final String type; // daily, weekly, monthly, quarterly
  final List<ReflectionQuestion> questions;
  final bool isDefault;
  final String? createdAt;

  ReflectionTemplate({
    this.id,
    required this.name,
    required this.type,
    this.questions = const [],
    this.isDefault = false,
    this.createdAt,
  });

  factory ReflectionTemplate.fromMap(Map<String, dynamic> map) {
    List<ReflectionQuestion> questions = [];
    if (map['questions'] != null) {
      try {
        // Parse questions from JSON string or list
        final questionsData = map['questions'];
        if (questionsData is List) {
          questions = questionsData
              .map((q) => ReflectionQuestion.fromMap(q as Map<String, dynamic>))
              .toList();
        }
      } catch (_) {}
    }
    
    return ReflectionTemplate(
      id: map['id'] as int?,
      name: map['name'] as String,
      type: map['type'] as String,
      questions: questions,
      isDefault: (map['is_default'] as int? ?? 0) == 1,
      createdAt: map['created_at'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type,
      'questions': questions.map((q) => q.toMap()).toList(),
      'is_default': isDefault ? 1 : 0,
      'created_at': createdAt ?? DateTime.now().toIso8601String(),
    };
  }
}

class ReflectionQuestion {
  final String id;
  final String question;
  final String? hint;
  final String type; // text, rating, choice
  final List<String>? options;
  final bool isRequired;

  ReflectionQuestion({
    required this.id,
    required this.question,
    this.hint,
    this.type = 'text',
    this.options,
    this.isRequired = true,
  });

  factory ReflectionQuestion.fromMap(Map<String, dynamic> map) {
    return ReflectionQuestion(
      id: map['id'] as String,
      question: map['question'] as String,
      hint: map['hint'] as String?,
      type: map['type'] as String? ?? 'text',
      options: map['options'] != null ? List<String>.from(map['options']) : null,
      isRequired: map['is_required'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'question': question,
      'hint': hint,
      'type': type,
      'options': options,
      'is_required': isRequired,
    };
  }
}

class ReflectionEntry {
  final int? id;
  final int templateId;
  final String templateName;
  final String type;
  final String date; // YYYY-MM-DD
  final Map<String, dynamic> answers; // question_id -> answer
  final String? overallNote;
  final int? moodLevel; // 1-5
  final String? createdAt;

  ReflectionEntry({
    this.id,
    required this.templateId,
    required this.templateName,
    required this.type,
    required this.date,
    this.answers = const {},
    this.overallNote,
    this.moodLevel,
    this.createdAt,
  });

  factory ReflectionEntry.fromMap(Map<String, dynamic> map) {
    Map<String, dynamic> answers = {};
    if (map['answers'] != null) {
      try {
        if (map['answers'] is String) {
          // Parse JSON string
          answers = Map<String, dynamic>.from(
            Map.castFrom(map['answers'] as Map),
          );
        } else if (map['answers'] is Map) {
          answers = Map<String, dynamic>.from(map['answers'] as Map);
        }
      } catch (_) {}
    }
    
    return ReflectionEntry(
      id: map['id'] as int?,
      templateId: map['template_id'] as int,
      templateName: map['template_name'] as String? ?? '',
      type: map['type'] as String,
      date: map['date'] as String,
      answers: answers,
      overallNote: map['overall_note'] as String?,
      moodLevel: map['mood_level'] as int?,
      createdAt: map['created_at'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'template_id': templateId,
      'template_name': templateName,
      'type': type,
      'date': date,
      'answers': answers.toString(),
      'overall_note': overallNote,
      'mood_level': moodLevel,
      'created_at': createdAt ?? DateTime.now().toIso8601String(),
    };
  }
}

// Default templates
class DefaultTemplates {
  static List<ReflectionTemplate> get templates => [
    ReflectionTemplate(
      name: '每日复盘',
      type: 'daily',
      isDefault: true,
      questions: [
        ReflectionQuestion(id: '1', question: '今天最值得记录的一件事是什么？'),
        ReflectionQuestion(id: '2', question: '今天完成了哪些重要任务？'),
        ReflectionQuestion(id: '3', question: '今天遇到了什么挑战？', isRequired: false),
        ReflectionQuestion(id: '4', question: '明天最重要的一件事是什么？'),
        ReflectionQuestion(id: '5', question: '今天的心情如何？', type: 'rating', hint: '1-5分'),
      ],
    ),
    ReflectionTemplate(
      name: '每周回顾',
      type: 'weekly',
      isDefault: true,
      questions: [
        ReflectionQuestion(id: '1', question: '本周最有成就感的一件事是什么？'),
        ReflectionQuestion(id: '2', question: '本周完成了哪些目标？'),
        ReflectionQuestion(id: '3', question: '本周遇到的最大挑战是什么？', isRequired: false),
        ReflectionQuestion(id: '4', question: '从本周学到的最重要的一课是什么？'),
        ReflectionQuestion(id: '5', question: '下周的重点目标是什么？'),
        ReflectionQuestion(id: '6', question: '对本周的整体满意度', type: 'rating', hint: '1-5分'),
      ],
    ),
    ReflectionTemplate(
      name: '月度回顾',
      type: 'monthly',
      isDefault: true,
      questions: [
        ReflectionQuestion(id: '1', question: '本月最重要的成就是什么？'),
        ReflectionQuestion(id: '2', question: '本月目标完成情况如何？'),
        ReflectionQuestion(id: '3', question: '本月最大的挑战是什么？'),
        ReflectionQuestion(id: '4', question: '本月学到了哪些新技能/知识？', isRequired: false),
        ReflectionQuestion(id: '5', question: '本月最感谢的人是谁？', isRequired: false),
        ReflectionQuestion(id: '6', question: '下个月的三个主要目标是什么？'),
        ReflectionQuestion(id: '7', question: '对本月整体满意度', type: 'rating'),
      ],
    ),
    ReflectionTemplate(
      name: '季度复盘',
      type: 'quarterly',
      isDefault: true,
      questions: [
        ReflectionQuestion(id: '1', question: '本季度最大的成就是什么？'),
        ReflectionQuestion(id: '2', question: '本季度目标完成率是多少？'),
        ReflectionQuestion(id: '3', question: '本季度遇到的最大困难是什么？'),
        ReflectionQuestion(id: '4', question: '本季度个人成长情况如何？'),
        ReflectionQuestion(id: '5', question: '本季度最感谢的一个人或一件事'),
        ReflectionQuestion(id: '6', question: '下个季度最重要的一件事是什么？'),
        ReflectionQuestion(id: '7', question: '下季度想要改进的一方面是什么？', isRequired: false),
        ReflectionQuestion(id: '8', question: '对季度整体满意度', type: 'rating'),
      ],
    ),
  ];
}