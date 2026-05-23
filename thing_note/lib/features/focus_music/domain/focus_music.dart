/// Focus Music 数据模型
class FocusMusicConfig {
  final int? id;
  final String name;
  final String? category; // nature, ambient, classical, lofi
  final String? url;
  final bool isLooping;
  final int volume;

  const FocusMusicConfig({
    this.id,
    required this.name,
    this.category,
    this.url,
    this.isLooping = true,
    this.volume = 70,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'category': category,
      'url': url,
      'is_looping': isLooping ? 1 : 0,
      'volume': volume,
    };
  }
}

/// Focus Music 会话
class FocusMusicSession {
  static const List<String> sceneTypes = ['focus', 'relax', 'meditation', 'sleep', 'work'];

  final int? id;
  final String sceneType;
  final String? playlistName;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int durationMinutes;

  const FocusMusicSession({
    this.id,
    required this.sceneType,
    this.playlistName,
    required this.startedAt,
    this.endedAt,
    this.durationMinutes = 0,
  });

  FocusMusicSession copyWith({
    int? id,
    String? sceneType,
    String? playlistName,
    DateTime? startedAt,
    DateTime? endedAt,
    int? durationMinutes,
  }) {
    return FocusMusicSession(
      id: id ?? this.id,
      sceneType: sceneType ?? this.sceneType,
      playlistName: playlistName ?? this.playlistName,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      durationMinutes: durationMinutes ?? this.durationMinutes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'scene_type': sceneType,
      'playlist_name': playlistName,
      'started_at': startedAt.toIso8601String(),
      'ended_at': endedAt?.toIso8601String(),
      'duration_minutes': durationMinutes,
    };
  }

  factory FocusMusicSession.fromMap(Map<String, dynamic> map) {
    return FocusMusicSession(
      id: map['id'] as int?,
      sceneType: map['scene_type'] as String,
      playlistName: map['playlist_name'] as String?,
      startedAt: DateTime.parse(map['started_at'] as String),
      endedAt: map['ended_at'] != null ? DateTime.parse(map['ended_at'] as String) : null,
      durationMinutes: map['duration_minutes'] as int? ?? 0,
    );
  }
}

class MusicSession {
  final int? id;
  final DateTime startedAt;
  final DateTime? endedAt;
  final String? playlistId;
  final int durationMinutes;

  const MusicSession({
    this.id,
    required this.startedAt,
    this.endedAt,
    this.playlistId,
    this.durationMinutes = 0,
  });
}