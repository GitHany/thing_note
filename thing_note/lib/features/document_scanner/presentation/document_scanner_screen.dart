import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:thing_note/l10n/generated/app_localizations.dart';

class DocumentScannerScreen extends ConsumerStatefulWidget {
  const DocumentScannerScreen({super.key});

  @override
  ConsumerState<DocumentScannerScreen> createState() =>
      _DocumentScannerScreenState();
}

class _DocumentScannerScreenState
    extends ConsumerState<DocumentScannerScreen> {
  final List<_ScannedDocument> _documents = [];
  final ImagePicker _picker = ImagePicker();
  final TextRecognizer _textRecognizer = TextRecognizer();
  bool _isProcessing = false;
  String? _extractedText;

  @override
  void dispose() {
    _textRecognizer.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 600;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.documentScanner),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => _showHistory(),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(isWideScreen ? 24 : 16),
        children: [
          // Scan options
          Row(
            children: [
              Expanded(
                child: _ScanOptionCard(
                  icon: Icons.camera_alt,
                  title: '拍照扫描',
                  onTap: () => _scanDocument(ImageSource.camera),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ScanOptionCard(
                  icon: Icons.photo_library,
                  title: '从相册选择',
                  onTap: () => _scanDocument(ImageSource.gallery),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Processing indicator
          if (_isProcessing) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context)!.processing,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      '正在识别文档内容...',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Extracted text preview
          if (_extractedText != null && !_isProcessing) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.extractedText,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.copy),
                              onPressed: _copyText,
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: _createRecord,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Divider(),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 300),
                      child: SingleChildScrollView(
                        child: Text(
                          _extractedText!,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Scanned documents
          if (_documents.isNotEmpty) ...[
            Text(
              AppLocalizations.of(context)!.scannedDocuments,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ...(_documents.map((doc) => _buildDocumentCard(doc))),
          ],
        ],
      ),
    );
  }

  Widget _buildDocumentCard(_ScannedDocument document) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _openDocument(document),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(document.imagePath),
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.image),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      document.title,
                      style: Theme.of(context).textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      _formatDateTime(document.scannedAt),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                    Text(
                      '${document.textLength} 字符',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              PopupMenuButton(
                itemBuilder: (context) => [
                  PopupMenuItem(
                    child: const ListTile(
                      leading: Icon(Icons.edit),
                      title: Text('编辑'),
                      contentPadding: EdgeInsets.zero,
                    ),
                    onTap: () {},
                  ),
                  PopupMenuItem(
                    child: const ListTile(
                      leading: Icon(Icons.delete),
                      title: Text('删除'),
                      contentPadding: EdgeInsets.zero,
                    ),
                    onTap: () {
                      setState(() => _documents.remove(document));
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _scanDocument(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image == null) return;

      setState(() => _isProcessing = true);

      final inputImage = InputImage.fromFilePath(image.path);
      final RecognizedText recognizedText =
          await _textRecognizer.processImage(inputImage);

      setState(() {
        _extractedText = recognizedText.text;
        _documents.insert(
          0,
          _ScannedDocument(
            imagePath: image.path,
            title: '扫描文档 ${_documents.length + 1}',
            extractedText: recognizedText.text,
            scannedAt: DateTime.now(),
            textLength: recognizedText.text.length,
          ),
        );
        _isProcessing = false;
      });
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('扫描失败: $e')),
        );
      }
    }
  }

  void _copyText() {
    // Copy to clipboard
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已复制到剪贴板')),
    );
  }

  void _createRecord() {
    // Create record from extracted text
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('正在创建记录...')),
    );
  }

  void _showHistory() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ListTile(
            leading: Icon(Icons.history),
            title: Text('扫描历史'),
          ),
          if (_documents.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('暂无扫描记录'),
            ),
        ],
      ),
    );
  }

  void _openDocument(_ScannedDocument document) {
    setState(() => _extractedText = document.extractedText);
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _ScannedDocument {
  final String imagePath;
  final String title;
  final String extractedText;
  final DateTime scannedAt;
  final int textLength;

  _ScannedDocument({
    required this.imagePath,
    required this.title,
    required this.extractedText,
    required this.scannedAt,
    required this.textLength,
  });
}

class _ScanOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _ScanOptionCard({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(
                icon,
                size: 48,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 8),
              Text(title),
            ],
          ),
        ),
      ),
    );
  }
}