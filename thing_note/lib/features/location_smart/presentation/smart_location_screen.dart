import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/location_smart/data/smart_location_provider.dart';
import 'package:thing_note/features/location_smart/domain/smart_location.dart';

class SmartLocationScreen extends ConsumerWidget {
  const SmartLocationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationsAsync = ref.watch(smartLocationNotifierProvider);
    final topLocationsAsync = ref.watch(topSmartLocationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Locations'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(smartLocationNotifierProvider.notifier).loadLocations(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Top locations header
          topLocationsAsync.when(
            data: (topLocations) {
              if (topLocations.isEmpty) return const SizedBox.shrink();

              return Container(
                padding: const EdgeInsets.all(16),
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Most Visited',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 80,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: topLocations.take(5).length,
                        itemBuilder: (context, index) {
                          final location = topLocations[index];
                          return Container(
                            width: 80,
                            margin: const EdgeInsets.only(right: 12),
                            child: Column(
                              children: [
                                Text(
                                  location.icon,
                                  style: const TextStyle(fontSize: 24),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  location.name,
                                  style: const TextStyle(fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                                Text(
                                  '${location.visitCount} visits',
                                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // All locations list
          Expanded(
            child: locationsAsync.when(
              data: (locations) {
                if (locations.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.location_off, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No saved locations', style: TextStyle(fontSize: 16, color: Colors.grey)),
                        SizedBox(height: 8),
                        Text(
                          'Locations from records will appear here',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: locations.length,
                  itemBuilder: (context, index) {
                    final location = locations[index];
                    return _buildLocationCard(context, ref, location);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error: $error')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddLocationDialog(context, ref),
        child: const Icon(Icons.add_location),
      ),
    );
  }

  Widget _buildLocationCard(BuildContext context, WidgetRef ref, SmartLocation location) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Color(int.parse(location.color.replaceFirst('#', '0xFF'))),
          child: Text(location.icon, style: const TextStyle(fontSize: 20)),
        ),
        title: Text(location.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (location.alias != null)
              Text('aka ${location.alias}', style: const TextStyle(fontSize: 12)),
            Text(
              '${location.visitCount} visits • avg ${location.averageVisitMinutes.toStringAsFixed(0)}min',
              style: const TextStyle(fontSize: 12),
            ),
            if (location.lastVisitedAt != null)
              Text(
                'Last: ${_formatDate(location.lastVisitedAt!)}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (location.isFavorite)
              const Icon(Icons.star, color: Colors.amber, size: 20),
            PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'favorite', child: Text('Toggle Favorite')),
                const PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
              onSelected: (value) {
                if (value == 'favorite') {
                  ref.read(smartLocationNotifierProvider.notifier).toggleFavorite(location.id!);
                } else if (value == 'delete') {
                  ref.read(smartLocationNotifierProvider.notifier).deleteLocation(location.id!);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddLocationDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final aliasController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Location'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'e.g., Home, Office',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: aliasController,
              decoration: const InputDecoration(
                labelText: 'Alias (optional)',
                hintText: 'e.g., My home',
                border: OutlineInputBorder(),
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
                // Add location logic
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Location added')),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.month}/${date.day}';
  }
}