import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/morning_checkin/data/morning_checkin_provider.dart';
import 'package:thing_note/features/morning_checkin/domain/morning_checkin.dart';

class MorningCheckinScreen extends ConsumerStatefulWidget {
  const MorningCheckinScreen({super.key});

  @override
  ConsumerState<MorningCheckinScreen> createState() => _MorningCheckinScreenState();
}

class _MorningCheckinScreenState extends ConsumerState<MorningCheckinScreen> {
  int _energyLevel = 3;
  int _moodLevel = 3;
  final _intentionController = TextEditingController();
  final _focusAreaController = TextEditingController();
  final _gratitudeController = TextEditingController();
  final List<String> _priorities = [];
  final _priorityController = TextEditingController();
  bool _isCompleted = false;

  @override
  void dispose() {
    _intentionController.dispose();
    _focusAreaController.dispose();
    _gratitudeController.dispose();
    _priorityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final checkinAsync = ref.watch(todayCheckinProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('晨间签到'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => _showHistory(context),
          ),
        ],
      ),
      body: checkinAsync.when(
        data: (checkin) {
          if (checkin != null && !_isCompleted) {
            _loadExistingCheckin(checkin);
          }
          return _buildCheckinForm();
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  void _loadExistingCheckin(MorningCheckin checkin) {
    _energyLevel = checkin.energyLevel;
    _moodLevel = checkin.moodLevel;
    _intentionController.text = checkin.intention ?? '';
    _focusAreaController.text = checkin.focusArea ?? '';
    _gratitudeController.text = checkin.gratitudeNote ?? '';
    _priorities.clear();
    _priorities.addAll(checkin.priorities);
    _isCompleted = true;
  }

  Widget _buildCheckinForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Center(
            child: Column(
              children: [
                Icon(
                  Icons.wb_sunny,
                  size: 64,
                  color: Colors.orange.shade300,
                ),
                const SizedBox(height: 8),
                Text(
                  '早安，今天也要元气满满！',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  _getGreeting(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Energy Level
          _buildSection(
            '能量水平',
            '你现在的精力状态如何？',
            Column(
              children: [
                _buildSliderRow(
                  Icons.bolt,
                  _energyLevel,
                  (value) => setState(() => _energyLevel = value),
                  ['疲惫', '较低', '一般', '良好', '充沛'],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Mood Level
          _buildSection(
            '心情状态',
            '此刻心情如何？',
            Column(
              children: [
                _buildSliderRow(
                  Icons.mood,
                  _moodLevel,
                  (value) => setState(() => _moodLevel = value),
                  ['很差', '较差', '一般', '良好', '很好'],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Intention
          _buildSection(
            '今日意图',
            '今天最想实现的是什么？',
            TextField(
              controller: _intentionController,
              decoration: const InputDecoration(
                hintText: '例如：保持专注，完成重要任务',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ),
          const SizedBox(height: 16),

          // Focus Area
          _buildSection(
            '聚焦领域',
            '今天需要重点关注的方面？',
            TextField(
              controller: _focusAreaController,
              decoration: const InputDecoration(
                hintText: '例如：工作、学习、家庭',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Priorities
          _buildSection(
            '今日优先级',
            '列出今天最重要的3件事',
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _priorityController,
                        decoration: const InputDecoration(
                          hintText: '输入事项后按回车添加',
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (value) {
                          if (value.isNotEmpty && _priorities.length < 5) {
                            setState(() {
                              _priorities.add(value);
                              _priorityController.clear();
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.add_circle),
                      onPressed: () {
                        if (_priorityController.text.isNotEmpty && _priorities.length < 5) {
                          setState(() {
                            _priorities.add(_priorityController.text);
                            _priorityController.clear();
                          });
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _priorities.asMap().entries.map((entry) {
                    return Chip(
                      label: Text('${entry.key + 1}. ${entry.value}'),
                      onDeleted: () {
                        setState(() => _priorities.removeAt(entry.key));
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Gratitude
          _buildSection(
            '感恩小事',
            '今天想感恩的一件事？',
            TextField(
              controller: _gratitudeController,
              decoration: const InputDecoration(
                hintText: '例如：感谢好天气',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ),
          const SizedBox(height: 24),

          // Save Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _saveCheckin,
              icon: Icon(_isCompleted ? Icons.update : Icons.check),
              label: Text(_isCompleted ? '更新签到' : '完成签到'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String subtitle, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        content,
      ],
    );
  }

  Widget _buildSliderRow(
    IconData icon,
    int value,
    ValueChanged<int> onChanged,
    List<String> labels,
  ) {
    return Row(
      children: [
        Icon(icon, color: Colors.orange),
        Expanded(
          child: Slider(
            value: value.toDouble(),
            min: 1,
            max: 5,
            divisions: 4,
            label: labels[value - 1],
            onChanged: (v) => onChanged(v.toInt()),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$value',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 9) return '早晨时光，适合规划一天';
    if (hour < 12) return '上午黄金时间，效率最高';
    if (hour < 14) return '中午休息，保持能量';
    return '下午时光，继续加油';
  }

  void _saveCheckin() async {
    final checkin = MorningCheckin(
      date: DateTime.now(),
      energyLevel: _energyLevel,
      moodLevel: _moodLevel,
      intention: _intentionController.text.isEmpty ? null : _intentionController.text,
      focusArea: _focusAreaController.text.isEmpty ? null : _focusAreaController.text,
      priorities: _priorities,
      gratitudeNote: _gratitudeController.text.isEmpty ? null : _gratitudeController.text,
      createdAt: DateTime.now(),
    );

    final dbService = ref.read(morningCheckinDbProvider);
    await dbService.saveCheckin(checkin);

    if (mounted) {
      setState(() => _isCompleted = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('签到完成，祝你有美好的一天！')),
      );
    }
  }

  void _showHistory(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MorningCheckinHistoryScreen(),
      ),
    );
  }
}

class MorningCheckinHistoryScreen extends ConsumerWidget {
  const MorningCheckinHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(checkinHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('签到历史'),
      ),
      body: historyAsync.when(
        data: (history) {
          if (history.isEmpty) {
            return const Center(
              child: Text('暂无签到记录'),
            );
          }
          return ListView.builder(
            itemCount: history.length,
            itemBuilder: (context, index) {
              final checkin = history[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${checkin.date.month}/${checkin.date.day}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildChip('能量: ${checkin.energyLevel}'),
                          const SizedBox(width: 8),
                          _buildChip('心情: ${checkin.moodLevel}'),
                        ],
                      ),
                      if (checkin.intention != null) ...[
                        const SizedBox(height: 8),
                        Text('意图: ${checkin.intention}'),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }
}