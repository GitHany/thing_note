import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models.dart';
import '../data/provider.dart';

class PersonalMilestonesScreen extends ConsumerWidget {
  const PersonalMilestonesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(activeMilestonesProvider);
    final completed = ref.watch(completedMilestonesProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Personal Milestones'),
          bottom: const TabBar(
            tabs: [
              Tab(text: '🎯 Active'),
              Tab(text: '✅ Completed'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _MilestoneListView(milestones: active, isActive: true),
            _MilestoneListView(milestones: completed, isActive: false),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showAddMilestoneDialog(context, ref),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  void _showAddMilestoneDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final targetController = TextEditingController(text: '1');
    final unitController = TextEditingController();
    String selectedCategory = 'personal';
    DateTime? selectedDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('New Milestone'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: 'Description (optional)'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: PersonalMilestone.categoryIcons.entries.map((e) => 
                    DropdownMenuItem(value: e.key, child: Row(children: [Icon(e.value), const SizedBox(width: 8), Text(e.key)]))
                  ).toList(),
                  onChanged: (v) => setState(() => selectedCategory = v!),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: targetController,
                        decoration: const InputDecoration(labelText: 'Target'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: unitController,
                        decoration: const InputDecoration(labelText: 'Unit (e.g., books)'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(selectedDate == null ? 'No target date' : 'Target: ${selectedDate!.toString().substring(0, 10)}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().add(const Duration(days: 30)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 3650)),
                      );
                      if (date != null) setState(() => selectedDate = date);
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (titleController.text.isNotEmpty) {
                  ref.read(milestonesProvider.notifier).addMilestone(
                    PersonalMilestone(
                      title: titleController.text,
                      description: descController.text.isEmpty ? null : descController.text,
                      category: selectedCategory,
                      targetValue: int.tryParse(targetController.text) ?? 1,
                      unit: unitController.text.isEmpty ? 'times' : unitController.text,
                      targetDate: selectedDate,
                    ),
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MilestoneListView extends ConsumerWidget {
  final List<PersonalMilestone> milestones;
  final bool isActive;

  const _MilestoneListView({required this.milestones, required this.isActive});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (milestones.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isActive ? Icons.flag : Icons.check_circle, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(isActive ? 'No active milestones' : 'No completed milestones yet'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: milestones.length,
      itemBuilder: (context, index) {
        final milestone = milestones[index];
        final icon = PersonalMilestone.categoryIcons[milestone.category] ?? Icons.star;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: Theme.of(context).primaryColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        milestone.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    if (milestone.targetDate != null)
                      Chip(
                        label: Text(milestone.targetDate!.toString().substring(0, 10)),
                        visualDensity: VisualDensity.compact,
                      ),
                    if (!isActive)
                      const Icon(Icons.check_circle, color: Colors.green),
                  ],
                ),
                if (milestone.description != null) ...[
                  const SizedBox(height: 4),
                  Text(milestone.description!, style: Theme.of(context).textTheme.bodySmall),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${milestone.currentValue} / ${milestone.targetValue} ${milestone.unit}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: milestone.progress,
                            backgroundColor: Colors.grey.shade200,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    if (isActive)
                      IconButton(
                        icon: const Icon(Icons.add_circle),
                        color: Colors.green,
                        onPressed: () {
                          final newValue = milestone.currentValue + 1;
                          ref.read(milestonesProvider.notifier).updateProgress(milestone.id!, newValue);
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Edit'),
                      onPressed: () => _showEditDialog(context, ref, milestone),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.delete, size: 18),
                      label: const Text('Delete'),
                      onPressed: () {
                        ref.read(milestonesProvider.notifier).deleteMilestone(milestone.id!);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, PersonalMilestone milestone) {
    final titleController = TextEditingController(text: milestone.title);
    final descController = TextEditingController(text: milestone.description ?? '');
    final currentController = TextEditingController(text: milestone.currentValue.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Milestone'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Title')),
            const SizedBox(height: 8),
            TextField(controller: descController, decoration: const InputDecoration(labelText: 'Description')),
            const SizedBox(height: 8),
            TextField(
              controller: currentController,
              decoration: InputDecoration(labelText: 'Current Value (${milestone.unit})'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              ref.read(milestonesProvider.notifier).updateMilestone(
                milestone.copyWith(
                  title: titleController.text,
                  description: descController.text.isEmpty ? null : descController.text,
                  currentValue: int.tryParse(currentController.text) ?? milestone.currentValue,
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