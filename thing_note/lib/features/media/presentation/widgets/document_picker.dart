import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class DocumentPickerSection extends StatefulWidget {
  final List<String> initialPaths;
  final ValueChanged<List<String>> onPathsChanged;

  const DocumentPickerSection({
    super.key,
    this.initialPaths = const [],
    required this.onPathsChanged,
  });

  @override
  State<DocumentPickerSection> createState() => _DocumentPickerSectionState();
}

class _DocumentPickerSectionState extends State<DocumentPickerSection> {
  late List<String> _paths;
  String? _lastInitPathsKey;
  bool _isExpanded = true;

  @override
  void initState() {
    super.initState();
    _paths = List.from(widget.initialPaths);
    _lastInitPathsKey = widget.initialPaths.join(',');
    _isExpanded = _paths.isNotEmpty;
  }

  @override
  void didUpdateWidget(covariant DocumentPickerSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newKey = widget.initialPaths.join(',');
    if (newKey != _lastInitPathsKey) {
      _paths = List.from(widget.initialPaths);
      _lastInitPathsKey = newKey;
    }
  }

  Future<void> _showTypeSelector() async {
    final result = await showDialog<_DocumentType?>(
      context: context,
      barrierColor: Colors.black54,
      builder: (dialogContext) {
        return Dialog.fullscreen(
          child: Scaffold(
            appBar: AppBar(
              title: Text(AppLocalizations.of(dialogContext)!.selectDocumentType),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(dialogContext),
              ),
            ),
            body: ListView(
              children: [
                _DocumentTypeListTile(
                  icon: Icons.description,
                  title: AppLocalizations.of(dialogContext)!.wordDocument,
                  extensions: '.doc, .docx',
                  onTap: () => Navigator.pop(dialogContext, _DocumentType.word),
                ),
                _DocumentTypeListTile(
                  icon: Icons.table_chart,
                  title: AppLocalizations.of(dialogContext)!.excelDocument,
                  extensions: '.xls, .xlsx, .csv',
                  onTap: () => Navigator.pop(dialogContext, _DocumentType.excel),
                ),
                _DocumentTypeListTile(
                  icon: Icons.slideshow,
                  title: AppLocalizations.of(dialogContext)!.pptDocument,
                  extensions: '.ppt, .pptx',
                  onTap: () => Navigator.pop(dialogContext, _DocumentType.ppt),
                ),
                _DocumentTypeListTile(
                  icon: Icons.picture_as_pdf,
                  title: AppLocalizations.of(dialogContext)!.pdfDocument,
                  extensions: '.pdf',
                  onTap: () => Navigator.pop(dialogContext, _DocumentType.pdf),
                ),
                _DocumentTypeListTile(
                  icon: Icons.code,
                  title: AppLocalizations.of(dialogContext)!.markdownDocument,
                  extensions: '.md',
                  onTap: () => Navigator.pop(dialogContext, _DocumentType.markdown),
                ),
                _DocumentTypeListTile(
                  icon: Icons.text_snippet,
                  title: AppLocalizations.of(dialogContext)!.textDocument,
                  extensions: '.txt, .rtf, .html',
                  onTap: () => Navigator.pop(dialogContext, _DocumentType.text),
                ),
                _DocumentTypeListTile(
                  icon: Icons.folder,
                  title: AppLocalizations.of(dialogContext)!.otherDocument,
                  extensions: '.odt, .ods, .odp, .pages, .numbers, .key, .epub',
                  onTap: () => Navigator.pop(dialogContext, _DocumentType.other),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (result != null && mounted) {
      await _pickDocument(result);
    }
  }

  Future<void> _pickDocument(_DocumentType type) async {
    try {
      final extensions = type.extensions;
      final result = await FilePicker.platform.pickFiles(
        type: FilePicker.custom,
        allowedExtensions: extensions.map((e) => e.replaceFirst('.', '')).toList(),
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty && mounted) {
        setState(() {
          for (final file in result.files) {
            if (file.path != null && !_paths.contains(file.path)) {
              _paths.add(file.path!);
            }
          }
        });
        widget.onPathsChanged(_paths);
        setState(() => _isExpanded = true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.pickDocumentFailed(e.toString()))),
        );
      }
    }
  }

  void _removeDocument(int index) {
    setState(() {
      _paths.removeAt(index);
      if (_paths.isEmpty) {
        _isExpanded = false;
      }
    });
    widget.onPathsChanged(_paths);
  }

  String _getFileName(String path) {
    return path.split('/').last.split('\\').last;
  }

  Future<String> _getFileSizeString(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        final bytes = await file.length();
        return _formatFileSize(bytes);
      }
    } catch (_) {}
    return '';
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            setState(() => _isExpanded = !_isExpanded);
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Icon(
                  Icons.attach_file,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.documents,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                ),
                Icon(
                  _isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
          ),
        ),
        if (_isExpanded) ...[
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_paths.isEmpty)
                  InkWell(
                    onTap: _showTypeSelector,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add,
                            size: 18,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            AppLocalizations.of(context)!.addDocument,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else ...[
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _paths.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      return _DocumentItem(
                        path: _paths[index],
                        fileName: _getFileName(_paths[index]),
                        getFileSize: () => _getFileSizeString(_paths[index]),
                        onRemove: () => _removeDocument(index),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  InkWell(
                    onTap: _showTypeSelector,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add,
                            size: 18,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            AppLocalizations.of(context)!.addMoreDocuments,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

enum _DocumentType {
  word(['.doc', '.docx']),
  excel(['.xls', '.xlsx', '.csv']),
  ppt(['.ppt', '.pptx']),
  pdf(['.pdf']),
  markdown(['.md']),
  text(['.txt', '.rtf', '.html']),
  other(['.odt', '.ods', '.odp', '.pages', '.numbers', '.key', '.epub']);

  final List<String> extensions;
  const _DocumentType(this.extensions);
}

class _DocumentTypeListTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String extensions;
  final VoidCallback onTap;

  const _DocumentTypeListTile({
    required this.icon,
    required this.title,
    required this.extensions,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(
        extensions,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class _DocumentItem extends StatefulWidget {
  final String path;
  final String fileName;
  final Future<String> Function() getFileSize;
  final VoidCallback onRemove;

  const _DocumentItem({
    required this.path,
    required this.fileName,
    required this.getFileSize,
    required this.onRemove,
  });

  @override
  State<_DocumentItem> createState() => _DocumentItemState();
}

class _DocumentItemState extends State<_DocumentItem> {
  String _fileSize = '';

  @override
  void initState() {
    super.initState();
    _loadFileSize();
  }

  Future<void> _loadFileSize() async {
    final size = await widget.getFileSize();
    if (mounted) {
      setState(() => _fileSize = size);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Icon(
            Icons.attach_file,
            size: 20,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.fileName,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (_fileSize.isNotEmpty) ...[
            const SizedBox(width: 8),
            Text(
              _fileSize,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ],
          IconButton(
            icon: Icon(
              Icons.close,
              size: 18,
              color: Theme.of(context).colorScheme.error,
            ),
            onPressed: widget.onRemove,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
          ),
        ],
      ),
    );
  }
}
