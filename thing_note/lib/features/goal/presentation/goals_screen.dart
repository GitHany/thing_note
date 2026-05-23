import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/app/theme/spacing_constants.dart';
import 'package:thing_note/features/goal/data/goal_repository.dart';
import 'package:thing_note/features/goal/domain/goal.dart';
import 'package:thing_note/l10n/generated/app_localizations.dart';

class GoalsScreen extends ConsumerStatefulWidget {
  const GoalsScreen({super.key});

  @override
  ConsumerState<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends ConsumerState<GoalsScreen> {
@override
  Widget build(BuildContext context) {
    final goalsAsync = ref.watch(goalsProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isUltraSmall = AppSpacing.isUltraSmall(screenWidth);
    final isSmall = AppSpacing.isSmall(screenWidth);
    
    // Responsive spacing
    final horizontalPadding = AppSpacing.getHorizontalPadding(screenWidth);
    final itemSpacing = AppSpacing.getItemSpacing(screenWidth);
    final cardPadding = isUltraSmall ? 12.0 : (isSmall ? 14.0 : 16.0);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.goalTracking),
        actions: [
          IconButton(
            icon: Icon(
              Icons.add,
              size: isUltraSmall ? 20 : 24,
            ),
            onPressed: () => _showAddGoalDialog(context),
          ),
        ],
      ),
      body: goalsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('错误: $e')),
        data: (goals) {
          if (goals.isEmpty) {
            return Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(horizontalPadding * 2),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.flag_outlined, 
                      size: isUltraSmall ? 48 : 64, 
                      color: Colors.grey
                    ),
                    SizedBox(height: isUltraSmall ? 12 : 16),
                    Text(
                      '暂无目标', 
                      style: TextStyle(fontSize: isUltraSmall ? 16 : 18)
                    ),
                    SizedBox(height: isUltraSmall ? 6 : 8),
                    ElevatedButton(
                      onPressed: () => _showAddGoalDialog(context),
                      child: Text(AppLocalizations.of(context)!.addGoal),
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.builder(
            padding: EdgeInsets.all(horizontalPadding).copyWith(
              top: horizontalPadding,
              bottom: horizontalPadding * 2,
            ),
            itemCount: goals.length,
            itemBuilder: (context, index) => Padding(
              padding: EdgeInsets.only(bottom: itemSpacing),
              child: _GoalCard(
                goal: goals[index],
                cardPadding: cardPadding,
                isCompact: isUltraSmall || isSmall,
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAddGoalDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    GoalPriority priority = GoalPriority.medium;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加目标'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: '目标标题'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: '目标描述'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              StatefulBuilder(
                builder: (context, setState) => DropdownButton<GoalPriority>(
                  value: priority,
                  isExpanded: true,
                  items: GoalPriority.values.map((p) {
                    return DropdownMenuItem(
                      value: p,
                      child: Text(p.displayName),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => priority = v!),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.trim().isNotEmpty) {
                final now = DateTime.now();
                final goal = Goal(
                  title: titleController.text.trim(),
                  description: descController.text.trim(),
                  priority: priority,
                  createdAt: now,
                  updatedAt: now,
                );
                ref.read(goalsProvider.notifier).addGoal(goal);
                Navigator.pop(context);
              }
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }
}

class _GoalCard extends ConsumerWidget {
  final Goal goal;
  final double cardPadding;
  final bool isCompact;

  const _GoalCard({
    required this.goal,
    this.cardPadding = 16.0,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isUltraSmall = AppSpacing.isUltraSmall(screenWidth);
    final isSmall = AppSpacing.isSmall(screenWidth);
    
    // Responsive values
    final titleFontSize = isUltraSmall ? 14.0 : (isSmall ? 16.0 : 18.0);
    final descriptionFontSize = isUltraSmall ? 11.0 : (isSmall ? 12.0 : 13.0);
    final badgeFontSize = isUltraSmall ? 10.0 : 12.0;
    final iconSize = isUltraSmall ? 12.0 : 14.0;
    
    Color priorityColor;
    String priorityLabel;
    switch (goal.priority) {
      case GoalPriority.critical:
        priorityColor = Colors.red;
        priorityLabel = '紧急';
        break;
      case GoalPriority.high:
        priorityColor = Colors.orange;
        priorityLabel = '高';
        break;
      case GoalPriority.medium:
        priorityColor = Colors.blue;
        priorityLabel = '中';
        break;
      case GoalPriority.low:
        priorityColor = Colors.grey;
        priorityLabel = '低';
        break;
    }

    return Card(
      margin: EdgeInsets.zero, // Use card theme margin
      child: InkWell(
        onTap: () => _showGoalDetail(context, ref),
        borderRadius: BorderRadius.circular(AppSpacing.mediumBorderRadius),
        child: Padding(
          padding: EdgeInsets.all(cardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Priority and overdue badges row
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isUltraSmall ? 6 : 8, 
                      vertical: isUltraSmall ? 2 : 4,
                    ),
                    decoration: BoxDecoration(
                      color: priorityColor.withAlpha(51),
                      borderRadius: BorderRadius.circular(isUltraSmall ? 4 : 6),
                    ),
                    child: Text(
                      priorityLabel,
                      style: TextStyle(color: priorityColor, fontSize: badgeFontSize),
                    ),
                  ),
                  const Spacer(),
                  if (goal.isOverdue)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isUltraSmall ? 6 : 8, 
                        vertical: isUltraSmall ? 2 : 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withAlpha(51),
                        borderRadius: BorderRadius.circular(isUltraSmall ? 4 : 6),
                      ),
                      child: Text(
                        '已逾期', 
                        style: TextStyle(color: Colors.red, fontSize: badgeFontSize),
                      ),
                    ),
                ],
              ),
              SizedBox(height: isUltraSmall ? 8 : 12),
              // Title
              Text(
                goal.title,
                style: TextStyle(
                  fontSize: titleFontSize, 
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (goal.description != null && goal.description!.isNotEmpty) ...[
                SizedBox(height: isUltraSmall ? 4 : 8),
                Text(
                  goal.description!,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: descriptionFontSize,
                  ),
                  maxLines: isCompact ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              SizedBox(height: isUltraSmall ? 8 : 12),
              // Progress bar
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: goal.progressPercent,
                        minHeight: isUltraSmall ? 6 : 8,
                        backgroundColor: Colors.grey[300],
                      ),
                    ),
                  ),
                  SizedBox(width: isUltraSmall ? 8 : 12),
                  Text(
                    '${goal.currentProgress}/${goal.targetProgress}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: isUltraSmall ? 10 : 12,
                    ),
                  ),
                ],
              ),
              if (goal.deadline != null) ...[
                SizedBox(height: isUltraSmall ? 4 : 8),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: iconSize, color: Colors.grey),
                    SizedBox(width: isUltraSmall ? 2 : 4),
                    Text(
                      '截止: ${_formatDate(goal.deadline!)}',
                      style: TextStyle(
                        color: Colors.grey[600], 
                        fontSize: isUltraSmall ? 9 : 12,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void _showGoalDetail(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _GoalDetailSheet(goal: goal),
    );
  }
}

class _GoalDetailSheet extends ConsumerWidget {
  final Goal goal;

  const _GoalDetailSheet({required this.goal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(goal.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (goal.description != null && goal.description!.isNotEmpty) ...[
            Text(goal.description!),
            const SizedBox(height: 16),
          ],
          Text('进度: ${goal.currentProgress}/${goal.targetProgress} (${(goal.progressPercent * 100).toInt()}%)'),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('更新进度: '),
              Expanded(
                child: Slider(
                  value: goal.currentProgress.toDouble(),
                  min: 0,
                  max: goal.targetProgress.toDouble(),
                  divisions: goal.targetProgress,
                  onChanged: (v) {
                    ref.read(goalsProvider.notifier).updateProgress(goal.id!, v.toInt());
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    final updated = goal.copyWith(status: GoalStatus.completed, updatedAt: DateTime.now());
                    ref.read(goalsProvider.notifier).updateGoal(updated);
                    Navigator.pop(context);
                  },
                  child: const Text('标记完成'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    ref.read(goalsProvider.notifier).deleteGoal(goal.id!);
                    Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('删除'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}