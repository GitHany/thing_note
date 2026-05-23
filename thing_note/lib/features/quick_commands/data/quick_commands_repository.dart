import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';
import 'package:thing_note/features/quick_commands/domain/quick_command_model.dart';

final quickCommandsRepositoryProvider = Provider<QuickCommandsRepository>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return QuickCommandsRepository(dbAsync);
});

final quickCommandsProvider = StateNotifierProvider<QuickCommandsNotifier, AsyncValue<List<QuickCommand>>>((ref) {
  final repository = ref.watch(quickCommandsRepositoryProvider);
  return QuickCommandsNotifier(repository);
});

final enabledCommandsProvider = Provider<List<QuickCommand>>((ref) {
  final commands = ref.watch(quickCommandsProvider);
  return commands.whenOrNull(
    data: (list) => list.where((c) => c.isEnabled).toList(),
  ) ?? [];
});

class QuickCommandsRepository {
  final AsyncValue<Database> _dbAsync;

  QuickCommandsRepository(this._dbAsync);

  Future<Database> get _db async {
    final db = _dbAsync.value;
    if (db == null) throw Exception('Database not initialized');
    return db;
  }

  Future<int> insertCommand(QuickCommand command) async {
    final db = await _db;
    return db.insert('quick_commands', command.toMap());
  }

  Future<int> updateCommand(QuickCommand command) async {
    final db = await _db;
    return db.update('quick_commands', command.toMap(), where: 'id = ?', whereArgs: [command.id]);
  }

  Future<int> deleteCommand(int id) async {
    final db = await _db;
    return db.delete('quick_commands', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> incrementUseCount(int id) async {
    final db = await _db;
    return db.rawUpdate(
      'UPDATE quick_commands SET use_count = use_count + 1 WHERE id = ?',
      [id],
    );
  }

  Future<List<QuickCommand>> getAllCommands() async {
    final db = await _db;
    final maps = await db.query('quick_commands', orderBy: 'use_count DESC');
    return maps.map((m) => QuickCommand.fromMap(m)).toList();
  }

  Future<List<QuickCommand>> getEnabledCommands() async {
    final db = await _db;
    final maps = await db.query(
      'quick_commands',
      where: 'is_enabled = 1',
      orderBy: 'use_count DESC',
    );
    return maps.map((m) => QuickCommand.fromMap(m)).toList();
  }

  Future<List<QuickCommand>> getCommandsByCategory(String category) async {
    final db = await _db;
    final maps = await db.query(
      'quick_commands',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'use_count DESC',
    );
    return maps.map((m) => QuickCommand.fromMap(m)).toList();
  }

  Future<List<String>> getCategories() async {
    final db = await _db;
    final maps = await db.rawQuery(
      'SELECT DISTINCT category FROM quick_commands WHERE category IS NOT NULL',
    );
    return maps.map((m) => m['category'] as String).toList();
  }

  // Action configuration helpers
  Map<String, dynamic> parseActionConfig(String config) {
    try {
      return jsonDecode(config) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  String encodeActionConfig(Map<String, dynamic> config) {
    return jsonEncode(config);
  }

  // Seed default commands
  Future<void> seedDefaultCommands() async {
    final existing = await getAllCommands();
    if (existing.isNotEmpty) return;

    final defaults = [
      QuickCommand(
        name: '新建记录',
        alias: 'new',
        commandType: 'navigate',
        actionConfig: jsonEncode({'path': '/record/new'}),
        category: '记录',
        createdAt: DateTime.now(),
      ),
      QuickCommand(
        name: '今日记录',
        alias: 'today',
        commandType: 'navigate',
        actionConfig: jsonEncode({'path': '/', 'filter': 'today'}),
        category: '记录',
        createdAt: DateTime.now(),
      ),
      QuickCommand(
        name: '时间线',
        alias: 'timeline',
        commandType: 'navigate',
        actionConfig: jsonEncode({'path': '/timeline'}),
        category: '视图',
        createdAt: DateTime.now(),
      ),
      QuickCommand(
        name: '日历',
        alias: 'calendar',
        commandType: 'navigate',
        actionConfig: jsonEncode({'path': '/calendar'}),
        category: '视图',
        createdAt: DateTime.now(),
      ),
      QuickCommand(
        name: '习惯打卡',
        alias: 'habit',
        commandType: 'navigate',
        actionConfig: jsonEncode({'path': '/habits'}),
        category: '习惯',
        createdAt: DateTime.now(),
      ),
      QuickCommand(
        name: '目标追踪',
        alias: 'goal',
        commandType: 'navigate',
        actionConfig: jsonEncode({'path': '/goals'}),
        category: '习惯',
        createdAt: DateTime.now(),
      ),
      QuickCommand(
        name: '运动记录',
        alias: 'exercise',
        commandType: 'navigate',
        actionConfig: jsonEncode({'path': '/exercise-tracker'}),
        category: '健康',
        createdAt: DateTime.now(),
      ),
      QuickCommand(
        name: '饮食追踪',
        alias: 'nutrition',
        commandType: 'navigate',
        actionConfig: jsonEncode({'path': '/nutrition-tracker'}),
        category: '健康',
        createdAt: DateTime.now(),
      ),
      QuickCommand(
        name: '快速搜索',
        alias: 'search',
        commandType: 'action',
        actionConfig: jsonEncode({'action': 'open_search'}),
        category: '工具',
        createdAt: DateTime.now(),
      ),
      QuickCommand(
        name: '设置',
        alias: 'settings',
        commandType: 'navigate',
        actionConfig: jsonEncode({'path': '/settings'}),
        category: '系统',
        createdAt: DateTime.now(),
      ),
    ];

    for (final cmd in defaults) {
      await insertCommand(cmd);
    }
  }
}

class QuickCommandsNotifier extends StateNotifier<AsyncValue<List<QuickCommand>>> {
  final QuickCommandsRepository _repository;

  QuickCommandsNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadCommands();
  }

  Future<void> loadCommands() async {
    state = const AsyncValue.loading();
    try {
      await _repository.seedDefaultCommands();
      final commands = await _repository.getAllCommands();
      state = AsyncValue.data(commands);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addCommand(QuickCommand command) async {
    try {
      await _repository.insertCommand(command);
      await loadCommands();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateCommand(QuickCommand command) async {
    try {
      await _repository.updateCommand(command);
      await loadCommands();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteCommand(int id) async {
    try {
      await _repository.deleteCommand(id);
      await loadCommands();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> toggleEnabled(QuickCommand command) async {
    final updated = command.copyWith(isEnabled: !command.isEnabled);
    await updateCommand(updated);
  }

  Future<void> incrementUseCount(int id) async {
    try {
      await _repository.incrementUseCount(id);
      await loadCommands();
    } catch (_) {}
  }
}