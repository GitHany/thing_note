import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:thing_note/features/report/data/report_service.dart';

class ReportScreen extends ConsumerStatefulWidget {
  const ReportScreen({super.key});

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> {
  ReportType _selectedType = ReportType.daily;
  DateTime _selectedDate = DateTime.now();
  Report? _generatedReport;
  bool _isGenerating = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('数据分析报告'),
        actions: [
          if (_generatedReport != null)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _shareReport,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              title: '报告类型',
              child: SegmentedButton<ReportType>(
                segments: const [
                  ButtonSegment(value: ReportType.daily, label: Text('日报')),
                  ButtonSegment(value: ReportType.weekly, label: Text('周报')),
                  ButtonSegment(value: ReportType.monthly, label: Text('月报')),
                ],
                selected: {_selectedType},
                onSelectionChanged: (selected) {
                  setState(() {
                    _selectedType = selected.first;
                    _generatedReport = null;
                  });
                },
              ),
            ),
            const SizedBox(height: 16),
            _buildSection(
              title: '选择日期',
              child: InkWell(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today),
                      const SizedBox(width: 12),
                      Text(
                        _formatDate(_selectedDate),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isGenerating ? null : _generateReport,
                icon: _isGenerating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.analytics),
                label: Text(_isGenerating ? '生成中...' : '生成报告'),
              ),
            ),
            if (_generatedReport != null) ...[
              const SizedBox(height: 24),
              _buildSection(
                title: '报告预览',
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _generatedReport!.title,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        _buildStatRow('📊 记录数量', '${_generatedReport!.recordCount}'),
                        _buildStatRow('⏱️ 总时长', _formatDuration(_generatedReport!.totalDurationSec)),
                        _buildStatRow('📷 照片', '${_generatedReport!.photoCount}'),
                        _buildStatRow('🎥 视频', '${_generatedReport!.videoCount}'),
                        if (_generatedReport!.moodAverage != null)
                          _buildStatRow('😊 情绪', '${_generatedReport!.moodAverage!.toStringAsFixed(1)}/5'),
                        if (_generatedReport!.topThingNames.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          const Text('🏷️ 最常用事情', style: TextStyle(fontWeight: FontWeight.bold)),
                          ...(_generatedReport!.topThingNames.take(5).map((item) =>
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text('  ${item.name}: ${item.count}次'),
                              ))),
                        ],
                        if (_generatedReport!.topTags.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          const Text('🏷️ 最常用标签', style: TextStyle(fontWeight: FontWeight.bold)),
                          ...(_generatedReport!.topTags.take(5).map((item) =>
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text('  ${item.name}: ${item.count}次'),
                              ))),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _exportAsText,
                      icon: const Icon(Icons.text_snippet),
                      label: const Text('导出文本'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _shareReport,
                      icon: const Icon(Icons.share),
                      label: const Text('分享报告'),
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

  Widget _buildSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Widget _buildStatRow(String icon, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Text(icon),
          const SizedBox(width: 8),
          Text(value, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('yyyy年MM月dd日').format(date);
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    if (hours > 0) {
      return '$hours小时$minutes分钟';
    }
    return '$minutes分钟';
  }

  void _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() {
        _selectedDate = date;
        _generatedReport = null;
      });
    }
  }

  Future<void> _generateReport() async {
    setState(() {
      _isGenerating = true;
    });

    final service = ref.read(reportServiceProvider);
    Report report;

    switch (_selectedType) {
      case ReportType.daily:
        report = await service.generateDailyReport(_selectedDate);
        break;
      case ReportType.weekly:
        final weekStart = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
        report = await service.generateWeeklyReport(weekStart);
        break;
      case ReportType.monthly:
        report = await service.generateMonthlyReport(_selectedDate.year, _selectedDate.month);
        break;
    }

    setState(() {
      _generatedReport = report;
      _isGenerating = false;
    });
  }

  Future<void> _exportAsText() async {
    if (_generatedReport == null) return;

    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/report_${DateTime.now().millisecondsSinceEpoch}.txt');
      await file.writeAsString(_generatedReport!.toFormattedString());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('报告已保存到: ${file.path}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出失败: $e')),
        );
      }
    }
  }

  Future<void> _shareReport() async {
    if (_generatedReport == null) return;

    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/report_${DateTime.now().millisecondsSinceEpoch}.txt');
      await file.writeAsString(_generatedReport!.toFormattedString());

      await Share.shareXFiles(
        [XFile(file.path)],
        text: _generatedReport!.title,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('分享失败: $e')),
        );
      }
    }
  }
}

enum ReportType { daily, weekly, monthly }