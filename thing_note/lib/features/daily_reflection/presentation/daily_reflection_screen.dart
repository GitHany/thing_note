import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/daily_reflection/data/daily_reflection_repository.dart';
import 'package:thing_note/features/daily_reflection/domain/daily_reflection.dart';

class DailyReflectionScreen extends ConsumerStatefulWidget {
  const DailyReflectionScreen({super.key});

  @override
  ConsumerState<DailyReflectionScreen> createState() => _DailyReflectionScreenState();
}

class _DailyReflectionScreenState extends ConsumerState<DailyReflectionScreen> {
  final _achievementsController = TextEditingController();
  final _gratitudeController = TextEditingController();
  final _improvementsController = TextEditingController();
  final _priorityController = TextEditingController();
  int _moodSummary = 3;

  @override
  void initState() {
    super.initState();
    _loadTodayReflection();
  }

  Future<void> _loadTodayReflection() async {
    final reflection = await ref.read(todayReflectionProvider.future);
    if (reflection != null) {
      _achievementsController.text = reflection.achievements;
      _gratitudeController.text = reflection.gratitude;
      _improvementsController.text = reflection.improvements;
      _priorityController.text = reflection.tomorrowPriority;
      setState(() {
        _moodSummary = reflection.moodSummary;
      });
    }
  }

  @override
  void dispose() {
    _achievementsController.dispose();
    _gratitudeController.dispose();
    _improvementsController.dispose();
    _priorityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ignore: unused_local_variable
    final reflectionsAsync = ref.watch(dailyReflectionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('每日反思'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => _showHistory(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              title: '🌟 今日成就',
              subtitle: '3件做得好的事',
              controller: _achievementsController,
              hint: '1. ...\n2. ...\n3. ...',
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: '🙏 感恩事项',
              subtitle: '3件感恩的事',
              controller: _gratitudeController,
              hint: '1. ...\n2. ...\n3. ...',
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: '📝 改进机会',
              subtitle: '1-2件可以改进的事',
              controller: _improvementsController,
              hint: '1. ...\n2. ...',
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: '🎯 明日重点',
              subtitle: '1件最重要的事',
              controller: _priorityController,
              hint: '今天最重要的事情是...',
            ),
            const SizedBox(height: 24),
            _buildMoodSelector(),
            const SizedBox(height: 32),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String subtitle,
    required TextEditingController controller,
    required String hint,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: hint,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('😊 今日心情', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(5, (index) {
                final level = index + 1;
                final isSelected = _moodSummary == level;
                return GestureDetector(
                  onTap: () => setState(() => _moodSummary = level),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected ? _getMoodColor(level).withOpacity(0.3) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? _getMoodColor(level) : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Text(_getMoodEmoji(level), style: const TextStyle(fontSize: 24)),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _saveReflection,
        icon: const Icon(Icons.save),
        label: const Text('保存反思'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  String _getMoodEmoji(int level) {
    switch (level) {
      case 1: return '😢';
      case 2: return '😕';
      case 3: return '😐';
      case 4: return '🙂';
      case 5: return '😄';
      default: return '😐';
    }
  }

  Color _getMoodColor(int level) {
    switch (level) {
      case 1: return Colors.red;
      case 2: return Colors.orange;
      case 3: return Colors.grey;
      case 4: return Colors.lightGreen;
      case 5: return Colors.green;
      default: return Colors.grey;
    }
  }

  Future<void> _saveReflection() async {
    final now = DateTime.now();
    final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final reflection = DailyReflection(
      date: dateStr,
      achievements: _achievementsController.text,
      gratitude: _gratitudeController.text,
      improvements: _improvementsController.text,
      tomorrowPriority: _priorityController.text,
      moodSummary: _moodSummary,
    );

    await ref.read(dailyReflectionsProvider.notifier).addReflection(reflection);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('反思已保存')),
      );
    }
  }

  void _showHistory(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text('历史反思', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Expanded(
                child: ref.watch(dailyReflectionsProvider).when(
                  data: (reflections) => ListView.builder(
                    controller: scrollController,
                    itemCount: reflections.length,
                    itemBuilder: (context, index) {
                      final r = reflections[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          title: Text(r.date),
                          subtitle: Text('${r.achievements.split('\n').length}项成就 | ${r.gratitude.split('\n').length}项感恩'),
                          trailing: Text(_getMoodEmoji(r.moodSummary), style: const TextStyle(fontSize: 24)),
                        ),
                      );
                    },
                  ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, s) => Center(child: Text('错误: $e')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}