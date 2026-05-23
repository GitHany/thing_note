import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/music_listening/data/music_listening_repository.dart';
import 'package:thing_note/features/music_listening/domain/music_listening.dart';

class MusicListeningScreen extends ConsumerStatefulWidget {
  const MusicListeningScreen({super.key});

  @override
  ConsumerState<MusicListeningScreen> createState() => _MusicListeningScreenState();
}

class _MusicListeningScreenState extends ConsumerState<MusicListeningScreen> {
  @override
  Widget build(BuildContext context) {
    final listeningAsync = ref.watch(musicListeningProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('音乐播放记录'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddMusicDialog(context),
          ),
        ],
      ),
      body: listeningAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('错误: $e')),
        data: (listening) {
          if (listening.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.music_note, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('暂无音乐记录', style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => _showAddMusicDialog(context),
                    child: const Text('添加记录'),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: listening.length,
            itemBuilder: (context, index) => _MusicListeningCard(item: listening[index]),
          );
        },
      ),
    );
  }

  void _showAddMusicDialog(BuildContext context) {
    final titleController = TextEditingController();
    final artistController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加音乐记录'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: '歌曲名称'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: artistController,
                decoration: const InputDecoration(labelText: '艺术家（可选）'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.trim().isNotEmpty) {
                final now = DateTime.now();
                final item = MusicListening(
                  title: titleController.text.trim(),
                  artist: artistController.text.trim().isEmpty ? null : artistController.text.trim(),
                  listenedAt: now,
                  createdAt: now,
                );
                ref.read(musicListeningProvider.notifier).addMusicListening(item);
                Navigator.pop(context);
              }
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }
}

class _MusicListeningCard extends ConsumerWidget {
  final MusicListening item;

  const _MusicListeningCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.purple,
          child: Icon(Icons.music_note, color: Colors.white),
        ),
        title: Text(item.title),
        subtitle: Text(item.artist ?? '未知艺术家'),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: () => ref.read(musicListeningProvider.notifier).deleteMusicListening(item.id!),
        ),
      ),
    );
  }
}