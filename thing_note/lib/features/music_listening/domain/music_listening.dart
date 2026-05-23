/// 音乐播放记录数据模型
class MusicListening {
  final int? id;
  final String title;
  final String? artist;
  final String? album;
  final String? albumArtUrl;
  final int durationSeconds;
  final String? source;
  final String? url;
  final DateTime listenedAt;
  final DateTime createdAt;

  const MusicListening({
    this.id,
    required this.title,
    this.artist,
    this.album,
    this.albumArtUrl,
    this.durationSeconds = 0,
    this.source,
    this.url,
    required this.listenedAt,
    required this.createdAt,
  });

  MusicListening copyWith({
    int? id,
    String? title,
    String? artist,
    String? album,
    String? albumArtUrl,
    int? durationSeconds,
    String? source,
    String? url,
    DateTime? listenedAt,
    DateTime? createdAt,
  }) {
    return MusicListening(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      albumArtUrl: albumArtUrl ?? this.albumArtUrl,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      source: source ?? this.source,
      url: url ?? this.url,
      listenedAt: listenedAt ?? this.listenedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String get formattedDuration {
    final minutes = durationSeconds ~/ 60;
    final seconds = durationSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'artist': artist,
      'album': album,
      'album_art_url': albumArtUrl,
      'duration_seconds': durationSeconds,
      'source': source,
      'url': url,
      'listened_at': listenedAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory MusicListening.fromMap(Map<String, dynamic> map) {
    return MusicListening(
      id: map['id'] as int?,
      title: map['title'] as String,
      artist: map['artist'] as String?,
      album: map['album'] as String?,
      albumArtUrl: map['album_art_url'] as String?,
      durationSeconds: map['duration_seconds'] as int? ?? 0,
      source: map['source'] as String?,
      url: map['url'] as String?,
      listenedAt: DateTime.parse(map['listened_at'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}