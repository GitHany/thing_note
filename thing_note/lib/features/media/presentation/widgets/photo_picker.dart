import 'dart:io';
import 'package:flutter/material.dart';
import 'package:thing_note/features/media/presentation/providers/media_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
  String? _lastInitPathsKey;

  @override
  void initState() {
    super.initState();
    _paths = List.from(widget.initialPaths);
    _lastInitPathsKey = widget.initialPaths.join(',');
  }

  @override
  void didUpdateWidget(covariant PhotoPickerSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newKey = widget.initialPaths.join(',');
    if (newKey != _lastInitPathsKey) {
      _paths = List.from(widget.initialPaths);
      _lastInitPathsKey = newKey;
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final files = await ref.read(mediaServiceProvider).pickPhotosFromGallery();
      if (files.isNotEmpty && mounted) {
        setState(() {
          for (final file in files) {
            _paths.add(file.path);
          }
        });
        widget.onPathsChanged(_paths);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.pickFromGalleryFailed(e.toString()))),
        );
      }
    }
  }

  Future<void> _pickFromCamera() async {
    try {
      final file = await ref.read(mediaServiceProvider).pickPhotoFromCamera();
      if (file != null && mounted) {
        setState(() {
          _paths.add(file.path);
        });
        widget.onPathsChanged(_paths);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.takePhotoFailed(e.toString()))),
        );
      }
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
          AppLocalizations.of(context)!.photos,
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
              return _PhotoThumbnail(
                path: path,
                onRemove: () => _removePhoto(index),
              );
            }),
            _AddPhotoButton(
              icon: Icons.photo_library,
              label: AppLocalizations.of(context)!.gallery,
              onTap: _pickFromGallery,
            ),
            _AddPhotoButton(
              icon: Icons.camera_alt,
              label: AppLocalizations.of(context)!.takePhoto,
              onTap: _pickFromCamera,
            ),
          ],
        ),
      ],
    );
  }
}

class _PhotoThumbnail extends StatelessWidget {
  final String path;
  final VoidCallback onRemove;

  const _PhotoThumbnail({
    required this.path,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        children: [
          Image.file(
            File(path),
            width: 80,
            height: 80,
            fit: BoxFit.cover,
            cacheWidth: 160,
            errorBuilder: (_, __, ___) => Container(
              width: 80,
              height: 80,
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Icon(
                Icons.broken_image,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(4),
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
      ),
    );
  }
}

class _AddPhotoButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _AddPhotoButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
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
              Icon(
                icon,
                size: 24,
                color: Theme.of(context).colorScheme.outline,
              ),
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
      ),
    );
  }
}