import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/habit_tournament/data/tournament_repository.dart';
import 'package:thing_note/features/habit_tournament/domain/tournament_models.dart';

class HabitTournamentScreen extends ConsumerWidget {
  const HabitTournamentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tournamentsAsync = ref.watch(habitTournamentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('习惯挑战赛'),
      ),
      body: tournamentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('错误: $e')),
        data: (tournaments) {
          final active = tournaments.where((t) => t.status == 'active').toList();
          final completed = tournaments.where((t) => t.status == 'completed').toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (active.isNotEmpty) ...[
                const Text('进行中', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ...active.map((t) => _TournamentCard(tournament: t)),
              ],
              if (completed.isNotEmpty) ...[
                const SizedBox(height: 24),
                const Text('已结束', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 12),
                ...completed.map((t) => _TournamentCard(tournament: t)),
              ],
              if (tournaments.isEmpty) ...[
                const SizedBox(height: 100),
                const Center(
                  child: Column(
                    children: [
                      Icon(Icons.emoji_events, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('暂无挑战赛', style: TextStyle(fontSize: 18)),
                      SizedBox(height: 8),
                      Text('发起挑战赛，与他人竞争', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final habitController = TextEditingController();
    final DateTime startDate = DateTime.now();
    DateTime? endDate;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('创建挑战赛'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: '挑战赛名称'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: habitController,
                decoration: const InputDecoration(labelText: '目标习惯'),
              ),
              const SizedBox(height: 12),
              ListTile(
                title: const Text('开始日期'),
                subtitle: Text('${startDate.year}/${startDate.month}/${startDate.day}'),
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
              if (nameController.text.isNotEmpty && habitController.text.isNotEmpty) {
                final tournament = HabitTournament(
                  name: nameController.text,
                  targetHabit: habitController.text,
                  startDate: startDate,
                  endDate: endDate,
                  createdAt: DateTime.now(),
                );
                ref.read(habitTournamentsProvider.notifier).addTournament(tournament);
                Navigator.pop(context);
              }
            },
            child: const Text('创建'),
          ),
        ],
      ),
    );
  }
}

class _TournamentCard extends ConsumerWidget {
  final HabitTournament tournament;

  const _TournamentCard({required this.tournament});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final participantsAsync = ref.watch(tournamentParticipantsProvider(tournament.id!));

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.emoji_events, color: Colors.amber),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tournament.name,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '目标: ${tournament.targetHabit}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                _StatusChip(status: tournament.status),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${tournament.startDate.month}/${tournament.startDate.day}${tournament.endDate != null ? ' - ${tournament.endDate!.month}/${tournament.endDate!.day}' : ''}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text('排行榜', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            participantsAsync.when(
              data: (participants) {
                if (participants.isEmpty) return const Text('暂无参与者');
                return Column(
                  children: participants.take(5).map((p) => ListTile(
                    dense: true,
                    leading: _RankBadge(rank: p.rank),
                    title: Text(p.participantName),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.local_fire_department, size: 16, color: Colors.orange),
                        const SizedBox(width: 4),
                        Text('${p.currentStreak}天'),
                      ],
                    ),
                  )).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('错误: $e'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => _showJoinDialog(context, ref),
              child: const Text('参与挑战'),
            ),
          ],
        ),
      ),
    );
  }

  void _showJoinDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('参与挑战'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: '你的昵称'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                ref.read(habitTournamentsProvider.notifier).joinTournament(
                  tournament.id!,
                  nameController.text,
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('参与成功！')),
                );
              }
            },
            child: const Text('加入'),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    
    switch (status) {
      case 'active':
        color = Colors.green;
        label = '进行中';
        break;
      case 'completed':
        color = Colors.grey;
        label = '已结束';
        break;
      default:
        color = Colors.grey;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 12)),
    );
  }
}

class _RankBadge extends StatelessWidget {
  final int rank;

  const _RankBadge({required this.rank});

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;
    
    switch (rank) {
      case 1:
        color = Colors.amber;
        icon = Icons.looks_one;
        break;
      case 2:
        color = Colors.grey;
        icon = Icons.looks_two;
        break;
      case 3:
        color = Colors.orange;
        icon = Icons.looks_3;
        break;
      default:
        return CircleAvatar(
          radius: 12,
          backgroundColor: Colors.grey[200],
          child: Text('$rank', style: const TextStyle(fontSize: 12)),
        );
    }

    return CircleAvatar(
      radius: 12,
      backgroundColor: color.withOpacity(0.2),
      child: Icon(icon, color: color, size: 20),
    );
  }
}