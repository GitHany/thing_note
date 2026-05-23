import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/mood_music_recommendation/data/mood_music_provider.dart';
import 'package:thing_note/features/mood_music_recommendation/domain/mood_music_model.dart';

class MoodMusicScreen extends ConsumerWidget {
  const MoodMusicScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMood = ref.watch(selectedMoodProvider);
    final recommendedTracksAsync = ref.watch(recommendedTracksProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('心情音乐'),
      ),
      body: Column(
        children: [
          // Mood Selector
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '选择当前心情',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: MoodType.values.map((mood) {
                    final isSelected = selectedMood == mood;
                    return GestureDetector(
                      onTap: () {
                        ref.read(selectedMoodProvider.notifier).state = mood;
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Theme.of(context).primaryColor
                              : Colors.grey[200],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(mood.emoji, style: const TextStyle(fontSize: 20)),
                            const SizedBox(width: 8),
                            Text(
                              mood.displayName,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.black87,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          
          const Divider(),
          
          // Recommendations
          Expanded(
            child: recommendedTracksAsync.when(
              data: (tracks) => _buildTrackList(tracks, ref),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackList(List<String> tracks, WidgetRef ref) {
    if (tracks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.music_note, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              '选择心情获取推荐',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tracks.length,
      itemBuilder: (context, index) {
        final track = tracks[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
              child: const Icon(Icons.music_note, color: Colors.deepPurple),
            ),
            title: Text(track),
            subtitle: const Text('推荐曲目'),
            trailing: IconButton(
              icon: const Icon(Icons.play_circle_filled),
              iconSize: 36,
              color: Theme.of(context).primaryColor,
              onPressed: () => _playTrack(context, track),
            ),
          ),
        );
      },
    );
  }

  void _playTrack(BuildContext context, String track) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('正在播放: $track')),
    );
  }
}