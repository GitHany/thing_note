import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:thing_note/features/media_compressor/data/media_compressor_service.dart';

class MediaCompressorScreen extends ConsumerStatefulWidget {
  const MediaCompressorScreen({super.key});

  @override
  ConsumerState<MediaCompressorScreen> createState() =>
      _MediaCompressorScreenState();
}

class _MediaCompressorScreenState extends ConsumerState<MediaCompressorScreen> {
  final List<String> _selectedFiles = [];
  final List<CompressionResult> _results = [];
  bool _isCompressing = false;
  double _progress = 0;

  int _quality = 80;
  int _maxWidth = 1920;
  final int _maxHeight = 1080;

  Future<void> _selectFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
    );

    if (result != null) {
      setState(() {
        _selectedFiles.clear();
        _selectedFiles.addAll(result.files.map((f) => f.path!));
      });
    }
  }

  Future<void> _compressFiles() async {
    if (_selectedFiles.isEmpty) return;

    setState(() {
      _isCompressing = true;
      _progress = 0;
      _results.clear();
    });

    try {
      final service = ref.read(mediaCompressorServiceProvider);
      final settings = CompressionSettings(
        quality: _quality,
        maxWidth: _maxWidth,
        maxHeight: _maxHeight,
      );

      final results = await service.batchCompressImages(
        paths: _selectedFiles,
        settings: settings,
        onProgress: (current, total) {
          setState(() {
            _progress = current / total;
          });
        },
      );

      setState(() => _results.addAll(results));
    } finally {
      setState(() => _isCompressing = false);
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Media Compressor'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Settings card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Compression Settings',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text('Quality:'),
                        Expanded(
                          child: Slider(
                            value: _quality.toDouble(),
                            min: 10,
                            max: 100,
                            divisions: 9,
                            label: '$_quality%',
                            onChanged: (value) {
                              setState(() => _quality = value.toInt());
                            },
                          ),
                        ),
                        Text('$_quality%'),
                      ],
                    ),
                    Row(
                      children: [
                        const Text('Max Width:'),
                        Expanded(
                          child: Slider(
                            value: _maxWidth.toDouble(),
                            min: 480,
                            max: 3840,
                            divisions: 7,
                            label: '$_maxWidth',
                            onChanged: (value) {
                              setState(() => _maxWidth = value.toInt());
                            },
                          ),
                        ),
                        Text('$_maxWidth'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // File selection
            OutlinedButton.icon(
              onPressed: _selectFiles,
              icon: const Icon(Icons.attach_file),
              label: Text(
                _selectedFiles.isEmpty
                    ? 'Select Images'
                    : '${_selectedFiles.length} files selected',
              ),
            ),
            const SizedBox(height: 8),

            // Selected files list
            if (_selectedFiles.isNotEmpty) ...[
              Container(
                height: 150,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.builder(
                  itemCount: _selectedFiles.length,
                  itemBuilder: (context, index) {
                    final path = _selectedFiles[index];
                    final name = path.split(Platform.pathSeparator).last;
                    return ListTile(
                      dense: true,
                      leading: const Icon(Icons.image),
                      title: Text(name, overflow: TextOverflow.ellipsis),
                      trailing: IconButton(
                        icon: const Icon(Icons.close, size: 16),
                        onPressed: () {
                          setState(() => _selectedFiles.removeAt(index));
                        },
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Compress button
              FilledButton.icon(
                onPressed: _isCompressing ? null : _compressFiles,
                icon: _isCompressing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.compress),
                label: Text(_isCompressing ? 'Compressing...' : 'Compress'),
              ),
            ],

            // Progress bar
            if (_isCompressing) ...[
              const SizedBox(height: 16),
              LinearProgressIndicator(value: _progress),
              const SizedBox(height: 8),
              Center(child: Text('${(_progress * 100).toInt()}% complete')),
            ],

            // Results
            if (_results.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                'Results',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ...(_results.map((result) => Card(
                    child: ListTile(
                      leading: const Icon(Icons.check_circle, color: Colors.green),
                      title: Text(
                        result.originalPath.split(Platform.pathSeparator).last,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '${_formatBytes(result.originalSize)} → '
                        '${_formatBytes(result.compressedSize)} '
                        '(${result.ratio.toStringAsFixed(1)}% saved)',
                      ),
                    ),
                  ))),
            ],
          ],
        ),
      ),
    );
  }
}