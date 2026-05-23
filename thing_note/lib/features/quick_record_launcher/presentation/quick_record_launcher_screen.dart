import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/voice_models.dart';

/// 快捷录音启动器屏幕
class QuickRecordLauncherScreen extends ConsumerWidget {
  const QuickRecordLauncherScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordingStateAsync = ref.watch(quickRecorderProvider);
    final recordingsAsync = ref.watch(recentRecordingsProvider);
    final state = recordingStateAsync.value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('快捷录音'),
      ),
      body: Column(
        children: [
          // 录音控制区
          Container(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                // 状态显示
                Text(
                  _getStateText(state),
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 24),
                // 录音按钮
                _RecordButton(
                  state: state,
                  onStart: () => ref.read(quickRecorderProvider.notifier).startRecording(),
                  onPause: () => ref.read(quickRecorderProvider.notifier).pauseRecording(),
                  onResume: () => ref.read(quickRecorderProvider.notifier).resumeRecording(),
                  onStop: () async {
                    final entry = await ref.read(quickRecorderProvider.notifier).stopRecording();
                    if (entry == null) {
                      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('录音太短，至少需要3秒')));
                    }
                  },
                ),
                const SizedBox(height: 16),
                // 提示文字
                Text(
                  state == RecordingState.recording ? '点击暂停，再次点击继续' : state == RecordingState.paused ? '点击继续录音' : '点击开始录音',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const Divider(),
          // 最近录音
          Expanded(
            child: recordingsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('加载失败')),
              data: (recordings) => recordings.isEmpty
                  ? const Center(child: Text('暂无录音'))
                  : ListView.builder(
                      itemCount: recordings.length,
                      itemBuilder: (context, index) {
                        final recording = recordings[index];
                        return ListTile(
                          leading: Icon(
                            recording.isFavorite ? Icons.star : Icons.mic,
                            color: recording.isFavorite ? Colors.amber : null,
                          ),
                          title: Text(recording.title ?? '未命名录音'),
                          subtitle: Text(recording.formattedDuration),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(icon: const Icon(Icons.play_arrow), onPressed: () {}),
                              IconButton(icon: const Icon(Icons.link), onPressed: () {}),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  String _getStateText(RecordingState? state) {
    switch (state) {
      case RecordingState.recording: return '🎙️ 录音中...';
      case RecordingState.paused: return '⏸️ 已暂停';
      default: return '🎤 点击开始录音';
    }
  }
}

class _RecordButton extends StatelessWidget {
  final RecordingState? state;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onStop;

  const _RecordButton({required this.state, required this.onStart, required this.onPause, required this.onResume, required this.onStop});

  @override
  Widget build(BuildContext context) {
    final isRecording = state == RecordingState.recording;
    final isPaused = state == RecordingState.paused;

    return GestureDetector(
      onTap: () {
        if (state == RecordingState.idle) onStart();
        else if (isRecording) onPause();
        else if (isPaused) onResume();
      },
      onLongPress: state != RecordingState.idle ? onStop : null,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: isRecording ? Colors.red : isPaused ? Colors.orange : Colors.blue,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: (isRecording ? Colors.red : isPaused ? Colors.orange : Colors.blue).withOpacity(0.4), blurRadius: 16, spreadRadius: 2),
          ],
        ),
        child: Icon(
          isRecording ? Icons.pause : isPaused ? Icons.play_arrow : Icons.mic,
          color: Colors.white,
          size: 40,
        ),
      ),
    );
  }
}