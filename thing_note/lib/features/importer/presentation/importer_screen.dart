import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:thing_note/features/importer/data/importer_service.dart';

class ImporterScreen extends ConsumerStatefulWidget {
  const ImporterScreen({super.key});

  @override
  ConsumerState<ImporterScreen> createState() => _ImporterScreenState();
}

class _ImporterScreenState extends ConsumerState<ImporterScreen> {
  bool _isImporting = false;
  String? _selectedFile;
  ImportResult? _result;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('数据导入'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              title: '支持格式',
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FormatItem(
                    icon: Icons.code,
                    title: 'JSON',
                    description: '从其他应用导出的 JSON 格式',
                  ),
                  SizedBox(height: 12),
                  _FormatItem(
                    icon: Icons.table_chart,
                    title: 'CSV',
                    description: '逗号分隔值文件，常见于电子表格',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: '导入文件',
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!, width: 2, style: BorderStyle.solid),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.upload_file, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        const Text(
                          '点击选择文件',
                          style: TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '支持 .json 和 .csv 文件',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _selectFile,
                          icon: const Icon(Icons.folder_open),
                          label: Text(_selectedFile ?? '选择文件'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _selectedFile != null && !_isImporting ? _startImport : null,
                          child: _isImporting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('开始导入'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (_result != null) ...[
              const SizedBox(height: 24),
              _buildSection(
                title: '导入结果',
                child: Card(
                  color: _result!.success ? Colors.green[50] : Colors.red[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _result!.success ? Icons.check_circle : Icons.error,
                              color: _result!.success ? Colors.green : Colors.red,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _result!.message,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _ResultChip(
                              label: '成功',
                              value: _result!.importedCount.toString(),
                              color: Colors.green,
                            ),
                            const SizedBox(width: 12),
                            _ResultChip(
                              label: '失败',
                              value: _result!.failedCount.toString(),
                              color: Colors.red,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            _buildSection(
              title: 'CSV 格式示例',
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const SelectableText(
                  'occurred_at,duration_sec,note,thing_name,tags\n'
                  '2024-01-15T10:30:00,3600,会议讨论项目进展,工作,会议,重要\n'
                  '2024-01-15T14:00:00,1800,健身训练,运动,健身',
                  style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: 'JSON 格式示例',
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const SelectableText(
                  '{\n'
                  '  "records": [\n'
                  '    {\n'
                  '      "occurred_at": "2024-01-15T10:30:00",\n'
                  '      "duration_sec": 3600,\n'
                  '      "note": "会议讨论项目进展",\n'
                  '      "thing_name": "工作",\n'
                  '      "tags": "会议,重要"\n'
                  '    }\n'
                  '  ]\n'
                  '}',
                  style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  Future<void> _selectFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json', 'csv'],
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _selectedFile = result.files.first.path;
        _result = null;
      });
    }
  }

  Future<void> _startImport() async {
    if (_selectedFile == null) return;

    setState(() {
      _isImporting = true;
      _result = null;
    });

    final service = ref.read(importerServiceProvider);
    final extension = _selectedFile!.toLowerCase();

    ImportResult result;
    if (extension.endsWith('.csv')) {
      result = await service.importFromCsv(_selectedFile!);
    } else {
      result = await service.importFromJson(_selectedFile!);
    }

    setState(() {
      _isImporting = false;
      _result = result;
    });
  }
}

class _FormatItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _FormatItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.blue),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(description, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          ],
        ),
      ],
    );
  }
}

class _ResultChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _ResultChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(color: color)),
          const SizedBox(width: 8),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}