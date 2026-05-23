import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/file_manager/data/file_manager_service.dart';
import 'package:thing_note/features/file_manager/domain/file_manager_entry.dart';

class FileManagerScreen extends ConsumerStatefulWidget {
  const FileManagerScreen({super.key});

  @override
  ConsumerState<FileManagerScreen> createState() => _FileManagerScreenState();
}

class _FileManagerScreenState extends ConsumerState<FileManagerScreen> {
  List<FileManagerEntry> _entries = [];
  bool _isLoading = false;
  String? _currentPath;

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    setState(() => _isLoading = true);

    try {
      final service = ref.read(fileManagerServiceProvider);
      if (_currentPath == null) {
        final appDir = await service.getAppDirectory();
        _currentPath = appDir.path;
      }
      final entries = await service.listFiles(_currentPath!);
      setState(() => _entries = entries);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteFile(FileManagerEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${entry.name}?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final service = ref.read(fileManagerServiceProvider);
      final success = entry.isDirectory
          ? await service.deleteDirectory(entry.path)
          : await service.deleteFile(entry.path);

      if (success) {
        _loadFiles();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('File Manager'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFiles,
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'clear_temp') {
                final service = ref.read(fileManagerServiceProvider);
                final count = await service.clearTempFiles();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Deleted $count temporary files')),
                  );
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear_temp',
                child: ListTile(
                  leading: Icon(Icons.cleaning_services),
                  title: Text('Clear Temp Files'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Breadcrumb
                if (_currentPath != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: Row(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Text(
                              _currentPath!,
                              style: Theme.of(context).textTheme.bodySmall,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: _entries.isEmpty
                      ? const Center(child: Text('No files'))
                      : ListView.builder(
                          itemCount: _entries.length,
                          itemBuilder: (context, index) {
                            final entry = _entries[index];
                            return ListTile(
                              leading: Icon(
                                entry.isDirectory
                                    ? Icons.folder
                                    : Icons.insert_drive_file,
                              ),
                              title: Text(entry.name),
                              subtitle: Text(entry.formattedSize),
                              trailing: PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'delete') {
                                    _deleteFile(entry);
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: ListTile(
                                      leading: Icon(Icons.delete, color: Colors.red),
                                      title: Text('Delete'),
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                ],
                              ),
                              onTap: entry.isDirectory
                                  ? () {
                                      setState(() {
                                        _currentPath = entry.path;
                                      });
                                      _loadFiles();
                                    }
                                  : null,
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}