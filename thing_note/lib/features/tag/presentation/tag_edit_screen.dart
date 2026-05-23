import 'package:flutter/material.dart';
import 'package:thing_note/l10n/generated/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:thing_note/features/tag/domain/tag.dart';
import 'package:thing_note/features/tag/presentation/providers/tag_provider.dart';

class TagEditScreen extends ConsumerStatefulWidget {
  final int? tagId;

  const TagEditScreen({super.key, this.tagId});

  @override
  ConsumerState<TagEditScreen> createState() => _TagEditScreenState();
}

class _TagEditScreenState extends ConsumerState<TagEditScreen> {
  late TextEditingController _nameController;
  late Color _selectedColor;
  Tag? _existingTag;

  final List<Color> _colorOptions = [
    const Color(0xFF607D8B), // Blue Grey
    const Color(0xFF2196F3), // Blue
    const Color(0xFF4CAF50), // Green
    const Color(0xFFFF9800), // Orange
    const Color(0xFFF44336), // Red
    const Color(0xFF9C27B0), // Purple
    const Color(0xFF00BCD4), // Cyan
    const Color(0xFFE91E63), // Pink
    const Color(0xFF795548), // Brown
    const Color(0xFF009688), // Teal
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _selectedColor = _colorOptions.first;
    if (widget.tagId != null) {
      _loadTag();
    }
  }

  Future<void> _loadTag() async {
    final repo = await ref.read(tagRepositoryProvider.future);
    final tag = await repo.getTagById(widget.tagId!);
    if (tag != null && mounted) {
      setState(() {
        _existingTag = tag;
        _nameController.text = tag.name;
        _selectedColor = Color(int.parse(tag.color.replaceFirst('#', '0xFF')));
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.tagId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing
            ? AppLocalizations.of(context)!.editTag
            : AppLocalizations.of(context)!.createTag),
        actions: [
          TextButton(
            onPressed: _saveTag,
            child: Text(AppLocalizations.of(context)!.save),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.tagName,
                border: const OutlineInputBorder(),
              ),
              autofocus: true,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 24),
            Text(
              AppLocalizations.of(context)!.selectColor,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _colorOptions.map((color) {
                final isSelected = _selectedColor.value == color.value;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = color),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: Colors.white, width: 3)
                          : null,
                      boxShadow: isSelected
                          ? [
                              BoxShadow(color: color.withOpacity(0.5), blurRadius: 8, spreadRadius: 2)
                            ]
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            // Preview
            Center(
              child: Column(
                children: [
                  Text(
                    AppLocalizations.of(context)!.preview,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  Chip(
                    avatar: CircleAvatar(
                      backgroundColor: _selectedColor,
                      child: Text(
                        _nameController.text.isEmpty ? 'T' : _nameController.text[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                    label: Text(_nameController.text.isEmpty ? 'Tag Name' : _nameController.text),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveTag() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.tagNameRequired)),
      );
      return;
    }

    final repo = await ref.read(tagRepositoryProvider.future);
    final tag = Tag(
      id: widget.tagId,
      name: _nameController.text.trim(),
      color: _colorToHex(_selectedColor),
      createdAt: _existingTag?.createdAt ?? DateTime.now(),
    );

    if (widget.tagId != null) {
      await repo.updateTag(tag);
    } else {
      await repo.createTag(tag);
    }

    ref.invalidate(tagListProvider);

    if (mounted) {
      context.pop();
    }
  }
}