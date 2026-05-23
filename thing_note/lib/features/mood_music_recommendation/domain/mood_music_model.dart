class MoodPlaylist {
  final int id;
  final String moodType;
  final String playlistName;
  final List<String> trackUris;
  final int useCount;
  final DateTime createdAt;

  MoodPlaylist({
    required this.id,
    required this.moodType,
    required this.playlistName,
    required this.trackUris,
    this.useCount = 0,
    required this.createdAt,
  });

  factory MoodPlaylist.fromMap(Map<String, dynamic> map) {
    return MoodPlaylist(
      id: map['id'] as int,
      moodType: map['mood_type'] as String,
      playlistName: map['playlist_name'] as String,
      trackUris: (map['track_uris'] as String?)?.split(',') ?? [],
      useCount: map['use_count'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'mood_type': moodType,
      'playlist_name': playlistName,
      'track_uris': trackUris.join(','),
      'use_count': useCount,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class MoodMusicRecommendation {
  final String moodType;
  final List<String> suggestedTracks;
  final double confidence;
  final String reason;

  MoodMusicRecommendation({
    required this.moodType,
    required this.suggestedTracks,
    required this.confidence,
    required this.reason,
  });
}

enum MoodType {
  happy,
  calm,
  sad,
  anxious,
  energetic,
  tired,
}

extension MoodTypeExtension on MoodType {
  String get displayName {
    switch (this) {
      case MoodType.happy:
        return '开心';
      case MoodType.calm:
        return '平静';
      case MoodType.sad:
        return '悲伤';
      case MoodType.anxious:
        return '焦虑';
      case MoodType.energetic:
        return '充满能量';
      case MoodType.tired:
        return '疲惫';
    }
  }

  String get emoji {
    switch (this) {
      case MoodType.happy:
        return '😊';
      case MoodType.calm:
        return '😌';
      case MoodType.sad:
        return '😢';
      case MoodType.anxious:
        return '😰';
      case MoodType.energetic:
        return '🤩';
      case MoodType.tired:
        return '😴';
    }
  }
}