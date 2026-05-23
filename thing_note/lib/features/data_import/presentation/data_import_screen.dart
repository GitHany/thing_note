import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/data_import/data/import_provider.dart';
import 'package:thing_note/features/data_import/domain/import_config.dart';

class DataImportScreen extends ConsumerStatefulWidget {
  const DataImportScreen({super.key});

  @override
  ConsumerState<DataImportScreen> createState() => _DataImportScreenState();
}

class _DataImportScreenState extends ConsumerState<DataImportScreen> {
  ImportSourceType _sourceType = ImportSourceType.json;
  String? _selectedFilePath;
  final bool _importPhotos = true;
  final bool _importAudio = true;
  bool _importLocation = true;
  bool _createMissingTags = true;
  bool _createMissingThingNames = true;

  @override
  Widget build(BuildContext context) {
    final importResult = ref.watch(dataImportNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Import Data'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Source type selection
            const Text(
              'Import Source',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ImportSourceType.values.map((type) {
                return ChoiceChip(
                  label: Text(_sourceTypeName(type)),
                  selected: _sourceType == type,
                  onSelected: (selected) {
                    if (selected) setState(() => _sourceType = type);
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // File selection
            const Text(
              'Select File',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _selectFile,
              icon: const Icon(Icons.folder_open),
              label: Text(_selectedFilePath ?? 'Choose file...'),
            ),

            const SizedBox(height: 24),

            // Import options
            const Text(
              'Import Options',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Import Location Data'),
              subtitle: const Text('Latitude, longitude, address'),
              value: _importLocation,
              onChanged: (value) => setState(() => _importLocation = value),
            ),
            SwitchListTile(
              title: const Text('Create Missing Tags'),
              subtitle: const Text('Auto-create tags that don\'t exist'),
              value: _createMissingTags,
              onChanged: (value) => setState(() => _createMissingTags = value),
            ),
            SwitchListTile(
              title: const Text('Create Missing Thing Names'),
              subtitle: const Text('Auto-create categories that don\'t exist'),
              value: _createMissingThingNames,
              onChanged: (value) => setState(() => _createMissingThingNames = value),
            ),

            const SizedBox(height: 24),

            // Import result
            importResult.when(
              data: (result) {
                if (result == null) return const SizedBox.shrink();
                return Card(
                  color: result.successCount > 0 ? Colors.green.shade50 : Colors.red.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              result.successCount > 0 ? Icons.check_circle : Icons.error,
                              color: result.successCount > 0 ? Colors.green : Colors.red,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              result.successCount > 0 ? 'Import Successful' : 'Import Failed',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('Total: ${result.totalRecords}'),
                        Text('Success: ${result.successCount}'),
                        if (result.failedCount > 0) Text('Failed: ${result.failedCount}'),
                        Text('Duration: ${result.duration.inSeconds}s'),
                        if (result.errors.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          const Text('Errors:', style: TextStyle(fontWeight: FontWeight.bold)),
                          ...result.errors.take(5).map((e) => Text(e, style: const TextStyle(fontSize: 12))),
                        ],
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
                    Text('Importing data...'),
                  ],
                ),
              ),
              error: (error, _) => Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Error: $error'),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        child: FilledButton(
          onPressed: _selectedFilePath != null && !importResult.isLoading ? _startImport : null,
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Start Import'),
          ),
        ),
      ),
    );
  }

  void _selectFile() {
    // In a real app, use file_picker package
    setState(() {
      _selectedFilePath = '/path/to/selected/file.json';
    });
  }

  Future<void> _startImport() async {
    if (_selectedFilePath == null) return;

    final config = ImportConfig(
      sourceType: _sourceType,
      filePath: _selectedFilePath!,
      importPhotos: _importPhotos,
      importAudio: _importAudio,
      importLocation: _importLocation,
      createMissingTags: _createMissingTags,
      createMissingThingNames: _createMissingThingNames,
    );

    await ref.read(dataImportNotifierProvider.notifier).import(config);
  }

  String _sourceTypeName(ImportSourceType type) {
    switch (type) {
      case ImportSourceType.json:
        return 'JSON';
      case ImportSourceType.csv:
        return 'CSV';
      case ImportSourceType.thingNoteBackup:
        return 'Thing Note Backup';
      case ImportSourceType.generic:
        return 'Generic';
    }
  }
}