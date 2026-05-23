/// Record merge configuration
class RecordMergeConfig {
  final List<int> sourceRecordIds;
  final int targetRecordId;
  final bool keepPhotos;
  final bool keepAudio;
  final bool keepVideo;
  final bool keepDocuments;
  final bool mergeTags;
  final bool mergeLocation;
  final String? notePrefix;

  RecordMergeConfig({
    required this.sourceRecordIds,
    required this.targetRecordId,
    this.keepPhotos = true,
    this.keepAudio = true,
    this.keepVideo = true,
    this.keepDocuments = true,
    this.mergeTags = true,
    this.mergeLocation = true,
    this.notePrefix,
  });
}

/// Merge result summary
class MergeResult {
  final int targetRecordId;
  final int sourceRecordsMerged;
  final int photosAdded;
  final int audioAdded;
  final int videoAdded;
  final int documentsAdded;
  final List<String> tagsMerged;
  final bool locationUpdated;
  final DateTime mergedAt;

  MergeResult({
    required this.targetRecordId,
    required this.sourceRecordsMerged,
    this.photosAdded = 0,
    this.audioAdded = 0,
    this.videoAdded = 0,
    this.documentsAdded = 0,
    this.tagsMerged = const [],
    this.locationUpdated = false,
    required this.mergedAt,
  });

  int get totalAttachmentsAdded => photosAdded + audioAdded + videoAdded + documentsAdded;
}

/// Merge preview showing what will be merged
class MergePreview {
  final int targetRecordId;
  final String targetNote;
  final List<int> sourceRecordIds;
  final int totalPhotos;
  final int totalAudio;
  final int totalVideo;
  final int totalDocuments;
  final List<String> tagsToMerge;
  final double? targetLatitude;
  final double? targetLongitude;

  MergePreview({
    required this.targetRecordId,
    required this.targetNote,
    required this.sourceRecordIds,
    this.totalPhotos = 0,
    this.totalAudio = 0,
    this.totalVideo = 0,
    this.totalDocuments = 0,
    this.tagsToMerge = const [],
    this.targetLatitude,
    this.targetLongitude,
  });
}

/// Merge conflict resolution
enum MergeConflictResolution {
  keepTarget,
  keepSource,
  mergeBoth,
}