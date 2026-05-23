import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/focus_music/data/focus_music_provider.dart';
import 'package:thing_note/features/focus_music/domain/focus_music.dart';

class FocusMusicScreen extends ConsumerWidget {
  const FocusMusicScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configsAsync = ref.watch(focusMusicConfigsProvider);
    final playerState = ref.watch(musicPlayerStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('专注音乐'),
      ),
      body: Column(
        children: [
          // Player Controls
          if (playerState.currentTrackId != null)
            _buildPlayerControls(context, ref, playerState),

          // Volume Slider
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.volume_down),
                Expanded(
                  child: Slider(
                    value: playerState.volume.toDouble(),
                    min: 0,
                    max: 100,
                    onChanged: (value) {
                      ref.read(musicPlayerStateProvider.notifier).setVolume(value.toInt());
                    },
                  ),
                ),
                const Icon(Icons.volume_up),
              ],
            ),
          ),

          // Categories
          Expanded(
            child: configsAsync.when(
              data: (configs) => _buildMusicList(context, ref, configs, playerState),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerControls(BuildContext context, WidgetRef ref, MusicPlayerState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).primaryColor.withOpacity(0.1),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              if (state.isPlaying) {
                ref.read(musicPlayerStateProvider.notifier).pause();
              } else {
                ref.read(musicPlayerStateProvider.notifier).play(state.currentTrackId!);
              }
            },
            icon: Icon(
              state.isPlaying ? Icons.pause_circle : Icons.play_circle,
              size: 48,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '正在播放',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                Text(
                  state.currentTrackId ?? '',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => ref.read(musicPlayerStateProvider.notifier).pause(),
            icon: const Icon(Icons.stop),
          ),
        ],
      ),
    );
  }

  Widget _buildMusicList(
    BuildContext context,
    WidgetRef ref,
    List<FocusMusicConfig> configs,
    MusicPlayerState playerState,
  ) {
    final categories = <String, List<FocusMusicConfig>>{};
    for (final config in configs) {
      final cat = config.category ?? 'other';
      categories.putIfAbsent(cat, () => []).add(config);
    }

    return ListView(
      children: categories.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _getCategoryName(entry.key),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            ...entry.value.map((config) {
              final isPlaying = playerState.isPlaying &&
                  playerState.currentTrackId == config.url;
              return ListTile(
                leading: Icon(
                  isPlaying ? Icons.pause_circle : Icons.play_circle_outline,
                  color: isPlaying ? Colors.green : null,
                ),
                title: Text(config.name),
                subtitle: Text('${config.volume}分钟'),
                onTap: () {
                  if (isPlaying) {
                    ref.read(musicPlayerStateProvider.notifier).pause();
                  } else {
                    ref.read(musicPlayerStateProvider.notifier).play(config.url ?? config.name);
                  }
                },
              );
            }),
          ],
        );
      }).toList(),
    );
  }

  String _getCategoryName(String category) {
    switch (category) {
      case 'nature':
        return '🌿 自然';
      case 'ambient':
        return '🎧 环境';
      case 'lofi':
        return '🎵 Lo-Fi';
      case 'classical':
        return '🎻 古典';
      default:
        return category;
    }
  }
}