import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';

class QuickCommand {
  final int? id;
  final String name;
  final String? alias;
  final String commandType;
  final String actionConfig;
  final String? category;
  final int useCount;
  final bool isEnabled;
  final DateTime createdAt;

  const QuickCommand({
    this.id,
    required this.name,
    this.alias,
    required this.commandType,
    required this.actionConfig,
    this.category,
    this.useCount = 0,
    this.isEnabled = true,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'alias': alias,
      'command_type': commandType,
      'action_config': actionConfig,
      'category': category,
      'use_count': useCount,
      'is_enabled': isEnabled ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory QuickCommand.fromMap(Map<String, dynamic> map) {
    return QuickCommand(
      id: map['id'] as int?,
      name: map['name'] as String,
      alias: map['alias'] as String?,
      commandType: map['command_type'] as String,
      actionConfig: map['action_config'] as String,
      category: map['category'] as String?,
      useCount: map['use_count'] as int? ?? 0,
      isEnabled: map['is_enabled'] == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

final quickCommandRepositoryProvider = Provider<QuickCommandRepository>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return QuickCommandRepository(dbAsync);
});

final quickCommandsProvider = StateNotifierProvider<QuickCommandsNotifier, AsyncValue<List<QuickCommand>>>((ref) {
  final repository = ref.watch(quickCommandRepositoryProvider);
  return QuickCommandsNotifier(repository);
});

class QuickCommandRepository {
  final AsyncValue<Database> _dbAsync;

  QuickCommandRepository(this._dbAsync);

  Future<Database> get _db async {
    final db = _dbAsync.value;
    if (db == null) throw Exception('Database not initialized');
    return db;
  }

  Future<int> insertCommand(QuickCommand command) async {
    final db = await _db;
    return db.insert('quick_commands', command.toMap());
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

  Future<List<QuickCommand>> getCommands() async {
    final db = await _db;
    final maps = await db.query('quick_commands', orderBy: 'use_count DESC');
    return maps.map((m) => QuickCommand.fromMap(m)).toList();
  }
}

class QuickCommandsNotifier extends StateNotifier<AsyncValue<List<QuickCommand>>> {
  final QuickCommandRepository _repository;

  QuickCommandsNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadCommands();
  }

  Future<void> loadCommands() async {
    state = const AsyncValue.loading();
    try {
      final commands = await _repository.getCommands();
      if (commands.isEmpty) {
        // Add default commands
        await _addDefaultCommands();
        final newCommands = await _repository.getCommands();
        state = AsyncValue.data(newCommands);
      } else {
        state = AsyncValue.data(commands);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> _addDefaultCommands() async {
    final defaults = [
      QuickCommand(name: '新建记录', alias: '/new', commandType: 'create', actionConfig: '{}', category: 'record', createdAt: DateTime.now()),
      QuickCommand(name: '快速搜索', alias: '/search', commandType: 'search', actionConfig: '{}', category: 'search', createdAt: DateTime.now()),
      QuickCommand(name: '运动记录', alias: '/exercise', commandType: 'create', actionConfig: '{"type":"exercise"}', category: 'health', createdAt: DateTime.now()),
      QuickCommand(name: '喝水提醒', alias: '/water', commandType: 'reminder', actionConfig: '{}', category: 'health', createdAt: DateTime.now()),
    ];

    for (final cmd in defaults) {
      await _repository.insertCommand(cmd);
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

  Future<void> deleteCommand(int id) async {
    try {
      await _repository.deleteCommand(id);
      await loadCommands();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> executeCommand(int id) async {
    await _repository.incrementUseCount(id);
    await loadCommands();
  }
}

class QuickCommandScreen extends ConsumerWidget {
  const QuickCommandScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final commandsAsync = ref.watch(quickCommandsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('快捷命令'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _addCommand(context, ref),
          ),
        ],
      ),
      body: commandsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('错误: $e')),
        data: (commands) => _buildContent(context, ref, commands),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, List<QuickCommand> commands) {
    final groupedCommands = <String, List<QuickCommand>>{};
    for (final cmd in commands) {
      final category = cmd.category ?? '其他';
      groupedCommands.putIfAbsent(category, () => []).add(cmd);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildQuickInput(context, ref),
        const SizedBox(height: 24),
        ...groupedCommands.entries.map((e) => _buildCategorySection(context, ref, e.key, e.value)),
      ],
    );
  }

  Widget _buildQuickInput(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('快速执行', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: '输入命令别名...',
              prefixIcon: const Icon(Icons.terminal),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onSubmitted: (value) => _executeCommand(context, ref, value),
          ),
          const SizedBox(height: 8),
          const Text('示例: /new, /search, /exercise', style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildCategorySection(BuildContext context, WidgetRef ref, String category, List<QuickCommand> commands) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${_getCategoryIcon(category)} $category',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...commands.map((cmd) => _CommandCard(
          command: cmd,
          onExecute: () => _executeCommand(context, ref, cmd.alias ?? cmd.name),
          onDelete: () => ref.read(quickCommandsProvider.notifier).deleteCommand(cmd.id!),
        )),
        const SizedBox(height: 16),
      ],
    );
  }

  String _getCategoryIcon(String category) {
    switch (category) {
      case 'record': return '📝';
      case 'search': return '🔍';
      case 'health': return '💪';
      default: return '📌';
    }
  }

  void _executeCommand(BuildContext context, WidgetRef ref, String alias) {
    final commands = ref.read(quickCommandsProvider).value ?? [];
    final command = commands.firstWhere(
      (c) => c.alias == alias || c.name.toLowerCase() == alias.toLowerCase(),
      orElse: () => commands.first,
    );

    ref.read(quickCommandsProvider.notifier).executeCommand(command.id!);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('执行命令: ${command.name}')),
    );
  }

  void _addCommand(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加命令'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(labelText: '命令名称'),
            ),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(labelText: '别名 (如 /cmd)'),
            ),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(labelText: '分类'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }
}

class _CommandCard extends StatelessWidget {
  final QuickCommand command;
  final VoidCallback onExecute;
  final VoidCallback onDelete;

  const _CommandCard({
    required this.command,
    required this.onExecute,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: Icon(Icons.terminal, color: Colors.blue),
          ),
        ),
        title: Text(command.name),
        subtitle: Text(
          '别名: ${command.alias ?? "无"} | 使用 ${command.useCount} 次',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.play_arrow, color: Colors.green),
              onPressed: onExecute,
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}