import 'dart:io';
import 'package:path_provider/path_provider.dart';

class FileStorage {
  static Future<Directory> get appDocumentsDirectory async {
    final dir = await getApplicationDocumentsDirectory();
    return Directory('${dir.path}/thing_note');
  }

  static Future<Directory> get recordsDirectory async {
    final appDir = await appDocumentsDirectory;
    return Directory('${appDir.path}/records');
  }

  static Future<Directory> get audioDirectory async {
    final recordsDir = await recordsDirectory;
    return Directory('${recordsDir.path}/audio');
  }

  static Future<Directory> get photosDirectory async {
    final recordsDir = await recordsDirectory;
    return Directory('${recordsDir.path}/photos');
  }

  static Future<String> saveAudioFile(String sourcePath) async {
    final audioDir = await audioDirectory;
    if (!await audioDir.exists()) {
      await audioDir.create(recursive: true);
    }
    final fileName = 'audio_${DateTime.now().millisecondsSinceEpoch}.aac';
    final destFile = File('${audioDir.path}/$fileName');
    await File(sourcePath).copy(destFile.path);
    return destFile.path;
  }

  static Future<String> savePhotoFile(String sourcePath) async {
    final photosDir = await photosDirectory;
    if (!await photosDir.exists()) {
      await photosDir.create(recursive: true);
    }
    final ext = sourcePath.split('.').last.toLowerCase();
    final fileName = 'photo_${DateTime.now().millisecondsSinceEpoch}.$ext';
    final destFile = File('${photosDir.path}/$fileName');
    await File(sourcePath).copy(destFile.path);
    return destFile.path;
  }

  static Future<String> saveAudioBytes(List<int> bytes, String ext) async {
    final audioDir = await audioDirectory;
    if (!await audioDir.exists()) {
      await audioDir.create(recursive: true);
    }
    final fileName = 'audio_${DateTime.now().millisecondsSinceEpoch}.$ext';
    final destFile = File('${audioDir.path}/$fileName');
    await destFile.writeAsBytes(bytes);
    return destFile.path;
  }

  static Future<String> savePhotoBytes(List<int> bytes, String ext) async {
    final photosDir = await photosDirectory;
    if (!await photosDir.exists()) {
      await photosDir.create(recursive: true);
    }
    final fileName = 'photo_${DateTime.now().millisecondsSinceEpoch}.$ext';
    final destFile = File('${photosDir.path}/$fileName');
    await destFile.writeAsBytes(bytes);
    return destFile.path;
  }

  static Future<void> deleteFile(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  static Future<bool> fileExists(String path) async {
    return File(path).exists();
  }
}