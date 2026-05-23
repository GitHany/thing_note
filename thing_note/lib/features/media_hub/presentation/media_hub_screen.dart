import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/media_models.dart';

/// 媒体中心屏幕
class MediaHubScreen extends ConsumerWidget {
  const MediaHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediaAsync = ref.watch(mediaHubProvider);
    final statsAsync = ref.watch(mediaStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('媒体中心'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(mediaHubProvider.notifier).loadMedia(),
          ),
        ],
      ),
      body: Column(
        children: [
          // 统计概览
          statsAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => const SizedBox.shrink(),
            data: (stats) => Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _MediaStatChip(icon: Icons.photo, count: stats.photoCount, label: '照片', color: Colors.blue),
                  _MediaStatChip(icon: Icons.videocam, count: stats.videoCount, label: '视频', color: Colors.red),
                  _MediaStatChip(icon: Icons.mic, count: stats.audioCount, label: '音频', color: Colors.green),
                  _MediaStatChip(icon: Icons.insert_drive_file, count: stats.documentCount, label: '文档', color: Colors.orange),
                ],
              ),
            ),
          ),
          const Divider(),
          // 媒体列表
          Expanded(
            child: mediaAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('加载失败: $e')),
              data: (files) => files.isEmpty
                  ? const Center(child: Text('暂无媒体文件'))
                  : GridView.builder(
                      padding: const EdgeInsets.all(8),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 4,
                        mainAxisSpacing: 4,
                      ),
                      itemCount: files.length,
                      itemBuilder: (context, index) {
                        final file = files[index];
                        return GestureDetector(
                          onTap: () => _showMediaPreview(context, file),
                          onLongPress: () => _showDeleteDialog(context, ref, file),
                          child: Container(
                            decoration: BoxDecoration(
                              color: file.type == MediaType.photo ? Colors.grey[200] : file.type.color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: file.type == MediaType.photo
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: const Icon(Icons.photo, size: 40),
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(_getMediaIcon(file.type), size: 32, color: file.type.color),
                                      const SizedBox(height: 4),
                                      Text(file.name, style: const TextStyle(fontSize: 10), overflow: TextOverflow.ellipsis),
                                    ],
                                  ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getMediaIcon(MediaType type) {
    switch (type) {
      case MediaType.photo: return Icons.photo;
      case MediaType.video: return Icons.videocam;
      case MediaType.audio: return Icons.mic;
      case MediaType.document: return Icons.insert_drive_file;
    }
  }

  void _showMediaPreview(BuildContext context, MediaFile file) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(file.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_getMediaIcon(file.type), size: 64),
            const SizedBox(height: 16),
            Text('大小: ${file.formattedSize}'),
            Text('创建: ${file.createdAt.toString().split('.')[0]}'),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('关闭'))],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, MediaFile file) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除媒体'),
        content: Text('确定删除 ${file.name} 吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          TextButton(
            onPressed: () {
              ref.read(mediaHubProvider.notifier).deleteMedia(file.id);
              Navigator.pop(context);
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _MediaStatChip extends StatelessWidget {
  final IconData icon;
  final int count;
  final String label;
  final Color color;

  const _MediaStatChip({required this.icon, required this.count, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Column(
            children: [
              Icon(icon, color: color, size: 20),
              Text('$count', style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(label, style: const TextStyle(fontSize: 10)),
            ],
          ),
        ),
      ),
    );
  }
}