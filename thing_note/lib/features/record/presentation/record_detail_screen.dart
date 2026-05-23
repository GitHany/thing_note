import 'dart:io';
import 'package:flutter/material.dart';
import 'package:thing_note/app/theme/app_theme.dart';
import 'package:thing_note/app/theme/spacing_constants.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:thing_note/core/utils/date_formatter.dart';
import 'package:thing_note/core/utils/duration_formatter.dart';
import 'package:thing_note/features/media/presentation/widgets/audio_player.dart';
import 'package:thing_note/features/record/domain/episode_record.dart';
import 'package:thing_note/features/record/data/record_repository_impl.dart';
import 'package:thing_note/features/record/presentation/providers/record_provider.dart';
import 'package:thing_note/features/record_link/presentation/link_records_dialog.dart';
import 'package:thing_note/features/thing_name/domain/thing_name.dart';
import 'package:thing_note/features/thing_name/presentation/providers/thing_name_provider.dart';
import 'package:thing_note/features/tag/presentation/providers/tag_provider.dart';
import 'package:thing_note/features/tag/domain/tag.dart';
import 'package:thing_note/l10n/generated/app_localizations.dart';
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth >= AppSpacing.mediumBreakpoint;
    final contentPadding = AppSpacing.getHorizontalPadding(screenWidth);
    final sectionSpacing = isWideScreen ? AppSpacing.largeSectionSpacing : AppSpacing.mediumSectionSpacing;
    
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

    // Fetch tags for this record
    final tagsAsync = ref.watch(tagsForRecordProvider(record.id!));
    final List<Tag> tags = tagsAsync.valueOrNull ?? [];

    return SingleChildScrollView(
      padding: EdgeInsets.all(contentPadding),
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
                    SizedBox(height: sectionSpacing),
                    _buildSection(
                      context,
                      icon: Icons.category,
                      title: AppLocalizations.of(context)!.thingName,
                      child: Text(thingName),
                    ),
                  ],
                  if (tags.isNotEmpty) ...[
                    SizedBox(height: sectionSpacing),
                    _buildSection(
                      context,
                      icon: Icons.label,
                      title: AppLocalizations.of(context)!.tags,
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: tags.map((tag) {
                          final tagColor = Color(int.parse(tag.color.replaceFirst('#', '0xFF')));
                          return Chip(
                            avatar: CircleAvatar(
                              backgroundColor: tagColor,
                              radius: 12,
                              child: Text(
                                tag.name[0].toUpperCase(),
                                style: const TextStyle(color: Colors.white, fontSize: 11),
                              ),
                            ),
                            label: Text(tag.name),
                            backgroundColor: tagColor.withAlpha(38),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                  SizedBox(height: sectionSpacing),
                  _buildSection(
                    context,
                    icon: Icons.timer,
                    title: AppLocalizations.of(context)!.duration,
                    child: Text(DurationFormatter.formatShort(record.duration)),
                  ),
                  if (record.hasReminder) ...[
                    SizedBox(height: sectionSpacing),
                    _buildSection(
                      context,
                      icon: Icons.alarm,
                      title: AppLocalizations.of(context)!.reminder,
                      child: Row(
                        children: [
                          Text(AppLocalizations.of(context)!.reminderSet),
                          const SizedBox(width: 10),
                          TextButton.icon(
                            icon: const Icon(Icons.close, size: 18),
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
                  // Display repeat type info
                  if (record.isRecurring) ...[
                    SizedBox(height: sectionSpacing),
                    _buildSection(
                      context,
                      icon: Icons.repeat,
                      title: AppLocalizations.of(context)!.repeatType,
                      child: Text(_getRepeatTypeLabel(context, record.repeatType)),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (record.hasLocation) ...[
            SizedBox(height: sectionSpacing),
            _buildSection(
              context,
              icon: Icons.location_on,
              title: AppLocalizations.of(context)!.location,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(record.address ?? ''),
                  if (record.latitude != null && record.longitude != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        '${record.latitude!.toStringAsFixed(6)}, ${record.longitude!.toStringAsFixed(6)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                      ),
                    ),
                ],
              ),
            ),
          ],
          if (record.note.isNotEmpty) ...[
            SizedBox(height: sectionSpacing),
            _buildSection(
              context,
              icon: Icons.note,
              title: AppLocalizations.of(context)!.note,
              child: Text(record.note),
            ),
          ],
          if (record.hasPhotos) ...[
            SizedBox(height: sectionSpacing),
            _buildSection(
              context,
              icon: Icons.photo_library,
              title: '${AppLocalizations.of(context)!.photos} (${record.photoPaths.length})',
              child: _buildPhotoGallery(context, record),
            ),
          ],
          if (record.hasVideos) ...[
            SizedBox(height: sectionSpacing),
            _buildSection(
              context,
              icon: Icons.videocam,
              title: '${AppLocalizations.of(context)!.videos} (${record.videoPaths.length})',
              child: _buildVideoList(context, record),
            ),
          ],
          if (record.hasAudio) ...[
            SizedBox(height: sectionSpacing),
            _buildSection(
              context,
              icon: Icons.mic,
              title: '${AppLocalizations.of(context)!.audios} (${record.audioPaths.length})',
              child: Column(
                children: record.audioPaths.asMap().entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: AudioPlayerWidget(
                      audioPath: entry.value,
                      showWaveform: true,
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
          // Linked records section
          SizedBox(height: sectionSpacing),
          _buildLinkedRecordsSection(context, ref, record),
          // Quick action bar
          SizedBox(height: sectionSpacing),
          _buildQuickActionsBar(context, ref, record),
          const SizedBox(height: 28),
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

  String _getRepeatTypeLabel(BuildContext context, String repeatType) {
    switch (repeatType) {
      case 'daily':
        return AppLocalizations.of(context)!.daily;
      case 'weekly':
        return AppLocalizations.of(context)!.weekly;
      case 'monthly':
        return AppLocalizations.of(context)!.monthly;
      case 'yearly':
        return AppLocalizations.of(context)!.yearly;
      default:
        return repeatType;
    }
  }

  Widget _buildQuickActionsBar(BuildContext context, WidgetRef ref, EpisodeRecord record) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmall = screenWidth < 360;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: EdgeInsets.symmetric(horizontal: isSmall ? 8 : 12, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _QuickActionButton(
            icon: Icons.share_outlined,
            label: '分享',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.construction, size: 18),
                      SizedBox(width: 8),
                      Text('分享功能正在开发中'),
                    ],
                  ),
                ),
              );
            },
          ),
          _QuickActionButton(
            icon: record.isFavorite ? Icons.star : Icons.star_border,
            label: '收藏',
            onPressed: () async {
              final repo = ref.read(recordRepositoryProvider);
              await repo.update(record.copyWith(isFavorite: !record.isFavorite));
              ref.invalidate(recordDetailProvider(record.id!));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(record.isFavorite ? '已取消收藏' : '已收藏'),
                    duration: const Duration(seconds: 1),
                  ),
                );
              }
            },
          ),
          _QuickActionButton(
            icon: Icons.edit_outlined,
            label: '编辑',
            onPressed: () => context.push('/record/${record.id}/edit'),
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
    final screenWidth = MediaQuery.of(context).size.width;
    final cardPadding = AppSpacing.getItemSpacing(screenWidth);
    return Container(
      decoration: AppTheme.sectionDecoration(context),
      padding: EdgeInsets.all(cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 10),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
            ],
          ),
          SizedBox(height: cardPadding - 6),
          child,
        ],
      ),
    );
  }

  Widget _buildPhotoGallery(BuildContext context, EpisodeRecord record) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Responsive cross axis count: 2 for ultra small (<=320), 2-3 for small (<360), 3 for normal, 4 for wide
    final crossAxisCount = screenWidth <= AppSpacing.ultraSmallBreakpoint 
        ? 2 
        : (screenWidth < AppSpacing.smallBreakpoint ? 2 : (screenWidth > 500 ? 4 : 3));
    final itemSize = (screenWidth - AppSpacing.getHorizontalPadding(screenWidth) * 2 - (crossAxisCount - 1) * 10) / crossAxisCount;
    const spacing = 10.0;
    final rowCount = (record.photoPaths.length / crossAxisCount).ceil();
    final double gridHeight = rowCount * itemSize + (rowCount - 1) * spacing;

    return SizedBox(
      height: gridHeight,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: spacing,
          mainAxisSpacing: spacing,
          childAspectRatio: 1,
        ),
        itemCount: record.photoPaths.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => _showFullScreenImage(context, record.photoPaths, index),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Hero(
                tag: 'photo_${record.id}_$index',
                child: Image.file(
                  File(record.photoPaths[index]),
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                  cacheWidth: 200,
                  errorBuilder: (_, __, ___) => Container(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: Icon(
                      Icons.broken_image,
                      color: Theme.of(context).colorScheme.error,
                    ),
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isUltraSmall = AppSpacing.isUltraSmall(screenWidth);
    final isSmall = AppSpacing.isSmall(screenWidth);
    final isWide = screenWidth >= AppSpacing.largeBreakpoint;
    // 响应式视频尺寸：小屏更紧凑，大屏更大
    final itemWidth = isUltraSmall ? 64.0 : (isSmall ? 72.0 : (isWide ? 130.0 : 105.0));
    final itemHeight = itemWidth;
    final iconSize = isUltraSmall ? 22.0 : (isSmall ? 24.0 : (isWide ? 42.0 : 36.0));

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: record.videoPaths.asMap().entries.map((entry) {
        final index = entry.key;
        final path = entry.value;
        final fileExists = File(path).existsSync();
        
        return GestureDetector(
          onTap: fileExists ? () => _openVideo(context, path) : null,
          child: Container(
            width: itemWidth,
            height: itemHeight,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    fileExists ? Icons.play_circle_filled : Icons.error_outline,
                    size: iconSize,
                    color: fileExists 
                        ? Theme.of(context).colorScheme.primary 
                        : Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    fileExists 
                        ? '${AppLocalizations.of(context)!.videos} ${index + 1}'
                        : AppLocalizations.of(context)!.loadFailed('').split('。')[0],
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: screenWidth < 360 ? 9 : 10,
                        ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
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

  Widget _buildLinkedRecordsSection(BuildContext context, WidgetRef ref, EpisodeRecord record) {
    final linkedRecordsAsync = ref.watch(linkedRecordsProvider(record.id!));

    return linkedRecordsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (linkedRecords) {
        if (linkedRecords.isEmpty) {
          return _buildSection(
            context,
            icon: Icons.link,
            title: AppLocalizations.of(context)!.linkedRecords,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.noLinkedRecords,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  icon: const Icon(Icons.add_link),
                  label: Text(AppLocalizations.of(context)!.addLink),
                  onPressed: () => _showLinkRecordsDialog(context, ref, record),
                ),
              ],
            ),
          );
        }

        return _buildSection(
          context,
          icon: Icons.link,
          title: '${AppLocalizations.of(context)!.linkedRecords} (${linkedRecords.length})',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...linkedRecords.map((linked) => _buildLinkedRecordItemCompact(context, linked)),
              const SizedBox(height: 14),
              Row(
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.add_link, size: 20),
                    label: Text(AppLocalizations.of(context)!.addLink),
                    onPressed: () => _showLinkRecordsDialog(context, ref, record),
                  ),
                  if (linkedRecords.isNotEmpty) ...[
                    const SizedBox(width: 10),
                    TextButton.icon(
                      icon: const Icon(Icons.link, size: 20),
                      label: Text(AppLocalizations.of(context)!.manageLinks),
                      onPressed: () => _showLinkRecordsDialog(context, ref, record),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLinkedRecordItemCompact(BuildContext context, EpisodeRecord linkedRecord) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          context.push('/record/${linkedRecord.id}');
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _getRecordIcon(linkedRecord),
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      linkedRecord.note.isNotEmpty ? linkedRecord.note : AppLocalizations.of(context)!.noNote,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 12,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormatter.formatDateTime(linkedRecord.occurredAt),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                        ),
                        if (linkedRecord.durationSec > 0) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.timer_outlined,
                            size: 12,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            DurationFormatter.formatShort(linkedRecord.duration),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (linkedRecord.hasPhotos)
                    const Icon(Icons.photo, size: 16, color: Colors.blue),
                  if (linkedRecord.hasAudio)
                    const Padding(padding: EdgeInsets.only(left: 4), child: Icon(Icons.mic, size: 16, color: Colors.orange)),
                  if (linkedRecord.hasVideos)
                    const Padding(padding: EdgeInsets.only(left: 4), child: Icon(Icons.videocam, size: 16, color: Colors.red)),
                  if (linkedRecord.isFavorite)
                    const Padding(padding: EdgeInsets.only(left: 4), child: Icon(Icons.star, size: 16, color: Colors.amber)),
                ],
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getRecordIcon(EpisodeRecord record) {
    if (record.hasVideos) return Icons.videocam;
    if (record.hasPhotos) return Icons.photo;
    if (record.hasAudio) return Icons.mic;
    if (record.note.isNotEmpty) return Icons.note;
    return Icons.event;
  }

  void _showLinkRecordsDialog(BuildContext context, WidgetRef ref, EpisodeRecord record) {
    showDialog(
      context: context,
      builder: (dialogContext) => LinkRecordsDialog(
        currentRecordId: record.id!,
        onLinked: () {
          ref.invalidate(linkedRecordsProvider(record.id!));
        },
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
            child: Text(
              AppLocalizations.of(ctx)!.delete,
              style: TextStyle(color: Theme.of(ctx).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isUltraSmall = AppSpacing.isUltraSmall(screenWidth);
    final isSmall = AppSpacing.isSmall(screenWidth);
    // Responsive sizing for ultra small screens
    final paddingH = isUltraSmall ? 8.0 : (isSmall ? 10.0 : 12.0);
    final paddingV = isUltraSmall ? 6.0 : (isSmall ? 8.0 : 8.0);
    final iconSize = isUltraSmall ? 18.0 : (isSmall ? 20.0 : 22.0);

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: paddingH, vertical: paddingV),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: iconSize),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontSize: isUltraSmall ? 8 : (isSmall ? 10 : 11),
                  ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
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
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareImage(context),
          ),
        ],
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
            maxScale: 5.0,
            child: Center(
              child: Hero(
                tag: 'photo_viewer_$index',
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
            ),
          );
        },
      ),
    );
  }

  void _shareImage(BuildContext context) {
    // TODO: 待 share_plus 实现分享功能
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.construction, size: 18),
            SizedBox(width: 8),
            Text('分享功能正在开发中'),
          ],
        ),
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
  double _playbackSpeed = 1.0;
  bool _showControls = true;

  final List<double> _speedOptions = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

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

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  void _setPlaybackSpeed(double speed) {
    setState(() {
      _playbackSpeed = speed;
      _controller.setPlaybackSpeed(speed);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _showControls
          ? AppBar(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              title: Text(AppLocalizations.of(context)!.videoPlayer),
              actions: [
                PopupMenuButton<double>(
                  icon: const Icon(Icons.speed),
                  tooltip: AppLocalizations.of(context)!.playbackSpeed,
                  onSelected: _setPlaybackSpeed,
                  itemBuilder: (_) => _speedOptions.map((speed) {
                    return PopupMenuItem(
                      value: speed,
                      child: Row(
                        children: [
                          if (_playbackSpeed == speed)
                            const Icon(Icons.check, size: 18)
                          else
                            const SizedBox(width: 18),
                          const SizedBox(width: 8),
                          Text('${speed}x'),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            )
          : null,
      body: GestureDetector(
        onTap: _toggleControls,
        child: Center(
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
                  ? Stack(
                      alignment: Alignment.center,
                      children: [
                        AspectRatio(
                          aspectRatio: _controller.value.aspectRatio,
                          child: VideoPlayer(_controller),
                        ),
                        if (_showControls)
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              color: Colors.black54,
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  VideoProgressIndicator(
                                    _controller,
                                    allowScrubbing: true,
                                    colors: VideoProgressColors(
                                      playedColor: Theme.of(context).colorScheme.primary,
                                      bufferedColor: const Color.fromRGBO(255, 255, 255, 0.3),
                                      backgroundColor: const Color.fromRGBO(255, 255, 255, 0.1),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '${_formatDuration(_controller.value.position)} / ${_formatDuration(_controller.value.duration)}',
                                        style: const TextStyle(color: Colors.white, fontSize: 12),
                                      ),
                                      if (_playbackSpeed != 1.0)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).colorScheme.primary,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            '${_playbackSpeed}x',
                                            style: const TextStyle(color: Colors.white, fontSize: 12),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        if (!_controller.value.isPlaying && _showControls)
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _controller.play();
                              });
                            },
                            child: Container(
                              width: 72,
                              height: 72,
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.play_arrow,
                                size: 48,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    )
                  : const CircularProgressIndicator(),
        ),
      ),
      floatingActionButton: _isInitialized && _showControls
          ? Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FloatingActionButton.small(
                  heroTag: 'rewind',
                  onPressed: () {
                    final newPosition = _controller.value.position - const Duration(seconds: 10);
                    _controller.seekTo(newPosition.isNegative ? Duration.zero : newPosition);
                  },
                  child: const Icon(Icons.replay_10),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  heroTag: 'playPause',
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
                ),
                const SizedBox(width: 8),
                FloatingActionButton.small(
                  heroTag: 'forward',
                  onPressed: () {
                    final newPosition = _controller.value.position + const Duration(seconds: 10);
                    final duration = _controller.value.duration;
                    _controller.seekTo(newPosition > duration ? duration : newPosition);
                  },
                  child: const Icon(Icons.forward_10),
                ),
              ],
            )
          : null,
    );
  }
}