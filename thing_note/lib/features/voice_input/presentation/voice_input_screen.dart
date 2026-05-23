import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/voice_input/data/voice_input_repository.dart';
import 'package:thing_note/features/voice_input/domain/voice_input.dart';

final voiceInputStateProvider = StateProvider<VoiceInputState>((ref) => VoiceInputState.idle);

class VoiceInputScreen extends ConsumerStatefulWidget {
  final Function(String)? onTextRecognized;
  final bool isEmbedded;

  const VoiceInputScreen({
    super.key,
    this.onTextRecognized,
    this.isEmbedded = false,
  });

  @override
  ConsumerState<VoiceInputScreen> createState() => _VoiceInputScreenState();
}

class _VoiceInputScreenState extends ConsumerState<VoiceInputScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  List<VoiceInputResult> _history = [];
  List<String> _suggestions = [];
  String _currentText = '';
  VoiceInputState _state = VoiceInputState.idle;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _loadData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final repo = ref.read(voiceInputRepositoryProvider);
    final results = await Future.wait([
      repo.getHistory(),
      repo.getCommonPhrases(),
    ]);
    setState(() {
      _history = results[0] as List<VoiceInputResult>;
      _suggestions = results[1] as List<String>;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('语音输入'),
        actions: [
          if (_history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: _clearHistory,
              tooltip: '清除历史',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(child: _buildVoiceArea()),
                if (_suggestions.isNotEmpty) _buildSuggestions(),
                if (_history.isNotEmpty) _buildHistoryList(),
              ],
            ),
    );
  }

  Widget _buildVoiceArea() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              final scale = 1.0 + (_animationController.value * 0.1);
              return Transform.scale(
                scale: _state == VoiceInputState.listening ? scale : 1.0,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: _getStateColor().withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _getStateColor(),
                      width: 3,
                    ),
                  ),
                  child: IconButton(
                    icon: Icon(
                      _getStateIcon(),
                      size: 48,
                      color: _getStateColor(),
                    ),
                    onPressed: _toggleListening,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          Text(
            _getStateText(),
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          if (_currentText.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _currentText,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => setState(() => _currentText = ''),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 24),
          if (_state == VoiceInputState.idle || _state == VoiceInputState.listening)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: _simulateVoiceInput,
                  icon: const Icon(Icons.mic),
                  label: Text(_state == VoiceInputState.listening ? '停止' : '开始录音'),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildSuggestions() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _suggestions.length,
        itemBuilder: (context, index) {
          final phrase = _suggestions[index];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              label: Text(phrase.length > 15 ? '${phrase.substring(0, 15)}...' : phrase),
              onPressed: () => _useSuggestion(phrase),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHistoryList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            '历史记录',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _history.length,
            itemBuilder: (context, index) {
              final result = _history[index];
              return ListTile(
                leading: Icon(
                  result.used ? Icons.check_circle : Icons.mic,
                  color: result.used ? Colors.green : Colors.grey,
                ),
                title: Text(result.transcribedText),
                subtitle: Text(
                  _formatTime(result.createdAt),
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.content_copy),
                  onPressed: () => _copyToClipboard(result.transcribedText),
                ),
                onTap: () => _useResult(result),
              );
            },
          ),
        ),
      ],
    );
  }

  void _toggleListening() {
    if (_state == VoiceInputState.listening) {
      setState(() => _state = VoiceInputState.idle);
    } else {
      setState(() => _state = VoiceInputState.listening);
      // In real implementation, start voice recognition here
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted && _state == VoiceInputState.listening) {
          _simulateVoiceInput();
        }
      });
    }
  }

  void _simulateVoiceInput() {
    // Simulate voice recognition result
    final samples = [
      '今天天气真好',
      '完成了一个重要任务',
      '阅读了一本书',
      '运动了30分钟',
      '和朋友聊天',
    ];
    final result = samples[DateTime.now().second % samples.length];
    setState(() {
      _currentText = result;
      _state = VoiceInputState.success;
    });
  }

  Future<void> _useResult(VoiceInputResult result) async {
    setState(() => _currentText = result.transcribedText);
    final repo = ref.read(voiceInputRepositoryProvider);
    await repo.markAsUsed(result.id!);
  }

  void _useSuggestion(String phrase) {
    setState(() => _currentText = phrase);
  }

  void _copyToClipboard(String text) {
    // In real app, use Clipboard.setData
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已复制到剪贴板')),
    );
  }

  Future<void> _clearHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('清除历史'),
        content: const Text('确定要清除所有语音输入历史吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('清除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final repo = ref.read(voiceInputRepositoryProvider);
      await repo.clearHistory();
      _loadData();
    }
  }

  IconData _getStateIcon() {
    switch (_state) {
      case VoiceInputState.listening:
        return Icons.mic;
      case VoiceInputState.processing:
        return Icons.hourglass_empty;
      case VoiceInputState.success:
        return Icons.check;
      case VoiceInputState.error:
        return Icons.error;
      default:
        return Icons.mic_none;
    }
  }

  Color _getStateColor() {
    switch (_state) {
      case VoiceInputState.listening:
        return Colors.red;
      case VoiceInputState.processing:
        return Colors.orange;
      case VoiceInputState.success:
        return Colors.green;
      case VoiceInputState.error:
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  String _getStateText() {
    switch (_state) {
      case VoiceInputState.listening:
        return '正在聆听...';
      case VoiceInputState.processing:
        return '处理中...';
      case VoiceInputState.success:
        return '识别完成';
      case VoiceInputState.error:
        return '识别失败，请重试';
      default:
        return '点击麦克风开始语音输入';
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前';
    if (diff.inHours < 24) return '${diff.inHours}小时前';
    return '${diff.inDays}天前';
  }
}

/// Compact voice input button widget for embedding in forms
class VoiceInputButton extends ConsumerWidget {
  final Function(String) onTextRecognized;

  const VoiceInputButton({
    super.key,
    required this.onTextRecognized,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      icon: const Icon(Icons.mic),
      onPressed: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (ctx) => DraggableScrollableSheet(
            initialChildSize: 0.6,
            builder: (context, scrollController) => VoiceInputScreen(
              onTextRecognized: onTextRecognized,
              isEmbedded: true,
            ),
          ),
        );
      },
    );
  }
}