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

  void _openPhotoPreview(int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _PhotoPreviewPage(
          paths: _paths,
          initialIndex: initialIndex,
          onRemove: (index) {
            _removePhoto(index);
            if (_paths.isEmpty) Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const double itemSize = 88.0;
    const double crossAxisSpacing = 8.0;
    const double mainAxisSpacing = 8.0;
    final int rowCount = (_paths.length / 3).ceil();
    final bool needsScroll = rowCount > 3;
    final double totalHeight = rowCount * itemSize + (rowCount - 1) * mainAxisSpacing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.photos,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _AddPhotoButton(
              icon: Icons.photo_library,
              label: AppLocalizations.of(context)!.gallery,
              onTap: _pickFromGallery,
            ),
            const SizedBox(width: 8),
            _AddPhotoButton(
              icon: Icons.camera_alt,
              label: AppLocalizations.of(context)!.takePhoto,
              onTap: _pickFromCamera,
            ),
          ],
        ),
        if (_paths.isNotEmpty) ...[
          const SizedBox(height: 8),
          SizedBox(
            height: totalHeight,
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: crossAxisSpacing,
                mainAxisSpacing: mainAxisSpacing,
                childAspectRatio: 1,
              ),
              itemCount: _paths.length,
              itemBuilder: (context, index) {
                return _PhotoThumbnail(
                  path: _paths[index],
                  onRemove: () => _removePhoto(index),
                  onTap: () => _openPhotoPreview(index),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

class _PhotoThumbnail extends StatelessWidget {
  final String path;
  final VoidCallback onRemove;
  final VoidCallback? onTap;

  const _PhotoThumbnail({
    required this.path,
    required this.onRemove,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            Image.file(
              File(path),
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              cacheWidth: 160,
              errorBuilder: (_, __, ___) => Container(
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

class _PhotoPreviewPage extends StatefulWidget {
  final List<String> paths;
  final int initialIndex;
  final void Function(int index)? onRemove;

  const _PhotoPreviewPage({
    required this.paths,
    this.initialIndex = 0,
    this.onRemove,
  });

  @override
  State<_PhotoPreviewPage> createState() => _PhotoPreviewPageState();
}

class _PhotoPreviewPageState extends State<_PhotoPreviewPage> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${_currentIndex + 1} / ${widget.paths.length}'),
        actions: [
          if (widget.onRemove != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () {
                widget.onRemove!(_currentIndex);
                if (widget.paths.isEmpty) return;
                setState(() {
                  if (_currentIndex >= widget.paths.length) {
                    _currentIndex = widget.paths.length - 1;
                  }
                });
              },
            ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.paths.length,
        onPageChanged: (index) {
          setState(() => _currentIndex = index);
        },
        itemBuilder: (context, index) {
          return InteractiveViewer(
            child: Center(
              child: Image.file(
                File(widget.paths[index]),
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.broken_image, color: Colors.white54, size: 64),
                    SizedBox(height: 16),
                    Text('图片加载失败', style: TextStyle(color: Colors.white54)),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}