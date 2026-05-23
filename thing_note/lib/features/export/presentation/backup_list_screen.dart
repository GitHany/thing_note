import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/l10n/generated/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';
import 'package:thing_note/features/export/presentation/providers/export_import_provider.dart';
import 'package:archive/archive.dart';

class BackupListScreen extends ConsumerStatefulWidget {
  const BackupListScreen({super.key});

  @override
  ConsumerState<BackupListScreen> createState() => _BackupListScreenState();
}

class _BackupListScreenState extends ConsumerState<BackupListScreen> {
  final Set<String> _selectedPaths = {};
  bool _isMultiSelectMode = false;

  Future<List<Map<String, dynamic>>> _getZipContents(String zipPath) async {
    try {
      final bytes = await File(zipPath).readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      final contents = <Map<String, dynamic>>[];
      for (final file in archive) {
        contents.add({
          'name': file.name,
          'isFile': file.isFile,
          'size': file.size,
        });
      }
      return contents;
    } catch (e) {
      return [];
    }
  }

  Future<void> _previewZipFile(BuildContext context, File file) async {
    final contents = await _getZipContents(file.path);
    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) => Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.archive),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.basename(file.path),
                          style: Theme.of(ctx).textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${contents.length} items',
                          style: Theme.of(ctx).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.share),
                    onPressed: () {
                      Navigator.pop(ctx);
                      Share.shareXFiles([XFile(file.path)], text: AppLocalizations.of(context)!.shareBackup(1));
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: contents.isEmpty
                  ? Center(
                      child: Text(
                        AppLocalizations.of(context)!.loadFailed('Failed to read archive'),
                        style: TextStyle(color: Theme.of(ctx).colorScheme.error),
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: contents.length,
                      itemBuilder: (_, index) {
                        final item = contents[index];
                        final icon = item['isFile'] ? Icons.insert_drive_file : Icons.folder;
                        final sizeStr = item['isFile'] ? _formatFileSize(item['size']) : '';
                        return ListTile(
                          leading: Icon(icon),
                          title: Text(
                            item['name'],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: sizeStr.isNotEmpty ? Text(sizeStr, style: Theme.of(ctx).textTheme.bodySmall) : null,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleSelect(String path) {
    setState(() {
      if (_selectedPaths.contains(path)) {
        _selectedPaths.remove(path);
      } else {
        _selectedPaths.add(path);
      }
      if (_selectedPaths.isEmpty) {
        _isMultiSelectMode = false;
      }
    });
  }

  void _selectAll(List<FileSystemEntity> files) {
    setState(() {
      if (_selectedPaths.length == files.length) {
        _selectedPaths.clear();
        _isMultiSelectMode = false;
      } else {
        _selectedPaths.addAll(files.map((f) => f.path));
      }
    });
  }

  Future<void> _deleteSelected() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(ctx)!.confirmDelete),
        content: Text(AppLocalizations.of(ctx)!.confirmDeleteBackup(_selectedPaths.length)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocalizations.of(ctx)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              AppLocalizations.of(ctx)!.delete,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await deleteBackupZips(_selectedPaths.toList());
        if (mounted) {
          setState(() {
            _isMultiSelectMode = false;
            _selectedPaths.clear();
          });
          ref.invalidate(backupZipListProvider);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.backupDeleted)),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.backupDeleteFailed(e.toString()))),
          );
        }
      }
    }
  }

  Future<void> _shareSelected() async {
    try {
      final xFiles = _selectedPaths.map((path) => XFile(path)).toList();
      await Share.shareXFiles(xFiles, text: AppLocalizations.of(context)!.shareBackup(_selectedPaths.length));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.shareFailed(e.toString()))),
        );
      }
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final backupListAsync = ref.watch(backupZipListProvider);

    return PopScope(
      canPop: !_isMultiSelectMode,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        setState(() {
          _isMultiSelectMode = false;
          _selectedPaths.clear();
        });
      },
      child: Scaffold(
        appBar: AppBar(
          title: _isMultiSelectMode
              ? Text(AppLocalizations.of(context)!.selectedCount(_selectedPaths.length))
              : Text(AppLocalizations.of(context)!.backupList),
          leading: _isMultiSelectMode
              ? IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      _isMultiSelectMode = false;
                      _selectedPaths.clear();
                    });
                  },
                )
              : null,
          actions: _isMultiSelectMode
              ? [
                  backupListAsync.when(
                    data: (files) => IconButton(
                      icon: Icon(
                        _selectedPaths.length == files.length
                            ? Icons.check_box
                            : Icons.check_box_outline_blank,
                      ),
                      onPressed: () => _selectAll(files),
                      tooltip: AppLocalizations.of(context)!.selectAll,
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.share),
                    onPressed: _selectedPaths.isEmpty ? null : _shareSelected,
                    tooltip: AppLocalizations.of(context)!.share,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: _selectedPaths.isEmpty ? null : _deleteSelected,
                    tooltip: AppLocalizations.of(context)!.delete,
                  ),
                ]
              : null,
        ),
        body: backupListAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text(err.toString())),
          data: (files) {
            if (files.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.folder_open,
                      size: 80,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context)!.noBackupZips,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context)!.noBackupZipsDesc,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              itemCount: files.length,
              itemBuilder: (context, index) {
                final file = files[index] as File;
                final isSelected = _selectedPaths.contains(file.path);
                final stat = file.statSync();
                final fileName = p.basename(file.path);

                return InkWell(
                  onTap: _isMultiSelectMode
                      ? () => _toggleSelect(file.path)
                      : () => _previewZipFile(context, file),
                  onLongPress: _isMultiSelectMode
                      ? null
                      : () {
                          setState(() {
                            _isMultiSelectMode = true;
                            _selectedPaths.add(file.path);
                          });
                        },
                  child: Container(
                    color: isSelected ? Theme.of(context).colorScheme.primaryContainer : null,
                    child: ListTile(
                      leading: _isMultiSelectMode
                          ? Icon(
                              isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                              color: Theme.of(context).colorScheme.primary,
                            )
                          : const Icon(Icons.archive),
                      title: Text(
                        fileName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '${_formatFileSize(stat.size)}  ·  ${DateFormat('yyyy-MM-dd HH:mm').format(stat.modified)}',
                      ),
                      trailing: _isMultiSelectMode
                          ? null
                          : Icon(
                              Icons.expand_more,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
