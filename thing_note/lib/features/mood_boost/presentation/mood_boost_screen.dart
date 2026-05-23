import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/mood_boost/data/mood_action_repository.dart';
import 'package:thing_note/features/mood_boost/domain/mood_action.dart';

class MoodBoostScreen extends ConsumerWidget {
  const MoodBoostScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMood = ref.watch(currentMoodProvider);
    // Track mood actions for potential future use
    ref.watch(moodActionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('情绪行动建议'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildMoodSelector(context, ref, currentMood),
            const SizedBox(height: 32),
            _buildMoodMessage(currentMood),
            const SizedBox(height: 24),
            _buildSuggestedActions(context, currentMood),
            const SizedBox(height: 32),
            _buildQuickActions(currentMood),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodSelector(BuildContext context, WidgetRef ref, int currentMood) {
    return Column(
      children: [
        const Text(
          '你现在的情绪如何？',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(5, (index) {
            final mood = index + 1;
            final isSelected = mood == currentMood;
            return GestureDetector(
              onTap: () => ref.read(currentMoodProvider.notifier).state = mood,
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: _getMoodColor(mood).withOpacity(isSelected ? 1 : 0.3),
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: _getMoodColor(mood), width: 3)
                          : null,
                    ),
                    child: Center(
                      child: Icon(
                        _getMoodIcon(mood),
                        color: isSelected ? Colors.white : _getMoodColor(mood),
                        size: 28,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getMoodLabel(mood),
                    style: TextStyle(
                      color: isSelected ? _getMoodColor(mood) : Colors.grey,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildMoodMessage(int mood) {
    final messages = {
      1: '别担心，一切都会好起来的 💙',
      2: '放松一下，给自己一点时间 🌿',
      3: '保持平衡，继续前行 🌟',
      4: '做得很好！继续保持 💪',
      5: '太棒了！分享你的快乐 🎉',
    };
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getMoodColor(mood).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        messages[mood] ?? '',
        style: TextStyle(
          fontSize: 16,
          color: _getMoodColor(mood),
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildSuggestedActions(BuildContext context, int mood) {
    final suggestedActions = PresetMoodAction.presets.where((p) => p.moodLevel == mood).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '推荐行动',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: suggestedActions.map((action) {
            return _ActionChip(action: action, onTap: () => _showActionDetail(context, action));
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildQuickActions(int mood) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '快速操作',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.1,
          children: [
            _QuickActionCard(
              icon: Icons.music_note,
              label: '听音乐',
              color: Colors.purple,
              onTap: () {},
            ),
            _QuickActionCard(
              icon: Icons.self_improvement,
              label: '冥想',
              color: Colors.teal,
              onTap: () {},
            ),
            _QuickActionCard(
              icon: Icons.directions_walk,
              label: '散步',
              color: Colors.green,
              onTap: () {},
            ),
            _QuickActionCard(
              icon: Icons.chat,
              label: '聊天',
              color: Colors.blue,
              onTap: () {},
            ),
            _QuickActionCard(
              icon: Icons.menu_book,
              label: '阅读',
              color: Colors.brown,
              onTap: () {},
            ),
            _QuickActionCard(
              icon: Icons.fitness_center,
              label: '运动',
              color: Colors.orange,
              onTap: () {},
            ),
          ],
        ),
      ],
    );
  }

  void _showActionDetail(BuildContext context, PresetMoodAction action) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(action.icon, color: _getMoodColor(action.moodLevel)),
            const SizedBox(width: 8),
            Text(action.actionName),
          ],
        ),
        content: Text('建议：$action\n\n这个行动可以帮助你调节情绪，请尝试一下！'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('开始: ${action.actionName} ✓')),
              );
            },
            child: const Text('开始'),
          ),
        ],
      ),
    );
  }

  Color _getMoodColor(int mood) {
    switch (mood) {
      case 1: return Colors.blue;
      case 2: return Colors.green;
      case 3: return Colors.amber;
      case 4: return Colors.orange;
      case 5: return Colors.red;
      default: return Colors.grey;
    }
  }

  IconData _getMoodIcon(int mood) {
    switch (mood) {
      case 1: return Icons.sentiment_very_dissatisfied;
      case 2: return Icons.sentiment_dissatisfied;
      case 3: return Icons.sentiment_neutral;
      case 4: return Icons.sentiment_satisfied;
      case 5: return Icons.sentiment_very_satisfied;
      default: return Icons.sentiment_neutral;
    }
  }

  String _getMoodLabel(int mood) {
    switch (mood) {
      case 1: return '很差';
      case 2: return '较差';
      case 3: return '一般';
      case 4: return '较好';
      case 5: return '很好';
      default: return '';
    }
  }
}

class _ActionChip extends StatelessWidget {
  final PresetMoodAction action;
  final VoidCallback onTap;

  const _ActionChip({required this.action, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(action.icon, size: 18),
      label: Text(action.actionName),
      onPressed: onTap,
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}