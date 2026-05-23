// Reflection Templates Provider
// Version: 1.0

import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/core/database/database_provider.dart';
import 'package:thing_note/features/reflection_templates/domain/reflection_models.dart';

// Templates provider
final reflectionTemplatesProvider = FutureProvider<List<ReflectionTemplate>>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  final results = await db.query('reflection_templates', orderBy: 'type ASC');
  
  if (results.isEmpty) {
    // Insert default templates
    for (final template in DefaultTemplates.templates) {
      await db.insert('reflection_templates', {
        'name': template.name,
        'type': template.type,
        'questions': jsonEncode(template.questions.map((q) => q.toMap()).toList()),
        'is_default': 1,
        'created_at': DateTime.now().toIso8601String(),
      });
    }
    return DefaultTemplates.templates;
  }
  
  return results.map((r) {
    try {
      final questionsData = jsonDecode(r['questions'] as String);
      return ReflectionTemplate(
        id: r['id'] as int?,
        name: r['name'] as String,
        type: r['type'] as String,
        questions: (questionsData as List)
            .map((q) => ReflectionQuestion.fromMap(q as Map<String, dynamic>))
            .toList(),
        isDefault: (r['is_default'] as int? ?? 0) == 1,
        createdAt: r['created_at'] as String?,
      );
    } catch (_) {
      return ReflectionTemplate(
        id: r['id'] as int?,
        name: r['name'] as String,
        type: r['type'] as String,
        isDefault: (r['is_default'] as int? ?? 0) == 1,
        createdAt: r['created_at'] as String?,
      );
    }
  }).toList();
});

// Templates by type provider
final templatesByTypeProvider = FutureProvider.family<List<ReflectionTemplate>, String>((ref, type) async {
  final db = await ref.watch(databaseProvider.future);
  final results = await db.query(
    'reflection_templates',
    where: 'type = ?',
    whereArgs: [type],
  );
  
  return results.map((r) {
    try {
      final questionsData = jsonDecode(r['questions'] as String);
      return ReflectionTemplate(
        id: r['id'] as int?,
        name: r['name'] as String,
        type: r['type'] as String,
        questions: (questionsData as List)
            .map((q) => ReflectionQuestion.fromMap(q as Map<String, dynamic>))
            .toList(),
        isDefault: (r['is_default'] as int? ?? 0) == 1,
        createdAt: r['created_at'] as String?,
      );
    } catch (_) {
      return ReflectionTemplate(
        id: r['id'] as int?,
        name: r['name'] as String,
        type: r['type'] as String,
        isDefault: (r['is_default'] as int? ?? 0) == 1,
        createdAt: r['created_at'] as String?,
      );
    }
  }).toList();
});

// Recent reflection entries
final recentReflectionEntriesProvider = FutureProvider<List<ReflectionEntry>>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  final results = await db.query(
    'reflection_entries',
    orderBy: 'date DESC',
    limit: 10,
  );
  
  return results.map((r) => ReflectionEntry.fromMap(r)).toList();
});

// Today's reflection check
final todayReflectionProvider = FutureProvider<ReflectionEntry?>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  final today = DateTime.now().toIso8601String().substring(0, 10);
  
  final results = await db.query(
    'reflection_entries',
    where: 'date = ?',
    whereArgs: [today],
  );
  
  if (results.isEmpty) return null;
  return ReflectionEntry.fromMap(results.first);
});

class ReflectionRepository {
  final dynamic db;
  
  ReflectionRepository(this.db);
  
  Future<int> createTemplate(ReflectionTemplate template) async {
    return await db.insert('reflection_templates', {
      'name': template.name,
      'type': template.type,
      'questions': jsonEncode(template.questions.map((q) => q.toMap()).toList()),
      'is_default': 0,
      'created_at': DateTime.now().toIso8601String(),
    });
  }
  
  Future<void> deleteTemplate(int id) async {
    await db.delete('reflection_templates', where: 'id = ?', whereArgs: [id]);
  }
  
  Future<int> saveEntry(ReflectionEntry entry) async {
    // Check if entry exists for this date
    final existing = await db.query(
      'reflection_entries',
      where: 'date = ? AND type = ?',
      whereArgs: [entry.date, entry.type],
    );
    
    if (existing.isNotEmpty) {
      await db.update(
        'reflection_entries',
        {
          'answers': entry.answers.toString(),
          'overall_note': entry.overallNote,
          'mood_level': entry.moodLevel,
        },
        where: 'date = ? AND type = ?',
        whereArgs: [entry.date, entry.type],
      );
      return existing.first['id'] as int;
    } else {
      return await db.insert('reflection_entries', entry.toMap());
    }
  }
  
  Future<List<ReflectionEntry>> getEntriesByType(String type) async {
    final results = await db.query(
      'reflection_entries',
      where: 'type = ?',
      whereArgs: [type],
      orderBy: 'date DESC',
    );
    return results.map((r) => ReflectionEntry.fromMap(r)).toList();
  }
}