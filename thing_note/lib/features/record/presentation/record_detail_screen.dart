import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:thing_note/core/utils/date_formatter.dart';
import 'package:thing_note/core/utils/duration_formatter.dart';
import 'package:thing_note/features/media/presentation/widgets/audio_player.dart';
import 'package:thing_note/features/record/domain/episode_record.dart';
import 'package:thing_note/features/record/presentation/providers/record_provider.dart';
import 'package:thing_note/features/thing_name/domain/thing_name.dart';
import 'package:thing_note/features/thing_name/presentation/providers/thing_name_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:video_player/video_player.dart';

class RecordDetailScreen extends ConsumerWidget {
  final int recordId;

  const RecordDetailScreen({super.key, required this.recordId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordAsync = ref.watch(recordDetailProvider(recordId));
    final thingNamesAsync = ref.watch(thingNameListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.recordDetail),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          recordAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (record) => record != null
                ? PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        context.push('/record/${record.id}/edit');
                      } else if (value == 'delete') {
                        _showDeleteDialog(context, ref);
                      }
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(value: 'edit', child: Text(AppLocalizations.of(context)!.edit)),
                      PopupMenuItem(value: 'delete', child: Text(AppLocalizations.of(context)!.delete)),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
      body: recordAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text(AppLocalizations.of(context)!.loadFailed(err.toString()))),
        data: (record) {
          if (record == null) {
            return Center(child: Text(AppLocalizations.of(context)!.recordNotExist));
          }
          return _buildContent(context, ref, record, thingNamesAsync);
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, EpisodeRecord record, AsyncValue<List<ThingName>> thingNamesAsync) {
    String? thingName;
    if (thingNamesAsync.hasValue) {
      final thingNames = thingNamesAsync.value!;
      ThingName? found;
      try {
        found = thingNames.firstWhere(
          (name) => name.id == record.thingNameId,
        );
      } catch (_) {
        found = null;
      }
      if (found != null) {
        thingName = found.name;
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Hero(
            tag: 'record_${record.id}',
            child: Material(
              type: MaterialType.transparency,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSection(
                    context,
                    icon: Icons.calendar_today,
                    title: AppLocalizations.of(context)!.occurredAt,
                    child: Text(DateFormatter.formatDateTime(record.occurredAt)),
                  ),
                  if (thingName != null) ...[
                    const SizedBox(height: 16),
                    _buildSection(
                      context,
                      icon: Icons.category,
                      title: AppLocalizations.of(context)!.thingName,
                      child: Text(thingName),
                    ),
                  ],
                  const SizedBox(height: 16),
                  _buildSection(
                    context,
                    icon: Icons.timer,
                    title: AppLocalizations.of(context)!.duration,
                    child: Text(DurationFormatter.formatShort(record.duration)),
                  ),
                  if (record.hasReminder) ...[
                    const SizedBox(height: 16),
                    _buildSection(
                      context,
                      icon: Icons.alarm,
                      title: AppLocalizations.of(context)!.reminder,
                      child: Row(
                        children: [
                          Text(AppLocalizations.of(context)!.reminderSet),
                          const SizedBox(width: 8),
                          TextButton.icon(
                            icon: const Icon(Icons.close, size: 16),
                            label: Text(AppLocalizations.of(context)!.closeReminder),
                            onPressed: () async {
                              await ref.read(recordNotifierProvider.notifier).update(
                                    record.copyWith(hasReminder: false),
                                  );
                              ref.invalidate(recordDetailProvider(recordId));
                              ref.invalidate(recordListProvider);
                              ref.invalidate(reminderCountProvider);
                              ref.invalidate(reminderRecordsProvider);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (record.hasLocation) ...[
            const SizedBox(height: 16),
            _buildSection(
              context,
              icon: Icons.location_on,
              title: AppLocalizations.of(context)!.location,
              child: Text(record.address ?? ''),
            ),
          ],
          if (record.note.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildSection(
              context,
              icon: Icons.note,
              title: AppLocalizations.of(context)!.note,
              child: Text(record.note),
            ),
          ],
          if (record.hasPhotos) ...[
            const SizedBox(height: 16),
            _buildSection(
              context,
              icon: Icons.photo_library,
              title: '${AppLocalizations.of(context)!.photos} (${record.photoPaths.length})',
              child: _buildPhotoGallery(context, record)),
          ],
          if (record.hasVideos) ...[
            const SizedBox(height: 16),
            _buildSection(
              context,
              icon: Icons.videocam,
              title: '${AppLocalizations.of(context)!.videos} (${record.videoPaths.length})',
              child: _buildVideoList(context, record)),
          ],
          if (record.hasAudio) ...[
            const SizedBox(height: 16),
            _buildSection(
              context,
              icon: Icons.mic,
              title: '${AppLocalizations.of(context)!.audios} (${record.audioPaths.length})',
              child: Column(
                children: record.audioPaths.map((path) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: AudioPlayerWidget(audioPath: path),
                  );
                }).toList(),
              ),
            ),
          ],
          const SizedBox(height: 24),
          Text(
            '${AppLocalizations.of(context)!.createdAt} ${DateFormatter.formatDateTime(record.createdAt)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
          if (record.createdAt != record.updatedAt)
            Text(
              '${AppLocalizations.of(context)!.updatedAt} ${DateFormatter.formatDateTime(record.updatedAt)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 26),
          child: child,
        ),
      ],
    );
  }

  Widget _buildPhotoGallery(BuildContext context, EpisodeRecord record) {
    const double itemSize = 88.0;
    const double spacing = 8.0;
    final int rowCount = (record.photoPaths.length / 3).ceil();
    final double gridHeight = rowCount * itemSize + (rowCount - 1) * spacing;

    return SizedBox(
      height: gridHeight,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: spacing,
          mainAxisSpacing: spacing,
          childAspectRatio: 1,
        ),
        itemCount: record.photoPaths.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => _showFullScreenImage(context, record.photoPaths, index),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                File(record.photoPaths[index]),
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                cacheWidth: 176,
                errorBuilder: (_, __, ___) => Container(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Icon(
                    Icons.broken_image,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showFullScreenImage(BuildContext context, List<String> paths, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _FullScreenImageViewer(imagePaths: paths, initialIndex: initialIndex),
      ),
    );
  }

  Widget _buildVideoList(BuildContext context, EpisodeRecord record) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: record.videoPaths.asMap().entries.map((entry) {
        final index = entry.key;
        final path = entry.value;
        return Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _openVideo(context, path),
              borderRadius: BorderRadius.circular(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.play_circle_filled,
                    size: 32,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${AppLocalizations.of(context)!.videos} ${index + 1}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  void _openVideo(BuildContext context, String path) {
    final file = File(path);
    if (!file.existsSync()) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _VideoPlayerPage(videoPath: path),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(ctx)!.confirmDelete),
        content: Text(AppLocalizations.of(ctx)!.confirmDeleteRecord),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(ctx)!.cancel),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(recordNotifierProvider.notifier).delete(recordId);
              ref.invalidate(recordListProvider);
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) Navigator.pop(context);
            },
            child: Text(AppLocalizations.of(ctx)!.delete),
          ),
        ],
      ),
    );
  }
}

class _FullScreenImageViewer extends StatefulWidget {
  final List<String> imagePaths;
  final int initialIndex;

  const _FullScreenImageViewer({
    required this.imagePaths,
    this.initialIndex = 0,
  });

  @override
  State<_FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<_FullScreenImageViewer> {
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
        title: Text('${_currentIndex + 1} / ${widget.imagePaths.length}'),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.imagePaths.length,
        onPageChanged: (index) {
          setState(() => _currentIndex = index);
        },
        itemBuilder: (context, index) {
          return InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: Center(
              child: Image.file(
                File(widget.imagePaths[index]),
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

class _VideoPlayerPage extends StatefulWidget {
  final String videoPath;

  const _VideoPlayerPage({required this.videoPath});

  @override
  State<_VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<_VideoPlayerPage> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.videoPath))
      ..initialize().then((_) {
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
          _controller.play();
        }
      }).catchError((error) {
        if (mounted) {
          setState(() => _hasError = true);
        }
      });
    _controller.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: _hasError
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.white54, size: 64),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context)!.loadFailed(''),
                    style: const TextStyle(color: Colors.white54),
                  ),
                ],
              )
            : _isInitialized
                ? AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        VideoPlayer(_controller),
                        VideoProgressIndicator(
                          _controller,
                          allowScrubbing: true,
                          colors: VideoProgressColors(
                            playedColor: Theme.of(context).colorScheme.primary,
                            bufferedColor: Colors.white.withOpacity(0.3),
                            backgroundColor: Colors.white.withOpacity(0.1),
                          ),
                        ),
                        if (!_controller.value.isPlaying)
                          GestureDetector(
                            onTap: () => _controller.play(),
                            child: const Icon(
                              Icons.play_circle_fill,
                              size: 64,
                              color: Colors.white70,
                            ),
                          ),
                      ],
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
