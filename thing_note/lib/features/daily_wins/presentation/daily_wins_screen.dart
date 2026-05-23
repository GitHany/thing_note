import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final dailyWinsProvider = StateNotifierProvider<DailyWinsNotifier, List<DailyWin>>((ref) {
  return DailyWinsNotifier();
});

class DailyWinsNotifier extends StateNotifier<List<DailyWin>> {
  DailyWinsNotifier() : super([]);

  void addWin(DailyWin win) {
    state = [win, ...state];
  }

  void removeWin(int id) {
    state = state.where((w) => w.id != id).toList();
  }

  List<DailyWin> getTodayWins() {
    final today = DateTime.now().toIso8601String().split('T')[0];
    return state.where((w) => w.winDate == today).toList();
  }

  int get todayPoints => getTodayWins().fold(0, (sum, w) => sum + w.points);
}

class DailyWin {
  final int id;
  final String winDate;
  final String title;
  final String? description;
  final String? category;
  final int points;
  final String createdAt;

  DailyWin({
    required this.id,
    required this.winDate,
    required this.title,
    this.description,
    this.category,
    this.points = 10,
    required this.createdAt,
  });

  DailyWin copyWith({
    int? id,
    String? winDate,
    String? title,
    String? description,
    String? category,
    int? points,
    String? createdAt,
  }) {
    return DailyWin(
      id: id ?? this.id,
      winDate: winDate ?? this.winDate,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      points: points ?? this.points,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class DailyWinsScreen extends ConsumerStatefulWidget {
  const DailyWinsScreen({super.key});

  @override
  ConsumerState<DailyWinsScreen> createState() => _DailyWinsScreenState();
}

class _DailyWinsScreenState extends ConsumerState<DailyWinsScreen> {
  int _nextId = 1;

  @override
  Widget build(BuildContext context) {
    final wins = ref.watch(dailyWinsProvider);
    final notifier = ref.read(dailyWinsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Wins'),
      ),
      body: Column(
        children: [
          _buildTodayCard(wins, notifier),
          Expanded(
            child: wins.isEmpty ? _buildEmptyState() : _buildWinsList(wins),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddWinDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Log Win'),
      ),
    );
  }

  Widget _buildTodayCard(List<DailyWin> wins, DailyWinsNotifier notifier) {
    final todayWins = notifier.getTodayWins();
    final points = notifier.todayPoints;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.amber, Colors.orange],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text(
            "Today's Wins",
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            '$points',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Text(
            'points earned',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              (todayWins.length > 5 ? 5 : todayWins.length),
              (i) => const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Icon(Icons.star, color: Colors.white, size: 24),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${todayWins.length} wins logged today',
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.emoji_events, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No wins logged yet',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Start logging your daily achievements!',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildWinsList(List<DailyWin> wins) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: wins.length,
      itemBuilder: (context, index) {
        final win = wins[index];
        return _buildWinCard(win);
      },
    );
  }

  Widget _buildWinCard(DailyWin win) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _getCategoryColor(win.category).withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getCategoryIcon(win.category),
            color: _getCategoryColor(win.category),
          ),
        ),
        title: Text(win.title),
        subtitle: win.description != null ? Text(win.description!) : null,
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.amber.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '+${win.points}',
            style: const TextStyle(
              color: Colors.amber,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(String? category) {
    switch (category) {
      case 'work': return Colors.blue;
      case 'health': return Colors.green;
      case 'learning': return Colors.purple;
      case 'social': return Colors.pink;
      case 'personal': return Colors.orange;
      default: return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String? category) {
    switch (category) {
      case 'work': return Icons.work;
      case 'health': return Icons.fitness_center;
      case 'learning': return Icons.school;
      case 'social': return Icons.people;
      case 'personal': return Icons.person;
      default: return Icons.star;
    }
  }

  void _showAddWinDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    String category = 'personal';
    int points = 10;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Log a Win! 🎉'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'What did you achieve?',
                    hintText: 'e.g., Finished project report',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: 'Details (optional)'),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                const Text('Category'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: ['work', 'health', 'learning', 'social', 'personal']
                      .map((c) => ChoiceChip(
                            label: Text(c.toUpperCase()),
                            selected: category == c,
                            onSelected: (_) => setState(() => category = c),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Points:'),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: () {
                        if (points > 5) setState(() => points -= 5);
                      },
                    ),
                    Text(
                      '$points',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () => setState(() => points += 5),
                    ),
                  ],
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
                if (titleController.text.isNotEmpty) {
                  final win = DailyWin(
                    id: _nextId++,
                    winDate: DateTime.now().toIso8601String().split('T')[0],
                    title: titleController.text,
                    description: descController.text.isEmpty ? null : descController.text,
                    category: category,
                    points: points,
                    createdAt: DateTime.now().toIso8601String(),
                  );
                  ref.read(dailyWinsProvider.notifier).addWin(win);
                  Navigator.pop(context);
                }
              },
              child: const Text('Log Win'),
            ),
          ],
        ),
      ),
    );
  }
}