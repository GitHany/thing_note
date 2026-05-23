import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:thing_note/features/media/presentation/providers/media_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/l10n/generated/app_localizations.dart';
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
    final screenWidth = MediaQuery.of(context).size.width;
    // 更灵活的响应式网格：超小屏更紧凑，大屏更宽松
    final crossAxisCount = screenWidth < 360 ? 2 : (screenWidth > 800 ? 6 : (screenWidth > 600 ? 4 : 3));
    final itemSize = screenWidth < 360 ? 88.0 : (screenWidth > 800 ? 130.0 : (screenWidth > 600 ? 110.0 : 100.0));
    final crossAxisSpacing = screenWidth < 360 ? 6.0 : (screenWidth > 600 ? 14.0 : 10.0);
    final mainAxisSpacing = screenWidth < 360 ? 6.0 : (screenWidth > 600 ? 14.0 : 10.0);
    final int rowCount = (_paths.length / crossAxisCount).ceil();
    final double totalHeight = rowCount * itemSize + (rowCount > 1 ? (rowCount - 1) * mainAxisSpacing : 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.photos,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _AddMediaButton(
              icon: Icons.photo_library,
              label: AppLocalizations.of(context)!.gallery,
              onTap: _pickFromGallery,
            ),
            const SizedBox(width: 12),
            _AddMediaButton(
              icon: Icons.camera_alt,
              label: AppLocalizations.of(context)!.takePhoto,
              onTap: _pickFromCamera,
            ),
          ],
        ),
        if (_paths.isNotEmpty) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: totalHeight,
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
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
    final screenWidth = MediaQuery.of(context).size.width;
    // 更灵活的响应式视频网格
    final crossAxisCount = screenWidth < 360 ? 2 : (screenWidth > 800 ? 6 : (screenWidth > 600 ? 4 : 3));
    final itemSize = screenWidth < 360 ? 80.0 : (screenWidth > 800 ? 120.0 : (screenWidth > 600 ? 105.0 : 90.0));
    final crossAxisSpacing = screenWidth < 360 ? 6.0 : (screenWidth > 600 ? 12.0 : 10.0);
    final mainAxisSpacing = screenWidth < 360 ? 6.0 : (screenWidth > 600 ? 12.0 : 10.0);
    final int rowCount = (_paths.length / crossAxisCount).ceil();
    final double totalHeight = rowCount * itemSize + (rowCount > 1 ? (rowCount - 1) * mainAxisSpacing : 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.videos,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 10),
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
          const SizedBox(height: 12),
          SizedBox(
            height: totalHeight,
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final borderRadius = isSmallScreen ? 8.0 : 12.0;
    final removeButtonPadding = isSmallScreen ? 4.0 : 6.0;
    final removeIconSize = isSmallScreen ? 12.0 : 16.0;
    
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
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
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: onRemove,
                child: Container(
                  padding: EdgeInsets.all(removeButtonPadding),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.error,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close,
                    size: removeIconSize,
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final borderRadius = isSmallScreen ? 8.0 : 12.0;
    final playIconPadding = isSmallScreen ? 8.0 : 12.0;
    final playIconSize = isSmallScreen ? 24.0 : 30.0;
    final removeButtonPadding = isSmallScreen ? 4.0 : 6.0;
    final removeIconSize = isSmallScreen ? 12.0 : 16.0;
    
    return GestureDetector(
      onTap: () => _openVideoPlayer(context),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(borderRadius),
              child: _VideoThumbnailImage(videoPath: path),
            ),
            Center(
              child: Container(
                padding: EdgeInsets.all(playIconPadding),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.play_arrow,
                  size: playIconSize,
                  color: Colors.white,
                ),
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: onRemove,
                child: Container(
                  padding: EdgeInsets.all(removeButtonPadding),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.error,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close,
                    size: removeIconSize,
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
    final screenWidth = MediaQuery.of(context).size.width;
    // 更灵活的响应式按钮尺寸
    final buttonSize = screenWidth < 360 ? 80.0 : (screenWidth > 600 ? 110.0 : 96.0);
    final iconSize = screenWidth < 360 ? 26.0 : (screenWidth > 600 ? 34.0 : 30.0);
    final fontSize = screenWidth < 360 ? 11.0 : 13.0;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: buttonSize,
          height: buttonSize,
          decoration: BoxDecoration(
            border: Border.all(
              color: colorScheme.outline.withOpacity(0.4),
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: iconSize,
                color: colorScheme.onSurface,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontSize: fontSize,
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
  bool _isAnnotating = false;
  final List<AnnotationElement> _annotations = [];
  AnnotationTool _selectedTool = AnnotationTool.pen;
  Color _selectedColor = Colors.red;
  double _strokeWidth = 3.0;

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

  void _toggleAnnotationMode() {
    setState(() {
      _isAnnotating = !_isAnnotating;
      if (!_isAnnotating) {
        _annotations.clear();
      }
    });
  }

  void _saveAnnotations() {
    if (_annotations.isEmpty) {
      _toggleAnnotationMode();
      return;
    }

    _encodeAnnotations();
    _toggleAnnotationMode();

    // Save feedback toast
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('标注已保存'),
        duration: Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _encodeAnnotations() {
    final elements = _annotations.map((e) => {
      'type': e.type.name,
      'color': e.color.value,
      'strokeWidth': e.strokeWidth,
      'points': e.points.map((p) => {'x': p.dx, 'y': p.dy}).toList(),
      'text': e.text,
      'rect': e.rect != null ? {'left': e.rect!.left, 'top': e.rect!.top, 'right': e.rect!.right, 'bottom': e.rect!.bottom} : null,
    }).toList();

    return '{"version":1,"elements":$elements}';
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
          IconButton(
            icon: Icon(_isAnnotating ? Icons.check : Icons.edit),
            tooltip: _isAnnotating ? '保存标注' : '添加标注',
            onPressed: _isAnnotating ? _saveAnnotations : _toggleAnnotationMode,
          ),
          if (widget.onRemove != null && !_isAnnotating)
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
      body: Stack(
        children: [
          PageView.builder(
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
          // Annotation overlay
          if (_isAnnotating) ...[
            // Tool bar
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.black87,
                padding: const EdgeInsets.all(12),
                child: SafeArea(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildToolButton(AnnotationTool.pen, Icons.edit),
                      _buildToolButton(AnnotationTool.arrow, Icons.arrow_forward),
                      _buildToolButton(AnnotationTool.rect, Icons.crop_square),
                      _buildToolButton(AnnotationTool.text, Icons.text_fields),
                      _buildColorButton(),
                      _buildStrokeWidthSlider(),
                      IconButton(
                        icon: const Icon(Icons.undo, color: Colors.white),
                        onPressed: _annotations.isNotEmpty
                            ? () => setState(() => _annotations.removeLast())
                            : null,
                      ),
                      IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white),
                        onPressed: _annotations.isNotEmpty
                            ? () => setState(() => _annotations.clear())
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Drawing canvas
            Positioned.fill(
              child: IgnorePointer(
                ignoring: false,
                child: GestureDetector(
                  onPanStart: (details) => _onPanStart(details),
                  onPanUpdate: (details) => _onPanUpdate(details),
                  onPanEnd: (details) => _onPanEnd(details),
                  child: CustomPaint(
                    painter: AnnotationPainter(_annotations),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildToolButton(AnnotationTool tool, IconData icon) {
    final isSelected = _selectedTool == tool;
    return IconButton(
      icon: Icon(icon, color: isSelected ? Theme.of(context).colorScheme.primary : Colors.white),
      onPressed: () => setState(() => _selectedTool = tool),
    );
  }

  Widget _buildColorButton() {
    return GestureDetector(
      onTap: () => _showColorPicker(),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: _selectedColor,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
      ),
    );
  }

  Widget _buildStrokeWidthSlider() {
    return SizedBox(
      width: 80,
      child: Slider(
        value: _strokeWidth,
        min: 1,
        max: 10,
        onChanged: (value) => setState(() => _strokeWidth = value),
        activeColor: Colors.white,
        inactiveColor: Colors.white30,
      ),
    );
  }

  void _showColorPicker() {
    final colors = [Colors.red, Colors.blue, Colors.green, Colors.yellow, Colors.orange, Colors.purple, Colors.white, Colors.black];
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('选择颜色', style: Theme.of(ctx).textTheme.titleMedium),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: colors.map((color) {
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedColor = color);
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(color: _selectedColor == color ? Colors.white : Colors.transparent, width: 3),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Offset? _startPoint;
  AnnotationElement? _currentElement;

  void _onPanStart(DragStartDetails details) {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final localPosition = details.localPosition;
    _startPoint = localPosition;

    switch (_selectedTool) {
      case AnnotationTool.pen:
        _currentElement = AnnotationElement(
          type: AnnotationType.freehand,
          color: _selectedColor,
          strokeWidth: _strokeWidth,
          points: [localPosition],
        );
        break;
      case AnnotationTool.arrow:
      case AnnotationTool.rect:
        _currentElement = AnnotationElement(
          type: _selectedTool == AnnotationTool.arrow ? AnnotationType.arrow : AnnotationType.rect,
          color: _selectedColor,
          strokeWidth: _strokeWidth,
          points: [localPosition, localPosition],
        );
        break;
      case AnnotationTool.text:
        _showTextInput(localPosition);
        return;
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_currentElement == null || _startPoint == null) return;

    final localPosition = details.localPosition;
    setState(() {
      if (_currentElement!.type == AnnotationType.freehand) {
        _currentElement!.points.add(localPosition);
      } else {
        _currentElement!.points[1] = localPosition;
      }
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_currentElement != null) {
      setState(() {
        _annotations.add(_currentElement!);
        _currentElement = null;
        _startPoint = null;
      });
    }
  }

  void _showTextInput(Offset position) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('输入文字'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '输入标注文字',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                setState(() {
                  _annotations.add(AnnotationElement(
                    type: AnnotationType.text,
                    color: _selectedColor,
                    strokeWidth: _strokeWidth,
                    points: [position],
                    text: controller.text,
                  ));
                });
              }
              Navigator.pop(ctx);
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }
}

enum AnnotationTool { pen, arrow, rect, text }

enum AnnotationType { freehand, arrow, rect, text }

class AnnotationElement {
  final AnnotationType type;
  final Color color;
  final double strokeWidth;
  final List<Offset> points;
  final String? text;
  final Rect? rect;

  AnnotationElement({
    required this.type,
    required this.color,
    required this.strokeWidth,
    required this.points,
    this.text,
    this.rect,
  });
}

class AnnotationPainter extends CustomPainter {
  final List<AnnotationElement> annotations;

  AnnotationPainter(this.annotations);

  @override
  void paint(Canvas canvas, Size size) {
    for (final annotation in annotations) {
      final paint = Paint()
        ..color = annotation.color
        ..strokeWidth = annotation.strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      switch (annotation.type) {
        case AnnotationType.freehand:
          if (annotation.points.length > 1) {
            final path = Path()..moveTo(annotation.points[0].dx, annotation.points[0].dy);
            for (int i = 1; i < annotation.points.length; i++) {
              path.lineTo(annotation.points[i].dx, annotation.points[i].dy);
            }
            canvas.drawPath(path, paint);
          }
          break;
        case AnnotationType.arrow:
          if (annotation.points.length >= 2) {
            final start = annotation.points[0];
            final end = annotation.points[1];
            canvas.drawLine(start, end, paint);

// Draw arrowhead
            const arrowLength = 15.0;
            const arrowAngle = 0.5;
            final angle = (end - start).direction;

            final p1 = end - Offset(cos(angle - arrowAngle) * arrowLength, sin(angle - arrowAngle) * arrowLength);
            final p2 = end - Offset(cos(angle + arrowAngle) * arrowLength, sin(angle + arrowAngle) * arrowLength);

            canvas.drawLine(end, p1, paint);
            canvas.drawLine(end, p2, paint);
          }
          break;
        case AnnotationType.rect:
          if (annotation.points.length >= 2) {
            final rect = Rect.fromPoints(annotation.points[0], annotation.points[1]);
            canvas.drawRect(rect, paint);
          }
          break;
        case AnnotationType.text:
          if (annotation.points.isNotEmpty && annotation.text != null) {
            final textSpan = TextSpan(
              text: annotation.text,
              style: TextStyle(
                color: annotation.color,
                fontSize: annotation.strokeWidth * 6,
                fontWeight: FontWeight.bold,
              ),
            );
            final textPainter = TextPainter(
              text: textSpan,
              textDirection: TextDirection.ltr,
            )..layout();

            textPainter.paint(canvas, annotation.points[0]);
          }
          break;
      }
    }
  }

  @override
  bool shouldRepaint(covariant AnnotationPainter oldDelegate) => true;
}
