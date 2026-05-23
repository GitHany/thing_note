import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/core/database/database_provider.dart';
import 'package:thing_note/features/personal_okr/data/okr_provider.dart';
import 'package:thing_note/features/personal_okr/domain/okr_models.dart';

class OkrScreen extends ConsumerStatefulWidget {
  const OkrScreen({super.key});

  @override
  ConsumerState<OkrScreen> createState() => _OkrScreenState();
}

class _OkrScreenState extends ConsumerState<OkrScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final okrListAsync = ref.watch(okrListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('个人OKR'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => _showHistory(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '当前季度'),
            Tab(text: '历史记录'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Current Quarter OKR
          okrListAsync.when(
            data: (okrList) {
              if (okrList.isEmpty) {
                return _buildEmptyState();
              }
              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(okrListProvider);
                },
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: okrList.length,
                  itemBuilder: (context, index) {
                    return _OkrCard(okrWithKr: okrList[index]);
                  },
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
          // History
          _buildHistoryTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddObjectiveDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('添加目标'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.flag_outlined,
            size: 80,
            color: Colors.grey.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            '还没有OKR目标',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '设置你的季度OKR，开始追踪目标',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddObjectiveDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('创建第一个OKR'),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    final allOkrAsync = ref.watch(allOkrProvider);
    return allOkrAsync.when(
      data: (objectives) {
        if (objectives.isEmpty) {
          return const Center(child: Text('暂无历史记录'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: objectives.length,
          itemBuilder: (context, index) {
            final obj = objectives[index];
            return Card(
              child: ListTile(
                leading: Icon(
                  obj.status == 'completed' ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: obj.status == 'completed' ? Colors.green : Colors.grey,
                ),
                title: Text(obj.title),
                subtitle: Text('Q${obj.quarter} ${obj.year}'),
                trailing: Text('${obj.progress.toStringAsFixed(0)}%'),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  void _showAddObjectiveDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    int selectedQuarter = ((DateTime.now().month - 1) ~/ 3) + 1;
    int selectedYear = DateTime.now().year;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加Objective'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: '目标标题',
                  hintText: '例如：成为技术专家',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descController,
                decoration: const InputDecoration(
                  labelText: '描述（可选）',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: selectedQuarter,
                      decoration: const InputDecoration(labelText: '季度'),
                      items: [1, 2, 3, 4].map((q) {
                        return DropdownMenuItem(value: q, child: Text('Q$q'));
                      }).toList(),
                      onChanged: (v) => selectedQuarter = v!,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: selectedYear,
                      decoration: const InputDecoration(labelText: '年份'),
                      items: [DateTime.now().year, DateTime.now().year + 1].map((y) {
                        return DropdownMenuItem(value: y, child: Text('$y'));
                      }).toList(),
                      onChanged: (v) => selectedYear = v!,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              if (titleController.text.isEmpty) return;
              final db = await ref.read(databaseProvider.future);
              final objective = OkrObjective(
                title: titleController.text,
                description: descController.text.isEmpty ? null : descController.text,
                quarter: selectedQuarter,
                year: selectedYear,
              );
              await db.insert('okr_objectives', objective.toMap());
              if (context.mounted) {
                Navigator.pop(context);
                ref.invalidate(okrListProvider);
              }
            },
            child: const Text('创建'),
          ),
        ],
      ),
    );
  }

  void _showHistory(BuildContext context) {
    _tabController.animateTo(1);
  }
}

class _OkrCard extends ConsumerWidget {
  final OkrWithKeyResults okrWithKr;

  const _OkrCard({required this.okrWithKr});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final objective = okrWithKr.objective;
    final keyResults = okrWithKr.keyResults;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        objective.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (objective.description != null)
                        Text(
                          objective.description!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ),
                ),
                _buildProgressIndicator(okrWithKr.overallProgress),
              ],
            ),
            const Divider(height: 24),
            Text(
              'Key Results',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            ...keyResults.map((kr) => _KeyResultItem(keyResult: kr)),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _showAddKeyResultDialog(context, ref, objective.id!),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('添加KR'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(double progress) {
    return SizedBox(
      width: 56,
      height: 56,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: progress / 100,
            backgroundColor: Colors.grey.shade200,
            strokeWidth: 4,
          ),
          Text(
            '${progress.toStringAsFixed(0)}%',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _showAddKeyResultDialog(BuildContext context, WidgetRef ref, int objectiveId) {
    final titleController = TextEditingController();
    final metricController = TextEditingController();
    final targetController = TextEditingController(text: '100');
    final unitController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加Key Result'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'KR标题',
                  hintText: '例如：完成Flutter进阶课程',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: metricController,
                decoration: const InputDecoration(
                  labelText: '衡量指标',
                  hintText: '例如：完成10章',
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: targetController,
                      decoration: const InputDecoration(labelText: '目标值'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: unitController,
                      decoration: const InputDecoration(labelText: '单位'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              if (titleController.text.isEmpty) return;
              final db = await ref.read(databaseProvider.future);
              final kr = OkrKeyResult(
                objectiveId: objectiveId,
                title: titleController.text,
                metric: metricController.text,
                targetValue: double.tryParse(targetController.text) ?? 100,
                unit: unitController.text,
              );
              await db.insert('okr_key_results', kr.toMap());
              if (context.mounted) {
                Navigator.pop(context);
                ref.invalidate(okrListProvider);
              }
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }
}

class _KeyResultItem extends ConsumerWidget {
  final OkrKeyResult keyResult;

  const _KeyResultItem({required this.keyResult});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  keyResult.title,
                  style: const TextStyle(fontSize: 14),
                ),
                if (keyResult.metric.isNotEmpty)
                  Text(
                    '${keyResult.currentValue.toStringAsFixed(0)}/${keyResult.targetValue.toStringAsFixed(0)} ${keyResult.unit}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline, size: 20),
            onPressed: () => _showUpdateProgressDialog(context, ref),
          ),
          SizedBox(
            width: 50,
            child: LinearProgressIndicator(
              value: keyResult.progressPercent / 100,
              backgroundColor: Colors.grey.shade200,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${keyResult.progressPercent.toStringAsFixed(0)}%',
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  void _showUpdateProgressDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController(
      text: keyResult.currentValue.toStringAsFixed(0),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('更新进度'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: '当前值',
            suffixText: keyResult.unit,
          ),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              final newValue = double.tryParse(controller.text) ?? keyResult.currentValue;
              final db = await ref.read(databaseProvider.future);
              await db.update(
                'okr_key_results',
                {'current_value': newValue},
                where: 'id = ?',
                whereArgs: [keyResult.id],
              );
              // Update objective progress
              await _updateObjectiveProgress(db, keyResult.objectiveId);
              if (context.mounted) {
                Navigator.pop(context);
                ref.invalidate(okrListProvider);
              }
            },
            child: const Text('更新'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateObjectiveProgress(dynamic db, int objectiveId) async {
    final keyResults = await db.query(
      'okr_key_results',
      where: 'objective_id = ?',
      whereArgs: [objectiveId],
    );

    if (keyResults.isEmpty) return;

    double totalProgress = 0;
    for (final kr in keyResults) {
      final target = (kr['target_value'] as num?)?.toDouble() ?? 100;
      final current = (kr['current_value'] as num?)?.toDouble() ?? 0;
      totalProgress += target > 0 ? (current / target * 100) : 0;
    }

    final avgProgress = totalProgress / keyResults.length;

    await db.update(
      'okr_objectives',
      {
        'progress': avgProgress,
        'status': avgProgress >= 100 ? 'completed' : 'active',
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [objectiveId],
    );
  }
}