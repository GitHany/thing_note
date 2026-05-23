import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

/// Compression result
class CompressionResult {
  final String originalPath;
  final String compressedPath;
  final int originalSize;
  final int compressedSize;
  final double ratio;

  CompressionResult({
    required this.originalPath,
    required this.compressedPath,
    required this.originalSize,
    required this.compressedSize,
    required this.ratio,
  });
}

/// Media compression settings
class CompressionSettings {
  final int maxWidth;
  final int maxHeight;
  final int quality;
  final CompressFormat format;

  CompressionSettings({
    this.maxWidth = 1920,
    this.maxHeight = 1080,
    this.quality = 80,
    this.format = CompressFormat.jpeg,
  });
}

enum ImageCompressFormat { jpeg, png, webp }

enum MediaType { image, video, audio }

class MediaCompressorService {
  /// Compress an image file
  Future<CompressionResult?> compressImage({
    required String path,
    CompressionSettings? settings,
  }) async {
    settings ??= CompressionSettings();

    final file = File(path);
    if (!await file.exists()) return null;

    final originalSize = await file.length();
    final result = await FlutterImageCompress.compressWithFile(
      path,
      minWidth: settings.maxWidth,
      minHeight: settings.maxHeight,
      quality: settings.quality,
      format: _toCompressFormat(settings.format),
    );

    if (result == null) return null;

    final dir = file.parent.path;
    final name = file.path.split(Platform.pathSeparator).last;
    final ext = settings.format == CompressFormat.png ? '.png' : '.jpg';
    final compressedPath = '$dir/compressed_$name$ext';

    final compressedFile = File(compressedPath);
    await compressedFile.writeAsBytes(result);

    final compressedSize = result.length;
    final ratio = (1 - compressedSize / originalSize) * 100;

    return CompressionResult(
      originalPath: path,
      compressedPath: compressedPath,
      originalSize: originalSize,
      compressedSize: compressedSize,
      ratio: ratio,
    );
  }

  /// Batch compress multiple images
  Future<List<CompressionResult>> batchCompressImages({
    required List<String> paths,
    CompressionSettings? settings,
    Function(int, int)? onProgress,
  }) async {
    final results = <CompressionResult>[];

    for (var i = 0; i < paths.length; i++) {
      final result = await compressImage(path: paths[i], settings: settings);
      if (result != null) {
        results.add(result);
      }
      onProgress?.call(i + 1, paths.length);
    }

    return results;
  }

  /// Estimate compressed size
  Future<int> estimateCompressedSize(String path, {int quality = 80}) async {
    final file = File(path);
    if (!await file.exists()) return 0;

    final bytes = await file.readAsBytes();
    final compressed = await FlutterImageCompress.compressWithList(
      bytes,
      quality: quality,
    );

    return compressed.length;
  }

  CompressFormat _toCompressFormat(CompressFormat format) {
    switch (format) {
      case CompressFormat.jpeg:
        return CompressFormat.jpeg;
      case CompressFormat.png:
        return CompressFormat.png;
      case CompressFormat.webp:
        return CompressFormat.webp;
      case CompressFormat.heic:
        return CompressFormat.heic;
    }
  }
}

final mediaCompressorServiceProvider = Provider<MediaCompressorService>((ref) {
  return MediaCompressorService();
});