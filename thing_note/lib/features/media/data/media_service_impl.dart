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
  bool _isPlayerOpen = false;

  MediaServiceImpl() {
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    try {
      await _player.openPlayer();
      _isPlayerOpen = true;
    } catch (e) {
      _isPlayerOpen = false;
    }
  }

  @override
  Future<List<XFile>> pickPhotosFromGallery() async {
    return await _imagePicker.pickMultiImage(
      imageQuality: 85,
      maxWidth: 1920,
      maxHeight: 1920,
    );
  }

  @override
  Future<XFile?> pickPhotoFromCamera() async {
    return await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      maxWidth: 1920,
      maxHeight: 1920,
    );
  }

  @override
  Future<String?> recordAudio() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      return null;
    }

    if (_recorder != null && _recorder!.isRecording) {
      await _recorder!.stopRecorder();
    }
    _recorder?.closeRecorder();
    _recorder = null;

    _recorder = FlutterSoundRecorder();

    try {
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
    } catch (e) {
      _recorder?.closeRecorder();
      _recorder = null;
      return null;
    }
  }

  @override
  Future<String?> stopRecording() async {
    if (_recorder == null) return null;

    try {
      if (_recorder!.isRecording) {
        final path = await _recorder!.stopRecorder();
        await _recorder!.closeRecorder();
        _recorder = null;
        return path;
      } else {
        await _recorder!.closeRecorder();
        _recorder = null;
        return null;
      }
    } catch (e) {
      try {
        await _recorder!.closeRecorder();
      } catch (_) {}
      _recorder = null;
      return null;
    }
  }

  Future<void> dispose() async {
    try {
      if (_recorder != null) {
        if (_recorder!.isRecording) {
          await _recorder!.stopRecorder();
        }
        await _recorder!.closeRecorder();
        _recorder = null;
      }
    } catch (_) {
      _recorder = null;
    }

    if (_isPlayerOpen) {
      try {
        await _player.closePlayer();
        _isPlayerOpen = false;
      } catch (_) {}
    }
  }
}