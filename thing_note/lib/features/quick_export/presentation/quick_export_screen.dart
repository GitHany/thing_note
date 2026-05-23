import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

final quickExportProvider = StateNotifierProvider<QuickExportNotifier, List<ExportConfig>>((ref) {
  return QuickExportNotifier();
});

class QuickExportNotifier extends StateNotifier<List<ExportConfig>> {
  QuickExportNotifier() : super([]);

  void addConfig(ExportConfig config) {
    state = [...state, config];
  }

  void removeConfig(int id) {
    state = state.where((c) => c.id != id).toList();
  }

  void incrementUsage(int id) {
    state = state.map((c) {
      if (c.id == id) {
        return c.copyWith(useCount: c.useCount + 1);
      }
      return c;
    }).toList();
  }
}

class ExportConfig {
  final int id;
  final String name;
  final String format;
  final List<String>? fields;
  final Map<String, dynamic>? filters;
  final int useCount;
  final String createdAt;

  ExportConfig({
    required this.id,
    required this.name,
    required this.format,
    this.fields,
    this.filters,
    this.useCount = 0,
    required this.createdAt,
  });

  ExportConfig copyWith({
    int? id,
    String? name,
    String? format,
    List<String>? fields,
    Map<String, dynamic>? filters,
    int? useCount,
    String? createdAt,
  }) {
    return ExportConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      format: format ?? this.format,
      fields: fields ?? this.fields,
      filters: filters ?? this.filters,
      useCount: useCount ?? this.useCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class QuickExportScreen extends ConsumerStatefulWidget {
  const QuickExportScreen({super.key});

  @override
  ConsumerState<QuickExportScreen> createState() => _QuickExportScreenState();
}

class _QuickExportScreenState extends ConsumerState<QuickExportScreen> {
  int _nextId = 1;
  // ignore: unused_field
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    final configs = ref.watch(quickExportProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quick Export'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showExportSettings(context),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildQuickExport(),
          const Divider(),
          _buildPresets(configs),
        ],
      ),
    );
  }

  Widget _buildQuickExport() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.flash_on, color: Colors.amber),
                  SizedBox(width: 8),
                  Text(
                    'Quick Export',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Select format and export records'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildFormatButton('JSON', Icons.data_object, Colors.blue),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildFormatButton('CSV', Icons.table_chart, Colors.green),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildFormatButton('HTML', Icons.web, Colors.orange),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildFormatButton('PDF', Icons.picture_as_pdf, Colors.red),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildFormatButton('Markdown', Icons.description, Colors.purple),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildFormatButton('Text', Icons.text_fields, Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormatButton(String format, IconData icon, Color color) {
    return InkWell(
      onTap: () => _showExportDialog(format),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 4),
            Text(
              format,
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresets(List<ExportConfig> configs) {
    return Expanded(
      child: configs.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bookmark_border, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text(
                    'No saved presets',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showSavePresetDialog(context),
                    icon: const Icon(Icons.save),
                    label: const Text('Save Current as Preset'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: configs.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: OutlinedButton.icon(
                      onPressed: () => _showSavePresetDialog(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Save Current as Preset'),
                    ),
                  );
                }
                final config = configs[index - 1];
                return _buildPresetCard(config);
              },
            ),
    );
  }

  Widget _buildPresetCard(ExportConfig config) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _getFormatColor(config.format).withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getFormatIcon(config.format),
            color: _getFormatColor(config.format),
          ),
        ),
        title: Text(config.name),
        subtitle: Text('Used ${config.useCount} times'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.play_arrow, color: Colors.green),
              onPressed: () => _exportWithPreset(config),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () {
                ref.read(quickExportProvider.notifier).removeConfig(config.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  Color _getFormatColor(String format) {
    switch (format) {
      case 'JSON': return Colors.blue;
      case 'CSV': return Colors.green;
      case 'HTML': return Colors.orange;
      case 'PDF': return Colors.red;
      case 'Markdown': return Colors.purple;
      case 'Text': return Colors.grey;
      default: return Colors.blue;
    }
  }

  IconData _getFormatIcon(String format) {
    switch (format) {
      case 'JSON': return Icons.data_object;
      case 'CSV': return Icons.table_chart;
      case 'HTML': return Icons.web;
      case 'PDF': return Icons.picture_as_pdf;
      case 'Markdown': return Icons.description;
      case 'Text': return Icons.text_fields;
      default: return Icons.save;
    }
  }

  void _showExportDialog(String format) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Export as $format'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Export all records or select date range?'),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.select_all),
              title: const Text('All Records'),
              onTap: () {
                Navigator.pop(context);
                _exportRecords(format, null);
              },
            ),
            ListTile(
              leading: const Icon(Icons.date_range),
              title: const Text('Custom Date Range'),
              onTap: () {
                Navigator.pop(context);
                _showDateRangeExport(format);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showDateRangeExport(String format) {
    // ignore: unused_local_variable
    final startDate = DateTime.now().subtract(const Duration(days: 30));
    // ignore: unused_local_variable
    final endDate = DateTime.now();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Date Range'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Last 7 days'),
              onTap: () {
                Navigator.pop(context);
                _exportRecords(format, DateTime.now().subtract(const Duration(days: 7)));
              },
            ),
            ListTile(
              title: const Text('Last 30 days'),
              onTap: () {
                Navigator.pop(context);
                _exportRecords(format, DateTime.now().subtract(const Duration(days: 30)));
              },
            ),
            ListTile(
              title: const Text('Last 90 days'),
              onTap: () {
                Navigator.pop(context);
                _exportRecords(format, DateTime.now().subtract(const Duration(days: 90)));
              },
            ),
            ListTile(
              title: const Text('This year'),
              onTap: () {
                Navigator.pop(context);
                _exportRecords(format, DateTime(DateTime.now().year, 1, 1));
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showSavePresetDialog(BuildContext context) {
    final nameController = TextEditingController();
    String format = 'CSV';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Save Export Preset'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Preset Name'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: format,
                decoration: const InputDecoration(labelText: 'Format'),
                items: ['JSON', 'CSV', 'HTML', 'Markdown', 'Text']
                    .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => format = value);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  final config = ExportConfig(
                    id: _nextId++,
                    name: nameController.text,
                    format: format,
                    createdAt: DateTime.now().toIso8601String(),
                  );
                  ref.read(quickExportProvider.notifier).addConfig(config);
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showExportSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Export Settings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Include Photos'),
              subtitle: const Text('Include photo paths in export'),
              value: true,
              onChanged: (_) {},
            ),
            SwitchListTile(
              title: const Text('Include Audio'),
              subtitle: const Text('Include audio file paths'),
              value: true,
              onChanged: (_) {},
            ),
            SwitchListTile(
              title: const Text('Include Location'),
              subtitle: const Text('Include GPS coordinates'),
              value: true,
              onChanged: (_) {},
            ),
            SwitchListTile(
              title: const Text('Include Tags'),
              subtitle: const Text('Include tags in export'),
              value: true,
              onChanged: (_) {},
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportRecords(String format, DateTime? startDate) async {
    setState(() => _isExporting = true);

    try {
      // Create sample data for export
      final data = {
        'exported_at': DateTime.now().toIso8601String(),
        'format': format,
        'start_date': startDate?.toIso8601String(),
        'records': [],
      };

      String content;
      String extension;

      switch (format) {
        case 'JSON':
          content = const JsonEncoder.withIndent('  ').convert(data);
          extension = 'json';
          break;
        case 'CSV':
          content = 'date,time,title,notes,tags\n';
          extension = 'csv';
          break;
        case 'HTML':
          content = '''<!DOCTYPE html>
<html><head><title>Export</title></head>
<body><h1>Records Export</h1>
<p>Exported: ${DateTime.now()}</p>
</body></html>''';
          extension = 'html';
          break;
        case 'Markdown':
          content = '''# Records Export

Exported: ${DateTime.now()}

''';
          extension = 'md';
          break;
        case 'Text':
          content = 'Records Export\n${DateTime.now()}\n\n';
          extension = 'txt';
          break;
        default:
          content = '';
          extension = 'txt';
      }

      // Save to temp file and share
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/export_${DateTime.now().millisecondsSinceEpoch}.$extension');
      await file.writeAsString(content);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Records Export',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Export completed!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isExporting = false);
    }
  }

  Future<void> _exportWithPreset(ExportConfig config) async {
    await _exportRecords(config.format, null);
    ref.read(quickExportProvider.notifier).incrementUsage(config.id);
  }
}