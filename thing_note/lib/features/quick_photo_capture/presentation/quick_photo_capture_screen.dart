import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:thing_note/features/record/domain/episode_record.dart';
import 'package:thing_note/features/record/presentation/providers/record_provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

// Quick Photo Capture State Provider
final quickPhotoCapturedProvider = StateProvider<File?>((ref) => null);
final quickPhotoOcrTextProvider = StateProvider<String>((ref) => '');

class QuickPhotoCaptureScreen extends ConsumerStatefulWidget {
  const QuickPhotoCaptureScreen({super.key});

  @override
  ConsumerState<QuickPhotoCaptureScreen> createState() => _QuickPhotoCaptureScreenState();
}

class _QuickPhotoCaptureScreenState extends ConsumerState<QuickPhotoCaptureScreen> {
  File? _capturedImage;
  String? _ocrText;
  bool _isProcessing = false;
  bool _isSaving = false;
  final _noteController = TextEditingController();
  final _picker = ImagePicker();
  final _textRecognizer = TextRecognizer();

  @override
  void dispose() {
    _noteController.dispose();
    // TextRecognizer in google_mlkit_text_recognition doesn't require manual disposal
    super.dispose();
  }

  Future<void> _capturePhoto(ImageSource source) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (photo != null) {
        setState(() {
          _capturedImage = File(photo.path);
          _isProcessing = true;
        });

        await _processImage(photo.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('拍照失败: $e')),
        );
      }
    }
  }

  Future<void> _processImage(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      setState(() {
        _ocrText = recognizedText.text;
        _noteController.text = recognizedText.text;
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('文字识别失败: $e')),
        );
      }
    }
  }

  Future<void> _saveRecord() async {
    if (_capturedImage == null) return;

    setState(() => _isSaving = true);

    try {
      // Copy image to app documents directory
      final appDir = await getApplicationDocumentsDirectory();
      final photosDir = Directory(path.join(appDir.path, 'photos'));
      if (!await photosDir.exists()) {
        await photosDir.create(recursive: true);
      }

      final fileName = 'photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedPath = path.join(photosDir.path, fileName);
      await _capturedImage!.copy(savedPath);

      // Create record
      final record = EpisodeRecord(
        occurredAt: DateTime.now(),
        durationSec: 0,
        note: _noteController.text,
        photoPaths: [savedPath],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await ref.read(recordNotifierProvider.notifier).create(record);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('记录已保存')),
        );
        ref.invalidate(recordListProvider);
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('快速拍照'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (_capturedImage != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                setState(() {
                  _capturedImage = null;
                  _ocrText = null;
                  _noteController.clear();
                });
              },
            ),
        ],
      ),
      body: _capturedImage == null
          ? _buildCaptureOptions()
          : _buildImagePreview(),
    );
  }

  Widget _buildCaptureOptions() {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.camera_alt,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  '拍照并自动识别文字',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  '拍照后自动提取图片中的文字',
                  style: TextStyle(color: Theme.of(context).colorScheme.outline),
                ),
              ],
            ),
          ),
        ),
        _buildQuickActions(),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _capturePhoto(ImageSource.camera),
              icon: const Icon(Icons.camera_alt),
              label: const Text('拍照'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _capturePhoto(ImageSource.gallery),
              icon: const Icon(Icons.photo_library),
              label: const Text('从相册选择'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildTips(),
        ],
      ),
    );
  }

  Widget _buildTips() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '使用技巧',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text('• 确保文字清晰可见'),
            const Text('• 保持光线充足'),
            const Text('• 尽量减少背景干扰'),
            const Text('• 文字方向保持水平'),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    return Column(
      children: [
        // Image Preview
        Expanded(
          flex: 2,
          child: Stack(
            children: [
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.black,
                ),
                child: Image.file(
                  _capturedImage!,
                  fit: BoxFit.contain,
                ),
              ),
              if (_isProcessing)
                Container(
                  color: Colors.black54,
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: Colors.white),
                        SizedBox(height: 16),
                        Text(
                          '正在识别文字...',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        // OCR Result & Save
        Expanded(
          flex: 2,
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.text_fields,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '识别结果',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const Spacer(),
                    if (_ocrText != null && _ocrText!.isNotEmpty)
                      TextButton.icon(
                        onPressed: () {
                          // Copy to clipboard
                        },
                        icon: const Icon(Icons.copy, size: 16),
                        label: const Text('复制'),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: TextField(
                        controller: _noteController,
                        maxLines: null,
                        expands: true,
                        decoration: const InputDecoration(
                          hintText: '编辑识别的文字...',
                          border: InputBorder.none,
                        ),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _capturedImage = null;
                            _ocrText = null;
                            _noteController.clear();
                          });
                        },
                        child: const Text('重新拍摄'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveRecord,
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('保存记录'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
