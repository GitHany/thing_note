import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/focus_music/domain/focus_music.dart';

/// 音乐配置列表
final focusMusicConfigsProvider = FutureProvider<List<FocusMusicConfig>>((ref) async {
  // TODO: 从数据库获取
  return defaultMusicConfigs;
});

const defaultMusicConfigs = [
  FocusMusicConfig(name: '雨声', category: 'nature', url: 'rain'),
  FocusMusicConfig(name: '海浪', category: 'nature', url: 'ocean'),
  FocusMusicConfig(name: '森林', category: 'nature', url: 'forest'),
  FocusMusicConfig(name: '咖啡馆', category: 'ambient', url: 'cafe'),
  FocusMusicConfig(name: '白噪音', category: 'ambient', url: 'white'),
  FocusMusicConfig(name: 'Lo-Fi', category: 'lofi', url: 'lofi'),
];

/// 当前播放状态
final musicPlayerStateProvider = StateNotifierProvider<MusicPlayerNotifier, MusicPlayerState>((ref) {
  return MusicPlayerNotifier();
});

class MusicPlayerState {
  final bool isPlaying;
  final String? currentTrackId;
  final int volume;

  const MusicPlayerState({
    this.isPlaying = false,
    this.currentTrackId,
    this.volume = 70,
  });

  MusicPlayerState copyWith({
    bool? isPlaying,
    String? currentTrackId,
    int? volume,
  }) {
    return MusicPlayerState(
      isPlaying: isPlaying ?? this.isPlaying,
      currentTrackId: currentTrackId ?? this.currentTrackId,
      volume: volume ?? this.volume,
    );
  }
}

class MusicPlayerNotifier extends StateNotifier<MusicPlayerState> {
  MusicPlayerNotifier() : super(const MusicPlayerState());

  void play(String trackId) {
    state = state.copyWith(isPlaying: true, currentTrackId: trackId);
  }

  void pause() {
    state = state.copyWith(isPlaying: false);
  }

  void setVolume(int volume) {
    state = state.copyWith(volume: volume);
  }
}