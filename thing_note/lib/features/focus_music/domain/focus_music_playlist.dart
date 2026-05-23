class FocusMusicPlaylist {
  final int? id;
  final String playlistName;
  final String? musicStyle;
  final String? trackList;
  final int trackCount;
  final bool isActive;
  final int useCount;
  final DateTime createdAt;

  FocusMusicPlaylist({
    this.id,
    required this.playlistName,
    this.musicStyle,
    this.trackList,
    this.trackCount = 0,
    this.isActive = false,
    this.useCount = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  static const musicStyles = [
    {'value': 'lofi', 'name': 'Lo-Fi', 'icon': '🎵', 'desc': '轻松背景音乐'},
    {'value': 'ambient', 'name': 'Ambient', 'icon': '🌿', 'desc': '自然环境音'},
    {'value': 'classical', 'name': '古典', 'icon': '🎻', 'desc': '经典古典音乐'},
    {'value': 'jazz', 'name': 'Jazz', 'icon': '🎷', 'desc': '爵士放松音乐'},
    {'value': 'nature', 'name': '自然音', 'icon': '🌊', 'desc': '雨声/海浪/森林'},
    {'value': 'white_noise', 'name': '白噪音', 'icon': '📻', 'desc': '纯白噪音'},
    {'value': 'binaural', 'name': '双耳节拍', 'icon': '🧠', 'desc': '专注力增强'},
    {'value': 'silent', 'name': '静音', 'icon': '🤫', 'desc': '无音乐专注'},
  ];

  static const defaultPlaylists = [
    {
      'name': '深度工作',
      'style': 'lofi',
      'tracks': ['Rainy Cafe', 'Lofi Study Beats', 'Midnight Focus'],
    },
    {
      'name': '创意灵感',
      'style': 'ambient',
      'tracks': ['Forest Rain', 'Ocean Waves', 'Meditation Bell'],
    },
    {
      'name': '学习备考',
      'style': 'classical',
      'tracks': ['Bach Piano', 'Mozart Sonata', 'Beethoven Moonlight'],
    },
    {
      'name': '轻松休息',
      'style': 'jazz',
      'tracks': ['Smooth Jazz', 'Piano Jazz', 'Bossanova'],
    },
  ];

  List<String> get tracks {
    if (trackList == null || trackList!.isEmpty) return [];
    return trackList!.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList();
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'playlist_name': playlistName,
      'music_style': musicStyle,
      'track_list': trackList,
      'track_count': trackCount,
      'is_active': isActive ? 1 : 0,
      'use_count': useCount,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory FocusMusicPlaylist.fromMap(Map<String, dynamic> map) {
    return FocusMusicPlaylist(
      id: map['id'] as int?,
      playlistName: map['playlist_name'] as String,
      musicStyle: map['music_style'] as String?,
      trackList: map['track_list'] as String?,
      trackCount: map['track_count'] as int? ?? 0,
      isActive: (map['is_active'] as int?) == 1,
      useCount: map['use_count'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
