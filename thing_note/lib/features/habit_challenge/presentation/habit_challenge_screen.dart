import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/habit_challenge/data/habit_challenge_repository.dart';
import 'package:thing_note/features/habit_challenge/domain/habit_challenge.dart';

final habitChallengeRepoProvider = Provider((ref) => HabitChallengeRepository(ref));

class HabitChallengeScreen extends ConsumerStatefulWidget {
  const HabitChallengeScreen({super.key});

  @override
  ConsumerState<HabitChallengeScreen> createState() => _HabitChallengeScreenState();
}

class _HabitChallengeScreenState extends ConsumerState<HabitChallengeScreen> {
  List<HabitChallenge> _challenges = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChallenges();
  }

  Future<void> _loadChallenges() async {
    setState(() => _isLoading = true);
    final repo = ref.read(habitChallengeRepoProvider);
    _challenges = await repo.getActiveChallenges();
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('习惯挑战'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _challenges.isEmpty
              ? _buildEmptyState()
              : _buildChallengeList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.emoji_events, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('还没有挑战', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 8),
          const Text('创建一个30天挑战来养成好习惯！'),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _showAddDialog,
            icon: const Icon(Icons.add),
            label: const Text('创建挑战'),
          ),
        ],
      ),
    );
  }

  Widget _buildChallengeList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _challenges.length,
      itemBuilder: (context, index) {
        final challenge = _challenges[index];
        return _ChallengeCard(
          challenge: challenge,
          onCheckIn: () => _checkIn(challenge),
          onDelete: () => _deleteChallenge(challenge.id!),
        );
      },
    );
  }

  void _showAddDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    int targetDays = 30;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('创建习惯挑战'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: '挑战名称'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: '描述（可选）'),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('目标天数: '),
                    Expanded(
                      child: Slider(
                        value: targetDays.toDouble(),
                        min: 7,
                        max: 100,
                        divisions: 93,
                        label: '$targetDays 天',
                        onChanged: (v) => setDialogState(() => targetDays = v.toInt()),
                      ),
                    ),
                    Text('$targetDays 天'),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) return;
                final repo = ref.read(habitChallengeRepoProvider);
                await repo.insertChallenge(HabitChallenge(
                  name: nameController.text.trim(),
                  description: descController.text.trim().isEmpty ? null : descController.text.trim(),
                  targetDays: targetDays,
                  startDate: DateTime.now(),
                  createdAt: DateTime.now(),
                ));
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                _loadChallenges();
              },
              child: const Text('创建'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _checkIn(HabitChallenge challenge) async {
    final repo = ref.read(habitChallengeRepoProvider);
    await repo.incrementStreak(challenge.id!);
    _loadChallenges();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Text('打卡成功！已连续 ${challenge.currentStreak + 1} 天'),
            ],
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _deleteChallenge(int id) async {
    final repo = ref.read(habitChallengeRepoProvider);
    await repo.archiveChallenge(id);
    _loadChallenges();
  }
}

class _ChallengeCard extends StatelessWidget {
  final HabitChallenge challenge;
  final VoidCallback onCheckIn;
  final VoidCallback onDelete;

  const _ChallengeCard({
    required this.challenge,
    required this.onCheckIn,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final progress = challenge.progress;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.local_fire_department, color: Colors.orange),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    challenge.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: onDelete,
                ),
              ],
            ),
            if (challenge.description != null) ...[
              const SizedBox(height: 8),
              Text(challenge.description!),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  '${challenge.currentStreak}',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                Text(' / ${challenge.targetDays} 天'),
                const Spacer(),
                if (challenge.isCompleted)
                  const Chip(
                    label: Text('已完成 🎉'),
                    backgroundColor: Colors.green,
                  )
                else
                  FilledButton.icon(
                    onPressed: onCheckIn,
                    icon: const Icon(Icons.check),
                    label: const Text('打卡'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[200],
            ),
            const SizedBox(height: 4),
            Text(
              '剩余 ${challenge.daysRemaining} 天',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}