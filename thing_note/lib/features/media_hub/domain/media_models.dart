import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 媒体文件类型
enum MediaType { photo, video, audio, document }

extension MediaTypeExtension on MediaType {
  Color get color {
    switch (this) {
      case MediaType.photo: return Colors.blue;
      case MediaType.video: return Colors.red;
      case MediaType.audio: return Colors.green;
      case MediaType.document: return Colors.orange;
    }
  }
}

/// 媒体文件模型
class MediaFile {
  final String id;
  final String path;
  final String name;
  final MediaType type;
  final DateTime createdAt;
  final int? durationSec; // for audio/video
  final int? linkedRecordId;
  final int sizeBytes;

  const MediaFile({
    required this.id,
    required this.path,
    required this.name,
    required this.type,
    required this.createdAt,
    this.durationSec,
    this.linkedRecordId,
    required this.sizeBytes,
  });

  String get formattedSize {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// 媒体分类统计
class MediaStats {
  final int photoCount;
  final int videoCount;
  final int audioCount;
  final int documentCount;
  final int totalSize;

  const MediaStats({
    required this.photoCount,
    required this.videoCount,
    required this.audioCount,
    required this.documentCount,
    required this.totalSize,
  });

  int get totalCount => photoCount + videoCount + audioCount + documentCount;
}

/// 媒体中心 Provider
final mediaHubProvider = StateNotifierProvider<MediaHubNotifier, AsyncValue<List<MediaFile>>>((ref) {
  return MediaHubNotifier();
});

class MediaHubNotifier extends StateNotifier<AsyncValue<List<MediaFile>>> {
  MediaHubNotifier() : super(const AsyncValue.loading());

  Future<void> loadMedia({MediaType? type, int? recordId}) async {
    state = const AsyncValue.loading();
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      // 模拟数据
      state = AsyncValue.data([
        MediaFile(id: '1', path: '/path/1.jpg', name: 'photo1.jpg', type: MediaType.photo, createdAt: DateTime.now(), sizeBytes: 1024 * 500),
        MediaFile(id: '2', path: '/path/2.mp4', name: 'video1.mp4', type: MediaType.video, createdAt: DateTime.now(), durationSec: 120, sizeBytes: 1024 * 1024 * 10),
      ]);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteMedia(String id) async {
    state.whenData((files) {
      state = AsyncValue.data(files.where((f) => f.id != id).toList());
    });
  }
}

/// 媒体统计 Provider
final mediaStatsProvider = FutureProvider<MediaStats>((ref) async {
  await Future.delayed(const Duration(milliseconds: 200));
  return const MediaStats(photoCount: 156, videoCount: 23, audioCount: 45, documentCount: 12, totalSize: 524288000);
});