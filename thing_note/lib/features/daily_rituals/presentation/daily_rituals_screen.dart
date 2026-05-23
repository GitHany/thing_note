import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models.dart';
import '../data/provider.dart';

class DailyRitualsScreen extends ConsumerStatefulWidget {
  const DailyRitualsScreen({super.key});

  @override
  ConsumerState<DailyRitualsScreen> createState() => _DailyRitualsScreenState();
}

class _DailyRitualsScreenState extends ConsumerState<DailyRitualsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rituals = ref.watch(dailyRitualsProvider);
    final completions = ref.watch(ritualCompletionsProvider(DateTime.now()));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Rituals'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '🌅 Morning'),
            Tab(text: '☀️ Afternoon'),
            Tab(text: '🌙 Evening'),
            Tab(text: '🌑 Night'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _RitualListView(timeOfDay: 'morning', rituals: rituals, completions: completions),
          _RitualListView(timeOfDay: 'afternoon', rituals: rituals, completions: completions),
          _RitualListView(timeOfDay: 'evening', rituals: rituals, completions: completions),
          _RitualListView(timeOfDay: 'night', rituals: rituals, completions: completions),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddRitualDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddRitualDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    String selectedTime = 'morning';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Ritual'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: 'Description (optional)'),
            ),
            const SizedBox(height: 8),
            StatefulBuilder(
              builder: (context, setState) => DropdownButtonFormField<String>(
                value: selectedTime,
                decoration: const InputDecoration(labelText: 'Time of Day'),
                items: const [
                  DropdownMenuItem(value: 'morning', child: Text('🌅 Morning')),
                  DropdownMenuItem(value: 'afternoon', child: Text('☀️ Afternoon')),
                  DropdownMenuItem(value: 'evening', child: Text('🌙 Evening')),
                  DropdownMenuItem(value: 'night', child: Text('🌑 Night')),
                ],
                onChanged: (v) => setState(() => selectedTime = v!),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                final rituals = ref.read(dailyRitualsProvider);
                final timeRituals = rituals.where((r) => r.timeOfDay == selectedTime).toList();
                ref.read(dailyRitualsProvider.notifier).addRitual(
                  DailyRitual(
                    name: nameController.text,
                    description: descController.text.isEmpty ? null : descController.text,
                    timeOfDay: selectedTime,
                    orderIndex: timeRituals.length,
                  ),
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class _RitualListView extends ConsumerWidget {
  final String timeOfDay;
  final List<DailyRitual> rituals;
  final AsyncValue<List<RitualCompletion>> completions;

  const _RitualListView({
    required this.timeOfDay,
    required this.rituals,
    required this.completions,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredRituals = rituals.where((r) => r.timeOfDay == timeOfDay && r.isActive).toList();

    return completions.when(
      data: (completionList) {
        final completedIds = completionList.map((c) => c.ritualId).toSet();

        if (filteredRituals.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.self_improvement, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'No rituals for this time',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                const Text('Tap + to add a ritual'),
              ],
            ),
          );
        }

        return ReorderableListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredRituals.length,
          onReorder: (oldIndex, newIndex) {
            if (newIndex > oldIndex) newIndex--;
            final reordered = [...filteredRituals];
            final item = reordered.removeAt(oldIndex);
            reordered.insert(newIndex, item);
            ref.read(dailyRitualsProvider.notifier).reorderRituals(reordered);
          },
          itemBuilder: (context, index) {
            final ritual = filteredRituals[index];
            final isCompleted = completedIds.contains(ritual.id);

            return Card(
              key: ValueKey(ritual.id),
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: IconButton(
                  icon: Icon(
                    isCompleted ? Icons.check_circle : Icons.circle_outlined,
                    color: isCompleted ? Colors.green : Colors.grey,
                  ),
                  onPressed: () {
                    if (isCompleted) {
                      ref.read(dailyRitualsProvider.notifier).uncompleteRitual(ritual.id!, DateTime.now());
                    } else {
                      ref.read(dailyRitualsProvider.notifier).completeRitual(
                        RitualCompletion(
                          ritualId: ritual.id!,
                          completedAt: DateTime.now(),
                        ),
                      );
                    }
                  },
                ),
                title: Text(
                  ritual.name,
                  style: TextStyle(
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                    color: isCompleted ? Colors.grey : null,
                  ),
                ),
                subtitle: ritual.description != null ? Text(ritual.description!) : null,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _showEditDialog(context, ref, ritual),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        ref.read(dailyRitualsProvider.notifier).deleteRitual(ritual.id!);
                      },
                    ),
                    const Icon(Icons.drag_handle),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, DailyRitual ritual) {
    final nameController = TextEditingController(text: ritual.name);
    final descController = TextEditingController(text: ritual.description ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Ritual'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(dailyRitualsProvider.notifier).updateRitual(
                ritual.copyWith(
                  name: nameController.text,
                  description: descController.text.isEmpty ? null : descController.text,
                ),
              );
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}