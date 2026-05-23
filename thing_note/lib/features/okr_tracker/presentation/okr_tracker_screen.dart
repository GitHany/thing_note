import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';

class OkrObjective {
  final int? id;
  final String objectiveTitle;
  final String periodType;
  final int periodYear;
  final int? periodQuarter;
  final int? periodMonth;
  final String? description;
  final String status;
  final double overallProgress;
  final int totalXp;
  final String createdAt;
  final String updatedAt;

  OkrObjective({
    this.id,
    required this.objectiveTitle,
    required this.periodType,
    required this.periodYear,
    this.periodQuarter,
    this.periodMonth,
    this.description,
    this.status = 'active',
    this.overallProgress = 0,
    this.totalXp = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id, 'objective_title': objectiveTitle, 'period_type': periodType,
    'period_year': periodYear, 'period_quarter': periodQuarter, 'period_month': periodMonth,
    'description': description, 'status': status, 'overall_progress': overallProgress,
    'total_xp': totalXp, 'created_at': createdAt, 'updated_at': updatedAt,
  };

  factory OkrObjective.fromMap(Map<String, dynamic> m) => OkrObjective(
    id: m['id'] as int?, objectiveTitle: m['objective_title'] as String,
    periodType: m['period_type'] as String, periodYear: m['period_year'] as int,
    periodQuarter: m['period_quarter'] as int?, periodMonth: m['period_month'] as int?,
    description: m['description'] as String?,
    status: m['status'] as String? ?? 'active',
    overallProgress: (m['overall_progress'] as num?)?.toDouble() ?? 0,
    totalXp: m['total_xp'] as int? ?? 0,
    createdAt: m['created_at'] as String, updatedAt: m['updated_at'] as String,
  );
}

class OkrKeyResult {
  final int? id;
  final int objectiveId;
  final String resultTitle;
  final double targetValue;
  final double currentValue;
  final String? unit;
  final double progressPercent;
  final double score;
  final String status;
  final String? checkedAt;
  final String? note;
  final String createdAt;
  final String updatedAt;

  OkrKeyResult({
    this.id,
    required this.objectiveId,
    required this.resultTitle,
    required this.targetValue,
    this.currentValue = 0,
    this.unit,
    this.progressPercent = 0,
    this.score = 0,
    this.status = 'on_track',
    this.checkedAt,
    this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id, 'objective_id': objectiveId, 'result_title': resultTitle,
    'target_value': targetValue, 'current_value': currentValue, 'unit': unit,
    'progress_percent': progressPercent, 'score': score, 'status': status,
    'checked_at': checkedAt, 'note': note, 'created_at': createdAt, 'updated_at': updatedAt,
  };

  factory OkrKeyResult.fromMap(Map<String, dynamic> m) => OkrKeyResult(
    id: m['id'] as int?, objectiveId: m['objective_id'] as int,
    resultTitle: m['result_title'] as String, targetValue: (m['target_value'] as num).toDouble(),
    currentValue: (m['current_value'] as num?)?.toDouble() ?? 0, unit: m['unit'] as String?,
    progressPercent: (m['progress_percent'] as num?)?.toDouble() ?? 0,
    score: (m['score'] as num?)?.toDouble() ?? 0, status: m['status'] as String? ?? 'on_track',
    checkedAt: m['checked_at'] as String?, note: m['note'] as String?,
    createdAt: m['created_at'] as String, updatedAt: m['updated_at'] as String,
  );
}

final okrTrackerProvider = StateNotifierProvider<OkrTrackerNotifier, List<OkrObjective>>((ref) {
  return OkrTrackerNotifier(ref);
});

class OkrTrackerNotifier extends StateNotifier<List<OkrObjective>> {
  final Ref ref;
  OkrTrackerNotifier(this.ref) : super([]) { loadObjectives(); }

  Future<Database> get _db => ref.read(databaseProvider.future);

  Future<void> loadObjectives() async {
    final db = await _db;
    final maps = await db.query('okr_objectives', where: 'status = ?', whereArgs: ['active'], orderBy: 'created_at DESC');
    state = maps.map((m) => OkrObjective.fromMap(m)).toList();
  }

  Future<int> createObjective(String title, String periodType, int year, {int? quarter, int? month}) async {
    final db = await _db;
    final now = DateTime.now().toIso8601String();
    final id = await db.insert('okr_objectives', {
      'objective_title': title, 'period_type': periodType, 'period_year': year,
      'period_quarter': quarter, 'period_month': month,
      'created_at': now, 'updated_at': now,
    });
    await loadObjectives();
    return id;
  }

  Future<void> updateProgress(int objectiveId, double progress) async {
    final db = await _db;
    await db.update(
      'okr_objectives',
      {'overall_progress': progress, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?', whereArgs: [objectiveId],
    );
    await loadObjectives();
  }
}

final okrKeyResultsProvider = StateNotifierProvider.family<OkrKeyResultsNotifier, List<OkrKeyResult>, int>((ref, objectiveId) {
  return OkrKeyResultsNotifier(ref, objectiveId);
});

class OkrKeyResultsNotifier extends StateNotifier<List<OkrKeyResult>> {
  final Ref ref;
  final int objectiveId;
  OkrKeyResultsNotifier(this.ref, this.objectiveId) : super([]) { loadKeyResults(); }

  Future<Database> get _db => ref.read(databaseProvider.future);

  Future<void> loadKeyResults() async {
    final db = await _db;
    final maps = await db.query('okr_key_results', where: 'objective_id = ?', whereArgs: [objectiveId], orderBy: 'created_at ASC');
    state = maps.map((m) => OkrKeyResult.fromMap(m)).toList();
  }

  Future<void> addKeyResult(String title, double target, {String? unit}) async {
    final db = await _db;
    final now = DateTime.now().toIso8601String();
    await db.insert('okr_key_results', {
      'objective_id': objectiveId, 'result_title': title, 'target_value': target,
      'unit': unit, 'created_at': now, 'updated_at': now,
    });
    await loadKeyResults();
  }

  Future<void> updateKeyResult(int id, double currentValue) async {
    final db = await _db;
    final kr = state.firstWhere((k) => k.id == id);
    final progress = kr.targetValue > 0 ? (currentValue / kr.targetValue * 100).clamp(0.0, 100.0) : 0.0;
    final score = progress >= 100 ? 1.0 : progress >= 70 ? 0.7 : progress >= 50 ? 0.5 : 0.3;
    
    await db.update('okr_key_results', {
      'current_value': currentValue, 'progress_percent': progress, 'score': score,
      'checked_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    }, where: 'id = ?', whereArgs: [id]);
    await loadKeyResults();
  }
}

class OkrTrackerScreen extends ConsumerWidget {
  const OkrTrackerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final objectives = ref.watch(okrTrackerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('OKR追踪')),
      body: objectives.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.flag, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('暂无OKR', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showCreateObjectiveDialog(context, ref),
                    icon: const Icon(Icons.add),
                    label: const Text('创建OKR'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: objectives.length,
              itemBuilder: (ctx, i) => _buildObjectiveCard(context, ref, objectives[i]),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateObjectiveDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildObjectiveCard(BuildContext context, WidgetRef ref, OkrObjective objective) {
    final keyResults = ref.watch(okrKeyResultsProvider(objective.id!));
    final progress = keyResults.isEmpty ? objective.overallProgress : keyResults.map((k) => k.progressPercent).reduce((a, b) => a + b) / keyResults.length;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Colors.purple.withOpacity(0.2),
          child: Text('O', style: TextStyle(color: Colors.purple[700], fontWeight: FontWeight.bold)),
        ),
        title: Text(objective.objectiveTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${objective.periodType} ${objective.periodYear}${objective.periodQuarter != null ? ' Q${objective.periodQuarter}' : ''}'),
            const SizedBox(height: 4),
            LinearProgressIndicator(value: progress / 100, backgroundColor: Colors.grey[200]),
            Text('${progress.toStringAsFixed(0)}%', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('关键结果 (KR)', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...keyResults.map((kr) => _buildKeyResultItem(context, ref, kr)),
                TextButton.icon(
                  onPressed: () => _showAddKeyResultDialog(context, ref, objective.id!),
                  icon: const Icon(Icons.add),
                  label: const Text('添加关键结果'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyResultItem(BuildContext context, WidgetRef ref, OkrKeyResult kr) {
    return Card(
      color: Colors.grey[50],
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(kr.resultTitle),
                  Text(
                    '${kr.currentValue.toStringAsFixed(1)} / ${kr.targetValue.toStringAsFixed(1)} ${kr.unit ?? ''}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle),
              onPressed: () => _showUpdateProgressDialog(context, ref, kr),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateObjectiveDialog(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController();
    String periodType = 'quarterly';
    int year = DateTime.now().year;
    int quarter = ((DateTime.now().month - 1) ~/ 3) + 1;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('创建目标 (O)'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: ctrl, decoration: const InputDecoration(labelText: '目标名称', border: OutlineInputBorder())),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: periodType,
                  decoration: const InputDecoration(labelText: '周期', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'quarterly', child: Text('季度')),
                    DropdownMenuItem(value: 'yearly', child: Text('年度')),
                    DropdownMenuItem(value: 'monthly', child: Text('月度')),
                  ],
                  onChanged: (v) => setState(() => periodType = v ?? 'quarterly'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
            ElevatedButton(
              onPressed: () {
                if (ctrl.text.isNotEmpty) {
                  ref.read(okrTrackerProvider.notifier).createObjective(
                    ctrl.text, periodType, year, quarter: quarter,
                  );
                  Navigator.pop(ctx);
                }
              },
              child: const Text('创建'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddKeyResultDialog(BuildContext context, WidgetRef ref, int objectiveId) {
    final titleCtrl = TextEditingController();
    final targetCtrl = TextEditingController();
    final unitCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('添加关键结果'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'KR名称', border: OutlineInputBorder())),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: TextField(controller: targetCtrl, decoration: const InputDecoration(labelText: '目标值', border: OutlineInputBorder()), keyboardType: TextInputType.number)),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: unitCtrl, decoration: const InputDecoration(labelText: '单位', border: OutlineInputBorder()))),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(
            onPressed: () {
              final target = double.tryParse(targetCtrl.text) ?? 0;
              if (titleCtrl.text.isNotEmpty && target > 0) {
                ref.read(okrKeyResultsProvider(objectiveId).notifier).addKeyResult(titleCtrl.text, target, unit: unitCtrl.text.isNotEmpty ? unitCtrl.text : null);
                Navigator.pop(ctx);
              }
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }

  void _showUpdateProgressDialog(BuildContext context, WidgetRef ref, OkrKeyResult kr) {
    final ctrl = TextEditingController(text: kr.currentValue.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('更新: ${kr.resultTitle}'),
        content: TextField(controller: ctrl, decoration: InputDecoration(labelText: '当前值 (目标: ${kr.targetValue})', border: const OutlineInputBorder()), keyboardType: TextInputType.number),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(
            onPressed: () {
              final value = double.tryParse(ctrl.text) ?? 0;
              ref.read(okrKeyResultsProvider(kr.objectiveId).notifier).updateKeyResult(kr.id!, value);
              Navigator.pop(ctx);
            },
            child: const Text('更新'),
          ),
        ],
      ),
    );
  }
}