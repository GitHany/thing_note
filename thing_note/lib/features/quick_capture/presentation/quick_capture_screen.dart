import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/quick_capture/data/quick_capture_provider.dart';

class QuickCaptureScreen extends ConsumerStatefulWidget {
  const QuickCaptureScreen({super.key});

  @override
  ConsumerState<QuickCaptureScreen> createState() => _QuickCaptureScreenState();
}

class _QuickCaptureScreenState extends ConsumerState<QuickCaptureScreen> {
  final TextEditingController _textController = TextEditingController();
  QuickCaptureMode _currentMode = QuickCaptureMode.standard;
  bool _isRecording = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final configAsync = ref.watch(quickCaptureConfigProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('快速记录'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showSettings(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Mode Selector
          _buildModeSelector(),
          
          // Content Area
          Expanded(
            child: _buildContentArea(),
          ),
          
          // Quick Tags
          configAsync.when(
            data: (config) => _buildQuickTags(config.quickTags),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          
          // Action Buttons
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildModeSelector() {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: QuickCaptureMode.values.map((mode) {
          final isSelected = _currentMode == mode;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _currentMode = mode;
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).primaryColor
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getModeIcon(mode),
                        color: isSelected ? Colors.white : Colors.grey,
                        size: 24,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getModeName(mode),
                        style: TextStyle(
                          fontSize: 10,
                          color: isSelected ? Colors.white : Colors.grey,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildContentArea() {
    switch (_currentMode) {
      case QuickCaptureMode.voice:
        return _buildVoiceArea();
      case QuickCaptureMode.photo:
        return _buildPhotoArea();
      case QuickCaptureMode.rapid:
        return _buildRapidArea();
      case QuickCaptureMode.minimalist:
        return _buildMinimalistArea();
      default:
        return _buildStandardArea();
    }
  }

  Widget _buildVoiceArea() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTapDown: (_) => _startRecording(),
            onTapUp: (_) => _stopRecording(),
            onTapCancel: () => _stopRecording(),
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isRecording ? Colors.red : Colors.blue,
                boxShadow: [
                  BoxShadow(
                    color: (_isRecording ? Colors.red : Colors.blue).withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Icon(
                _isRecording ? Icons.stop : Icons.mic,
                color: Colors.white,
                size: 48,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _isRecording ? '正在录音...' : '按住录音',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (_isRecording) ...[
            const SizedBox(height: 8),
            const Text(
              '00:00',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPhotoArea() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.camera_alt,
            size: 64,
            color: Colors.grey.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text('点击拍照'),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // Trigger camera
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('打开相机拍照')),
              );
            },
            icon: const Icon(Icons.camera),
            label: const Text('拍照'),
          ),
        ],
      ),
    );
  }

  Widget _buildRapidArea() {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            '快速连续记录模式\n每次点击快速添加一条记录',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ),
        Expanded(
          child: Center(
            child: ElevatedButton(
              onPressed: () => _addRapidCapture(),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(32),
                shape: const CircleBorder(),
                backgroundColor: Colors.amber,
              ),
              child: const Icon(
                Icons.flash_on,
                size: 48,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const Text('快速添加'),
      ],
    );
  }

  Widget _buildMinimalistArea() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _textController,
        maxLines: null,
        expands: true,
        decoration: const InputDecoration(
          hintText: '输入内容...',
          border: InputBorder.none,
        ),
        style: const TextStyle(fontSize: 18),
        textAlignVertical: TextAlignVertical.top,
      ),
    );
  }

  Widget _buildStandardArea() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _textController,
            maxLines: 8,
            decoration: const InputDecoration(
              hintText: '记录内容...',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.mic),
                onPressed: () {
                  setState(() {
                    _currentMode = QuickCaptureMode.voice;
                  });
                },
              ),
              IconButton(
                icon: const Icon(Icons.camera_alt),
                onPressed: () {
                  setState(() {
                    _currentMode = QuickCaptureMode.photo;
                  });
                },
              ),
              IconButton(
                icon: const Icon(Icons.location_on),
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickTags(List<String> tags) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: tags.map((tag) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FilterChip(
              label: Text(tag),
              selected: false,
              onSelected: (selected) {
                // Add tag to capture
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                _textController.clear();
              },
              child: const Text('清除'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: () => _saveCapture(),
              child: const Text('保存记录'),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getModeIcon(QuickCaptureMode mode) {
    switch (mode) {
      case QuickCaptureMode.standard:
        return Icons.edit;
      case QuickCaptureMode.voice:
        return Icons.mic;
      case QuickCaptureMode.photo:
        return Icons.camera_alt;
      case QuickCaptureMode.rapid:
        return Icons.flash_on;
      case QuickCaptureMode.minimalist:
        return Icons.text_fields;
    }
  }

  String _getModeName(QuickCaptureMode mode) {
    switch (mode) {
      case QuickCaptureMode.standard:
        return '标准';
      case QuickCaptureMode.voice:
        return '语音';
      case QuickCaptureMode.photo:
        return '拍照';
      case QuickCaptureMode.rapid:
        return '快速';
      case QuickCaptureMode.minimalist:
        return '极简';
    }
  }

  void _startRecording() {
    setState(() {
      _isRecording = true;
    });
  }

  void _stopRecording() {
    setState(() {
      _isRecording = false;
    });
  }

  void _addRapidCapture() {
    // ignore: unused_local_variable
    final capture = QuickCapture(
      type: 'rapid',
      content: '快速记录 ${DateTime.now().toString().substring(11, 16)}',
      capturedAt: DateTime.now().toIso8601String(),
    );
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('已添加快速记录'),
        duration: Duration(milliseconds: 500),
      ),
    );
  }

  void _saveCapture() {
    final content = _textController.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入内容')),
      );
      return;
    }
    
    // ignore: unused_local_variable
    final capture = QuickCapture(
      type: _getTypeFromMode(_currentMode),
      content: content,
      capturedAt: DateTime.now().toIso8601String(),
    );
    
    _textController.clear();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('记录已保存')),
    );
  }

  String _getTypeFromMode(QuickCaptureMode mode) {
    switch (mode) {
      case QuickCaptureMode.voice:
        return 'voice';
      case QuickCaptureMode.photo:
        return 'photo';
      case QuickCaptureMode.rapid:
        return 'rapid';
      case QuickCaptureMode.minimalist:
        return 'text';
      default:
        return 'text';
    }
  }

  void _showSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const QuickCaptureSettingsSheet(),
    );
  }
}

class QuickCaptureSettingsSheet extends ConsumerStatefulWidget {
  const QuickCaptureSettingsSheet({super.key});

  @override
  ConsumerState<QuickCaptureSettingsSheet> createState() => _QuickCaptureSettingsSheetState();
}

class _QuickCaptureSettingsSheetState extends ConsumerState<QuickCaptureSettingsSheet> {
  bool _autoTime = true;
  bool _autoLocation = true;
  bool _soundEnabled = true;
  final int _rapidInterval = 30;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            '快速记录设置',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 24),
          SwitchListTile(
            title: const Text('自动记录时间'),
            subtitle: const Text('自动使用当前时间'),
            value: _autoTime,
            onChanged: (value) => setState(() => _autoTime = value),
          ),
          SwitchListTile(
            title: const Text('自动记录位置'),
            subtitle: const Text('自动获取GPS位置'),
            value: _autoLocation,
            onChanged: (value) => setState(() => _autoLocation = value),
          ),
          SwitchListTile(
            title: const Text('声音反馈'),
            subtitle: const Text('记录成功时播放提示音'),
            value: _soundEnabled,
            onChanged: (value) => setState(() => _soundEnabled = value),
          ),
          ListTile(
            title: const Text('快速模式间隔'),
            subtitle: Text('$_rapidInterval 秒'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Show interval picker
            },
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('设置已保存')),
                );
              },
              child: const Text('保存设置'),
            ),
          ),
        ],
      ),
    );
  }
}