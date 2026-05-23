import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/core/database/database_provider.dart';
import 'package:thing_note/features/skill_tracker/data/skill_provider.dart';
import 'package:thing_note/features/skill_tracker/domain/skill_models.dart';

class SkillTrackerScreen extends ConsumerWidget {
  const SkillTrackerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final skillsAsync = ref.watch(skillsProvider);
    final statsAsync = ref.watch(skillStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('技能追踪'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddSkillDialog(context, ref),
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats Header
          statsAsync.when(
            data: (stats) => _buildStatsHeader(stats),
            loading: () => const SizedBox(height: 80),
            error: (_, __) => const SizedBox(),
          ),
          
          // Skills List
          Expanded(
            child: skillsAsync.when(
              data: (skills) {
                if (skills.isEmpty) {
                  return _buildEmptyState(context, ref);
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(skillsProvider);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: skills.length,
                    itemBuilder: (context, index) {
                      return _SkillCard(skill: skills[index]);
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsHeader(SkillStats stats) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.blue.shade50,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('在学', '${stats.activeSkills}', Colors.blue),
          _buildStatItem('已掌握', '${stats.masteredSkills}', Colors.green),
          _buildStatItem('总时长', '${stats.totalHours}h', Colors.orange),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.code, size: 80, color: Colors.grey.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            '还没有技能',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text('开始追踪你的技能学习', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddSkillDialog(context, ref),
            icon: const Icon(Icons.add),
            label: const Text('添加第一个技能'),
          ),
        ],
      ),
    );
  }

  void _showAddSkillDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    String selectedCategory = 'programming';
    int selectedColor = 0xFF2196F3;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('添加技能'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: '技能名称',
                    hintText: '例如：Flutter',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: '描述（可选）'),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(labelText: '类别'),
                  items: const [
                    DropdownMenuItem(value: 'programming', child: Text('编程')),
                    DropdownMenuItem(value: 'design', child: Text('设计')),
                    DropdownMenuItem(value: 'language', child: Text('语言')),
                    DropdownMenuItem(value: 'music', child: Text('音乐')),
                    DropdownMenuItem(value: 'sports', child: Text('运动')),
                    DropdownMenuItem(value: 'other', child: Text('其他')),
                  ],
                  onChanged: (v) => setState(() => selectedCategory = v!),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  children: [
                    0xFF2196F3,
                    0xFF4CAF50,
                    0xFFFF9800,
                    0xFF9C27B0,
                    0xFFE91E63,
                    0xFF00BCD4,
                  ].map((color) {
                    return GestureDetector(
                      onTap: () => setState(() => selectedColor = color),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Color(color),
                          shape: BoxShape.circle,
                          border: selectedColor == color
                              ? Border.all(color: Colors.black, width: 2)
                              : null,
                        ),
                      ),
                    );
                  }).toList(),
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
                if (nameController.text.isEmpty) return;
                final db = await ref.read(databaseProvider.future);
                final skill = Skill(
                  name: nameController.text,
                  description: descController.text.isEmpty ? null : descController.text,
                  category: selectedCategory,
                  color: selectedColor,
                );
                await db.insert('skills', skill.toMap());
                if (context.mounted) {
                  Navigator.pop(context);
                  ref.invalidate(skillsProvider);
                }
              },
              child: const Text('添加'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkillCard extends ConsumerWidget {
  final Skill skill;

  const _SkillCard({required this.skill});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showSkillDetail(context, ref),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Color(skill.color),
                    child: Icon(
                      _getCategoryIcon(skill.category),
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          skill.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          _getCategoryLabel(skill.category),
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusChip(),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text('Lv.${skill.currentLevel}'),
                  const Spacer(),
                  Text('${skill.totalHours}h'),
                ],
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: skill.progressPercent / 100,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation(Color(skill.color)),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    '目标: Lv.${skill.targetLevel}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const Spacer(),
                  Text(
                    '${skill.progressPercent.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(skill.color),
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

  Widget _buildStatusChip() {
    Color chipColor;
    String label;
    
    switch (skill.status) {
      case 'mastered':
        chipColor = Colors.green;
        label = '已掌握';
        break;
      case 'practicing':
        chipColor = Colors.orange;
        label = '练习中';
        break;
      default:
        chipColor = Colors.blue;
        label = '学习中';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, color: chipColor),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'programming': return Icons.code;
      case 'design': return Icons.palette;
      case 'language': return Icons.translate;
      case 'music': return Icons.music_note;
      case 'sports': return Icons.sports_basketball;
      default: return Icons.star;
    }
  }

  String _getCategoryLabel(String category) {
    switch (category) {
      case 'programming': return '编程';
      case 'design': return '设计';
      case 'language': return '语言';
      case 'music': return '音乐';
      case 'sports': return '运动';
      default: return '其他';
    }
  }

  void _showSkillDetail(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Color(skill.color),
                      child: Icon(
                        _getCategoryIcon(skill.category),
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            skill.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (skill.description != null)
                            Text(
                              skill.description!,
                              style: const TextStyle(color: Colors.grey),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: () => _showAddHoursDialog(context, ref),
                    ),
                  ],
                ),
                const Divider(),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    children: [
                      _buildDetailRow('当前等级', 'Lv.${skill.currentLevel}'),
                      _buildDetailRow('目标等级', 'Lv.${skill.targetLevel}'),
                      _buildDetailRow('总学习时长', '${skill.totalHours}小时'),
                      _buildDetailRow('学习状态', _getStatusLabel(skill.status)),
                      if (skill.lastPracticedAt != null)
                        _buildDetailRow(
                          '最近练习',
                          DateTime.parse(skill.lastPracticedAt!).toString().substring(0, 10),
                        ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                _showDeleteConfirmation(context, ref);
                              },
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              label: const Text('删除技能', style: TextStyle(color: Colors.red)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
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

  String _getStatusLabel(String status) {
    switch (status) {
      case 'mastered': return '已掌握';
      case 'practicing': return '练习中';
      default: return '学习中';
    }
  }

  void _showAddHoursDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController(text: '1');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('记录学习时长'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: '学习时长',
            suffixText: '小时',
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
              final hours = int.tryParse(controller.text) ?? 0;
              if (hours <= 0) return;
              
              final db = await ref.read(databaseProvider.future);
              final newHours = skill.totalHours + hours;
              final newLevel = (newHours ~/ 100).clamp(1, skill.targetLevel);
              
              await db.update(
                'skills',
                {
                  'total_hours': newHours,
                  'current_level': newLevel,
                  'status': newLevel >= skill.targetLevel ? 'mastered' : 'learning',
                  'last_practiced_at': DateTime.now().toIso8601String(),
                },
                where: 'id = ?',
                whereArgs: [skill.id],
              );
              
              if (context.mounted) {
                Navigator.pop(context);
                Navigator.pop(context);
                ref.invalidate(skillsProvider);
              }
            },
            child: const Text('记录'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除技能'),
        content: Text('确定要删除 "${skill.name}" 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final db = await ref.read(databaseProvider.future);
              await db.delete('skill_milestones', where: 'skill_id = ?', whereArgs: [skill.id]);
              await db.delete('skills', where: 'id = ?', whereArgs: [skill.id]);
              if (context.mounted) {
                Navigator.pop(context);
                ref.invalidate(skillsProvider);
              }
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}