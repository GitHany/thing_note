import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/enhanced_export/data/enhanced_export_repository.dart';
import 'package:thing_note/features/enhanced_export/domain/export_models.dart';

class EnhancedExportScreen extends ConsumerStatefulWidget {
  const EnhancedExportScreen({super.key});

  @override
  ConsumerState<EnhancedExportScreen> createState() => _EnhancedExportScreenState();
}

class _EnhancedExportScreenState extends ConsumerState<EnhancedExportScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Export options
  DateTime? _startDate;
  DateTime? _endDate;
  ExportFormat _selectedFormat = ExportFormat.csv;
  bool _includePhotos = false;
  bool _includeAudio = false;
  bool _includeLocation = false;
  
  // State
  bool _isExporting = false;
  ExportResult? _lastResult;
  List<ExportTemplate> _templates = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadTemplates();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTemplates() async {
    final repo = ref.read(enhancedExportRepositoryProvider);
    _templates = await repo.getTemplates();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('增强导出'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '快速导出', icon: Icon(Icons.speed)),
            Tab(text: '自定义导出', icon: Icon(Icons.tune)),
            Tab(text: '模板', icon: Icon(Icons.description)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildQuickExportTab(),
          _buildCustomExportTab(),
          _buildTemplatesTab(),
        ],
      ),
    );
  }

  Widget _buildQuickExportTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '快速导出选项',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildDateRangeSelector(),
                  const SizedBox(height: 16),
                  const Text('导出格式'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: ExportFormat.values.map((format) {
                      return ChoiceChip(
                        label: Text(_getFormatName(format)),
                        selected: _selectedFormat == format,
                        onSelected: (s) => setState(() => _selectedFormat = format),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
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
                  SwitchListTile(
                    title: const Text('包含位置信息'),
                    value: _includeLocation,
                    onChanged: (v) => setState(() => _includeLocation = v),
                  ),
                  SwitchListTile(
                    title: const Text('包含照片路径'),
                    value: _includePhotos,
                    onChanged: (v) => setState(() => _includePhotos = v),
                  ),
                  SwitchListTile(
                    title: const Text('包含音频路径'),
                    value: _includeAudio,
                    onChanged: (v) => setState(() => _includeAudio = v),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (_lastResult != null) _buildLastResultCard(),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isExporting ? null : _performExport,
              icon: _isExporting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.download),
              label: Text(_isExporting ? '导出中...' : '开始导出'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomExportTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '高级筛选',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildDateRangeSelector(),
                  const SizedBox(height: 16),
                  const Text(
                    '时间范围',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      ActionChip(
                        label: const Text('今天'),
                        onPressed: () {
                          final now = DateTime.now();
                          setState(() {
                            _startDate = DateTime(now.year, now.month, now.day);
                            _endDate = now;
                          });
                        },
                      ),
                      ActionChip(
                        label: const Text('本周'),
                        onPressed: () {
                          final now = DateTime.now();
                          final weekStart = now.subtract(Duration(days: now.weekday - 1));
                          setState(() {
                            _startDate = DateTime(weekStart.year, weekStart.month, weekStart.day);
                            _endDate = now;
                          });
                        },
                      ),
                      ActionChip(
                        label: const Text('本月'),
                        onPressed: () {
                          final now = DateTime.now();
                          setState(() {
                            _startDate = DateTime(now.year, now.month, 1);
                            _endDate = now;
                          });
                        },
                      ),
                      ActionChip(
                        label: const Text('本年'),
                        onPressed: () {
                          final now = DateTime.now();
                          setState(() {
                            _startDate = DateTime(now.year, 1, 1);
                            _endDate = now;
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '输出格式',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildFormatSelector(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '数据内容',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _buildContentOptions(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isExporting ? null : _performExport,
              icon: _isExporting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.settings),
              label: Text(_isExporting ? '处理中...' : '自定义导出'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplatesTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '导出模板',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: _showAddTemplateDialog,
              ),
            ],
          ),
        ),
        if (_templates.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.description_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('暂无模板'),
                  const SizedBox(height: 8),
                  Text(
                    '创建模板以快速导出数据',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              itemCount: _templates.length,
              itemBuilder: (context, index) {
                final template = _templates[index];
                return _TemplateCard(
                  template: template,
                  onExport: () => _exportWithTemplate(template),
                  onSetDefault: () => _setDefaultTemplate(template),
                  onDelete: () => _deleteTemplate(template),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildDateRangeSelector() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _selectDate(true),
            icon: const Icon(Icons.calendar_today, size: 16),
            label: Text(_startDate != null ? _formatDate(_startDate!) : '开始日期'),
          ),
        ),
        const SizedBox(width: 8),
        const Text('至'),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _selectDate(false),
            icon: const Icon(Icons.calendar_today, size: 16),
            label: Text(_endDate != null ? _formatDate(_endDate!) : '结束日期'),
          ),
        ),
      ],
    );
  }

  Widget _buildFormatSelector() {
    return Column(
      children: ExportFormat.values.map((format) {
        return RadioListTile<ExportFormat>(
          title: Text(_getFormatName(format)),
          subtitle: Text(_getFormatDescription(format)),
          value: format,
          groupValue: _selectedFormat,
          onChanged: (v) => setState(() => _selectedFormat = v!),
        );
      }).toList(),
    );
  }

  Widget _buildContentOptions() {
    return Column(
      children: [
        const CheckboxListTile(
          title: Text('基本记录信息'),
          subtitle: Text('日期、时间、事件名称、时长'),
          value: true,
          onChanged: null,
        ),
        const CheckboxListTile(
          title: Text('备注内容'),
          value: true,
          onChanged: null,
        ),
        const CheckboxListTile(
          title: Text('标签信息'),
          value: true,
          onChanged: null,
        ),
        SwitchListTile(
          title: const Text('位置信息'),
          value: _includeLocation,
          onChanged: (v) => setState(() => _includeLocation = v),
        ),
        SwitchListTile(
          title: const Text('媒体文件路径'),
          value: _includePhotos || _includeAudio,
          onChanged: (v) {
            setState(() {
              _includePhotos = v;
              _includeAudio = v;
            });
          },
        ),
      ],
    );
  }

  Widget _buildLastResultCard() {
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
                Text(
                  '导出成功',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('记录数: ${_lastResult!.recordCount}'),
            Text('文件大小: ${_formatBytes(_lastResult!.fileSizeBytes)}'),
            Text('耗时: ${_lastResult!.duration.inSeconds}秒'),
            const SizedBox(height: 8),
            Text(
              '文件: ${_lastResult!.filePath}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (isStart ? _startDate : _endDate) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
        }
      });
    }
  }

  Future<void> _performExport() async {
    setState(() => _isExporting = true);
    
    final config = ExportConfig(
      startDate: _startDate,
      endDate: _endDate,
      format: _selectedFormat,
      includePhotos: _includePhotos,
      includeAudio: _includeAudio,
      includeLocation: _includeLocation,
    );
    
    final repo = ref.read(enhancedExportRepositoryProvider);
    _lastResult = await repo.export(config);
    
    setState(() => _isExporting = false);
    
    if (mounted) {
      if (_lastResult!.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出成功: ${_lastResult!.filePath}')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出失败: ${_lastResult!.errorMessage}')),
        );
      }
    }
  }

  void _showAddTemplateDialog() {
    final nameController = TextEditingController();
    ExportFormat format = ExportFormat.csv;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('创建导出模板'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: '模板名称'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<ExportFormat>(
                value: format,
                decoration: const InputDecoration(labelText: '导出格式'),
                items: ExportFormat.values.map((f) {
                  return DropdownMenuItem(
                    value: f,
                    child: Text(_getFormatName(f)),
                  );
                }).toList(),
                onChanged: (v) => setDialogState(() => format = v!),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) return;
                final repo = ref.read(enhancedExportRepositoryProvider);
                await repo.saveTemplate(ExportTemplate(
                  name: nameController.text.trim(),
                  format: format,
                  createdAt: DateTime.now(),
                ));
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                _loadTemplates();
              },
              child: const Text('创建'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportWithTemplate(ExportTemplate template) async {
    setState(() => _isExporting = true);
    _selectedFormat = template.format;
    
    final config = ExportConfig(
      startDate: _startDate,
      endDate: _endDate,
      format: template.format,
      template: template,
    );
    
    final repo = ref.read(enhancedExportRepositoryProvider);
    _lastResult = await repo.export(config);
    
    setState(() => _isExporting = false);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('模板 "${template.name}" 导出完成')),
      );
    }
  }

  Future<void> _setDefaultTemplate(ExportTemplate template) async {
    final repo = ref.read(enhancedExportRepositoryProvider);
    await repo.setDefaultTemplate(template.id!);
    _loadTemplates();
  }

  Future<void> _deleteTemplate(ExportTemplate template) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除模板'),
        content: Text('确定要删除模板 "${template.name}" 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final repo = ref.read(enhancedExportRepositoryProvider);
      await repo.deleteTemplate(template.id!);
      _loadTemplates();
    }
  }

  String _getFormatName(ExportFormat format) {
    switch (format) {
      case ExportFormat.csv:
        return 'CSV';
      case ExportFormat.json:
        return 'JSON';
      case ExportFormat.markdown:
        return 'Markdown';
      case ExportFormat.html:
        return 'HTML';
      case ExportFormat.pdf:
        return 'PDF';
    }
  }

  String _getFormatDescription(ExportFormat format) {
    switch (format) {
      case ExportFormat.csv:
        return '通用电子表格格式';
      case ExportFormat.json:
        return '结构化数据格式';
      case ExportFormat.markdown:
        return '易读的文档格式';
      case ExportFormat.html:
        return '网页格式';
      case ExportFormat.pdf:
        return '便携式文档格式';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class _TemplateCard extends StatelessWidget {
  final ExportTemplate template;
  final VoidCallback onExport;
  final VoidCallback onSetDefault;
  final VoidCallback onDelete;

  const _TemplateCard({
    required this.template,
    required this.onExport,
    required this.onSetDefault,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.description, color: Colors.blue),
        ),
        title: Row(
          children: [
            Text(template.name),
            if (template.isDefault) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '默认',
                  style: TextStyle(fontSize: 10, color: Colors.amber),
                ),
              ),
            ],
          ],
        ),
        subtitle: Text(_getFormatName(template.format)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.play_arrow),
              onPressed: onExport,
            ),
            PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'default',
                  child: Text('设为默认'),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('删除'),
                ),
              ],
              onSelected: (value) {
                if (value == 'default') onSetDefault();
                if (value == 'delete') onDelete();
              },
            ),
          ],
        ),
      ),
    );
  }

  String _getFormatName(ExportFormat format) {
    switch (format) {
      case ExportFormat.csv:
        return 'CSV 格式';
      case ExportFormat.json:
        return 'JSON 格式';
      case ExportFormat.markdown:
        return 'Markdown 格式';
      case ExportFormat.html:
        return 'HTML 格式';
      case ExportFormat.pdf:
        return 'PDF 格式';
    }
  }
}