import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:thing_note/features/ocr/domain/ocr_service.dart';

class OcrScreen extends ConsumerStatefulWidget {
  const OcrScreen({super.key});

  @override
  ConsumerState<OcrScreen> createState() => _OcrScreenState();
}

class _OcrScreenState extends ConsumerState<OcrScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  String _recognizedText = '';
  bool _isProcessing = false;
  Map<String, dynamic> _extractedInfo = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('文字识别 (OCR)'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image selection
            if (_selectedImage != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  _selectedImage!,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 16),
            ],
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('拍照'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('相册'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Process button
            if (_selectedImage != null)
              ElevatedButton(
                onPressed: _isProcessing ? null : _processImage,
                child: _isProcessing 
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('识别文字'),
              ),
            const SizedBox(height: 24),
            // Extracted info
            if (_extractedInfo.isNotEmpty) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('提取的信息', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      if (_extractedInfo['phones'] != null)
                        _InfoRow(label: '电话', values: _extractedInfo['phones']),
                      if (_extractedInfo['emails'] != null)
                        _InfoRow(label: '邮箱', values: _extractedInfo['emails']),
                      if (_extractedInfo['urls'] != null)
                        _InfoRow(label: '链接', values: _extractedInfo['urls']),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            // Recognized text
            if (_recognizedText.isNotEmpty) ...[
              const Text('识别结果', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(_recognizedText),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _copyToClipboard(),
                      icon: const Icon(Icons.copy),
                      label: const Text('复制'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _createRecord(),
                      icon: const Icon(Icons.add),
                      label: const Text('创建记录'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
        _recognizedText = '';
        _extractedInfo = {};
      });
    }
  }

  Future<void> _processImage() async {
    if (_selectedImage == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final ocrService = ref.read(ocrServiceProvider);
      final text = await ocrService.recognizeText(_selectedImage!);
      final info = await ocrService.extractInfo(text);

      setState(() {
        _recognizedText = text;
        _extractedInfo = info;
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('识别失败: $e')),
        );
      }
    }
  }

  void _copyToClipboard() {
    // TODO: Implement clipboard copy
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已复制到剪贴板')),
    );
  }

  void _createRecord() {
    // TODO: Navigate to record creation with OCR text
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('创建记录功能开发中')),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final List<String> values;

  const _InfoRow({required this.label, required this.values});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Text('$label:', style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(
            child: Text(values.join(', ')),
          ),
        ],
      ),
    );
  }
}