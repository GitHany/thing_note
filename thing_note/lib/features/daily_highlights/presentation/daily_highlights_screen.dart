import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:thing_note/features/record/presentation/providers/record_provider.dart';
import 'package:thing_note/features/record/domain/episode_record.dart';
import 'package:intl/intl.dart';

// Daily Highlights State Provider
final dailyHighlightsProvider = FutureProvider<DailyHighlights>((ref) async {
  final records = await ref.watch(recordListProvider.future);
  final today = DateTime.now();
  final todayRecords = records.where((r) {
    return r.occurredAt.year == today.year &&
        r.occurredAt.month == today.month &&
        r.occurredAt.day == today.day;
  }).toList();

  return DailyHighlights(
    date: today,
    totalRecords: todayRecords.length,
    favoriteRecords: todayRecords.where((r) => r.isFavorite).toList(),
    photoRecords: todayRecords.where((r) => r.hasPhotos).toList(),
    audioRecords: todayRecords.where((r) => r.hasAudio).toList(),
    topTags: _extractTopTags(todayRecords),
    highlightNote: _getHighlightNote(todayRecords),
  );
});

List<String> _extractTopTags(List<EpisodeRecord> records) {
  // Simple tag extraction from notes
  final tags = <String, int>{};
  for (final record in records) {
    final matches = RegExp(r'#(\w+)').allMatches(record.note);
    for (final match in matches) {
      final tag = match.group(1)!;
      tags[tag] = (tags[tag] ?? 0) + 1;
    }
  }
  final sortedEntries = tags.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return sortedEntries.take(5).map((e) => e.key).toList();
}

String? _getHighlightNote(List<EpisodeRecord> records) {
  if (records.isEmpty) return null;
  // Find the most detailed record
  records.sort((a, b) => b.note.length.compareTo(a.note.length));
  return records.first.note.isNotEmpty ? records.first.note : null;
}

class DailyHighlights {
  final DateTime date;
  final int totalRecords;
  final List<EpisodeRecord> favoriteRecords;
  final List<EpisodeRecord> photoRecords;
  final List<EpisodeRecord> audioRecords;
  final List<String> topTags;
  final String? highlightNote;

  DailyHighlights({
    required this.date,
    required this.totalRecords,
    required this.favoriteRecords,
    required this.photoRecords,
    required this.audioRecords,
    required this.topTags,
    this.highlightNote,
  });
}

class DailyHighlightsScreen extends ConsumerWidget {
  const DailyHighlightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final highlightsAsync = ref.watch(dailyHighlightsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('每日亮点'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareHighlights(context),
          ),
        ],
      ),
      body: highlightsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('加载失败: $err')),
        data: (highlights) => _buildContent(context, ref, highlights),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, DailyHighlights highlights) {
    if (highlights.totalRecords == 0) {
      return _buildEmptyState(context);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDateHeader(context, highlights.date),
          const SizedBox(height: 16),
          _buildStatsSummary(context, highlights),
          const SizedBox(height: 16),
          if (highlights.highlightNote != null) ...[
            _buildHighlightNote(context, highlights.highlightNote!),
            const SizedBox(height: 16),
          ],
          if (highlights.topTags.isNotEmpty) ...[
            _buildTopTags(context, highlights.topTags),
            const SizedBox(height: 16),
          ],
          if (highlights.favoriteRecords.isNotEmpty) ...[
            _buildFavoriteRecords(context, highlights.favoriteRecords),
            const SizedBox(height: 16),
          ],
          if (highlights.photoRecords.isNotEmpty) ...[
            _buildPhotoRecords(context, highlights.photoRecords),
            const SizedBox(height: 16),
          ],
          if (highlights.audioRecords.isNotEmpty) ...[
            _buildAudioRecords(context, highlights.audioRecords),
          ],
        ],
      ),
    );
  }

  Widget _buildDateHeader(BuildContext context, DateTime date) {
    final now = DateTime.now();
    final isToday = date.year == now.year && date.month == now.month && date.day == now.day;
    
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            isToday ? '今天' : DateFormat('MM月dd日').format(date),
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          DateFormat('EEEE').format(date),
          style: TextStyle(
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSummary(BuildContext context, DailyHighlights highlights) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            '总记录',
            highlights.totalRecords.toString(),
            Icons.note,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            context,
            '收藏',
            highlights.favoriteRecords.length.toString(),
            Icons.star,
            Colors.amber,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            context,
            '照片',
            highlights.photoRecords.length.toString(),
            Icons.photo,
            Colors.green,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            context,
            '语音',
            highlights.audioRecords.length.toString(),
            Icons.mic,
            Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHighlightNote(BuildContext context, String note) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '今日亮点',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              note,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopTags(BuildContext context, List<String> tags) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.tag,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '热门标签',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: tags.map((tag) {
                return Chip(
                  avatar: const Icon(Icons.tag, size: 16),
                  label: Text('#$tag'),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoriteRecords(BuildContext context, List<EpisodeRecord> records) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.star,
                  color: Colors.amber,
                ),
                const SizedBox(width: 8),
                Text(
                  '收藏记录',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                Text(
                  '${records.length}条',
                  style: TextStyle(color: Theme.of(context).colorScheme.outline),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...records.take(3).map((record) {
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  record.note.isNotEmpty ? record.note : '无内容记录',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(DateFormat('HH:mm').format(record.occurredAt)),
                onTap: () => context.push('/record/${record.id}'),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoRecords(BuildContext context, List<EpisodeRecord> records) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.photo,
                  color: Colors.green,
                ),
                const SizedBox(width: 8),
                Text(
                  '照片记录',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                Text(
                  '${records.length}条',
                  style: TextStyle(color: Theme.of(context).colorScheme.outline),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: records.take(5).length,
                itemBuilder: (context, index) {
                  return Container(
                    width: 80,
                    height: 80,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.photo,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioRecords(BuildContext context, List<EpisodeRecord> records) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.mic,
                  color: Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  '语音记录',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                Text(
                  '${records.length}条',
                  style: TextStyle(color: Theme.of(context).colorScheme.outline),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...records.take(3).map((record) {
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.play_arrow, color: Colors.red),
                ),
                title: Text(
                  '语音记录 ${DateFormat('HH:mm').format(record.occurredAt)}',
                ),
                subtitle: Text('${record.totalAudioDurationSec ~/ 60}分钟'),
                onTap: () => context.push('/record/${record.id}'),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.summarize,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            '今日暂无记录',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            '开始记录你的日常生活吧',
            style: TextStyle(color: Theme.of(context).colorScheme.outline),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.push('/record/new'),
            icon: const Icon(Icons.add),
            label: const Text('添加记录'),
          ),
        ],
      ),
    );
  }

  void _shareHighlights(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('分享功能开发中')),
    );
  }
}
