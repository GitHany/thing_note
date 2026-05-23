import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/voice_note/domain/voice_note.dart';
import 'package:intl/intl.dart';

class VoiceNoteScreen extends ConsumerStatefulWidget {
  const VoiceNoteScreen({super.key});

  @override
  ConsumerState<VoiceNoteScreen> createState() => _VoiceNoteScreenState();
}

class _VoiceNoteScreenState extends ConsumerState<VoiceNoteScreen> {
  bool _isRecording = false;
  int _recordingDuration = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('语音笔记'),
      ),
      body: Column(
        children: [
          // Recording controls
          Container(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                // Waveform visualization (placeholder)
                Container(
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _isRecording
                      ? _WaveformAnimation()
                      : const Center(child: Text('准备就绪')),
                ),
                const SizedBox(height: 16),
                // Duration display
                Text(
                  _formatDuration(_recordingDuration),
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 24),
                // Record button
                GestureDetector(
                  onTapDown: (_) => _startRecording(),
                  onTapUp: (_) => _stopRecording(),
                  onTapCancel: () => _stopRecording(),
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: _isRecording ? Colors.red : Colors.blue,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (_isRecording ? Colors.red : Colors.blue).withOpacity(0.4),
                          blurRadius: 16,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Icon(
                      _isRecording ? Icons.stop : Icons.mic,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _isRecording ? '松手停止' : '按住录音',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const Divider(),
          // Notes list
          Expanded(
            child: _VoiceNoteList(),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _startRecording() {
    setState(() {
      _isRecording = true;
      _recordingDuration = 0;
    });
    // TODO: Start actual recording
  }

  void _stopRecording() {
    if (!_isRecording) return;
    setState(() {
      _isRecording = false;
    });
    // TODO: Stop recording and save
    if (_recordingDuration > 0) {
      _showSaveDialog();
    }
  }

  void _showSaveDialog() {
    showDialog(
      context: context,
      builder: (context) => _SaveVoiceNoteDialog(
        duration: _recordingDuration,
      ),
    );
  }
}

class _WaveformAnimation extends StatefulWidget {
  @override
  State<_WaveformAnimation> createState() => _WaveformAnimationState();
}

class _WaveformAnimationState extends State<_WaveformAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(20, (index) {
            final height = 20 + 20 * ((index + _controller.value * 10) % 10 / 10);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 4,
              height: height,
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        );
      },
    );
  }
}

class _VoiceNoteList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Mock data - in production would use Riverpod provider
    final notes = <VoiceNote>[
      VoiceNote(
        id: 1,
        title: '会议记录',
        filePath: '/path/to/file1.m4a',
        durationSec: 120,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        transcribedText: '讨论了项目进度...',
      ),
      VoiceNote(
        id: 2,
        title: '灵感笔记',
        filePath: '/path/to/file2.m4a',
        durationSec: 45,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        isFavorite: true,
      ),
    ];

    if (notes.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.mic_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('还没有语音笔记'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: notes.length,
      itemBuilder: (context, index) {
        return _VoiceNoteCard(note: notes[index]);
      },
    );
  }
}

class _VoiceNoteCard extends StatelessWidget {
  final VoiceNote note;

  const _VoiceNoteCard({required this.note});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MM月dd日 HH:mm');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.mic, color: Colors.blue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        note.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        dateFormat.format(note.createdAt),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (note.isFavorite)
                  const Icon(Icons.star, color: Colors.amber),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.timer, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  '${note.durationSec}秒',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    // TODO: Play audio
                  },
                  child: const Row(
                    children: [
                      Icon(Icons.play_arrow),
                      Text('播放'),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // TODO: Transcribe
                  },
                  child: const Text('转文字'),
                ),
              ],
            ),
            if (note.transcribedText != null) ...[
              const Divider(),
              Text(
                note.transcribedText!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SaveVoiceNoteDialog extends StatefulWidget {
  final int duration;

  const _SaveVoiceNoteDialog({required this.duration});

  @override
  State<_SaveVoiceNoteDialog> createState() => _SaveVoiceNoteDialogState();
}

class _SaveVoiceNoteDialogState extends State<_SaveVoiceNoteDialog> {
  final _titleController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('保存语音笔记'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('时长: ${widget.duration}秒'),
          const SizedBox(height: 16),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: '标题',
              hintText: '输入笔记标题',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: () {
            // TODO: Save note
            Navigator.pop(context);
          },
          child: const Text('保存'),
        ),
      ],
    );
  }
}