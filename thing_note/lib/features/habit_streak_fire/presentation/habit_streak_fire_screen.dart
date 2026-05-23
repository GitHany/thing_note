import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/habit_streak_fire/data/streak_fire_repository.dart';
import 'package:thing_note/features/habit_streak_fire/domain/habit_streak_fire.dart';

class HabitStreakFireScreen extends ConsumerWidget {
  const HabitStreakFireScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('习惯火焰'),
      ),
      body: FutureBuilder<List<HabitStreakFire>>(
        future: ref.read(streakFireRepositoryProvider).getOnFireHabits(),
        builder: (context, snapshot) {
          final onFire = snapshot.data ?? [];
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 火焰总览
                _FlameOverview(onFireCount: onFire.length),
                const SizedBox(height: 24),
                const Text('正在燃烧的习惯', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (onFire.isEmpty)
                  _NoFireState()
                else
                  ...onFire.map((sf) => _StreakFireCard(streakFire: sf)),
                const SizedBox(height: 24),
                // 火焰等级说明
                _FireLevelLegend(),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FlameOverview extends StatelessWidget {
  final int onFireCount;
  const _FlameOverview({required this.onFireCount});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: onFireCount > 0 ? Colors.orange.shade100 : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.local_fire_department,
                size: 36,
                color: onFireCount > 0 ? Colors.orange : Colors.grey,
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$onFireCount 个习惯正在燃烧',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  onFireCount > 0 ? '保持火焰，持续努力！' : '开始一个习惯来点燃火焰',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NoFireState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            Icon(Icons.local_fire_department_outlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text('还没有燃烧的习惯', style: TextStyle(color: Colors.grey.shade500)),
            const SizedBox(height: 4),
            Text('坚持7天以上就会点燃火焰！', style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _StreakFireCard extends StatelessWidget {
  final HabitStreakFire streakFire;
  const _StreakFireCard({required this.streakFire});

  @override
  Widget build(BuildContext context) {
    final color = HabitStreakFire.getFlameColorByLevel(streakFire.fireLevel);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                streakFire.fireIcon,
                color: color,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '连续 ${streakFire.currentStreak} 天',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    streakFire.fireLevelLabel,
                    style: TextStyle(color: color, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('最高 ${streakFire.bestStreak} 天', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Text('火焰 ${streakFire.totalFires} 次', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FireLevelLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('火焰等级', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...[
              (0, '未点燃', '0天', Colors.grey),
              (1, '微火', '7+天', const Color(0xFFFFEA00)),
              (2, '小火', '14+天', const Color(0xFFFFD600)),
              (3, '中火', '30+天', const Color(0xFFFFAB00)),
              (4, '大火', '50+天', const Color(0xFFFF6D00)),
              (5, '熊熊烈火', '100+天', const Color(0xFFFF1744)),
            ].map((item) {
              final (level, label, days, color) = item;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(HabitStreakFire.getFlameColorByLevel(level) == Colors.grey
                        ? Icons.local_fire_department_outlined
                        : Icons.whatshot,
                        color: color, size: 20),
                    const SizedBox(width: 8),
                    Expanded(child: Text(label)),
                    Text(days, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
