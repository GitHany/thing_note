import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class VoiceSearchScreen extends ConsumerStatefulWidget {
  const VoiceSearchScreen({super.key});

  @override
  ConsumerState<VoiceSearchScreen> createState() => _VoiceSearchScreenState();
}

class _VoiceSearchScreenState extends ConsumerState<VoiceSearchScreen> {
  bool _isListening = false;
  String _transcribedText = '';
  List<String> _searchHistory = [];

  @override
  void initState() {
    super.initState();
    _searchHistory = [
      '工作记录',
      '健身',
      '会议',
      '学习笔记',
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('语音搜索'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          _buildVoiceInput(),
          if (_transcribedText.isNotEmpty) _buildSearchResults(),
          if (_transcribedText.isEmpty) _buildSearchHistory(),
        ],
      ),
    );
  }

  Widget _buildVoiceInput() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          GestureDetector(
            onTap: _toggleListening,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isListening
                    ? Theme.of(context).colorScheme.error
                    : Theme.of(context).colorScheme.primaryContainer,
              ),
              child: Icon(
                _isListening ? Icons.stop : Icons.mic,
                size: 60,
                color: _isListening
                    ? Colors.white
                    : Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _isListening ? '正在聆听...' : '点击开始语音搜索',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          if (_transcribedText.isNotEmpty) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text(
                    '识别结果：',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _transcribedText,
                    style: const TextStyle(fontSize: 18),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    return Expanded(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          const Text(
            '搜索结果',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _buildResultItem('团队会议记录', '05-21 10:00', '工作'),
          _buildResultItem('项目进度汇报', '05-20 14:30', '工作'),
          _buildResultItem('周工作总结', '05-19 17:00', '工作'),
        ],
      ),
    );
  }

  Widget _buildResultItem(String title, String date, String tag) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.description),
        title: Text(title),
        subtitle: Row(
          children: [
            Text(date),
            const SizedBox(width: 8),
            Chip(
              label: Text(tag, style: const TextStyle(fontSize: 10)),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {},
      ),
    );
  }

  Widget _buildSearchHistory() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '搜索历史',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _searchHistory.clear();
                    });
                  },
                  child: const Text('清除'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _searchHistory.length,
              itemBuilder: (context, index) {
                final query = _searchHistory[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const Icon(Icons.history),
                    title: Text(query),
                    trailing: IconButton(
                      icon: const Icon(Icons.mic),
                      onPressed: () {
                        setState(() {
                          _transcribedText = query;
                        });
                      },
                    ),
                    onTap: () {
                      setState(() {
                        _transcribedText = query;
                      });
                    },
                  ),
                );
              },
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Chip(
                  label: Text('支持中文'),
                  avatar: Icon(Icons.translate, size: 18),
                ),
                SizedBox(width: 8),
                Chip(
                  label: Text('离线可用'),
                  avatar: Icon(Icons.cloud_off, size: 18),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _toggleListening() {
    setState(() {
      _isListening = !_isListening;
      if (_isListening) {
        _simulateListening();
      }
    });
  }

  void _simulateListening() async {
    await Future.delayed(const Duration(seconds: 2));
    if (mounted && _isListening) {
      setState(() {
        _transcribedText = '工作记录';
        _isListening = false;
        if (!_searchHistory.contains(_transcribedText)) {
          _searchHistory.insert(0, _transcribedText);
        }
      });
    }
  }
}