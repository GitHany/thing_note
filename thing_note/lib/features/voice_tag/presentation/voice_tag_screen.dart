import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/voice_tag/domain/voice_command.dart';

class VoiceTagScreen extends ConsumerStatefulWidget {
  const VoiceTagScreen({super.key});

  @override
  ConsumerState<VoiceTagScreen> createState() => _VoiceTagScreenState();
}

class _VoiceTagScreenState extends ConsumerState<VoiceTagScreen>
    with SingleTickerProviderStateMixin {
  bool _isListening = false;
  String _lastRecognizedText = '';
  final _resultController = TextEditingController();
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _resultController.dispose();
    super.dispose();
  }

  void _toggleListening() {
    setState(() {
      _isListening = !_isListening;
      if (_isListening) {
        _animationController.repeat(reverse: true);
        // Simulate voice recognition
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            _simulateRecognition();
          }
        });
      } else {
        _animationController.stop();
      }
    });
  }

  void _simulateRecognition() {
    final samples = [
      '创建一个新记录，工作事项',
      '添加标签:重要',
      '搜索今天的记录',
      '启动25分钟计时器',
      '记录心情：很好',
    ];
    final randomText = samples[DateTime.now().millisecond % samples.length];
    
    setState(() {
      _isListening = false;
      _lastRecognizedText = randomText;
      _resultController.text = randomText;
    });
    _animationController.stop();
  }

  @override
  Widget build(BuildContext context) {
    final intent = CommandIntent.parseIntent(_lastRecognizedText);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('语音标签'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {},
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildVoiceButton(),
            const SizedBox(height: 32),
            if (_lastRecognizedText.isNotEmpty) ...[
              _buildResultCard(intent),
              const SizedBox(height: 16),
              _buildIntentActions(intent),
            ],
            const Spacer(),
            _buildQuickCommands(),
          ],
        ),
      ),
    );
  }

  Widget _buildVoiceButton() {
    return GestureDetector(
      onTap: _toggleListening,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isListening
                  ? Colors.red.withOpacity(0.2 + _animationController.value * 0.3)
                  : Colors.blue.withOpacity(0.2),
              border: Border.all(
                color: _isListening ? Colors.red : Colors.blue,
                width: 4,
              ),
            ),
            child: Center(
              child: Icon(
                _isListening ? Icons.mic : Icons.mic_none,
                size: 48,
                color: _isListening ? Colors.red : Colors.blue,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildResultCard(String intent) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getIntentIcon(intent),
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  CommandIntent.getIntentDescription(intent),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _resultController,
              decoration: const InputDecoration(
                hintText: '识别结果',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() => _lastRecognizedText = value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntentActions(String intent) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (intent == CommandIntent.createRecord)
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add),
            label: const Text('创建记录'),
          ),
        if (intent == CommandIntent.addTag)
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.label),
            label: const Text('添加标签'),
          ),
        if (intent == CommandIntent.search)
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.search),
            label: const Text('搜索'),
          ),
        if (intent == CommandIntent.timer)
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.timer),
            label: const Text('启动计时'),
          ),
        ElevatedButton.icon(
          onPressed: () {
            _resultController.clear();
            setState(() => _lastRecognizedText = '');
          },
          icon: const Icon(Icons.refresh),
          label: const Text('重试'),
        ),
      ],
    );
  }

  Widget _buildQuickCommands() {
    final commands = [
      ('创建记录', Icons.add),
      ('添加标签', Icons.label),
      ('搜索', Icons.search),
      ('计时器', Icons.timer),
      ('记录心情', Icons.mood),
    ];

    return Column(
      children: [
        const Text('快捷命令', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: commands.map((c) {
            return ActionChip(
              avatar: Icon(c.$2, size: 18),
              label: Text(c.$1),
              onPressed: () => setState(() {
                _resultController.text = c.$1;
                _lastRecognizedText = c.$1;
              }),
            );
          }).toList(),
        ),
      ],
    );
  }

  IconData _getIntentIcon(String intent) {
    switch (intent) {
      case CommandIntent.createRecord:
        return Icons.add_circle;
      case CommandIntent.addTag:
        return Icons.label;
      case CommandIntent.search:
        return Icons.search;
      case CommandIntent.timer:
        return Icons.timer;
      case CommandIntent.mood:
        return Icons.mood;
      default:
        return Icons.help;
    }
  }
}