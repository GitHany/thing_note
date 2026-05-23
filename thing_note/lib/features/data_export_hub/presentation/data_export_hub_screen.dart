import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class DataExportHubScreen extends ConsumerStatefulWidget {
  const DataExportHubScreen({super.key});

  @override
  ConsumerState<DataExportHubScreen> createState() => _DataExportHubScreenState();
}

class _DataExportHubScreenState extends ConsumerState<DataExportHubScreen> {
  String _selectedFormat = 'json';
  DateTimeRange? _dateRange;
  bool _includePhotos = true;
  bool _includeAudio = true;
  bool _includeLocation = true;
  bool _includeTags = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('数据导出中心'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildFormatSelector(),
            _buildDateRangeSelector(),
            _buildContentOptions(),
            _buildExportPreview(),
            _buildExportHistory(),
          ],
        ),
      ),
    );
  }

  Widget _buildFormatSelector() {
    final formats = [
      {'format': 'json', 'icon': Icons.data_object, 'label': 'JSON', 'desc': '通用数据格式'},
      {'format': 'csv', 'icon': Icons.table_chart, 'label': 'CSV', 'desc': '表格数据格式'},
      {'format': 'html', 'icon': Icons.web, 'label': 'HTML', 'desc': '网页格式'},
      {'format': 'md', 'icon': Icons.article, 'label': 'Markdown', 'desc': '文档格式'},
      {'format': 'pdf', 'icon': Icons.picture_as_pdf, 'label': 'PDF', 'desc': '便携文档格式'},
    ];

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '选择导出格式',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: formats.map((format) {
                final isSelected = _selectedFormat == format['format'];
                return ChoiceChip(
                  label: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        format['icon'] as IconData,
                        size: 24,
                        color: isSelected ? Colors.white : null,
                      ),
                      Text(format['label'] as String),
                    ],
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedFormat = format['format'] as String;
                    });
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateRangeSelector() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: const Icon(Icons.date_range),
        title: const Text('导出时间范围'),
        subtitle: Text(
          _dateRange != null
              ? '${_dateRange!.start.toString().substring(0, 10)} - ${_dateRange!.end.toString().substring(0, 10)}'
              : '全部时间',
        ),
        trailing: TextButton(
          onPressed: () => _selectDateRange(context),
          child: const Text('选择'),
        ),
      ),
    );
  }

  Widget _buildContentOptions() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '包含内容',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              title: const Text('照片和视频'),
              value: _includePhotos,
              onChanged: (value) {
                setState(() {
                  _includePhotos = value ?? true;
                });
              },
              secondary: const Icon(Icons.photo),
            ),
            CheckboxListTile(
              title: const Text('音频文件'),
              value: _includeAudio,
              onChanged: (value) {
                setState(() {
                  _includeAudio = value ?? true;
                });
              },
              secondary: const Icon(Icons.mic),
            ),
            CheckboxListTile(
              title: const Text('位置信息'),
              value: _includeLocation,
              onChanged: (value) {
                setState(() {
                  _includeLocation = value ?? true;
                });
              },
              secondary: const Icon(Icons.location_on),
            ),
            CheckboxListTile(
              title: const Text('标签数据'),
              value: _includeTags,
              onChanged: (value) {
                setState(() {
                  _includeTags = value ?? true;
                });
              },
              secondary: const Icon(Icons.label),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportPreview() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '导出预览',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () => _previewExport(),
                  child: const Text('预览'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildPreviewStat('记录数量', '1,234')),
                const SizedBox(width: 8),
                Expanded(child: _buildPreviewStat('预估大小', '~15 MB')),
                const SizedBox(width: 8),
                Expanded(child: _buildPreviewStat('预计时间', '~10 秒')),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _startExport(),
                icon: const Icon(Icons.download),
                label: const Text('开始导出'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewStat(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildExportHistory() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              '导出历史',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          _buildHistoryItem('2026-05-21 10:30', 'JSON', '15 MB'),
          _buildHistoryItem('2026-05-20 14:20', 'CSV', '8 MB'),
          _buildHistoryItem('2026-05-19 09:15', 'HTML', '25 MB'),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(String date, String format, String size) {
    return ListTile(
      leading: const Icon(Icons.description),
      title: Text('$format 导出'),
      subtitle: Text('$date - $size'),
      trailing: IconButton(
        icon: const Icon(Icons.download),
        onPressed: () {},
      ),
    );
  }

  void _selectDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
    );
    if (picked != null) {
      setState(() {
        _dateRange = picked;
      });
    }
  }

  void _previewExport() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('导出预览'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('记录列表：'),
            SizedBox(height: 8),
            Text('• 团队会议 (05-21 10:00)'),
            Text('• 健身记录 (05-21 07:00)'),
            Text('• 学习Flutter (05-20 20:00)'),
            Text('• ...'),
            SizedBox(height: 16),
            Text('包含附件：'),
            Text('• 照片: 89 张'),
            Text('• 音频: 12 个'),
            Text('• 视频: 5 个'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  void _startExport() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('正在导出...'),
          ],
        ),
      ),
    );

    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('导出完成！')),
      );
    }
  }
}