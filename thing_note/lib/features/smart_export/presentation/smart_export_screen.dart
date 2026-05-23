import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/smart_export/data/export_service.dart';
import 'package:thing_note/features/smart_export/domain/export_models.dart';

class SmartExportScreen extends ConsumerStatefulWidget {
  const SmartExportScreen({super.key});

  @override
  ConsumerState<SmartExportScreen> createState() => _SmartExportScreenState();
}

class _SmartExportScreenState extends ConsumerState<SmartExportScreen> {
  ExportFormat _selectedFormat = ExportFormat.csv;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _includePhotos = true;
  bool _includeAudio = false;
  bool _includeLocation = true;
  bool _includeTags = true;

  @override
  Widget build(BuildContext context) {
    final profilesAsync = ref.watch(exportProfilesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('智能导出'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => _showExportHistory(context),
            tooltip: '导出历史',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 快速预设
            const Text(
              '快速预设',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            profilesAsync.when(
              data: (profiles) => SizedBox(
                height: 80,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _QuickPresetCard(
                      icon: Icons.table_chart,
                      label: 'CSV 导出',
                      onTap: () => setState(() => _selectedFormat = ExportFormat.csv),
                    ),
                    _QuickPresetCard(
                      icon: Icons.data_object,
                      label: 'JSON 备份',
                      onTap: () => setState(() => _selectedFormat = ExportFormat.json),
                    ),
                    _QuickPresetCard(
                      icon: Icons.description,
                      label: 'Markdown',
                      onTap: () => setState(() => _selectedFormat = ExportFormat.markdown),
                    ),
                    ...profiles.map((p) => _QuickPresetCard(
                      icon: Icons.bookmark,
                      label: p.name,
                      onTap: () => _loadProfile(p),
                    )),
                  ],
                ),
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 24),
            // 格式选择
            const Text(
              '导出格式',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ExportFormat.values.map((format) => ChoiceChip(
                label: Text(format.label),
                selected: _selectedFormat == format,
                onSelected: (selected) {
                  if (selected) setState(() => _selectedFormat = format);
                },
              )).toList(),
            ),
            const SizedBox(height: 24),
            // 日期范围
            const Text(
              '日期范围',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today),
                    label: Text(_startDate != null ? _formatDate(_startDate!) : '开始日期'),
                    onPressed: () => _selectDate(context, true),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('至'),
                ),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today),
                    label: Text(_endDate != null ? _formatDate(_endDate!) : '结束日期'),
                    onPressed: () => _selectDate(context, false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // 包含内容
            const Text(
              '包含内容',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('照片'),
                    value: _includePhotos,
                    onChanged: (value) => setState(() => _includePhotos = value),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('音频'),
                    value: _includeAudio,
                    onChanged: (value) => setState(() => _includeAudio = value),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('位置信息'),
                    value: _includeLocation,
                    onChanged: (value) => setState(() => _includeLocation = value),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('标签'),
                    value: _includeTags,
                    onChanged: (value) => setState(() => _includeTags = value),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // 导出按钮
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _startExport,
                icon: const Icon(Icons.download),
                label: const Text('开始导出'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _saveAsPreset,
                icon: const Icon(Icons.save),
                label: const Text('保存为预设'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _loadProfile(ExportProfile profile) {
    setState(() {
      _selectedFormat = ExportFormat.fromValue(profile.format);
    });
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final date = await showDatePicker(
      context: context,
      initialDate: isStart ? (_startDate ?? DateTime.now()) : (_endDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (date != null) {
      setState(() {
        if (isStart) {
          _startDate = date;
        } else {
          _endDate = date;
        }
      });
    }
  }

  void _startExport() async {
    final service = ref.read(smartExportServiceProvider);
    
    final options = ExportOptions(
      includePhotos: _includePhotos,
      includeAudio: _includeAudio,
      includeLocation: _includeLocation,
      includeTags: _includeTags,
      startDate: _startDate,
      endDate: _endDate,
    );

    final result = await service.exportRecords(
      format: _selectedFormat,
      options: options,
    );

    await service.recordExport(_selectedFormat.value, 0, null);

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('导出成功'),
          content: SingleChildScrollView(
            child: SelectableText(result.substring(0, result.length.clamp(0, 1000))),
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
  }

  void _saveAsPreset() {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('保存预设'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: '预设名称'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                final service = ref.read(smartExportServiceProvider);
                await service.createProfile(ExportProfile(
                  name: nameController.text,
                  format: _selectedFormat.value,
                ));
                ref.invalidate(exportProfilesProvider);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('预设已保存')),
                  );
                }
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _showExportHistory(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Consumer(
        builder: (context, ref, _) {
          final service = ref.watch(smartExportServiceProvider);
          return FutureBuilder<List<Map<String, dynamic>>>(
            future: service.getExportHistory(),
            builder: (context, snapshot) {
              final history = snapshot.data ?? [];
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Text('导出历史', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: history.isEmpty
                        ? const Center(child: Text('暂无导出历史'))
                        : ListView.builder(
                            itemCount: history.length,
                            itemBuilder: (context, index) {
                              final item = history[index];
                              return ListTile(
                                leading: const Icon(Icons.download),
                                title: Text(item['format']?.toString().toUpperCase() ?? '未知'),
                                subtitle: Text('${item['record_count']} 条记录'),
                                trailing: Text(_formatDate(DateTime.parse(item['created_at'] ?? ''))),
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day} ${date.hour}:${date.minute}';
  }
}

/// 快速预设卡片
class _QuickPresetCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickPresetCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 100,
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.blue),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(fontSize: 12), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}