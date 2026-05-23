import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/voice_journal/data/voice_journal_repository.dart';
import 'package:thing_note/features/voice_journal/domain/voice_journal_entry.dart';

class VoiceJournalScreen extends ConsumerStatefulWidget {
  const VoiceJournalScreen({super.key});

  @override
  ConsumerState<VoiceJournalScreen> createState() => _VoiceJournalScreenState();
}

class _VoiceJournalScreenState extends ConsumerState<VoiceJournalScreen> {
  bool _isRecording = false;

  @override
  Widget build(BuildContext context) {
    final entriesAsync = ref.watch(voiceJournalEntriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('语音日记'),
      ),
      body: entriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('错误: $e')),
        data: (entries) {
          if (entries.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.mic_none, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('还没有语音日记', style: TextStyle(fontSize: 18)),
                  SizedBox(height: 8),
                  Text('点击下方按钮开始录音', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: entries.length,
            itemBuilder: (context, index) => _VoiceEntryCard(entry: entries[index]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _toggleRecording,
        icon: Icon(_isRecording ? Icons.stop : Icons.mic),
        label: Text(_isRecording ? '停止' : '录音'),
        backgroundColor: _isRecording ? Colors.red : Colors.blue,
        foregroundColor: Colors.white,
      ),
    );
  }

  void _toggleRecording() {
    setState(() => _isRecording = !_isRecording);
    if (_isRecording) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('录音中... (模拟录音功能)')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('录音已停止')),
      );
    }
  }
}

class _VoiceEntryCard extends ConsumerWidget {
  final VoiceJournalEntry entry;
  const _VoiceEntryCard({required this.entry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: entry.isFavorite ? Colors.red.shade50 : Colors.blue.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                entry.isFavorite ? Icons.favorite : Icons.mic,
                color: entry.isFavorite ? Colors.red : Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.date,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '时长: ${entry.durationLabel}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  if (entry.transcript != null)
                    Text(
                      entry.transcript!.length > 50
                          ? '${entry.transcript!.substring(0, 50)}...'
                          : entry.transcript!,
                      style: const TextStyle(fontSize: 13),
                    ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                entry.isFavorite ? Icons.favorite : Icons.favorite_border,
                color: entry.isFavorite ? Colors.red : Colors.grey,
              ),
              onPressed: () {
                ref.read(voiceJournalRepositoryProvider).toggleFavorite(entry.id!, !entry.isFavorite);
                ref.invalidate(voiceJournalEntriesProvider);
              },
            ),
          ],
        ),
      ),
    );
  }
}
