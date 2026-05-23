import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/journal/domain/journal.dart';
import 'package:thing_note/features/journal/data/journal_provider.dart';
import 'package:intl/intl.dart';

class JournalScreen extends ConsumerStatefulWidget {
  const JournalScreen({super.key});

  @override
  ConsumerState<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends ConsumerState<JournalScreen> {
  String _selectedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

  @override
  Widget build(BuildContext context) {
    final journalAsync = ref.watch(journalNotifierProvider);
    final dateFormat = DateFormat('yyyy-MM-dd');
    final displayFormat = DateFormat('yyyy年MM月dd日');

    return Scaffold(
      appBar: AppBar(
        title: const Text('日记本'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: dateFormat.parse(_selectedDate),
                firstDate: DateTime(2020),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (date != null) {
                setState(() {
                  _selectedDate = dateFormat.format(date);
                });
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 日期选择器
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    final current = dateFormat.parse(_selectedDate);
                    setState(() {
                      _selectedDate = dateFormat.format(current.subtract(const Duration(days: 1)));
                    });
                  },
                ),
                Text(
                  displayFormat.format(dateFormat.parse(_selectedDate)),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    final current = dateFormat.parse(_selectedDate);
                    setState(() {
                      _selectedDate = dateFormat.format(current.add(const Duration(days: 1)));
                    });
                  },
                ),
              ],
            ),
          ),
          // 今日日记列表
          Expanded(
            child: journalAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('错误: $e')),
              data: (journals) {
                final todayJournals = journals.where((j) => j.date == _selectedDate).toList();
                if (todayJournals.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.book_outlined, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text('今天还没有写日记'),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => _showEditor(context, null),
                          icon: const Icon(Icons.add),
                          label: const Text('写日记'),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: todayJournals.length,
                  itemBuilder: (context, index) {
                    final journal = todayJournals[index];
                    return _JournalCard(
                      journal: journal,
                      onTap: () => _showEditor(context, journal),
                      onDelete: () => _deleteJournal(journal.id!),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEditor(context, null),
        child: const Icon(Icons.edit),
      ),
    );
  }

  void _showEditor(BuildContext context, Journal? journal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _JournalEditor(
        initialDate: _selectedDate,
        existingJournal: journal,
      ),
    );
  }

  Future<void> _deleteJournal(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除日记'),
        content: const Text('确定要删除这篇日记吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(journalNotifierProvider.notifier).deleteJournal(id);
    }
  }
}

class _JournalCard extends StatelessWidget {
  final Journal journal;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _JournalCard({
    required this.journal,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (journal.mood != null) ...[
                    Text(_getMoodEmoji(journal.mood!), style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 8),
                  ],
                  if (journal.weather != null) ...[
                    Text(_getWeatherEmoji(journal.weather!), style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                  ],
                  if (journal.isPrivate)
                    const Icon(Icons.lock, size: 20, color: Colors.grey),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: onDelete,
                  ),
                ],
              ),
              const Divider(),
              Text(
                journal.content,
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getMoodEmoji(String mood) {
    switch (mood) {
      case 'great': return '😄';
      case 'good': return '🙂';
      case 'neutral': return '😐';
      case 'bad': return '😔';
      case 'terrible': return '😢';
      default: return '😐';
    }
  }

  String _getWeatherEmoji(String weather) {
    switch (weather) {
      case 'sunny': return '☀️';
      case 'cloudy': return '⛅';
      case 'rainy': return '🌧️';
      case 'snowy': return '❄️';
      case 'windy': return '💨';
      default: return '🌤️';
    }
  }
}

class _JournalEditor extends ConsumerStatefulWidget {
  final String initialDate;
  final Journal? existingJournal;

  const _JournalEditor({
    required this.initialDate,
    this.existingJournal,
  });

  @override
  ConsumerState<_JournalEditor> createState() => _JournalEditorState();
}

class _JournalEditorState extends ConsumerState<_JournalEditor> {
  late TextEditingController _contentController;
  String? _selectedMood;
  String? _selectedWeather;
  bool _isPrivate = false;

  final List<String> _moods = ['great', 'good', 'neutral', 'bad', 'terrible'];
  final List<String> _weatherOptions = ['sunny', 'cloudy', 'rainy', 'snowy', 'windy'];

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController(
      text: widget.existingJournal?.content ?? '',
    );
    _selectedMood = widget.existingJournal?.mood;
    _selectedWeather = widget.existingJournal?.weather;
    _isPrivate = widget.existingJournal?.isPrivate ?? false;
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.existingJournal == null ? '写日记' : '编辑日记',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 心情选择
            const Text('心情'),
            const SizedBox(height: 8),
            Row(
              children: _moods.map((mood) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(_getMoodEmoji(mood)),
                    selected: _selectedMood == mood,
                    onSelected: (selected) {
                      setState(() {
                        _selectedMood = selected ? mood : null;
                      });
                    },
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            // 天气选择
            const Text('天气'),
            const SizedBox(height: 8),
            Row(
              children: _weatherOptions.map((weather) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(_getWeatherEmoji(weather)),
                    selected: _selectedWeather == weather,
                    onSelected: (selected) {
                      setState(() {
                        _selectedWeather = selected ? weather : null;
                      });
                    },
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            // 私密模式
            Row(
              children: [
                const Text('私密日记'),
                const Spacer(),
                Switch(
                  value: _isPrivate,
                  onChanged: (value) {
                    setState(() {
                      _isPrivate = value;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 内容输入
            TextField(
              controller: _contentController,
              maxLines: 8,
              decoration: const InputDecoration(
                hintText: '今天发生了什么...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            // 保存按钮
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveJournal,
                child: const Text('保存'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getMoodEmoji(String mood) {
    switch (mood) {
      case 'great': return '😄';
      case 'good': return '🙂';
      case 'neutral': return '😐';
      case 'bad': return '😔';
      case 'terrible': return '😢';
      default: return '😐';
    }
  }

  String _getWeatherEmoji(String weather) {
    switch (weather) {
      case 'sunny': return '☀️';
      case 'cloudy': return '⛅';
      case 'rainy': return '🌧️';
      case 'snowy': return '❄️';
      case 'windy': return '💨';
      default: return '🌤️';
    }
  }

  void _saveJournal() {
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入日记内容')),
      );
      return;
    }

    final now = DateTime.now();
    final journal = Journal(
      id: widget.existingJournal?.id,
      date: widget.initialDate,
      content: _contentController.text.trim(),
      mood: _selectedMood,
      weather: _selectedWeather,
      isPrivate: _isPrivate,
      linkedRecordIds: widget.existingJournal?.linkedRecordIds,
      createdAt: widget.existingJournal?.createdAt ?? now,
      updatedAt: now,
    );

    if (widget.existingJournal == null) {
      ref.read(journalNotifierProvider.notifier).addJournal(journal);
    } else {
      ref.read(journalNotifierProvider.notifier).updateJournal(journal);
    }

    Navigator.pop(context);
  }
}