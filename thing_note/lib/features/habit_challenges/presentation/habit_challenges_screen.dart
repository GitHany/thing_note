import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:thing_note/core/database/database_provider.dart';

class HabitChallenge {
  final int? id;
  final String name;
  final String? description;
  final String targetHabit;
  final String startDate;
  final String? endDate;
  final int maxParticipants;
  final String? reward;
  final String status;
  final String createdAt;

  HabitChallenge({
    this.id,
    required this.name,
    this.description,
    required this.targetHabit,
    required this.startDate,
    this.endDate,
    this.maxParticipants = 50,
    this.reward,
    this.status = 'active',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id, 'name': name, 'description': description, 'target_habit': targetHabit,
    'start_date': startDate, 'end_date': endDate, 'max_participants': maxParticipants,
    'reward': reward, 'status': status, 'created_at': createdAt,
  };

  factory HabitChallenge.fromMap(Map<String, dynamic> m) => HabitChallenge(
    id: m['id'] as int?, name: m['name'] as String, description: m['description'] as String?,
    targetHabit: m['target_habit'] as String? ?? m['habit_title'] as String? ?? '',
    startDate: m['start_date'] as String, endDate: m['end_date'] as String?,
    maxParticipants: m['max_participants'] as int? ?? 50,
    reward: m['reward'] as String?, status: m['status'] as String? ?? 'active',
    createdAt: m['created_at'] as String,
  );
}

class ChallengeParticipant {
  final int? id;
  final int challengeId;
  final String habitTitle;
  final int targetDays;
  final int completedDays;
  final String startDate;
  final String? endDate;
  final String status;
  final int rewardEarned;
  final String joinedAt;

  ChallengeParticipant({
    this.id,
    required this.challengeId,
    required this.habitTitle,
    required this.targetDays,
    this.completedDays = 0,
    required this.startDate,
    this.endDate,
    this.status = 'active',
    this.rewardEarned = 0,
    required this.joinedAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id, 'challenge_id': challengeId, 'habit_title': habitTitle,
    'target_days': targetDays, 'completed_days': completedDays,
    'start_date': startDate, 'end_date': endDate, 'status': status,
    'reward_earned': rewardEarned, 'joined_at': joinedAt,
  };

  factory ChallengeParticipant.fromMap(Map<String, dynamic> m) => ChallengeParticipant(
    id: m['id'] as int?, challengeId: m['challenge_id'] as int? ?? m['id'] as int? ?? 0,
    habitTitle: m['habit_title'] as String, targetDays: m['target_days'] as int,
    completedDays: m['completed_days'] as int? ?? 0,
    startDate: m['start_date'] as String, endDate: m['end_date'] as String?,
    status: m['status'] as String? ?? 'active', rewardEarned: m['reward_earned'] as int? ?? 0,
    joinedAt: m['joined_at'] as String,
  );

  double get progress => targetDays > 0 ? completedDays / targetDays : 0;
}

final habitChallengesProvider = StateNotifierProvider<HabitChallengesNotifier, List<HabitChallenge>>((ref) {
  return HabitChallengesNotifier(ref);
});

class HabitChallengesNotifier extends StateNotifier<List<HabitChallenge>> {
  final Ref ref;
  HabitChallengesNotifier(this.ref) : super([]) { loadChallenges(); }

  Future<Database> get _db => ref.read(databaseProvider.future);

  Future<void> loadChallenges() async {
    final db = await _db;
    final maps = await db.query('habit_tournaments', orderBy: 'start_date DESC');
    state = maps.map((m) => HabitChallenge.fromMap(m)).toList();
  }

  Future<void> createChallenge(String name, String habit, int days) async {
    final db = await _db;
    final now = DateTime.now();
    await db.insert('habit_tournaments', {
      'name': name, 'target_habit': habit, 'start_date': now.toIso8601String(),
      'end_date': now.add(Duration(days: days)).toIso8601String(),
      'status': 'active', 'created_at': now.toIso8601String(),
    });
    await loadChallenges();
  }

  Future<void> joinChallenge(int challengeId, String habitTitle, int targetDays) async {
    final db = await _db;
    await db.insert('habit_challenge_participants', {
      'challenge_id': challengeId, 'habit_title': habitTitle,
      'target_days': targetDays, 'start_date': DateTime.now().toIso8601String(),
      'joined_at': DateTime.now().toIso8601String(),
    });
  }
}

class HabitChallengesScreen extends ConsumerWidget {
  const HabitChallengesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challenges = ref.watch(habitChallengesProvider);
    final activeChallenges = challenges.where((c) => c.status == 'active').toList();

    return Scaffold(
      appBar: AppBar(title: const Text('习惯挑战')),
      body: activeChallenges.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.emoji_events, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('暂无挑战', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showCreateDialog(context, ref),
                    icon: const Icon(Icons.add),
                    label: const Text('创建挑战'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: activeChallenges.length,
              itemBuilder: (ctx, i) => _buildChallengeCard(context, ref, activeChallenges[i]),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildChallengeCard(BuildContext context, WidgetRef ref, HabitChallenge challenge) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.emoji_events, color: Colors.amber),
                const SizedBox(width: 8),
                Expanded(child: Text(challenge.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
              ],
            ),
            if (challenge.description != null) ...[
              const SizedBox(height: 8),
              Text(challenge.description!, style: TextStyle(color: Colors.grey[600])),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.repeat, size: 16, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text('目标: ${challenge.targetHabit}', style: TextStyle(color: Colors.grey[600])),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text('开始: ${challenge.startDate.substring(0, 10)}', style: TextStyle(color: Colors.grey[600])),
                if (challenge.endDate != null) ...[
                  const SizedBox(width: 16),
                  Text('结束: ${challenge.endDate!.substring(0, 10)}', style: TextStyle(color: Colors.grey[600])),
                ],
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _showJoinDialog(context, ref, challenge),
                    child: const Text('参与挑战'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final habitCtrl = TextEditingController();
    int days = 21;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('创建习惯挑战'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: '挑战名称', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: habitCtrl, decoration: const InputDecoration(labelText: '目标习惯', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                const Text('挑战天数'),
                Wrap(
                  spacing: 8,
                  children: [21, 30, 66, 100].map((d) => ChoiceChip(
                    label: Text('$d天'),
                    selected: days == d,
                    onSelected: (_) => setState(() => days = d),
                  )).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.isNotEmpty && habitCtrl.text.isNotEmpty) {
                  ref.read(habitChallengesProvider.notifier).createChallenge(nameCtrl.text, habitCtrl.text, days);
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

  void _showJoinDialog(BuildContext context, WidgetRef ref, HabitChallenge challenge) {
    final habitCtrl = TextEditingController(text: challenge.targetHabit);
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('参与挑战'),
        content: TextField(controller: habitCtrl, decoration: const InputDecoration(labelText: '你的习惯', border: OutlineInputBorder())),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(
            onPressed: () {
              final startDate = DateTime.parse(challenge.startDate);
              final endDate = challenge.endDate != null ? DateTime.parse(challenge.endDate!) : DateTime.now().add(const Duration(days: 30));
              final targetDays = endDate.difference(startDate).inDays;
              ref.read(habitChallengesProvider.notifier).joinChallenge(challenge.id!, habitCtrl.text, targetDays);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已加入挑战!')));
            },
            child: const Text('加入'),
          ),
        ],
      ),
    );
  }
}