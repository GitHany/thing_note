import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/record_merge/data/record_merge_provider.dart';
import 'package:thing_note/features/record_merge/domain/record_merge.dart';

class RecordMergeScreen extends ConsumerStatefulWidget {
  final int targetRecordId;
  final List<int> sourceRecordIds;

  const RecordMergeScreen({
    super.key,
    required this.targetRecordId,
    required this.sourceRecordIds,
  });

  @override
  ConsumerState<RecordMergeScreen> createState() => _RecordMergeScreenState();
}

class _RecordMergeScreenState extends ConsumerState<RecordMergeScreen> {
  bool _keepPhotos = true;
  bool _keepAudio = true;
  bool _keepVideo = true;
  bool _keepDocuments = true;
  bool _mergeTags = true;
  bool _mergeLocation = true;

  @override
  Widget build(BuildContext context) {
    final previewAsync = ref.watch(mergePreviewProvider((widget.targetRecordId, widget.sourceRecordIds)));
    final mergeResult = ref.watch(recordMergeNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Merge Records'),
      ),
      body: Column(
        children: [
          // Preview section
          previewAsync.when(
            data: (preview) {
              return Container(
                padding: const EdgeInsets.all(16),
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Merge Preview',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    _buildPreviewRow(Icons.photo, 'Photos', preview.totalPhotos),
                    _buildPreviewRow(Icons.audiotrack, 'Audio', preview.totalAudio),
                    _buildPreviewRow(Icons.videocam, 'Video', preview.totalVideo),
                    _buildPreviewRow(Icons.description, 'Documents', preview.totalDocuments),
                    _buildPreviewRow(Icons.label, 'Tags to merge', preview.tagsToMerge.length),
                    if (preview.targetLatitude != null)
                      _buildPreviewRow(Icons.location_on, 'Location', 1),
                    const SizedBox(height: 8),
                    Text(
                      'Source: ${widget.sourceRecordIds.length} records → Target: Record #${widget.targetRecordId}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text('Error: $error')),
          ),

          // Options
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Merge Options',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text('Include Photos'),
                  subtitle: const Text('Merge photos from source records'),
                  value: _keepPhotos,
                  onChanged: (value) => setState(() => _keepPhotos = value),
                ),
                SwitchListTile(
                  title: const Text('Include Audio'),
                  subtitle: const Text('Merge audio files'),
                  value: _keepAudio,
                  onChanged: (value) => setState(() => _keepAudio = value),
                ),
                SwitchListTile(
                  title: const Text('Include Video'),
                  subtitle: const Text('Merge video files'),
                  value: _keepVideo,
                  onChanged: (value) => setState(() => _keepVideo = value),
                ),
                SwitchListTile(
                  title: const Text('Include Documents'),
                  subtitle: const Text('Merge document files'),
                  value: _keepDocuments,
                  onChanged: (value) => setState(() => _keepDocuments = value),
                ),
                const Divider(),
                SwitchListTile(
                  title: const Text('Merge Tags'),
                  subtitle: const Text('Combine tags from all records'),
                  value: _mergeTags,
                  onChanged: (value) => setState(() => _mergeTags = value),
                ),
                SwitchListTile(
                  title: const Text('Merge Location'),
                  subtitle: const Text('Keep target record location'),
                  value: _mergeLocation,
                  onChanged: (value) => setState(() => _mergeLocation = value),
                ),
              ],
            ),
          ),

          // Result
          mergeResult.when(
            data: (result) {
              if (result == null) return const SizedBox.shrink();
              return Container(
                padding: const EdgeInsets.all(16),
                color: Colors.green.shade50,
                child: Column(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 48),
                    const SizedBox(height: 8),
                    Text(
                      'Merge Complete!',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text('${result.sourceRecordsMerged} records merged into #${result.targetRecordId}'),
                    Text('${result.totalAttachmentsAdded} attachments added'),
                  ],
                ),
              );
            },
            loading: () => const LinearProgressIndicator(),
            error: (error, _) => Container(
              padding: const EdgeInsets.all(16),
              color: Colors.red.shade50,
              child: Text('Merge failed: $error'),
            ),
          ),

          // Action button
          Container(
            padding: const EdgeInsets.all(16),
            child: FilledButton(
              onPressed: mergeResult.isLoading ? null : _startMerge,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: mergeResult.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Merge Records'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewRow(IconData icon, String label, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(label),
          const Spacer(),
          Text(
            count.toString(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Future<void> _startMerge() async {
    final config = RecordMergeConfig(
      targetRecordId: widget.targetRecordId,
      sourceRecordIds: widget.sourceRecordIds,
      keepPhotos: _keepPhotos,
      keepAudio: _keepAudio,
      keepVideo: _keepVideo,
      keepDocuments: _keepDocuments,
      mergeTags: _mergeTags,
      mergeLocation: _mergeLocation,
    );

    await ref.read(recordMergeNotifierProvider.notifier).merge(config);
  }
}