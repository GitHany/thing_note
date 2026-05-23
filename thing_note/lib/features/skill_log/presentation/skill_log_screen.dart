import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/skill_log/data/skill_log_repository.dart';
import 'package:thing_note/features/skill_log/domain/skill_log_model.dart';

final skillsProvider = FutureProvider<List<SkillLog>>((ref) async {
  final repo = ref.read(skillLogRepositoryProvider);
  return repo.getAllSkills();
});

final skillStatsProvider = FutureProvider.autoDispose<Map<String, int>>((ref) async {
  final repo = ref.watch(skillLogRepositoryProvider);
  return await repo.getOverallStatistics();
});

class SkillLogScreen extends ConsumerStatefulWidget {
  const SkillLogScreen({super.key});

  @override
  ConsumerState<SkillLogScreen> createState() => _SkillLogScreenState();
}

class _SkillLogScreenState extends ConsumerState<SkillLogScreen> {
  @override
  Widget build(BuildContext context) {
    final skillsAsync = ref.watch(skillsProvider);
    final statsAsync = ref.watch(skillStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Skill Development Log'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddSkillDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStats(statsAsync),
          Expanded(
            child: skillsAsync.when(
              data: (skills) => skills.isEmpty
                  ? _buildEmptyState()
                  : _buildSkillList(skills),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSkillDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('New Skill'),
      ),
    );
  }

  Widget _buildStats(AsyncValue<Map<String, int>> statsAsync) {
    return statsAsync.when(
      data: (stats) {
        final totalMinutes = stats['total_minutes'] ?? 0;
        final totalHours = totalMinutes ~/ 60;
        final remainingMinutes = totalMinutes % 60;
        
        return Container(
          padding: const EdgeInsets.all(16),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    icon: Icons.psychology,
                    value: '${stats['active_skills'] ?? 0}',
                    label: 'Skills',
                    color: Colors.blue,
                  ),
                  _buildStatItem(
                    icon: Icons.timer,
                    value: '$totalHours${remainingMinutes > 0 ? 'h ${remainingMinutes}m' : ''}',
                    label: 'Total Time',
                    color: Colors.green,
                  ),
                  _buildStatItem(
                    icon: Icons.history,
                    value: '${stats['total_sessions'] ?? 0}',
                    label: 'Sessions',
                    color: Colors.purple,
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.psychology, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No skills tracked yet',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Start tracking your skill development journey',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillList(List<SkillLog> skills) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: skills.length,
      itemBuilder: (context, index) {
        final skill = skills[index];
        return _buildSkillCard(skill);
      },
    );
  }

  Widget _buildSkillCard(SkillLog skill) {
    return FutureBuilder<Map<String, dynamic>>(
      future: ref.read(skillLogRepositoryProvider).getSkillStatistics(skill.id!),
      builder: (context, snapshot) {
        final stats = snapshot.data ?? {};
        
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _getLevelColor(skill.currentLevel).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.psychology,
                        color: _getLevelColor(skill.currentLevel),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            skill.skillName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Row(
                            children: [
                              _buildLevelBadge(skill.currentLevel),
                              const SizedBox(width: 8),
                              Text(
                                '${skill.totalHours}h total',
                                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton(
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'add_session', child: Text('Log Session')),
                        const PopupMenuItem(value: 'edit', child: Text('Edit')),
                        const PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                      onSelected: (value) {
                        if (value == 'add_session') {
                          _showLogSessionDialog(context, skill);
                        } else if (value == 'edit') {
                          _showEditSkillDialog(context, skill);
                        } else if (value == 'delete') {
                          _deleteSkill(skill);
                        }
                      },
                    ),
                  ],
                ),
                if (skill.description != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    skill.description!,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatColumn(
                      icon: Icons.history,
                      value: '${stats['sessions_count'] ?? 0}',
                      label: 'Sessions',
                      color: Colors.blue,
                    ),
                    _buildStatColumn(
                      icon: Icons.calendar_today,
                      value: '${(stats['this_week_minutes'] ?? 0) ~/ 60}h',
                      label: 'This Week',
                      color: Colors.green,
                    ),
                    _buildStatColumn(
                      icon: Icons.star,
                      value: (stats['avg_rating'] as double?)?.toStringAsFixed(1) ?? '-',
                      label: 'Avg Rating',
                      color: Colors.amber,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showLogSessionDialog(context, skill),
                    icon: const Icon(Icons.add),
                    label: const Text('Log Practice Session'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatColumn({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.grey[600], fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildLevelBadge(String level) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: _getLevelColor(level).withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        level.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: _getLevelColor(level),
        ),
      ),
    );
  }

  Color _getLevelColor(String level) {
    switch (level) {
      case 'beginner':
        return Colors.grey;
      case 'elementary':
        return Colors.green;
      case 'intermediate':
        return Colors.blue;
      case 'advanced':
        return Colors.purple;
      case 'expert':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  void _showAddSkillDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    String targetLevel = 'intermediate';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('New Skill'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Skill Name',
                    hintText: 'e.g., Python, Guitar, Public Speaking',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: 'Description (optional)'),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: targetLevel,
                  decoration: const InputDecoration(labelText: 'Target Level'),
                  items: SkillLog.levels
                      .map((l) => DropdownMenuItem(value: l, child: Text(l.toUpperCase())))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => targetLevel = value);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  _createSkill(nameController.text, descController.text, targetLevel);
                  Navigator.pop(context);
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditSkillDialog(BuildContext context, SkillLog skill) {
    final nameController = TextEditingController(text: skill.skillName);
    final descController = TextEditingController(text: skill.description ?? '');
    String targetLevel = skill.targetLevel ?? 'intermediate';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Skill'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Skill Name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: targetLevel,
                  decoration: const InputDecoration(labelText: 'Target Level'),
                  items: SkillLog.levels
                      .map((l) => DropdownMenuItem(value: l, child: Text(l.toUpperCase())))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => targetLevel = value);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  _updateSkill(skill.copyWith(
                    skillName: nameController.text,
                    description: descController.text.isEmpty ? null : descController.text,
                    targetLevel: targetLevel,
                  ));
                  Navigator.pop(context);
                }
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogSessionDialog(BuildContext context, SkillLog skill) {
    final durationController = TextEditingController();
    final summaryController = TextEditingController();
    final noteController = TextEditingController();
    String practiceType = 'practice';
    int rating = 3;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Log Session - ${skill.skillName}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Text('Duration (minutes):'),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: () {
                        final current = int.tryParse(durationController.text) ?? 0;
                        if (current > 5) {
                          durationController.text = '${current - 5}';
                        }
                      },
                    ),
                    SizedBox(
                      width: 60,
                      child: TextField(
                        controller: durationController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(hintText: '30'),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        final current = int.tryParse(durationController.text) ?? 0;
                        durationController.text = '${current + 5}';
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: practiceType,
                  decoration: const InputDecoration(labelText: 'Practice Type'),
                  items: const [
                    DropdownMenuItem(value: 'practice', child: Text('Practice')),
                    DropdownMenuItem(value: 'learning', child: Text('Learning')),
                    DropdownMenuItem(value: 'project', child: Text('Project')),
                    DropdownMenuItem(value: 'review', child: Text('Review')),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => practiceType = value);
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Rating:'),
                    const Spacer(),
                    ...List.generate(5, (i) => IconButton(
                      icon: Icon(
                        i < rating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                      ),
                      onPressed: () => setState(() => rating = i + 1),
                    )),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: summaryController,
                  decoration: const InputDecoration(labelText: 'Output Summary (optional)'),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteController,
                  decoration: const InputDecoration(labelText: 'Notes (optional)'),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final duration = int.tryParse(durationController.text);
                if (duration != null && duration > 0) {
                  _logSession(
                    skill,
                    duration,
                    practiceType,
                    rating,
                    summaryController.text.isEmpty ? null : summaryController.text,
                    noteController.text.isEmpty ? null : noteController.text,
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text('Log Session'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createSkill(String name, String description, String targetLevel) async {
    final repo = ref.read(skillLogRepositoryProvider);
    final now = DateTime.now().toIso8601String();
    final skill = SkillLog(
      skillName: name,
      description: description.isEmpty ? null : description,
      targetLevel: targetLevel,
      createdAt: now,
      updatedAt: now,
    );
    await repo.insertSkill(skill);
    ref.invalidate(skillsProvider);
    ref.invalidate(skillStatsProvider);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Skill created!'), backgroundColor: Colors.green),
      );
    }
  }

  Future<void> _updateSkill(SkillLog skill) async {
    final repo = ref.read(skillLogRepositoryProvider);
    await repo.updateSkill(skill.copyWith(updatedAt: DateTime.now().toIso8601String()));
    ref.invalidate(skillsProvider);
  }

  Future<void> _logSession(
    SkillLog skill,
    int duration,
    String practiceType,
    int rating,
    String? summary,
    String? note,
  ) async {
    final repo = ref.read(skillLogRepositoryProvider);
    final now = DateTime.now();
    final session = SkillSession(
      skillId: skill.id!,
      durationMinutes: duration,
      practiceType: practiceType,
      rating: rating,
      outputSummary: summary,
      note: note,
      sessionDate: now.toIso8601String().split('T')[0],
      createdAt: now.toIso8601String(),
    );
    await repo.insertSession(session);
    ref.invalidate(skillsProvider);
    ref.invalidate(skillStatsProvider);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session logged!'), backgroundColor: Colors.green),
      );
    }
  }

  Future<void> _deleteSkill(SkillLog skill) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Skill?'),
        content: Text('Delete "${skill.skillName}" and all its sessions?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      final repo = ref.read(skillLogRepositoryProvider);
      await repo.deleteSkill(skill.id!);
      ref.invalidate(skillsProvider);
      ref.invalidate(skillStatsProvider);
    }
  }
}