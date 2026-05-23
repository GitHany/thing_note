/// 快速拍照 - Quick Photo Capture
/// 一键快速拍照记录
library;

import 'package:flutter/material.dart';

/// 拍照配置
class QuickPhotoConfig {
  final bool enabled;
  final int maxPhotos;
  final bool autoTag;
  final List<String> quickTags;
  final String? defaultThingName;

  QuickPhotoConfig({
    this.enabled = true,
    this.maxPhotos = 3,
    this.autoTag = true,
    this.quickTags = const [],
    this.defaultThingName,
  });
}

/// 拍照结果
class QuickPhotoResult {
  final List<String> photoPaths;
  final DateTime capturedAt;
  final String? location;
  final bool addedToRecord;

  QuickPhotoResult({
    required this.photoPaths,
    required this.capturedAt,
    this.location,
    this.addedToRecord = false,
  });
}

/// 快速拍照按钮
class QuickPhotoButton extends StatefulWidget {
  final VoidCallback onPressed;
  final int badgeCount;
  final Color? backgroundColor;

  const QuickPhotoButton({
    super.key,
    required this.onPressed,
    this.badgeCount = 0,
    this.backgroundColor,
  });

  @override
  State<QuickPhotoButton> createState() => _QuickPhotoButtonState();
}

class _QuickPhotoButtonState extends State<QuickPhotoButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onPressed();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: widget.backgroundColor ?? Theme.of(context).colorScheme.primary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              const Center(
                child: Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              if (widget.badgeCount > 0)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Text(
                      '${widget.badgeCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

/// 快速拍照预览
class QuickPhotoPreview extends StatelessWidget {
  final List<String> photoPaths;
  final VoidCallback? onRemove;
  final VoidCallback? onAddMore;

  const QuickPhotoPreview({
    super.key,
    required this.photoPaths,
    this.onRemove,
    this.onAddMore,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.photo_library,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                '快速拍照 (${photoPaths.length})',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const Spacer(),
              if (onAddMore != null)
                TextButton.icon(
                  onPressed: onAddMore,
                  icon: const Icon(Icons.add_a_photo, size: 18),
                  label: const Text('添加'),
                ),
            ],
          ),
          if (photoPaths.isNotEmpty) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: photoPaths.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Stack(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.image),
                        ),
                        if (onRemove != null)
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => onRemove!(),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  size: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}