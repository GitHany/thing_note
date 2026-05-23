import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/core/database/database_provider.dart';
import 'package:thing_note/features/mood_music_recommendation/domain/mood_music_model.dart';

final moodPlaylistsProvider = FutureProvider<List<MoodPlaylist>>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  final results = await db.query('mood_music_playlists', orderBy: 'use_count DESC');
  return results.map((m) => MoodPlaylist.fromMap(m)).toList();
});

final selectedMoodProvider = StateProvider<MoodType?>((ref) => null);

final recommendedTracksProvider = FutureProvider<List<String>>((ref) async {
  final mood = ref.watch(selectedMoodProvider);
  if (mood == null) return [];
  
  // 模拟音乐推荐 - 基于心情类型返回推荐列表
  final recommendations = _getRecommendationsForMood(mood);
  return recommendations;
});

List<String> _getRecommendationsForMood(MoodType mood) {
  switch (mood) {
    case MoodType.happy:
      return ['Happy - Pharell Williams', 'Good Time - Owl City', 'Walking on Sunshine'];
    case MoodType.calm:
      return ['Weightless - Marconi Union', 'Clair de Lune', 'Gymnopédie No.1'];
    case MoodType.sad:
      return ['Someone Like You - Adele', 'Fix You - Coldplay', 'Let Her Go'];
    case MoodType.anxious:
      return ['Weightless', 'Deep Peace', 'Calm'];
    case MoodType.energetic:
      return ['Eye of the Tiger', 'Lose Yourself', 'Stronger'];
    case MoodType.tired:
      return ['Coffee', 'Lofi Hip Hop', 'Rain Sounds'];
  }
}

class MoodMusicNotifier extends StateNotifier<AsyncValue<List<MoodPlaylist>>> {
  final Ref ref;
  
  MoodMusicNotifier(this.ref) : super(const AsyncValue.loading()) {
    _loadPlaylists();
  }
  
  Future<void> _loadPlaylists() async {
    state = const AsyncValue.loading();
    try {
      final db = await ref.read(databaseProvider.future);
      final results = await db.query('mood_music_playlists', orderBy: 'use_count DESC');
      state = AsyncValue.data(results.map((m) => MoodPlaylist.fromMap(m)).toList());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
  
  Future<void> addPlaylist(MoodPlaylist playlist) async {
    final db = await ref.read(databaseProvider.future);
    await db.insert('mood_music_playlists', playlist.toMap()..remove('id'));
    await _loadPlaylists();
  }
  
  Future<void> incrementUseCount(int playlistId) async {
    final db = await ref.read(databaseProvider.future);
    await db.rawUpdate(
      'UPDATE mood_music_playlists SET use_count = use_count + 1 WHERE id = ?',
      [playlistId],
    );
    await _loadPlaylists();
  }
}

final moodMusicNotifierProvider =
    StateNotifierProvider<MoodMusicNotifier, AsyncValue<List<MoodPlaylist>>>((ref) {
  return MoodMusicNotifier(ref);
});