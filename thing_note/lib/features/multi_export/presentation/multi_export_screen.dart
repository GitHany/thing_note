import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/multi_export/data/export_provider.dart';
import 'package:thing_note/features/multi_export/domain/export_config.dart';

class MultiExportScreen extends ConsumerStatefulWidget {
  const MultiExportScreen({super.key});

  @override
  ConsumerState<MultiExportScreen> createState() => _MultiExportScreenState();
}

class _MultiExportScreenState extends ConsumerState<MultiExportScreen> {
  ExportFormat _selectedFormat = ExportFormat.json;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _includePhotos = false;
  bool _includeAudio = false;
  bool _includeLocation = true;
  bool _includeTags = true;

  @override
  Widget build(BuildContext context) {
    final exportResult = ref.watch(exportNotifierProvider);
    final templates = ref.watch(exportTemplatesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Export Data'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Format selection
            const Text(
              'Export Format',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ExportFormat.values.map((format) {
                return ChoiceChip(
                  label: Text(_formatName(format)),
                  selected: _selectedFormat == format,
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedFormat = format);
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // Date range
            const Text(
              'Date Range (optional)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _selectDate(context, true),
                    icon: const Icon(Icons.calendar_today),
                    label: Text(_startDate != null ? _formatDate(_startDate!) : 'Start Date'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _selectDate(context, false),
                    icon: const Icon(Icons.calendar_today),
                    label: Text(_endDate != null ? _formatDate(_endDate!) : 'End Date'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Include options
            const Text(
              'Include in Export',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Location Data'),
              subtitle: const Text('Latitude, longitude, address'),
              value: _includeLocation,
              onChanged: (value) => setState(() => _includeLocation = value),
            ),
            SwitchListTile(
              title: const Text('Tags'),
              subtitle: const Text('All associated tags'),
              value: _includeTags,
              onChanged: (value) => setState(() => _includeTags = value),
            ),
            SwitchListTile(
              title: const Text('Photos'),
              subtitle: const Text('Photo paths and references'),
              value: _includePhotos,
              onChanged: (value) => setState(() => _includePhotos = value),
            ),
            SwitchListTile(
              title: const Text('Audio'),
              subtitle: const Text('Audio file references'),
              value: _includeAudio,
              onChanged: (value) => setState(() => _includeAudio = value),
            ),

            const SizedBox(height: 24),

            // Saved templates
            templates.when(
              data: (templateList) {
                if (templateList.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Saved Templates',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...templateList.map((template) {
                      return ListTile(
                        leading: const Icon(Icons.description),
                        title: Text(template.name),
                        subtitle: Text('Format: ${template.format.name}'),
                        onTap: () => _applyTemplate(template),
                      );
                    }),
                  ],
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),

            const SizedBox(height: 24),

            // Export status
            exportResult.when(
              data: (result) {
                if (result == null) return const SizedBox.shrink();
                return Card(
                  color: Colors.green.shade50,
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
                              'Export Complete!',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('Records exported: ${result.recordCount}'),
                        Text('File size: ${result.formattedSize}'),
                        Text('Format: ${result.format.name.toUpperCase()}'),
                        const SizedBox(height: 8),
                        Text(
                          'Saved to: ${result.filePath}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                );
              },
              loading: () => const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Exporting data...'),
                  ],
                ),
              ),
              error: (error, _) => Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Export failed: $error'),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        child: FilledButton(
          onPressed: _startExport,
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Export Now'),
          ),
        ),
      ),
    );
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

  void _applyTemplate(ExportTemplate template) {
    setState(() {
      _selectedFormat = template.format;
      _includePhotos = template.includePhotos;
      _includeAudio = template.includeAudio;
      _includeLocation = template.includeLocation;
      _includeTags = template.includeTags;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Applied template: ${template.name}')),
    );
  }

  Future<void> _startExport() async {
    final config = ExportConfig(
      format: _selectedFormat,
      startDate: _startDate,
      endDate: _endDate,
      includePhotos: _includePhotos,
      includeAudio: _includeAudio,
      includeLocation: _includeLocation,
      includeTags: _includeTags,
    );

    await ref.read(exportNotifierProvider.notifier).export(config);
  }

  String _formatName(ExportFormat format) {
    switch (format) {
      case ExportFormat.json:
        return 'JSON';
      case ExportFormat.csv:
        return 'CSV';
      case ExportFormat.html:
        return 'HTML';
      case ExportFormat.markdown:
        return 'Markdown';
      case ExportFormat.pdf:
        return 'PDF';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}