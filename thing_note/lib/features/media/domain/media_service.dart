import 'package:image_picker/image_picker.dart';

abstract class MediaService {
  Future<List<XFile>> pickPhotosFromGallery();
  Future<XFile?> pickPhotoFromCamera();
  Future<List<XFile>> pickVideosFromGallery();
  Future<List<XFile>> pickAudioFromFiles();
  Future<String?> recordAudio();
  Future<String?> stopRecording();
}
