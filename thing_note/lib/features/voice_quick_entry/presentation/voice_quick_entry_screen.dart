import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';

// Voice Quick Entry State
class VoiceEntryState {
  final bool isRecording;
  final int recordingDuration;
  final String? transcribedText;
  final bool isProcessing;
  final List<VoiceEntry> history;

  VoiceEntryState({
    this.isRecording = false,
    this.recordingDuration = 0,
    this.transcribedText,
    this.isProcessing = false,
    this.history = const [],
  });

  VoiceEntryState copyWith({
    bool? isRecording,
    int? recordingDuration,
    String? transcribedText,
    bool? isProcessing,
    List<VoiceEntry>? history,
  }) {
    return VoiceEntryState(
      isRecording: isRecording ?? this.isRecording,
      recordingDuration: recordingDuration ?? this.recordingDuration,
      transcribedText: transcribedText ?? this.transcribedText,
      isProcessing: isProcessing ?? this.isProcessing,
      history: history ?? this.history,
    );
  }
}

class VoiceEntry {
  final int id;
  final String text;
  final int duration;
  final DateTime createdAt;
  final bool isSaved;

  VoiceEntry({
    required this.id,
    required this.text,
    required this.duration,
    required this.createdAt,
    this.isSaved = false,
  });
}

final voiceEntryStateProvider = StateNotifierProvider<VoiceEntryNotifier, VoiceEntryState>((ref) {
  return VoiceEntryNotifier();
});

class VoiceEntryNotifier extends StateNotifier<VoiceEntryState> {
  VoiceEntryNotifier() : super(VoiceEntryState(
    history: [
      VoiceEntry(
        id: 1,
        text: '今天完成了项目初版开发',
        duration: 15,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      VoiceEntry(
        id: 2,
        text: '学习 Flutter 状态管理',
        duration: 12,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ],
  ));

  Timer? _timer;

  void startRecording() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      state = state.copyWith(
        isRecording: true,
        recordingDuration: state.recordingDuration + 1,
      );
    });
    state = state.copyWith(isRecording: true);
  }

  void stopRecording() {
    _timer?.cancel();
    state = state.copyWith(
      isRecording: false,
      isProcessing: true,
    );

    // Simulate transcription
    Future.delayed(const Duration(seconds: 2), () {
      final transcribed = _generateTranscribedText();
      state = state.copyWith(
        isProcessing: false,
        transcribedText: transcribed,
      );
    });
  }

  void cancelRecording() {
    _timer?.cancel();
    state = state.copyWith(
      isRecording: false,
      recordingDuration: 0,
    );
  }

  String _generateTranscribedText() {
    // Simulated transcription
    final phrases = [
      '今天完成了项目初版开发',
      '学习 Flutter Riverpod',
      '准备下周会议资料',
      '整理今日工作笔记',
      '阅读技术文档',
    ];
    return phrases[DateTime.now().second % phrases.length];
  }

  void saveEntry(String text) {
    final entry = VoiceEntry(
      id: DateTime.now().millisecondsSinceEpoch,
      text: text,
      duration: state.recordingDuration,
      createdAt: DateTime.now(),
      isSaved: true,
    );
    state = state.copyWith(
      history: [entry, ...state.history],
      transcribedText: null,
      recordingDuration: 0,
    );
  }

  void discardEntry() {
    state = state.copyWith(
      transcribedText: null,
      recordingDuration: 0,
    );
  }

  void deleteEntry(int id) {
    state = state.copyWith(
      history: state.history.where((e) => e.id != id).toList(),
    );
  }
}

class VoiceQuickEntryScreen extends ConsumerWidget {
  const VoiceQuickEntryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final voiceState = ref.watch(voiceEntryStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('语音快速录入'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showSettings(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: voiceState.transcribedText != null
                ? _buildTranscriptionView(context, ref, voiceState)
                : voiceState.isRecording || voiceState.isProcessing
                    ? _buildRecordingView(context, ref, voiceState)
                    : _buildIdleView(context, ref, voiceState),
          ),
          _buildHistorySection(context, ref, voiceState),
        ],
      ),
    );
  }

  Widget _buildIdleView(BuildContext context, WidgetRef ref, VoiceEntryState state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTapDown: (_) => ref.read(voiceEntryStateProvider.notifier).startRecording(),
            onTapUp: (_) => ref.read(voiceEntryStateProvider.notifier).stopRecording(),
            onTapCancel: () => ref.read(voiceEntryStateProvider.notifier).cancelRecording(),
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.primary.withOpacity(0.7),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Icon(
                Icons.mic,
                size: 64,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '按住说话',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            '松开后将自动转写为文字',
            style: TextStyle(color: Theme.of(context).colorScheme.outline),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingView(BuildContext context, WidgetRef ref, VoiceEntryState state) {
    final minutes = state.recordingDuration ~/ 60;
    final seconds = state.recordingDuration % 60;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.red,
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.3),
                  blurRadius: 30,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: const Icon(
              Icons.stop,
              size: 64,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '正在录音...',
            style: TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: () => ref.read(voiceEntryStateProvider.notifier).cancelRecording(),
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }

  Widget _buildTranscriptionView(BuildContext context, WidgetRef ref, VoiceEntryState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.text_fields,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '转写结果',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    state.transcribedText ?? '',
                    style: const TextStyle(fontSize: 20),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => ref.read(voiceEntryStateProvider.notifier).discardEntry(),
                  icon: const Icon(Icons.delete),
                  label: const Text('删除'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: () {
                    ref.read(voiceEntryStateProvider.notifier).saveEntry(state.transcribedText!);
                    _showSaveSuccess(context);
                  },
                  icon: const Icon(Icons.save),
                  label: const Text('保存为记录'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySection(BuildContext context, WidgetRef ref, VoiceEntryState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '最近录音',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              if (state.history.isNotEmpty)
                TextButton(
                  onPressed: () {
                    // View all history
                  },
                  child: const Text('查看全部'),
                ),
            ],
          ),
          if (state.history.isNotEmpty)
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: state.history.length,
                itemBuilder: (context, index) {
                  final entry = state.history[index];
                  return _buildHistoryCard(context, ref, entry);
                },
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text('暂无录音历史'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(BuildContext context, WidgetRef ref, VoiceEntry entry) {
    return Card(
      margin: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: () {
          // Re-use entry text
        },
        onLongPress: () {
          _showEntryOptions(context, ref, entry);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 200,
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.mic,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${entry.duration}秒',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  const Spacer(),
                  if (entry.isSaved)
                    const Icon(Icons.check_circle, size: 16, color: Colors.green),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Text(
                  entry.text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEntryOptions(BuildContext context, WidgetRef ref, VoiceEntry entry) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('重新编辑'),
              onTap: () {
                Navigator.pop(context);
                // Re-edit entry
              },
            ),
            ListTile(
              leading: const Icon(Icons.save),
              title: const Text('保存为记录'),
              onTap: () {
                Navigator.pop(context);
                ref.read(voiceEntryStateProvider.notifier).saveEntry(entry.text);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('删除', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                ref.read(voiceEntryStateProvider.notifier).deleteEntry(entry.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '语音设置',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('自动保存录音'),
              subtitle: const Text('录音结束后自动保存'),
              value: true,
              onChanged: (value) {},
            ),
            SwitchListTile(
              title: const Text('噪音抑制'),
              subtitle: const Text('减少背景噪音'),
              value: true,
              onChanged: (value) {},
            ),
            SwitchListTile(
              title: const Text('实时转写'),
              subtitle: const Text('边录音边显示文字'),
              value: false,
              onChanged: (value) {},
            ),
          ],
        ),
      ),
    );
  }

  void _showSaveSuccess(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('已保存为记录'),
        duration: Duration(seconds: 1),
      ),
    );
  }
}
