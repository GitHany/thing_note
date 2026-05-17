import 'package:image_picker/image_picker.dart';

abstract class MediaService {
  Future<List<XFile>> pickPhotosFromGallery();
  Future<XFile?> pickPhotoFromCamera();
  Future<String?> recordAudio();
  Future<String?> stopRecording();
}
