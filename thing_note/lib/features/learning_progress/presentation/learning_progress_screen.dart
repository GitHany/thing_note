import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/learning_progress/data/learning_provider.dart';

class LearningProgressScreen extends ConsumerStatefulWidget {
  const LearningProgressScreen({super.key});

  @override
  ConsumerState<LearningProgressScreen> createState() => _LearningProgressScreenState();
}

class _LearningProgressScreenState extends ConsumerState<LearningProgressScreen> {
  @override
  Widget build(BuildContext context) {
    final progressAsync = ref.watch(learningProgressProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('学习进度'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddProgressDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => _showSessionHistory(context),
          ),
        ],
      ),
      body: progressAsync.when(
        data: (progressList) {
          if (progressList.isEmpty) {
            return _buildEmptyState();
          }
          
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(learningProgressProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: progressList.length,
              itemBuilder: (context, index) {
                final progress = progressList[index];
                return _buildProgressCard(progress);
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _startLearningSession(context),
        icon: const Icon(Icons.play_arrow),
        label: const Text('开始学习'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.school_outlined,
            size: 80,
            color: Colors.grey.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            '还没有学习记录',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '点击右下角开始学习会话',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(LearningProgress progress) {
    final progressPercent = progress.progressPercent;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showProgressDetail(context, progress),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      progress.subject,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildStatusChip(progress.status),
                ],
              ),
              if (progress.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  progress.description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${progress.totalHours} / ${progress.targetHours} 小时',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Text(
                              '${progressPercent.toStringAsFixed(1)}%',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: progressPercent / 100,
                          backgroundColor: Colors.grey.withOpacity(0.2),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _getProgressColor(progressPercent),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  _buildProficiencyBadge(progress.proficiencyLevel),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (progress.lastStudied != null) ...[
                    Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      _formatLastStudied(progress.lastStudied!),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  const Spacer(),
                  if (progress.nextMilestone != null)
                    Chip(
                      label: Text(progress.nextMilestone!),
                      backgroundColor: Colors.blue.withOpacity(0.1),
                      labelStyle: const TextStyle(fontSize: 10),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;
    
    switch (status) {
      case 'active':
        color = Colors.green;
        label = '进行中';
        break;
      case 'paused':
        color = Colors.orange;
        label = '暂停';
        break;
      case 'completed':
        color = Colors.blue;
        label = '已完成';
        break;
      default:
        color = Colors.grey;
        label = status;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildProficiencyBadge(double level) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _getProficiencyColor(level).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.psychology,
            size: 16,
            color: _getProficiencyColor(level),
          ),
          const SizedBox(width: 4),
          Text(
            level.toStringAsFixed(1),
            style: TextStyle(
              color: _getProficiencyColor(level),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color _getProgressColor(double percent) {
    if (percent >= 80) return Colors.green;
    if (percent >= 50) return Colors.blue;
    if (percent >= 25) return Colors.orange;
    return Colors.red;
  }

  Color _getProficiencyColor(double level) {
    if (level >= 4.5) return Colors.green;
    if (level >= 3.5) return Colors.blue;
    if (level >= 2.5) return Colors.orange;
    return Colors.red;
  }

  String _formatLastStudied(String dateStr) {
    final date = DateTime.parse(dateStr);
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inDays == 0) return '今天';
    if (diff.inDays == 1) return '昨天';
    if (diff.inDays < 7) return '${diff.inDays}天前';
    return '${date.month}/${date.day}';
  }

  void _showAddProgressDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final targetController = TextEditingController(text: '100');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加学习科目'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: '科目名称',
                  hintText: '例如：Python编程',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descController,
                decoration: const InputDecoration(
                  labelText: '描述（可选）',
                  hintText: '简短描述学习目标',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: targetController,
                decoration: const InputDecoration(
                  labelText: '目标时长（小时）',
                  hintText: '例如：100',
                ),
                keyboardType: TextInputType.number,
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
            onPressed: () async {
              if (nameController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('请输入科目名称')),
                );
                return;
              }
              
              // ignore: unused_local_variable
              final progress = LearningProgress(
                subject: nameController.text,
                description: descController.text,
                targetHours: int.tryParse(targetController.text) ?? 100,
                createdAt: DateTime.now().toIso8601String(),
                updatedAt: DateTime.now().toIso8601String(),
              );
              
              // Save to database
              Navigator.pop(context);
              ref.invalidate(learningProgressProvider);
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('科目已添加')),
              );
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }

  void _showProgressDetail(BuildContext context, LearningProgress progress) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                progress.subject,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildDetailRow('总学习时长', '${progress.totalHours} 小时'),
              _buildDetailRow('目标时长', '${progress.targetHours} 小时'),
              _buildDetailRow('完成进度', '${progress.progressPercent.toStringAsFixed(1)}%'),
              _buildDetailRow('熟练度', progress.proficiencyLevel.toStringAsFixed(1)),
              _buildDetailRow('状态', progress.status),
              if (progress.lastStudied != null)
                _buildDetailRow('最近学习', _formatLastStudied(progress.lastStudied!)),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _startLearningSession(context, subject: progress.subject);
                      },
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('开始学习'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('编辑'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _startLearningSession(BuildContext context, {String? subject}) {
    // Navigate to learning session screen or start timer
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(subject != null ? '开始学习 $subject' : '开始学习会话'),
        action: SnackBarAction(
          label: '查看',
          onPressed: () {},
        ),
      ),
    );
  }

  void _showSessionHistory(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const LearningSessionHistoryScreen(),
      ),
    );
  }
}

class LearningSessionHistoryScreen extends ConsumerWidget {
  const LearningSessionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // This would fetch from a sessions provider
    return Scaffold(
      appBar: AppBar(
        title: const Text('学习历史'),
      ),
      body: const Center(
        child: Text('学习会话历史'),
      ),
    );
  }
}