// Habit Stacking Provider
// Version: 1.0

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/core/database/database_provider.dart';
import 'package:thing_note/features/habit_stacking/domain/habit_stack_models.dart';

// All habit stacks provider
final habitStacksProvider = FutureProvider<List<HabitStackWithLinks>>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  
  final stacks = await db.query('habit_stacks', orderBy: 'created_at DESC');
  
  final List<HabitStackWithLinks> result = [];
  for (final stackMap in stacks) {
    final stack = HabitStack.fromMap(stackMap);
    final links = await db.query(
      'stack_links',
      where: 'stack_id = ?',
      whereArgs: [stack.id],
      orderBy: 'order_index ASC',
    );
    
    // Get habit names
    final habitNames = <String>[];
    for (final link in links) {
      final habitId = link['habit_id'] as int;
      final habits = await db.query('habits', where: 'id = ?', whereArgs: [habitId]);
      if (habits.isNotEmpty) {
        habitNames.add(habits.first['name'] as String);
      }
    }
    
    result.add(HabitStackWithLinks(
      stack: stack,
      links: links.map((l) => StackLink.fromMap(l)).toList(),
      habitNames: habitNames,
    ));
  }
  
  return result;
});

// Active stacks provider (for today view)
final activeStacksProvider = FutureProvider<List<HabitStackWithLinks>>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  
  final stacks = await db.query(
    'habit_stacks',
    where: 'is_active = ?',
    whereArgs: [1],
    orderBy: 'created_at DESC',
  );
  
  final List<HabitStackWithLinks> result = [];
  for (final stackMap in stacks) {
    final stack = HabitStack.fromMap(stackMap);
    final links = await db.query(
      'stack_links',
      where: 'stack_id = ?',
      whereArgs: [stack.id],
      orderBy: 'order_index ASC',
    );
    
    final habitNames = <String>[];
    for (final link in links) {
      final habitId = link['habit_id'] as int;
      final habits = await db.query('habits', where: 'id = ?', whereArgs: [habitId]);
      if (habits.isNotEmpty) {
        habitNames.add(habits.first['name'] as String);
      }
    }
    
    result.add(HabitStackWithLinks(
      stack: stack,
      links: links.map((l) => StackLink.fromMap(l)).toList(),
      habitNames: habitNames,
    ));
  }
  
  return result;
});

class HabitStackRepository {
  final dynamic db;
  
  HabitStackRepository(this.db);
  
  Future<int> createStack(HabitStack stack) async {
    return await db.insert('habit_stacks', stack.toMap());
  }
  
  Future<void> updateStack(HabitStack stack) async {
    await db.update(
      'habit_stacks',
      {...stack.toMap(), 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [stack.id],
    );
  }
  
  Future<void> deleteStack(int id) async {
    await db.delete('stack_links', where: 'stack_id = ?', whereArgs: [id]);
    await db.delete('habit_stacks', where: 'id = ?', whereArgs: [id]);
  }
  
  Future<int> addLinkToStack(StackLink link) async {
    // Update order index
    final existingLinks = await db.query(
      'stack_links',
      where: 'stack_id = ?',
      whereArgs: [link.stackId],
    );
    
    final newLink = StackLink(
      stackId: link.stackId,
      habitId: link.habitId,
      orderIndex: existingLinks.length,
      triggerText: link.triggerText,
    );
    
    return await db.insert('stack_links', newLink.toMap());
  }
  
  Future<void> removeLinkFromStack(int linkId) async {
    await db.delete('stack_links', where: 'id = ?', whereArgs: [linkId]);
  }
  
  Future<void> reorderLinks(int stackId, List<int> linkIds) async {
    for (int i = 0; i < linkIds.length; i++) {
      await db.update(
        'stack_links',
        {'order_index': i},
        where: 'id = ?',
        whereArgs: [linkIds[i]],
      );
    }
  }
  
  Future<void> toggleStackActive(int stackId, bool isActive) async {
    await db.update(
      'habit_stacks',
      {
        'is_active': isActive ? 1 : 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [stackId],
    );
  }
}