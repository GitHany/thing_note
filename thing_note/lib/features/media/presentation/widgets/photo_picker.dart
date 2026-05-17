import 'dart:io';
import 'package:flutter/material.dart';
import 'package:thing_note/features/media/presentation/providers/media_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PhotoPickerSection extends ConsumerStatefulWidget {
  final List<String> initialPaths;
  final ValueChanged<List<String>> onPathsChanged;

  const PhotoPickerSection({
    super.key,
    this.initialPaths = const [],
    required this.onPathsChanged,
  });

  @override
  ConsumerState<PhotoPickerSection> createState() => _PhotoPickerSectionState();
}

class _PhotoPickerSectionState extends ConsumerState<PhotoPickerSection> {
  late List<String> _paths;

  @override
  void initState() {
    super.initState();
    _paths = List.from(widget.initialPaths);
  }

  Future<void> _pickFromGallery() async {
    final files = await ref.read(mediaServiceProvider).pickPhotosFromGallery();
    if (files.isNotEmpty) {
      setState(() {
        for (final file in files) {
          _paths.add(file.path);
        }
      });
      widget.onPathsChanged(_paths);
    }
  }

  Future<void> _pickFromCamera() async {
    final file = await ref.read(mediaServiceProvider).pickPhotoFromCamera();
    if (file != null) {
      setState(() {
        _paths.add(file.path);
      });
      widget.onPathsChanged(_paths);
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _paths.removeAt(index);
    });
    widget.onPathsChanged(_paths);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '照片',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ..._paths.asMap().entries.map((entry) {
              final index = entry.key;
              final path = entry.value;
              return Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(path),
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 80,
                        height: 80,
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        child: const Icon(Icons.broken_image),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () => _removePhoto(index),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.error,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }),
            ...[
              _buildAddButton(context, Icons.photo_library, '相册', _pickFromGallery),
              _buildAddButton(context, Icons.camera_alt, '拍照', _pickFromCamera),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildAddButton(
      BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
