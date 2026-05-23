import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';

class PriorityMatrixTask {
  final int? id;
  final String title;
  final String? description;
  final String quadrant;
  final int urgencyScore;
  final int importanceScore;
  final int estimatedMinutes;
  final String? dueDate;
  final String status;
  final int? linkedRecordId;
  final int sortOrder;
  final String createdAt;

  PriorityMatrixTask({
    this.id,
    required this.title,
    this.description,
    required this.quadrant,
    this.urgencyScore = 0,
    this.importanceScore = 0,
    this.estimatedMinutes = 30,
    this.dueDate,
    this.status = 'pending',
    this.linkedRecordId,
    this.sortOrder = 0,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id, 'title': title, 'description': description, 'quadrant': quadrant,
      'urgency_score': urgencyScore, 'importance_score': importanceScore,
      'estimated_minutes': estimatedMinutes, 'due_date': dueDate, 'status': status,
      'linked_record_id': linkedRecordId, 'sort_order': sortOrder, 'created_at': createdAt,
    };
  }

  factory PriorityMatrixTask.fromMap(Map<String, dynamic> m) {
    return PriorityMatrixTask(
      id: m['id'] as int?, title: m['title'] as String,
      description: m['description'] as String?, quadrant: m['quadrant'] as String,
      urgencyScore: m['urgency_score'] as int? ?? 0,
      importanceScore: m['importance_score'] as int? ?? 0,
      estimatedMinutes: m['estimated_minutes'] as int? ?? 30,
      dueDate: m['due_date'] as String?, status: m['status'] as String? ?? 'pending',
      linkedRecordId: m['linked_record_id'] as int?,
      sortOrder: m['sort_order'] as int? ?? 0, createdAt: m['created_at'] as String,
    );
  }
}

final priorityMatrixProvider = StateNotifierProvider<PriorityMatrixNotifier, List<PriorityMatrixTask>>((ref) {
  return PriorityMatrixNotifier(ref);
});

class PriorityMatrixNotifier extends StateNotifier<List<PriorityMatrixTask>> {
  final Ref ref;
  PriorityMatrixNotifier(this.ref) : super([]) { loadTasks(); }

  Future<Database> get _db => ref.read(databaseProvider.future);

  Future<void> loadTasks() async {
    final db = await _db;
    final maps = await db.query('priority_matrix_tasks', orderBy: 'sort_order ASC');
    state = maps.map((m) => PriorityMatrixTask.fromMap(m)).toList();
  }

  Future<void> addTask(PriorityMatrixTask task) async {
    final db = await _db;
    await db.insert('priority_matrix_tasks', task.toMap()..remove('id'));
    await loadTasks();
  }

  Future<void> deleteTask(int id) async {
    final db = await _db;
    await db.delete('priority_matrix_tasks', where: 'id = ?', whereArgs: [id]);
    await loadTasks();
  }

  Future<void> completeTask(int id) async {
    final db = await _db;
    await db.update('priority_matrix_tasks', {'status': 'completed'}, where: 'id = ?', whereArgs: [id]);
    await loadTasks();
  }
}

class PriorityMatrixScreen extends ConsumerWidget {
  const PriorityMatrixScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(priorityMatrixProvider);

    final q1 = tasks.where((t) => t.quadrant == 'urgent_important').toList();
    final q2 = tasks.where((t) => t.quadrant == 'important_not_urgent').toList();
    final q3 = tasks.where((t) => t.quadrant == 'urgent_not_important').toList();
    final q4 = tasks.where((t) => t.quadrant == 'not_urgent_not_important').toList();

    return Scaffold(
      appBar: AppBar(title: const Text('任务优先级矩阵')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: _buildQuadrant(context, ref, '紧急且重要', 'q1', Colors.red, q1)),
                Expanded(child: _buildQuadrant(context, ref, '重要不紧急', 'q2', Colors.blue, q2)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildQuadrant(context, ref, '紧急不重要', 'q3', Colors.orange, q3)),
                Expanded(child: _buildQuadrant(context, ref, '都不紧急', 'q4', Colors.grey, q4)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuadrant(BuildContext context, WidgetRef ref, String title, String type, Color color, List<PriorityMatrixTask> tasks) {
    String quadrant;
    switch (type) {
      case 'q1': quadrant = 'urgent_important'; break;
      case 'q2': quadrant = 'important_not_urgent'; break;
      case 'q3': quadrant = 'urgent_not_important'; break;
      default: quadrant = 'not_urgent_not_important';
    }

    return Container(
      height: 200,
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        border: Border.all(color: color.withOpacity(0.5), width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: const BorderRadius.vertical(top: Radius.circular(10))),
            child: Row(
              children: [
                Expanded(child: Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12))),
                Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)), child: Text('${tasks.length}', style: const TextStyle(color: Colors.white, fontSize: 10))),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: tasks.length + 1,
              itemBuilder: (ctx, i) {
                if (i == tasks.length) {
                  return GestureDetector(
                    onTap: () => _showAddDialog(context, ref, quadrant),
                    child: const Center(child: Icon(Icons.add, color: Colors.grey)),
                  );
                }
                final task = tasks[i];
                return Card(
                  color: task.status == 'completed' ? Colors.green.withOpacity(0.1) : null,
                  child: ListTile(
                    dense: true,
                    title: Text(task.title, style: TextStyle(fontSize: 12, decoration: task.status == 'completed' ? TextDecoration.lineThrough : null)),
                    trailing: IconButton(
                      icon: const Icon(Icons.check, size: 16),
                      onPressed: () => ref.read(priorityMatrixProvider.notifier).completeTask(task.id!),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref, String quadrant) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('添加任务'),
        content: TextField(controller: ctrl, decoration: const InputDecoration(labelText: '任务名称', border: OutlineInputBorder())),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(
            onPressed: () {
              if (ctrl.text.isNotEmpty) {
                ref.read(priorityMatrixProvider.notifier).addTask(
                  PriorityMatrixTask(title: ctrl.text, quadrant: quadrant, createdAt: DateTime.now().toIso8601String()),
                );
                Navigator.pop(ctx);
              }
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }
}