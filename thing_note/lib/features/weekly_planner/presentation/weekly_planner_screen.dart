import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final weeklyPlannerProvider = StateNotifierProvider<WeeklyPlannerNotifier, List<WeeklyPlannerItem>>((ref) {
  return WeeklyPlannerNotifier();
});

class WeeklyPlannerNotifier extends StateNotifier<List<WeeklyPlannerItem>> {
  WeeklyPlannerNotifier() : super([]);

  void addItem(WeeklyPlannerItem item) {
    state = [...state, item];
  }

  void updateItem(WeeklyPlannerItem item) {
    state = state.map((i) => i.id == item.id ? item : i).toList();
  }

  void removeItem(int id) {
    state = state.where((i) => i.id != id).toList();
  }

  List<WeeklyPlannerItem> getItemsForDay(int dayOfWeek) {
    return state.where((i) => i.dayOfWeek == dayOfWeek).toList()
      ..sort((a, b) => (a.startTime ?? '00:00').compareTo(b.startTime ?? '00:00'));
  }

  int get completedItemsCount => state.where((i) => i.status == 'completed').length;
}

class WeeklyPlannerItem {
  final int id;
  final String title;
  final String? description;
  final int dayOfWeek;
  final String? startTime;
  final int durationMinutes;
  final String priority;
  final String status;
  final int? linkedRecordId;
  final String createdAt;

  WeeklyPlannerItem({
    required this.id,
    required this.title,
    this.description,
    required this.dayOfWeek,
    this.startTime,
    this.durationMinutes = 60,
    this.priority = 'normal',
    this.status = 'pending',
    this.linkedRecordId,
    required this.createdAt,
  });

  WeeklyPlannerItem copyWith({
    int? id,
    String? title,
    String? description,
    int? dayOfWeek,
    String? startTime,
    int? durationMinutes,
    String? priority,
    String? status,
    int? linkedRecordId,
    String? createdAt,
  }) {
    return WeeklyPlannerItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startTime: startTime ?? this.startTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      linkedRecordId: linkedRecordId ?? this.linkedRecordId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class WeeklyPlannerScreen extends ConsumerStatefulWidget {
  const WeeklyPlannerScreen({super.key});

  @override
  ConsumerState<WeeklyPlannerScreen> createState() => _WeeklyPlannerScreenState();
}

class _WeeklyPlannerScreenState extends ConsumerState<WeeklyPlannerScreen> {
  int _nextId = 1;
  int _selectedDay = DateTime.now().weekday % 7;

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(weeklyPlannerProvider);
    final notifier = ref.read(weeklyPlannerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly Planner'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddItemDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildWeekSelector(),
          _buildStats(items, notifier),
          Expanded(
            child: _buildDayView(items, notifier),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddItemDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Task'),
      ),
    );
  }

  Widget _buildWeekSelector() {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(7, (index) {
          final isSelected = _selectedDay == index;
          return GestureDetector(
            onTap: () => setState(() => _selectedDay = index),
            child: Container(
              width: 44,
              height: 60,
              decoration: BoxDecoration(
                color: isSelected ? Colors.blue : Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    days[index],
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[600],
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: isSelected ? Colors.blue : Colors.grey[800],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStats(List<WeeklyPlannerItem> items, WeeklyPlannerNotifier notifier) {
    final todayItems = items.where((i) => i.dayOfWeek == _selectedDay).toList();
    final completed = todayItems.where((i) => i.status == 'completed').length;
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatColumn(
                icon: Icons.list,
                value: '${todayItems.length}',
                label: 'Total',
                color: Colors.blue,
              ),
              _buildStatColumn(
                icon: Icons.check_circle,
                value: '$completed',
                label: 'Done',
                color: Colors.green,
              ),
              _buildStatColumn(
                icon: Icons.pending,
                value: '${todayItems.length - completed}',
                label: 'Pending',
                color: Colors.orange,
              ),
            ],
          ),
        ),
      ),
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
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 11)),
      ],
    );
  }

  Widget _buildDayView(List<WeeklyPlannerItem> items, WeeklyPlannerNotifier notifier) {
    final dayItems = notifier.getItemsForDay(_selectedDay);

    if (dayItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_available, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 8),
            Text('No tasks for this day', style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: dayItems.length,
      itemBuilder: (context, index) {
        final item = dayItems[index];
        return _buildItemCard(item, notifier);
      },
    );
  }

  Widget _buildItemCard(WeeklyPlannerItem item, WeeklyPlannerNotifier notifier) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: item.startTime != null
            ? Container(
                width: 50,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getPriorityColor(item.priority).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.startTime!,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _getPriorityColor(item.priority),
                    fontSize: 12,
                  ),
                ),
              )
            : null,
        title: Text(
          item.title,
          style: TextStyle(
            decoration: item.status == 'completed' ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Text('${item.durationMinutes} min'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (item.status != 'completed')
              IconButton(
                icon: const Icon(Icons.check, color: Colors.green),
                onPressed: () {
                  notifier.updateItem(item.copyWith(status: 'completed'));
                },
              ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => notifier.removeItem(item.id),
            ),
          ],
        ),
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'high': return Colors.red;
      case 'normal': return Colors.blue;
      case 'low': return Colors.grey;
      default: return Colors.blue;
    }
  }

  void _showAddItemDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final timeController = TextEditingController();
    String priority = 'normal';
    int duration = 60;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Weekly Task'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Task Title'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: 'Description (optional)'),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: timeController,
                  decoration: const InputDecoration(
                    labelText: 'Start Time (optional)',
                    hintText: '09:00',
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Duration:'),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: () {
                        if (duration > 15) setState(() => duration -= 15);
                      },
                    ),
                    Text('$duration min', style: const TextStyle(fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () => setState(() => duration += 15),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'high', label: Text('High')),
                    ButtonSegment(value: 'normal', label: Text('Normal')),
                    ButtonSegment(value: 'low', label: Text('Low')),
                  ],
                  selected: {priority},
                  onSelectionChanged: (set) {
                    setState(() => priority = set.first);
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
                if (titleController.text.isNotEmpty) {
                  final item = WeeklyPlannerItem(
                    id: _nextId++,
                    title: titleController.text,
                    description: descController.text.isEmpty ? null : descController.text,
                    dayOfWeek: _selectedDay,
                    startTime: timeController.text.isEmpty ? null : timeController.text,
                    durationMinutes: duration,
                    priority: priority,
                    createdAt: DateTime.now().toIso8601String(),
                  );
                  ref.read(weeklyPlannerProvider.notifier).addItem(item);
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}