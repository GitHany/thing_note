import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/smart_sort/data/smart_sort_service.dart';
import 'package:thing_note/features/smart_sort/domain/sort_config.dart';

final sortConfigProvider = StateProvider<SortConfig>((ref) => SortConfig());
final groupConfigProvider = StateProvider<GroupConfig>((ref) => GroupConfig());

class SmartSortScreen extends ConsumerWidget {
  const SmartSortScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sortConfig = ref.watch(sortConfigProvider);
    final groupConfig = ref.watch(groupConfigProvider);
    final service = ref.read(smartSortServiceProvider);
    final suggestions = service.getSortSuggestions();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Sort'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Current sort
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Sort',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Chip(label: Text(_getFieldLabel(sortConfig.field))),
                      const SizedBox(width: 8),
                      Chip(label: Text(_getOrderLabel(sortConfig.order))),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Sort by
          Text(
            'Sort By',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: SortField.values.map((field) {
              return ChoiceChip(
                label: Text(_getFieldLabel(field)),
                selected: sortConfig.field == field,
                onSelected: (selected) {
                  if (selected) {
                    ref.read(sortConfigProvider.notifier).state =
                        sortConfig.copyWith(field: field);
                  }
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Order
          Text(
            'Order',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          SegmentedButton<SortOrder>(
            segments: const [
              ButtonSegment(
                value: SortOrder.ascending,
                label: Text('Ascending'),
                icon: Icon(Icons.arrow_upward),
              ),
              ButtonSegment(
                value: SortOrder.descending,
                label: Text('Descending'),
                icon: Icon(Icons.arrow_downward),
              ),
            ],
            selected: {sortConfig.order},
            onSelectionChanged: (selected) {
              ref.read(sortConfigProvider.notifier).state =
                  sortConfig.copyWith(order: selected.first);
            },
          ),
          const SizedBox(height: 24),

          // Group by
          Text(
            'Group By',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: GroupField.values.map((field) {
              return ChoiceChip(
                label: Text(_getGroupLabel(field)),
                selected: groupConfig.field == field,
                onSelected: (selected) {
                  ref.read(groupConfigProvider.notifier).state =
                      GroupConfig(field: field, enabled: selected);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Suggestions
          Text(
            'Quick Sort Suggestions',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ...suggestions.map((s) => Card(
                child: ListTile(
                  title: Text(s.title),
                  subtitle: Text(s.description),
                  trailing: IconButton(
                    icon: const Icon(Icons.play_arrow),
                    onPressed: () {
                      ref.read(sortConfigProvider.notifier).state = s.config;
                    },
                  ),
                ),
              )),
        ],
      ),
    );
  }

  String _getFieldLabel(SortField field) {
    switch (field) {
      case SortField.occurredAt:
        return 'Date';
      case SortField.createdAt:
        return 'Created';
      case SortField.duration:
        return 'Duration';
      case SortField.thingName:
        return 'Category';
      case SortField.tagCount:
        return 'Tags';
    }
  }

  String _getOrderLabel(SortOrder order) {
    return order == SortOrder.ascending ? '↑ Ascending' : '↓ Descending';
  }

  String _getGroupLabel(GroupField field) {
    switch (field) {
      case GroupField.date:
        return 'Date';
      case GroupField.thingName:
        return 'Category';
      case GroupField.tag:
        return 'Tag';
      case GroupField.location:
        return 'Location';
      case GroupField.none:
        return 'None';
    }
  }
}