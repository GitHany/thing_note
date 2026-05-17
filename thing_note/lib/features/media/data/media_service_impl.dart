import 'package:flutter_sound/flutter_sound.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:thing_note/features/media/domain/media_service.dart';
import 'package:uuid/uuid.dart';

class MediaServiceImpl implements MediaService {
  final ImagePicker _imagePicker = ImagePicker();
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  FlutterSoundRecorder? _recorder;
  String? _currentRecordingPath;

  MediaServiceImpl() {
    _player.openPlayer();
  }

  @override
  Future<List<XFile>> pickPhotosFromGallery() async {
    return await _imagePicker.pickMultiImage();
  }

  @override
  Future<XFile?> pickPhotoFromCamera() async {
    return await _imagePicker.pickImage(source: ImageSource.camera);
  }

  @override
  Future<String?> recordAudio() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      return null;
    }

    _recorder = FlutterSoundRecorder();

    await _recorder!.openRecorder();
    await _recorder!.setSubscriptionDuration(const Duration(milliseconds: 100));

    final tempDir = await getTemporaryDirectory();
    final uuid = const Uuid().v4();
    _currentRecordingPath = '${tempDir.path}/audio_$uuid.aac';

    await _recorder!.startRecorder(
      toFile: _currentRecordingPath,
      codec: Codec.aacADTS,
    );

    return _currentRecordingPath;
  }

  @override
  Future<String?> stopRecording() async {
    if (_recorder == null || !_recorder!.isRecording) return null;

    final path = await _recorder!.stopRecorder();
    await _recorder!.closeRecorder();
    _recorder = null;

    return path;
  }

  void dispose() {
    _recorder?.closeRecorder();
    _player.closePlayer();
  }
}
