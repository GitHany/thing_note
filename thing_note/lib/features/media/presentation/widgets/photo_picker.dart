import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:thing_note/features/media/presentation/providers/media_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

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
    const double itemSize = 100.0;
    const double crossAxisSpacing = 8.0;
    const double mainAxisSpacing = 8.0;
    final int rowCount = (_paths.length / 3).ceil();
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
            _AddMediaButton(
              icon: Icons.photo_library,
              label: AppLocalizations.of(context)!.gallery,
              onTap: _pickFromGallery,
            ),
            const SizedBox(width: 8),
            _AddMediaButton(
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

class VideoPickerSection extends ConsumerStatefulWidget {
  final List<String> initialPaths;
  final ValueChanged<List<String>> onPathsChanged;

  const VideoPickerSection({
    super.key,
    this.initialPaths = const [],
    required this.onPathsChanged,
  });

  @override
  ConsumerState<VideoPickerSection> createState() => _VideoPickerSectionState();
}

class _VideoPickerSectionState extends ConsumerState<VideoPickerSection> {
  late List<String> _paths;
  String? _lastInitPathsKey;

  @override
  void initState() {
    super.initState();
    _paths = List.from(widget.initialPaths);
    _lastInitPathsKey = widget.initialPaths.join(',');
  }

  @override
  void didUpdateWidget(covariant VideoPickerSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newKey = widget.initialPaths.join(',');
    if (newKey != _lastInitPathsKey) {
      _paths = List.from(widget.initialPaths);
      _lastInitPathsKey = newKey;
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final files = await ref.read(mediaServiceProvider).pickVideosFromGallery();
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
          SnackBar(content: Text(AppLocalizations.of(context)!.pickVideoFailed(e.toString()))),
        );
      }
    }
  }

  void _removeVideo(int index) {
    setState(() {
      _paths.removeAt(index);
    });
    widget.onPathsChanged(_paths);
  }

  @override
  Widget build(BuildContext context) {
    const double itemSize = 88.0;
    const double crossAxisSpacing = 8.0;
    const double mainAxisSpacing = 8.0;
    final int rowCount = (_paths.length / 3).ceil();
    final double totalHeight = rowCount * itemSize + (rowCount - 1) * mainAxisSpacing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.videos,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _AddMediaButton(
              icon: Icons.video_library,
              label: AppLocalizations.of(context)!.selectVideo,
              onTap: _pickFromGallery,
            ),
          ],
        ),
        if (_paths.isNotEmpty) ...[
          const SizedBox(height: 8),
          SizedBox(
            height: totalHeight,
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: crossAxisSpacing,
                mainAxisSpacing: mainAxisSpacing,
                childAspectRatio: 1,
              ),
              itemCount: _paths.length,
              itemBuilder: (context, index) {
                return _VideoThumbnail(
                  path: _paths[index],
                  onRemove: () => _removeVideo(index),
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

class _VideoThumbnail extends StatelessWidget {
  final String path;
  final VoidCallback onRemove;

  const _VideoThumbnail({
    required this.path,
    required this.onRemove,
  });

  Future<void> _openVideoPlayer(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _VideoPlayerPage(videoPath: path),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openVideoPlayer(context),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _VideoThumbnailImage(videoPath: path),
            ),
            Center(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow,
                  size: 24,
                  color: Colors.white,
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

class _VideoThumbnailImage extends StatefulWidget {
  final String videoPath;

  const _VideoThumbnailImage({required this.videoPath});

  @override
  State<_VideoThumbnailImage> createState() => _VideoThumbnailImageState();
}

class _VideoThumbnailImageState extends State<_VideoThumbnailImage> {
  Uint8List? _thumbnailBytes;

  @override
  void initState() {
    super.initState();
    _loadThumbnail();
  }

  Future<void> _loadThumbnail() async {
    try {
      final thumbnail = await VideoThumbnail.thumbnailData(
        video: widget.videoPath,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 160,
        quality: 75,
      );
      if (mounted) {
        setState(() {
          _thumbnailBytes = thumbnail;
        });
      }
    } catch (e) {
      // 缩略图加载失败，使用默认图标
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_thumbnailBytes != null) {
      return Image.memory(
        _thumbnailBytes!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.video_library,
        size: 32,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

class _VideoPlayerPage extends StatefulWidget {
  final String videoPath;

  const _VideoPlayerPage({required this.videoPath});

  @override
  State<_VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<_VideoPlayerPage> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _isLandscape = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.videoPath))
      ..initialize().then((_) {
        if (mounted) {
          final aspectRatio = _controller.value.aspectRatio;
          _isLandscape = aspectRatio > 1.0;
          if (_isLandscape) {
            SystemChrome.setPreferredOrientations([
              DeviceOrientation.landscapeLeft,
              DeviceOrientation.landscapeRight,
            ]);
          }
          setState(() {
            _isInitialized = true;
          });
          _controller.play();
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _isLandscape
          ? null
          : AppBar(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
            ),
      body: Center(
        child: _isInitialized
            ? GestureDetector(
                onTap: () {
                  setState(() {
                    _controller.value.isPlaying
                        ? _controller.pause()
                        : _controller.play();
                  });
                },
                child: AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: VideoPlayer(_controller),
                ),
              )
            : const CircularProgressIndicator(),
      ),
      floatingActionButton: _isInitialized
          ? FloatingActionButton(
              onPressed: () {
                setState(() {
                  _controller.value.isPlaying
                      ? _controller.pause()
                      : _controller.play();
                });
              },
              child: Icon(
                _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
              ),
            )
          : null,
    );
  }
}

class _AddMediaButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _AddMediaButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
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
              color: colorScheme.outline.withOpacity(0.3),
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 24,
                color: colorScheme.onSurface,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurface,
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
