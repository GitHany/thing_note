import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';
import 'package:thing_note/features/voice_structured_note/domain/voice_note_models.dart';

/// 语音结构化笔记服务 Provider
final voiceStructuredNoteServiceProvider = Provider<VoiceStructuredNoteService>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return VoiceStructuredNoteService(dbAsync);
});

/// 笔记列表 Provider
final voiceStructuredNotesProvider = FutureProvider<List<VoiceStructuredNote>>((ref) async {
  final service = ref.watch(voiceStructuredNoteServiceProvider);
  return service.getAllNotes();
});

/// 笔记详情 Provider
final voiceStructuredNoteDetailProvider = FutureProvider.family<VoiceStructuredNote?, int>((ref, id) async {
  final service = ref.watch(voiceStructuredNoteServiceProvider);
  return service.getNoteById(id);
});

class VoiceStructuredNoteService {
  final AsyncValue<Database> _dbAsync;

  VoiceStructuredNoteService(this._dbAsync);

  Future<Database> get _db async {
    final db = _dbAsync.value;
    if (db == null) throw Exception('Database not initialized');
    return db;
  }

  /// 获取所有笔记
  Future<List<VoiceStructuredNote>> getAllNotes() async {
    final db = await _db;
    final maps = await db.query(
      'voice_structured_notes',
      orderBy: 'created_at DESC',
    );
    return maps.map((m) => VoiceStructuredNote.fromMap(m)).toList();
  }

  /// 获取笔记详情
  Future<VoiceStructuredNote?> getNoteById(int id) async {
    final db = await _db;
    final maps = await db.query(
      'voice_structured_notes',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return VoiceStructuredNote.fromMap(maps.first);
  }

  /// 创建笔记
  Future<int> createNote(VoiceStructuredNote note) async {
    final db = await _db;
    return db.insert('voice_structured_notes', note.toMap()..remove('id'));
  }

  /// 更新笔记
  Future<int> updateNote(VoiceStructuredNote note) async {
    final db = await _db;
    return db.update(
      'voice_structured_notes',
      note.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  /// 删除笔记
  Future<int> deleteNote(int id) async {
    final db = await _db;
    return db.delete('voice_structured_notes', where: 'id = ?', whereArgs: [id]);
  }

  /// 搜索笔记
  Future<List<VoiceStructuredNote>> searchNotes(String query) async {
    final db = await _db;
    final maps = await db.query(
      'voice_structured_notes',
      where: 'title LIKE ? OR raw_text LIKE ? OR keywords LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: 'created_at DESC',
    );
    return maps.map((m) => VoiceStructuredNote.fromMap(m)).toList();
  }

  /// 添加分段
  Future<int> addSegment(VoiceSegment segment) async {
    final db = await _db;
    return db.insert('voice_segments', segment.toMap()..remove('id'));
  }

  /// 获取笔记的分段
  Future<List<VoiceSegment>> getSegments(int noteId) async {
    final db = await _db;
    final maps = await db.query(
      'voice_segments',
      where: 'note_id = ?',
      whereArgs: [noteId],
      orderBy: 'start_time ASC',
    );
    return maps.map((m) => VoiceSegment.fromMap(m)).toList();
  }

  /// 提取关键词
  List<String> extractKeywords(String text) {
    final keywords = <String>[];
    
    // 提取时间相关词汇
    final timePatterns = RegExp(r'(今天|明天|后天|本周|下周|早上|下午|晚上|上午|中午)');
    final timeMatches = timePatterns.allMatches(text);
    for (final match in timeMatches) {
      keywords.add(match.group(0)!);
    }

    // 提取常用动作词
    final actionPatterns = RegExp(r'(完成|开始|计划|需要|应该|必须|重要|紧急)');
    final actionMatches = actionPatterns.allMatches(text);
    for (final match in actionMatches) {
      keywords.add(match.group(0)!);
    }

    // 提取名词（简单的关键词提取）
    final words = text.split(RegExp(r'[\s,，。.!:;]+'));
    for (final word in words) {
      if (word.length >= 2 && word.length <= 6 && !keywords.contains(word)) {
        keywords.add(word);
      }
    }

    return keywords.take(10).toList();
  }

  /// 结构化文本（模拟 AI 处理）
  String structureText(String rawText, TemplateType templateType) {
    final sections = <String>[];

    switch (templateType) {
      case TemplateType.meeting:
        sections.add('heading:::会议概要');
        sections.add('content:::${_extractMeetingSummary(rawText)}');
        sections.add('heading:::关键决策');
        sections.add('list:::${_extractDecisions(rawText)}');
        sections.add('heading:::待办事项');
        sections.add('todo:::${_extractTodos(rawText)}');
        break;

      case TemplateType.daily:
        sections.add('heading:::今日总结');
        sections.add('content:::${_extractDailySummary(rawText)}');
        sections.add('heading:::明日计划');
        sections.add('todo:::${_extractTodos(rawText)}');
        break;

      case TemplateType.idea:
        sections.add('heading:::核心想法');
        sections.add('content:::${_extractCoreIdea(rawText)}');
        sections.add('heading:::详细说明');
        sections.add('content:::${_extractDetails(rawText)}');
        break;

      case TemplateType.todo:
        sections.add('todo:::${_extractTodos(rawText)}');
        break;

      case TemplateType.note:
      default:
        // 按句子分段
        final sentences = rawText.split(RegExp(r'[。.!?\n]+'));
        for (final sentence in sentences) {
          if (sentence.trim().isNotEmpty) {
            sections.add('content:::${sentence.trim()}');
          }
        }
    }

    return sections.join('|||');
  }

  String _extractMeetingSummary(String text) {
    // 简单提取前两句话作为概要
    final sentences = text.split(RegExp(r'[。.!?]'));
    if (sentences.length >= 2) {
      return '${sentences[0]}. ${sentences[1]}.';
    }
    return sentences.isNotEmpty ? sentences[0] : text;
  }

  String _extractDecisions(String text) {
    // 提取包含"决定"或"决策"的句子
    final decisions = <String>[];
    final sentences = text.split(RegExp(r'[。.!?\n]+'));
    for (final sentence in sentences) {
      if (sentence.contains('决定') || sentence.contains('决策') || sentence.contains('通过')) {
        decisions.add(sentence.trim());
      }
    }
    return decisions.isEmpty ? '暂无明确决策' : decisions.join('; ');
  }

  String _extractTodos(String text) {
    // 提取包含"待办"、"需要"、"应该"的句子
    final todos = <String>[];
    final sentences = text.split(RegExp(r'[。.!?\n]+'));
    for (final sentence in sentences) {
      if (sentence.contains('待办') || sentence.contains('需要') || 
          sentence.contains('应该') || sentence.contains('要') || 
          sentence.contains('必须') || sentence.contains('计划')) {
        todos.add(sentence.trim());
      }
    }
    return todos.isEmpty ? '暂无待办事项' : todos.join('; ');
  }

  String _extractDailySummary(String text) {
    // 提取今日相关的句子
    final summaries = <String>[];
    final sentences = text.split(RegExp(r'[。.!?\n]+'));
    for (final sentence in sentences) {
      if (sentence.contains('今天') || sentence.contains('今日') || sentence.contains('完成')) {
        summaries.add(sentence.trim());
      }
    }
    return summaries.isEmpty ? text.substring(0, text.length.clamp(0, 200)) : summaries.join('; ');
  }

  String _extractCoreIdea(String text) {
    // 提取核心想法（第一句话或包含"想法"、"灵感"的句子）
    final sentences = text.split(RegExp(r'[。.!?\n]+'));
    for (final sentence in sentences) {
      if (sentence.contains('想法') || sentence.contains('灵感') || sentence.contains('创意')) {
        return sentence.trim();
      }
    }
    return sentences.isNotEmpty ? sentences[0] : text.substring(0, text.length.clamp(0, 100));
  }

  String _extractDetails(String text) {
    // 提取除了第一句之外的所有内容
    final sentences = text.split(RegExp(r'[。.!?\n]+'));
    if (sentences.length > 1) {
      return sentences.skip(1).take(5).join('; ');
    }
    return '';
  }

  /// 创建为记录
  Future<int?> createRecordFromNote(VoiceStructuredNote note) async {
    final db = await _db;

    // 获取默认事情类型
    final thingNames = await db.query('thing_names', limit: 1);
    final thingNameId = thingNames.isNotEmpty ? thingNames.first['id'] : null;

    // 创建记录
    final recordId = await db.insert('episode_records', {
      'occurred_at': note.createdAt.toIso8601String(),
      'duration_sec': 0,
      'note': note.rawText,
      'thing_name_id': thingNameId,
      'created_at': note.createdAt.toIso8601String(),
      'updated_at': note.createdAt.toIso8601String(),
    });

    // 更新笔记关联
    await db.update(
      'voice_structured_notes',
      {'linked_record_id': recordId},
      where: 'id = ?',
      whereArgs: [note.id],
    );

    return recordId;
  }
}