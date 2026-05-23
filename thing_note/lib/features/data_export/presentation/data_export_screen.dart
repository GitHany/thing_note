import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/data_export/data/data_export_repository.dart';
import 'package:thing_note/features/data_export/domain/data_export.dart';

final dataExportRepoProvider = Provider((ref) => DataExportRepository(ref));

class DataExportScreen extends ConsumerStatefulWidget {
  const DataExportScreen({super.key});

  @override
  ConsumerState<DataExportScreen> createState() => _DataExportScreenState();
}

class _DataExportScreenState extends ConsumerState<DataExportScreen> {
  String _format = 'json';
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  bool _isExporting = false;
  ExportResult? _result;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('数据导出'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFormatSelector(),
            const SizedBox(height: 16),
            _buildDateRange(),
            const SizedBox(height: 16),
            _buildPreview(),
            const SizedBox(height: 24),
            _buildExportButton(),
            if (_result != null) ...[
              const SizedBox(height: 16),
              _buildResult(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFormatSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('导出格式', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('JSON'),
                  selected: _format == 'json',
                  onSelected: (selected) {
                    if (selected) setState(() => _format = 'json');
                  },
                ),
                ChoiceChip(
                  label: const Text('CSV'),
                  selected: _format == 'csv',
                  onSelected: (selected) {
                    if (selected) setState(() => _format = 'csv');
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateRange() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('日期范围', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    title: const Text('开始日期'),
                    subtitle: Text('${_startDate.year}-${_startDate.month.toString().padLeft(2, '0')}-${_startDate.day.toString().padLeft(2, '0')}'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () => _selectDate(true),
                  ),
                ),
                Expanded(
                  child: ListTile(
                    title: const Text('结束日期'),
                    subtitle: Text('${_endDate.year}-${_endDate.month.toString().padLeft(2, '0')}-${_endDate.day.toString().padLeft(2, '0')}'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () => _selectDate(false),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('导出预览', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            FutureBuilder<Map<String, dynamic>>(
              future: _getPreview(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final preview = snapshot.data!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.description, size: 16),
                        const SizedBox(width: 4),
                        Text('记录数量: ${preview['count'] ?? 0}'),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(Icons.timer, size: 16),
                        const SizedBox(width: 4),
                        Text('总时长: ${preview['total_duration'] ?? 0} 秒'),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(Icons.category, size: 16),
                        const SizedBox(width: 4),
                        Text('事情种类: ${preview['unique_things'] ?? 0}'),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportButton() {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: _isExporting ? null : _export,
        icon: _isExporting
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.download),
        label: Text(_isExporting ? '导出中...' : '开始导出'),
      ),
    );
  }

  Widget _buildResult() {
    if (_result == null) return const SizedBox();

    if (_result!.success) {
      return Card(
        color: Colors.green.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 8),
                  Text('导出成功', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              Text('文件路径: ${_result!.filePath}'),
              Text('记录数量: ${_result!.recordCount}'),
              Text('文件大小: ${(_result!.fileSizeBytes / 1024).toStringAsFixed(2)} KB'),
            ],
          ),
        ),
      );
    } else {
      return Card(
        color: Colors.red.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.error, color: Colors.red),
              const SizedBox(width: 8),
              Expanded(child: Text('导出失败: ${_result!.errorMessage}')),
            ],
          ),
        ),
      );
    }
  }

  Future<void> _selectDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<Map<String, dynamic>> _getPreview() async {
    final repo = ref.read(dataExportRepoProvider);
    return repo.getExportPreview(startDate: _startDate, endDate: _endDate);
  }

  Future<void> _export() async {
    setState(() => _isExporting = true);
    final repo = ref.read(dataExportRepoProvider);
    _result = await repo.exportRecords(
      format: _format,
      startDate: _startDate,
      endDate: _endDate,
    );
    setState(() => _isExporting = false);
  }
}