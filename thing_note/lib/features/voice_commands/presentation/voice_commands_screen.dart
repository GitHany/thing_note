import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/l10n/generated/app_localizations.dart';

class VoiceCommandsScreen extends ConsumerStatefulWidget {
  const VoiceCommandsScreen({super.key});

  @override
  ConsumerState<VoiceCommandsScreen> createState() =>
      _VoiceCommandsScreenState();
}

class _VoiceCommandsScreenState extends ConsumerState<VoiceCommandsScreen> {
  bool _isListening = false;
  String _recognizedText = '';
  final List<_CommandHistory> _commandHistory = [
    _CommandHistory(
      command: '创建新记录',
      response: '好的，正在打开记录表单',
      time: DateTime.now().subtract(const Duration(minutes: 5)),
      success: true,
    ),
    _CommandHistory(
      command: '查看今天的记录',
      response: '今天共有 8 条记录',
      time: DateTime.now().subtract(const Duration(hours: 1)),
      success: true,
    ),
    _CommandHistory(
      command: '打开日历',
      response: '正在打开日历页面',
      time: DateTime.now().subtract(const Duration(hours: 2)),
      success: true,
    ),
    _CommandHistory(
      command: '未识别的命令',
      response: '抱歉，我没有理解您的意思',
      time: DateTime.now().subtract(const Duration(hours: 3)),
      success: false,
    ),
  ];

  final List<_VoiceCommand> _availableCommands = [
    _VoiceCommand(
      phrase: '创建记录',
      description: '打开新建记录页面',
      icon: Icons.add,
    ),
    _VoiceCommand(
      phrase: '查看日历',
      description: '打开日历视图',
      icon: Icons.calendar_month,
    ),
    _VoiceCommand(
      phrase: '搜索记录',
      description: '开始搜索',
      icon: Icons.search,
    ),
    _VoiceCommand(
      phrase: '打开设置',
      description: '进入设置页面',
      icon: Icons.settings,
    ),
    _VoiceCommand(
      phrase: '查看统计',
      description: '查看数据分析',
      icon: Icons.analytics,
    ),
    _VoiceCommand(
      phrase: '开始专注',
      description: '启动专注模式',
      icon: Icons.timer,
    ),
    _VoiceCommand(
      phrase: '备份数据',
      description: '执行数据备份',
      icon: Icons.backup,
    ),
    _VoiceCommand(
      phrase: '打开周报',
      description: '查看周报摘要',
      icon: Icons.article,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 600;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.voiceCommands),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showSettings(),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(isWideScreen ? 24 : 16),
        children: [
          // Voice input area
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _toggleListening,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: _isListening ? 120 : 100,
                      height: _isListening ? 120 : 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isListening
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.surface,
                        boxShadow: _isListening
                            ? [
                                BoxShadow(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withOpacity(0.4),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ]
                            : null,
                      ),
                      child: Icon(
                        _isListening ? Icons.mic : Icons.mic_none,
                        size: 48,
                        color: _isListening
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isListening
                        ? AppLocalizations.of(context)!.listening
                        : AppLocalizations.of(context)!.tapToSpeak,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (_recognizedText.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      '"$_recognizedText"',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontStyle: FontStyle.italic,
                          ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Available commands
          Text(
            AppLocalizations.of(context)!.availableCommands,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableCommands
                .map((cmd) => ActionChip(
                      avatar: Icon(cmd.icon, size: 18),
                      label: Text(cmd.phrase),
                      onPressed: () => _executeCommand(cmd),
                    ))
                .toList(),
          ),
          const SizedBox(height: 24),

          // Command history
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.commandHistory,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              TextButton(
                onPressed: () => _clearHistory(),
                child: Text(AppLocalizations.of(context)!.clearAll),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...(_commandHistory.map((h) => _buildHistoryItem(h))),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(_CommandHistory history) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          history.success ? Icons.check_circle : Icons.error,
          color: history.success ? Colors.green : Colors.red,
        ),
        title: Text(history.command),
        subtitle: Text(history.response),
        trailing: Text(
          _formatTime(history.time),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    );
  }

  void _toggleListening() {
    setState(() {
      _isListening = !_isListening;
      if (_isListening) {
        _startListening();
      } else {
        _stopListening();
      }
    });
  }

  void _startListening() {
    // Simulate voice recognition
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _isListening) {
        setState(() {
          _recognizedText = '创建新记录';
          _isListening = false;
        });
        _processCommand(_recognizedText);
      }
    });
  }

  void _stopListening() {
    _recognizedText = '';
  }

  void _processCommand(String command) {
    final matched = _availableCommands.firstWhere(
      (cmd) => cmd.phrase.contains(command),
      orElse: () => _availableCommands.first,
    );
    _executeCommand(matched);
  }

  void _executeCommand(_VoiceCommand command) {
    setState(() {
      _commandHistory.insert(
        0,
        _CommandHistory(
          command: command.phrase,
          response: '执行成功',
          time: DateTime.now(),
          success: true,
        ),
      );
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('执行命令: ${command.phrase}')),
    );
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.record_voice_over),
            title: const Text('语音识别语言'),
            subtitle: const Text('中文'),
            onTap: () => Navigator.pop(ctx),
          ),
          ListTile(
            leading: const Icon(Icons.volume_up),
            title: const Text('语音反馈'),
            trailing: Switch(value: true, onChanged: (v) {}),
          ),
          ListTile(
            leading: const Icon(Icons.record_voice_over),
            title: const Text('唤醒词'),
            subtitle: const Text('小帮'),
            onTap: () => Navigator.pop(ctx),
          ),
        ],
      ),
    );
  }

  void _clearHistory() {
    setState(() => _commandHistory.clear());
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}分钟前';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}小时前';
    } else {
      return '${diff.inDays}天前';
    }
  }
}

class _VoiceCommand {
  final String phrase;
  final String description;
  final IconData icon;

  _VoiceCommand({
    required this.phrase,
    required this.description,
    required this.icon,
  });
}

class _CommandHistory {
  final String command;
  final String response;
  final DateTime time;
  final bool success;

  _CommandHistory({
    required this.command,
    required this.response,
    required this.time,
    required this.success,
  });
}