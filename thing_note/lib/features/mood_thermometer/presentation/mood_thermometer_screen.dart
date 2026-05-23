import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/mood_thermometer/data/mood_thermometer_service.dart';
import 'package:thing_note/features/mood_thermometer/domain/mood_thermometer_models.dart';

/// 情绪温度计屏幕
class MoodThermometerScreen extends ConsumerStatefulWidget {
  const MoodThermometerScreen({super.key});

  @override
  ConsumerState<MoodThermometerScreen> createState() => _MoodThermometerScreenState();
}

class _MoodThermometerScreenState extends ConsumerState<MoodThermometerScreen> {
  List<MoodThermometerRecord> _recentRecords = [];
  MoodThermometerStats? _stats;
  MoodThermometerRecord? _currentMood;
  bool _isLoading = true;
  int _selectedMoodLevel = 50;
  String? _selectedCategory;
  String? _selectedTrigger;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final service = ref.read(moodThermometerServiceProvider);
      final records = await service.getRecentRecords(limit: 7);
      final stats = await service.getStats();
      final current = await service.getCurrentMood();

      setState(() {
        _recentRecords = records;
        _stats = stats;
        _currentMood = current;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('情绪温度计'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => _showHistoryDialog(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildCurrentMoodCard(),
                    const SizedBox(height: 16),
                    _buildThermometerInput(),
                    const SizedBox(height: 16),
                    _buildStatsCards(),
                    const SizedBox(height: 16),
                    _buildRecentRecords(),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showRecordDialog,
        icon: const Icon(Icons.add),
        label: const Text('记录情绪'),
      ),
    );
  }

  /// 当前情绪卡片
  Widget _buildCurrentMoodCard() {
    if (_currentMood == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(
                Icons.thermostat,
                size: 48,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                '还没有记录',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                '点击下方按钮记录您的情绪',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      );
    }

    final moodColor = Color(_currentMood!.moodColorValue);

    return Card(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              moodColor.withOpacity(0.1),
              moodColor.withOpacity(0.3),
            ],
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: moodColor.withOpacity(0.2),
                border: Border.all(color: moodColor, width: 3),
              ),
              child: Center(
                child: Text(
                  '${_currentMood!.moodLevel}',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: moodColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _currentMood!.moodDescription,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: moodColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatDateTime(_currentMood!.recordedAt),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (_currentMood!.category != null) ...[
                    const SizedBox(height: 4),
                    Chip(
                      label: Text(_currentMood!.category!),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showRecordDialog(existingRecord: _currentMood),
            ),
          ],
        ),
      ),
    );
  }

  /// 温度计输入
  Widget _buildThermometerInput() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '快速记录',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            // 温度计可视化
            Container(
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  colors: [
                    Colors.red,
                    Colors.orange,
                    Colors.yellow,
                    Colors.lightGreen,
                    Colors.green,
                  ],
                ),
              ),
              child: SliderTheme(
                data: const SliderThemeData(
                  trackHeight: 40,
                  thumbShape: RoundSliderThumbShape(enabledThumbRadius: 16),
                  overlayShape: RoundSliderOverlayShape(overlayRadius: 24),
                  trackShape: RoundedRectSliderTrackShape(),
                  activeTrackColor: Colors.transparent,
                  inactiveTrackColor: Colors.transparent,
                ),
                child: Slider(
                  value: _selectedMoodLevel.toDouble(),
                  min: 0,
                  max: 100,
                  onChanged: (value) {
                    setState(() {
                      _selectedMoodLevel = value.round();
                    });
                  },
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('😢'),
                Text('$_selectedMoodLevel'),
                const Text('😊'),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildQuickMoodButton(20, '低落'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildQuickMoodButton(50, '一般'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildQuickMoodButton(80, '开心'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickMoodButton(int level, String label) {
    final isSelected = _selectedMoodLevel == level;
    return OutlinedButton(
      onPressed: () => setState(() => _selectedMoodLevel = level),
      style: OutlinedButton.styleFrom(
        backgroundColor: isSelected
            ? Theme.of(context).colorScheme.primaryContainer
            : null,
      ),
      child: Text(label),
    );
  }

  /// 统计卡片
  Widget _buildStatsCards() {
    if (_stats == null || _stats!.totalRecords == 0) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            '平均',
            _stats!.averageMood.toStringAsFixed(0),
            Icons.show_chart,
            _getMoodColor(_stats!.averageMood),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            '最高',
            '${_stats!.highestMood}',
            Icons.arrow_upward,
            Colors.green,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            '最低',
            '${_stats!.lowestMood}',
            Icons.arrow_downward,
            Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  /// 最近记录
  Widget _buildRecentRecords() {
    if (_recentRecords.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '最近7天',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 100,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: _recentRecords.take(7).map((record) {
                  return _buildDayMoodIndicator(record);
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayMoodIndicator(MoodThermometerRecord record) {
    final color = Color(record.moodColorValue);
    final dayNames = ['一', '二', '三', '四', '五', '六', '日'];

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 30,
          height: 60,
          decoration: BoxDecoration(
            color: color.withOpacity(0.3),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: 30,
              height: 60 * (record.moodLevel / 100),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          dayNames[record.recordedAt.weekday - 1],
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  /// 记录对话框
  void _showRecordDialog({MoodThermometerRecord? existingRecord}) {
    _selectedMoodLevel = existingRecord?.moodLevel ?? 50;
    _selectedCategory = existingRecord?.category;
    _selectedTrigger = existingRecord?.trigger;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        existingRecord != null ? '编辑情绪' : '记录情绪',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 情绪滑块
                  Container(
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      gradient: const LinearGradient(
                        colors: [
                          Colors.red,
                          Colors.orange,
                          Colors.yellow,
                          Colors.lightGreen,
                          Colors.green,
                        ],
                      ),
                    ),
                    child: SliderTheme(
                      data: const SliderThemeData(
                        trackHeight: 50,
                        thumbShape: RoundSliderThumbShape(enabledThumbRadius: 20),
                        trackShape: RoundedRectSliderTrackShape(),
                        activeTrackColor: Colors.transparent,
                        inactiveTrackColor: Colors.transparent,
                      ),
                      child: Slider(
                        value: _selectedMoodLevel.toDouble(),
                        min: 0,
                        max: 100,
                        onChanged: (value) {
                          setModalState(() {
                            _selectedMoodLevel = value.round();
                          });
                        },
                      ),
                    ),
                  ),
                  Center(
                    child: Text(
                      '$_selectedMoodLevel - ${_getMoodDescription(_selectedMoodLevel)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: _getMoodColor(_selectedMoodLevel.toDouble()),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 类别选择
                  Text(
                    '类别',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: MoodCategory.values.map((cat) {
                      final isSelected = _selectedCategory == cat.label;
                      return ChoiceChip(
                        label: Text('${cat.emoji} ${cat.label}'),
                        selected: isSelected,
                        onSelected: (selected) {
                          setModalState(() {
                            _selectedCategory = selected ? cat.label : null;
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // 触发因素
                  Text(
                    '触发因素',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: MoodTrigger.common.take(10).map((trigger) {
                      final isSelected = _selectedTrigger == trigger;
                      return ChoiceChip(
                        label: Text(trigger),
                        selected: isSelected,
                        onSelected: (selected) {
                          setModalState(() {
                            _selectedTrigger = selected ? trigger : null;
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  FilledButton(
                    onPressed: () => _saveMood(existingRecord),
                    child: Text(existingRecord != null ? '保存' : '记录'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _saveMood(MoodThermometerRecord? existingRecord) async {
    try {
      final service = ref.read(moodThermometerServiceProvider);

      final record = MoodThermometerRecord(
        id: existingRecord?.id,
        moodLevel: _selectedMoodLevel,
        category: _selectedCategory,
        trigger: _selectedTrigger,
        recordedAt: DateTime.now(),
      );

      if (existingRecord != null) {
        await service.updateRecord(existingRecord.id!, record);
      } else {
        await service.recordMood(record);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('情绪已记录')),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
      }
    }
  }

  void _showHistoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('历史记录'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: FutureBuilder<List<MoodThermometerRecord>>(
            future: ref.read(moodThermometerServiceProvider).getRecentRecords(limit: 30),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final records = snapshot.data!;
              if (records.isEmpty) {
                return const Center(child: Text('暂无记录'));
              }

              return ListView.builder(
                itemCount: records.length,
                itemBuilder: (context, index) {
                  final record = records[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Color(record.moodColorValue).withOpacity(0.2),
                      child: Text(
                        '${record.moodLevel}',
                        style: TextStyle(
                          color: Color(record.moodColorValue),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(record.moodDescription),
                    subtitle: Text(_formatDateTime(record.recordedAt)),
                    trailing: record.category != null
                        ? Chip(label: Text(record.category!))
                        : null,
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  Color _getMoodColor(double level) {
    if (level >= 80) return Colors.green;
    if (level >= 60) return Colors.lightGreen;
    if (level >= 40) return Colors.yellow;
    if (level >= 20) return Colors.orange;
    return Colors.red;
  }

  String _getMoodDescription(int level) {
    if (level >= 90) return '非常好';
    if (level >= 80) return '很好';
    if (level >= 70) return '不错';
    if (level >= 60) return '良好';
    if (level >= 50) return '一般';
    if (level >= 40) return '有点低落';
    if (level >= 30) return '不太好';
    if (level >= 20) return '低落';
    if (level >= 10) return '很差';
    return '非常差';
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inMinutes < 60) return '${diff.inMinutes} 分钟前';
    if (diff.inHours < 24) return '${diff.inHours} 小时前';
    if (diff.inDays < 7) return '${diff.inDays} 天前';

    return '${dateTime.month}/${dateTime.day} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}