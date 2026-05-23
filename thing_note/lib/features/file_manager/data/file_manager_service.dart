import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:thing_note/features/file_manager/domain/file_manager_entry.dart';

class FileManagerService {
  /// Get the app's document directory
  Future<Directory> getAppDirectory() async {
    return await getApplicationDocumentsDirectory();
  }

  /// List files in a directory
  Future<List<FileManagerEntry>> listFiles(String path) async {
    final dir = Directory(path);
    if (!await dir.exists()) return [];

    final entries = <FileManagerEntry>[];
    await for (final entity in dir.list()) {
      final stat = await entity.stat();
      entries.add(FileManagerEntry(
        name: p.basename(entity.path),
        path: entity.path,
        isDirectory: stat.type == FileSystemEntityType.directory,
        size: stat.type == FileSystemEntityType.file ? stat.size : null,
        modifiedAt: stat.modified,
      ));
    }

    // Sort: directories first, then by name
    entries.sort((a, b) {
      if (a.isDirectory && !b.isDirectory) return -1;
      if (!a.isDirectory && b.isDirectory) return 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    return entries;
  }

  /// Calculate storage statistics
  Future<FileStorageStats> calculateStorageStats() async {
    final appDir = await getApplicationDocumentsDirectory();
    final stats = [0, 0, 0, 0, 0, 0]; // [fileCount, photoCount, videoCount, audioCount, documentCount, backupCount]

    await _calculateDirectoryStats(appDir, stats);

    return FileStorageStats(
      totalSize: 0,
      fileCount: stats[0],
      photoCount: stats[1],
      videoCount: stats[2],
      audioCount: stats[3],
      documentCount: stats[4],
      backupCount: stats[5],
    );
  }

  Future<void> _calculateDirectoryStats(Directory dir, List<int> stats) async {
    int fileCount = 0;
    int photoCount = 0;
    int videoCount = 0;
    int audioCount = 0;
    int documentCount = 0;
    int backupCount = 0;

    await for (final entity in dir.list(recursive: true)) {
      if (entity is File) {
        final name = entity.path.toLowerCase();

        fileCount++;
        if (name.endsWith('.jpg') || name.endsWith('.png') || name.endsWith('.jpeg')) {
          photoCount++;
        } else if (name.endsWith('.mp4') || name.endsWith('.mov') || name.endsWith('.avi')) {
          videoCount++;
        } else if (name.endsWith('.m4a') || name.endsWith('.mp3') || name.endsWith('.aac')) {
          audioCount++;
        } else if (name.endsWith('.pdf') || name.endsWith('.doc') || name.endsWith('.docx')) {
          documentCount++;
        } else if (name.endsWith('.zip') || name.endsWith('.tar')) {
          backupCount++;
        }
      }
    }

    stats[0] = fileCount;
    stats[1] = photoCount;
    stats[2] = videoCount;
    stats[3] = audioCount;
    stats[4] = documentCount;
    stats[5] = backupCount;
  }

  /// Delete a file
  Future<bool> deleteFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Delete a directory
  Future<bool> deleteDirectory(String path) async {
    try {
      final dir = Directory(path);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Clear temporary files
  Future<int> clearTempFiles() async {
    final appDir = await getApplicationDocumentsDirectory();
    int deletedCount = 0;

    await for (final entity in appDir.list()) {
      if (entity is File) {
        final name = entity.path.toLowerCase();
        if (name.contains('temp') || name.contains('cache')) {
          try {
            await entity.delete();
            deletedCount++;
          } catch (_) {}
        }
      }
    }

    return deletedCount;
  }

  /// Rename a file
  Future<bool> renameFile(String path, String newName) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        final newPath = file.parent.path + Platform.pathSeparator + newName;
        await file.rename(newPath);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Get file info
  Future<FileManagerEntry?> getFileInfo(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        final stat = await file.stat();
        return FileManagerEntry(
          name: file.path.split(Platform.pathSeparator).last,
          path: file.path,
          isDirectory: false,
          size: stat.size,
          modifiedAt: stat.modified,
        );
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}

final fileManagerServiceProvider = Provider<FileManagerService>((ref) {
  return FileManagerService();
});