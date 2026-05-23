import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/weekly_intentions/data/weekly_intentions_repository.dart';
import 'package:thing_note/features/weekly_intentions/domain/weekly_intention.dart';

class WeeklyIntentionsScreen extends ConsumerStatefulWidget {
  const WeeklyIntentionsScreen({super.key});

  @override
  ConsumerState<WeeklyIntentionsScreen> createState() => _WeeklyIntentionsScreenState();
}

class _WeeklyIntentionsScreenState extends ConsumerState<WeeklyIntentionsScreen> {
  final _themeController = TextEditingController();
  final _intentionsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCurrentWeek();
  }

  Future<void> _loadCurrentWeek() async {
    final intention = await ref.read(currentWeekIntentionProvider.future);
    if (intention != null) {
      _themeController.text = intention.weekTheme ?? '';
      _intentionsController.text = intention.intentions;
    }
  }

  @override
  void dispose() {
    _themeController.dispose();
    _intentionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final intentionsAsync = ref.watch(weeklyIntentionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('周意图规划'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWeekHeader(),
            const SizedBox(height: 24),
            _buildThemeSection(),
            const SizedBox(height: 24),
            _buildIntentionsSection(),
            const SizedBox(height: 24),
            _buildSaveButton(),
            const SizedBox(height: 24),
            _buildHistorySection(intentionsAsync),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekHeader() {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final sunday = monday.add(const Duration(days: 6));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo.shade400, Colors.purple.shade400],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_today, color: Colors.white, size: 32),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('本周主题', style: TextStyle(color: Colors.white70, fontSize: 12)),
              Text(
                '${_formatDate(monday)} - ${_formatDate(sunday)}',
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.lightbulb_outline, color: Colors.amber),
                SizedBox(width: 8),
                Text('本周主题', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            const Text('用一个词或短语概括本周的核心关注点', style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 12),
            TextField(
              controller: _themeController,
              decoration: const InputDecoration(
                hintText: '例如：专注成长、健康生活',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntentionsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.flag, color: Colors.green),
                SizedBox(width: 8),
                Text('主要意图', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            const Text('设定3个主要意图（而不是详细任务列表）', style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 12),
            TextField(
              controller: _intentionsController,
              maxLines: 6,
              decoration: const InputDecoration(
                hintText: '1. 专注于重要但不紧急的任务\n2. 保持每日运动习惯\n3. 减少社交媒体时间',
                border: OutlineInputBorder(),
              ),
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
        onPressed: _saveIntentions,
        icon: const Icon(Icons.save),
        label: const Text('保存本周意图'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildHistorySection(AsyncValue<List<WeeklyIntention>> intentionsAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('历史意图', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        intentionsAsync.when(
          data: (intentions) {
            if (intentions.isEmpty) {
              return const Text('暂无历史记录', style: TextStyle(color: Colors.grey));
            }
            return Column(
              children: intentions.take(4).map((i) => _HistoryCard(intention: i)).toList(),
            );
          },
          loading: () => const CircularProgressIndicator(),
          error: (e, s) => Text('错误: $e'),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}';
  }

  Future<void> _saveIntentions() async {
    final now = DateTime.now();
    final weekday = now.weekday;
    final monday = now.subtract(Duration(days: weekday - 1));
    final weekStart = '${monday.year}-${monday.month.toString().padLeft(2, '0')}-${monday.day.toString().padLeft(2, '0')}';

    final intention = WeeklyIntention(
      weekStart: weekStart,
      weekTheme: _themeController.text.isEmpty ? null : _themeController.text,
      intentions: _intentionsController.text,
    );

    await ref.read(weeklyIntentionsProvider.notifier).addIntention(intention);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('本周意图已保存')),
      );
    }
  }
}

class _HistoryCard extends StatelessWidget {
  final WeeklyIntention intention;

  const _HistoryCard({required this.intention});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(intention.weekTheme ?? '无主题'),
        subtitle: Text('${intention.intentionList.length} 个意图'),
        trailing: intention.themeContinuation > 0
            ? const Chip(label: Text('延续'), backgroundColor: Colors.blue)
            : null,
      ),
    );
  }
}