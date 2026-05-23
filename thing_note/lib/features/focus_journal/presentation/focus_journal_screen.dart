import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models.dart';
import '../data/provider.dart';

class FocusJournalScreen extends ConsumerStatefulWidget {
  const FocusJournalScreen({super.key});

  @override
  ConsumerState<FocusJournalScreen> createState() => _FocusJournalScreenState();
}

class _FocusJournalScreenState extends ConsumerState<FocusJournalScreen> {
  @override
  Widget build(BuildContext context) {
    final todayEntry = ref.watch(todayFocusJournalProvider);
    final stats = ref.watch(weeklyStatsProvider);
    final entries = ref.watch(focusJournalProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Focus Journal'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Weekly Stats Card
          Card(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('This Week', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatItem(
                        icon: Icons.timer,
                        label: 'Sessions',
                        value: '${stats['totalSessions']}',
                      ),
                      _StatItem(
                        icon: Icons.hourglass_bottom,
                        label: 'Hours',
                        value: (stats['totalHours'] as double).toStringAsFixed(1),
                      ),
                      _StatItem(
                        icon: Icons.star,
                        label: 'Avg Rating',
                        value: (stats['avgProductivity'] as double).toStringAsFixed(1),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Today's Entry
          Text("Today's Entry", style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (todayEntry != null)
            _EntryCard(entry: todayEntry, onDelete: () {
              ref.read(focusJournalProvider.notifier).deleteEntry(todayEntry.id!);
            })
          else
            Card(
              child: ListTile(
                leading: const Icon(Icons.add_circle_outline),
                title: const Text('Log your focus session'),
                trailing: FilledButton(
                  onPressed: () => _showAddEntryDialog(context, ref),
                  child: const Text('Add'),
                ),
              ),
            ),
          
          const SizedBox(height: 24),
          
          // History
          Text('Recent Entries', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...entries.take(20).map((entry) => _EntryCard(entry: entry, onDelete: () {
            ref.read(focusJournalProvider.notifier).deleteEntry(entry.id!);
          })),
        ],
      ),
    );
  }

  void _showAddEntryDialog(BuildContext context, WidgetRef ref) {
    String selectedDuration = '30min';
    String selectedTaskType = 'deep_work';
    int selectedRating = 3;
    String selectedEnergy = 'medium';
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Log Focus Session'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Focus Duration'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: ['15min', '30min', '1h', '2h', '2h+'].map((d) => 
                    ChoiceChip(
                      label: Text(d),
                      selected: selectedDuration == d,
                      onSelected: (s) => setState(() => selectedDuration = d),
                    )
                  ).toList(),
                ),
                const SizedBox(height: 16),
                const Text('Task Type'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: FocusJournalEntry.taskTypeLabels.entries.map((e) => 
                    ChoiceChip(
                      avatar: Icon(FocusJournalEntry.taskTypeIcons[e.key], size: 18),
                      label: Text(e.value),
                      selected: selectedTaskType == e.key,
                      onSelected: (s) => setState(() => selectedTaskType = e.key),
                    )
                  ).toList(),
                ),
                const SizedBox(height: 16),
                const Text('Productivity Rating'),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) => 
                    IconButton(
                      icon: Icon(i < selectedRating ? Icons.star : Icons.star_border),
                      color: Colors.amber,
                      onPressed: () => setState(() => selectedRating = i + 1),
                    )
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Energy Level'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: ['high', 'medium', 'low'].map((e) => 
                    ChoiceChip(
                      label: Text(e == 'high' ? '🔋 High' : e == 'medium' ? '⚡ Medium' : '🪫 Low'),
                      selected: selectedEnergy == e,
                      onSelected: (s) => setState(() => selectedEnergy = e),
                    )
                  ).toList(),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(labelText: 'Notes (optional)'),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                ref.read(focusJournalProvider.notifier).addEntry(
                  FocusJournalEntry(
                    date: DateTime.now(),
                    focusDuration: selectedDuration,
                    taskType: selectedTaskType,
                    productivityRating: selectedRating,
                    notes: notesController.text.isEmpty ? null : notesController.text,
                    energyLevel: selectedEnergy,
                  ),
                );
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatItem({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 28, color: Theme.of(context).primaryColor),
        const SizedBox(height: 4),
        Text(value, style: Theme.of(context).textTheme.headlineSmall),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _EntryCard extends StatelessWidget {
  final FocusJournalEntry entry;
  final VoidCallback onDelete;

  const _EntryCard({required this.entry, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final taskIcon = FocusJournalEntry.taskTypeIcons[entry.taskType] ?? Icons.circle;
    final isToday = DateTime.now().day == entry.date.day && 
                    DateTime.now().month == entry.date.month &&
                    DateTime.now().year == entry.date.year;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
          child: Icon(taskIcon, color: Theme.of(context).primaryColor),
        ),
        title: Row(
          children: [
            Text(FocusJournalEntry.taskTypeLabels[entry.taskType] ?? entry.taskType),
            const SizedBox(width: 8),
            Text('• ${entry.focusDuration}', style: Theme.of(context).textTheme.bodySmall),
            if (isToday) ...[
              const SizedBox(width: 8),
              const Chip(label: Text('Today'), visualDensity: VisualDensity.compact, padding: EdgeInsets.zero),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(entry.date.toString().substring(0, 10)),
                const SizedBox(width: 8),
                ...List.generate(5, (i) => 
                  Icon(i < entry.productivityRating ? Icons.star : Icons.star_border, 
                       size: 14, color: Colors.amber)
                ),
              ],
            ),
            if (entry.energyLevel != null)
              Text('Energy: ${entry.energyLevel}'),
            if (entry.notes != null)
              Text(entry.notes!, maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ),
        trailing: IconButton(icon: const Icon(Icons.delete_outline), onPressed: onDelete),
      ),
    );
  }
}