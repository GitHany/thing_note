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

class RecordDetailScreen extends ConsumerWidget {
  final int recordId;

  const RecordDetailScreen({super.key, required this.recordId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordAsync = ref.watch(recordDetailProvider(recordId));
    final thingNamesAsync = ref.watch(thingNameListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('记录详情'),
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
                        context.push('/record/$recordId/edit');
                      } else if (value == 'delete') {
                        _showDeleteDialog(context, ref);
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'edit', child: Text('编辑')),
                      const PopupMenuItem(value: 'delete', child: Text('删除')),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
      body: recordAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('加载失败: $err')),
        data: (record) {
          if (record == null) {
            return const Center(child: Text('记录不存在'));
          }
          return _buildContent(context, record, thingNamesAsync);
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, EpisodeRecord record, AsyncValue<List<ThingName>> thingNamesAsync) {
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
          _buildSection(
            context,
            icon: Icons.calendar_today,
            title: '发生时间',
            child: Text(DateFormatter.formatDateTime(record.occurredAt)),
          ),
          if (thingName != null) ...[
            const SizedBox(height: 16),
            _buildSection(
              context,
              icon: Icons.category,
              title: '事件名称',
              child: Text(thingName),
            ),
          ],
          const SizedBox(height: 16),
          _buildSection(
            context,
            icon: Icons.timer,
            title: '持续时长',
            child: Text(DurationFormatter.formatShort(record.duration)),
          ),
          if (record.note.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildSection(
              context,
              icon: Icons.note,
              title: '备注',
              child: Text(record.note),
            ),
          ],
          if (record.hasPhotos) ...[
            const SizedBox(height: 16),
            _buildSection(
              context,
              icon: Icons.photo_library,
              title: '照片 (${record.photoPaths.length})',
              child: _buildPhotoGallery(context, record)),
          ],
          if (record.hasAudio) ...[
            const SizedBox(height: 16),
            _buildSection(
              context,
              icon: Icons.mic,
              title: '录音 (${record.audioPaths.length})',
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
            '创建于 ${DateFormatter.formatDateTime(record.createdAt)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
          if (record.createdAt != record.updatedAt)
            Text(
              '更新于 ${DateFormatter.formatDateTime(record.updatedAt)}',
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
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: record.photoPaths.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => _showFullScreenImage(context, record.photoPaths[index]),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                File(record.photoPaths[index]),
                width: 100,
                height: 100,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 100,
                  height: 100,
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: const Icon(Icons.broken_image),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showFullScreenImage(BuildContext context, String path) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(backgroundColor: Colors.black),
          body: Center(
            child: InteractiveViewer(
              child: Image.file(File(path)),
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这条记录吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              ref.read(recordNotifierProvider.notifier).delete(recordId);
              ref.invalidate(recordListProvider);
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}
