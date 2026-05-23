// Focus Music feature
// Version: 1.0
// Description: 专注音乐播放，帮助用户进入专注状态

class FocusPlaylist {
  final int? id;
  final String name;
  final String? description;
  final String category; // focus, relax, energize, meditation
  final int color;
  final int trackCount;
  final String? coverUrl;
  final bool isDefault;
  final String? createdAt;

  FocusPlaylist({
    this.id,
    required this.name,
    this.description,
    this.category = 'focus',
    this.color = 0xFF2196F3,
    this.trackCount = 0,
    this.coverUrl,
    this.isDefault = false,
    this.createdAt,
  });

  factory FocusPlaylist.fromMap(Map<String, dynamic> map) {
    return FocusPlaylist(
      id: map['id'] as int?,
      name: map['name'] as String,
      description: map['description'] as String?,
      category: map['category'] as String? ?? 'focus',
      color: map['color'] as int? ?? 0xFF2196F3,
      trackCount: map['track_count'] as int? ?? 0,
      coverUrl: map['cover_url'] as String?,
      isDefault: (map['is_default'] as int? ?? 0) == 1,
      createdAt: map['created_at'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'category': category,
      'color': color,
      'track_count': trackCount,
      'cover_url': coverUrl,
      'is_default': isDefault ? 1 : 0,
      'created_at': createdAt ?? DateTime.now().toIso8601String(),
    };
  }
}

class FocusTrack {
  final int? id;
  final String title;
  final String? artist;
  final String? filePath;
  final String? url; // streaming URL
  final int durationSeconds;
  final String category; // ambient, lofi, classical, nature, white_noise
  final int playCount;
  final bool isFavorite;
  final String? createdAt;

  FocusTrack({
    this.id,
    required this.title,
    this.artist,
    this.filePath,
    this.url,
    this.durationSeconds = 0,
    this.category = 'ambient',
    this.playCount = 0,
    this.isFavorite = false,
    this.createdAt,
  });

  factory FocusTrack.fromMap(Map<String, dynamic> map) {
    return FocusTrack(
      id: map['id'] as int?,
      title: map['title'] as String,
      artist: map['artist'] as String?,
      filePath: map['file_path'] as String?,
      url: map['url'] as String?,
      durationSeconds: map['duration_seconds'] as int? ?? 0,
      category: map['category'] as String? ?? 'ambient',
      playCount: map['play_count'] as int? ?? 0,
      isFavorite: (map['is_favorite'] as int? ?? 0) == 1,
      createdAt: map['created_at'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'artist': artist,
      'file_path': filePath,
      'url': url,
      'duration_seconds': durationSeconds,
      'category': category,
      'play_count': playCount,
      'is_favorite': isFavorite ? 1 : 0,
      'created_at': createdAt ?? DateTime.now().toIso8601String(),
    };
  }
}

class PlaybackState {
  final FocusTrack? currentTrack;
  final bool isPlaying;
  final double volume;
  final bool isShuffle;
  final bool isRepeat;
  final String? currentPlaylistId;
  final int positionSeconds;

  PlaybackState({
    this.currentTrack,
    this.isPlaying = false,
    this.volume = 0.7,
    this.isShuffle = false,
    this.isRepeat = false,
    this.currentPlaylistId,
    this.positionSeconds = 0,
  });

  PlaybackState copyWith({
    FocusTrack? currentTrack,
    bool? isPlaying,
    double? volume,
    bool? isShuffle,
    bool? isRepeat,
    String? currentPlaylistId,
    int? positionSeconds,
  }) {
    return PlaybackState(
      currentTrack: currentTrack ?? this.currentTrack,
      isPlaying: isPlaying ?? this.isPlaying,
      volume: volume ?? this.volume,
      isShuffle: isShuffle ?? this.isShuffle,
      isRepeat: isRepeat ?? this.isRepeat,
      currentPlaylistId: currentPlaylistId ?? this.currentPlaylistId,
      positionSeconds: positionSeconds ?? this.positionSeconds,
    );
  }
}