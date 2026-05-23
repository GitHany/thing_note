import 'dart:io';
import 'dart:ui' show Rect;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrService {
  final TextRecognizer _textRecognizer = TextRecognizer();

  Future<String> recognizeText(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final recognizedTexts = await _textRecognizer.processImage(inputImage);
      
      if (recognizedTexts.text.isEmpty) {
        return '未识别到文字';
      }
      
      return recognizedTexts.text;
    } catch (e) {
      return 'OCR 识别失败: $e';
    }
  }

  Future<List<TextBlockResult>> recognizeBlocks(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final recognizedTexts = await _textRecognizer.processImage(inputImage);
      
      return recognizedTexts.blocks.map((block) {
        return TextBlockResult(
          text: block.text,
          boundingBox: block.boundingBox,
          lines: block.lines.map((line) => line.text).toList(),
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> extractInfo(String text) async {
    // Extract common patterns
    final Map<String, dynamic> info = {};
    
    // Extract phone numbers
    final phoneRegex = RegExp(r'[\d]{3}-?[\d]{4}-?[\d]{4}');
    final phones = phoneRegex.allMatches(text).map((m) => m.group(0)!).toList();
    if (phones.isNotEmpty) info['phones'] = phones;
    
    // Extract emails
    final emailRegex = RegExp(r'[\w.-]+@[\w.-]+\.\w+');
    final emails = emailRegex.allMatches(text).map((m) => m.group(0)!).toList();
    if (emails.isNotEmpty) info['emails'] = emails;
    
    // Extract URLs
    final urlRegex = RegExp(r'https?://[^\s]+');
    final urls = urlRegex.allMatches(text).map((m) => m.group(0)!).toList();
    if (urls.isNotEmpty) info['urls'] = urls;
    
    return info;
  }

  void dispose() {
    _textRecognizer.close();
  }
}

class TextBlockResult {
  final String text;
  final Rect boundingBox;
  final List<String> lines;

  TextBlockResult({
    required this.text,
    required this.boundingBox,
    required this.lines,
  });
}

final ocrServiceProvider = Provider<OcrService>((ref) {
  return OcrService();
});