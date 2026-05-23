import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/record_version/data/record_version_provider.dart';

class RecordVersionScreen extends ConsumerWidget {
  final int recordId;

  const RecordVersionScreen({super.key, required this.recordId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final versionsAsync = ref.watch(recordVersionsProvider(recordId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Versions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(recordVersionNotifierProvider.notifier).loadVersions(),
          ),
        ],
      ),
      body: versionsAsync.when(
        data: (versions) {
          if (versions.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No versions yet',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Changes will be tracked automatically',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: versions.length,
            itemBuilder: (context, index) {
              final version = versions[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getChangeTypeColor(version.changeType),
                    child: Icon(
                      _getChangeTypeIcon(version.changeType),
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    version.note.isNotEmpty
                        ? (version.note.length > 50 ? '${version.note.substring(0, 50)}...' : version.note)
                        : 'No content',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(version.versionAt),
                        style: const TextStyle(fontSize: 12),
                      ),
                      if (version.changeType == 'updated' && version.changeDetail != null)
                        Text(
                          version.changeDetail!,
                          style: const TextStyle(fontSize: 12, color: Colors.orange),
                        ),
                    ],
                  ),
                  trailing: version.changeType == 'updated'
                      ? TextButton(
                          onPressed: () => _showRestoreDialog(context, ref, version.id!),
                          child: const Text('Restore'),
                        )
                      : null,
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Color _getChangeTypeColor(String changeType) {
    switch (changeType) {
      case 'created':
        return Colors.green;
      case 'updated':
        return Colors.blue;
      case 'restored':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getChangeTypeIcon(String changeType) {
    switch (changeType) {
      case 'created':
        return Icons.add_circle;
      case 'updated':
        return Icons.edit;
      case 'restored':
        return Icons.restore;
      default:
        return Icons.history;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';

    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void _showRestoreDialog(BuildContext context, WidgetRef ref, int versionId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore Version'),
        content: const Text('Are you sure you want to restore this version? Current content will be replaced.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(recordVersionNotifierProvider.notifier).restoreVersion(versionId);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Version restored successfully')),
                );
              }
            },
            child: const Text('Restore'),
          ),
        ],
      ),
    );
  }
}