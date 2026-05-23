import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/mood_calendar/data/mood_calendar_repository.dart';
import 'package:thing_note/features/mood_calendar/domain/mood_entry.dart';
import 'package:thing_note/l10n/generated/app_localizations.dart';

final moodCalendarProvider = Provider((ref) => ref.watch(moodCalendarRepositoryProvider));

class MoodCalendarScreen extends ConsumerStatefulWidget {
  const MoodCalendarScreen({super.key});

  @override
  ConsumerState<MoodCalendarScreen> createState() => _MoodCalendarScreenState();
}

class _MoodCalendarScreenState extends ConsumerState<MoodCalendarScreen> {
  DateTime _selectedMonth = DateTime.now();
  List<MoodEntry> _entries = [];

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

Future<void> _loadEntries() async {
    final repo = ref.read(moodCalendarProvider);
    _entries = await repo.getByMonth(_selectedMonth.year, _selectedMonth.month);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.moodCalendar),
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: () {
              setState(() => _selectedMonth = DateTime.now());
              _loadEntries();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildMonthSelector(),
            const SizedBox(height: 16),
            _buildMoodCalendar(),
            const SizedBox(height: 24),
            _buildMoodLegend(),
            const SizedBox(height: 24),
            _buildRecentMoods(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddMoodDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildMonthSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () {
                setState(() {
                  _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
                });
                _loadEntries();
              },
            ),
            Text(
              '${_selectedMonth.year}年${_selectedMonth.month}月',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () {
                setState(() {
                  _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
                });
                _loadEntries();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodCalendar() {
    final firstDay = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final lastDay = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);
    final startWeekday = firstDay.weekday % 7;

    final days = <Widget>[];
    
    // Weekday headers
    const weekDays = ['日', '一', '二', '三', '四', '五', '六'];
    for (final day in weekDays) {
      days.add(Center(child: Text(day, style: const TextStyle(fontWeight: FontWeight.bold))));
    }

    // Empty cells
    for (var i = 0; i < startWeekday; i++) {
      days.add(const SizedBox());
    }

    // Calendar days
    for (var day = 1; day <= lastDay.day; day++) {
      final dateStr = '${_selectedMonth.year}-${_selectedMonth.month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
      final entry = _entries.where((e) => e.date == dateStr).firstOrNull;
      
      days.add(GestureDetector(
        onTap: entry != null ? () => _showMoodDetails(entry) : _showAddMoodDialog,
        child: Container(
          decoration: BoxDecoration(
            color: entry != null ? _getMoodColor(entry.level).withOpacity(0.3) : null,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('$day', style: const TextStyle(fontWeight: FontWeight.w500)),
              if (entry != null)
                Text(
                  entry.moodEmoji,
                  style: const TextStyle(fontSize: 16),
                ),
            ],
          ),
        ),
      ));
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
          children: days,
        ),
      ),
    );
  }

  Widget _buildMoodLegend() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('情绪图例', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            const Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _MoodLegendItem(emoji: '😢', label: '很差', level: 1),
                _MoodLegendItem(emoji: '😕', label: '较差', level: 2),
                _MoodLegendItem(emoji: '😐', label: '一般', level: 3),
                _MoodLegendItem(emoji: '🙂', label: '不错', level: 4),
                _MoodLegendItem(emoji: '😄', label: '很好', level: 5),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentMoods() {
    return FutureBuilder<List<MoodEntry>>(
      future: ref.read(moodCalendarProvider).getRecent(7),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        final recent = snapshot.data!;
        
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('最近情绪', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                if (recent.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('还没有记录'),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: recent.length,
                    itemBuilder: (context, index) {
                      final entry = recent[index];
                      return ListTile(
                        leading: Text(entry.moodEmoji, style: const TextStyle(fontSize: 24)),
                        title: Text(entry.moodLabel),
                        subtitle: Text(entry.date),
                        trailing: entry.note != null && entry.note!.isNotEmpty
                            ? const Icon(Icons.note, size: 16)
                            : null,
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getMoodColor(int level) {
    switch (level) {
      case 1: return Colors.red;
      case 2: return Colors.orange;
      case 3: return Colors.yellow;
      case 4: return Colors.lightGreen;
      case 5: return Colors.green;
      default: return Colors.grey;
    }
  }

  void _showAddMoodDialog() {
    int selectedLevel = 3;
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('记录今日情绪'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                spacing: 12,
                children: [1, 2, 3, 4, 5].map((level) {
                  return GestureDetector(
                    onTap: () => setDialogState(() => selectedLevel = level),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: selectedLevel == level
                            ? _getMoodColor(level).withOpacity(0.3)
                            : null,
                        border: Border.all(
                          color: selectedLevel == level
                              ? _getMoodColor(level)
                              : Colors.grey.withOpacity(0.3),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getMoodEmoji(level),
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(
                  labelText: '备注（可选）',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () async {
                final today = DateTime.now().toIso8601String().split('T')[0];
                final entry = MoodEntry(
                  date: today,
                  level: selectedLevel,
                  note: noteController.text.isNotEmpty ? noteController.text : null,
                );
                await ref.read(moodCalendarProvider).insertOrUpdate(entry);
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                _loadEntries();
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }

  void _showMoodDetails(MoodEntry entry) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Text(entry.moodEmoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 8),
            Text(entry.moodLabel),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('日期: ${entry.date}'),
            if (entry.note != null && entry.note!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('备注: ${entry.note}'),
            ],
            if (entry.triggers != null && entry.triggers!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('触发因素: ${entry.triggers!.join(", ")}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('关闭'),
          ),
        ],
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
}

class _MoodLegendItem extends StatelessWidget {
  final String emoji;
  final String label;
  final int level;

  const _MoodLegendItem({
    required this.emoji,
    required this.label,
    required this.level,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 4),
        Text(label),
      ],
    );
  }
}