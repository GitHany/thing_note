import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/time_block/domain/time_block.dart';
import 'package:intl/intl.dart';

class TimeBlockScreen extends ConsumerStatefulWidget {
  const TimeBlockScreen({super.key});

  @override
  ConsumerState<TimeBlockScreen> createState() => _TimeBlockScreenState();
}

class _TimeBlockScreenState extends ConsumerState<TimeBlockScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final blocksAsync = ref.watch(todayTimeBlocksProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('时间块管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (date != null) {
                setState(() {
                  _selectedDate = date;
                });
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Date header
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    setState(() {
                      _selectedDate = _selectedDate.subtract(const Duration(days: 1));
                    });
                  },
                ),
                Text(
                  DateFormat('yyyy年MM月dd日').format(_selectedDate),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    setState(() {
                      _selectedDate = _selectedDate.add(const Duration(days: 1));
                    });
                  },
                ),
              ],
            ),
          ),
          // Time blocks list
          Expanded(
            child: blocksAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('错误: $e')),
              data: (blocks) {
                if (blocks.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.event_busy, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text('今天没有安排时间块'),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => _showAddDialog(context),
                          icon: const Icon(Icons.add),
                          label: const Text('添加时间块'),
                        ),
                      ],
                    ),
                  );
                }
                return _TimeBlockList(blocks: blocks);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _TimeBlockEditor(initialDate: _selectedDate),
    );
  }
}

class _TimeBlockList extends StatelessWidget {
  final List<TimeBlock> blocks;

  const _TimeBlockList({required this.blocks});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: blocks.length,
      itemBuilder: (context, index) {
        final block = blocks[index];
        return _TimeBlockCard(block: block);
      },
    );
  }
}

class _TimeBlockCard extends StatelessWidget {
  final TimeBlock block;

  const _TimeBlockCard({required this.block});

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('HH:mm');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          // TODO: Edit block
        },
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: Color(int.parse(block.color.replaceFirst('#', '0xFF'))),
                width: 4,
              ),
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      block.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          '${timeFormat.format(block.startTime)} - ${timeFormat.format(block.endTime)}',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                    if (block.repeatType != 'none') ...[
                      const SizedBox(height: 4),
                      Chip(
                        label: Text(_getRepeatLabel(block.repeatType)),
                        labelStyle: const TextStyle(fontSize: 10),
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                children: [
                  Text(
                    '${block.durationMinutes}分钟',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () {
                      // TODO: Delete
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getRepeatLabel(String type) {
    switch (type) {
      case 'daily': return '每天';
      case 'weekly': return '每周';
      case 'monthly': return '每月';
      default: return type;
    }
  }
}

class _TimeBlockEditor extends StatefulWidget {
  final DateTime initialDate;

  const _TimeBlockEditor({
    required this.initialDate,
  });

  @override
  State<_TimeBlockEditor> createState() => _TimeBlockEditorState();
}

class _TimeBlockEditorState extends State<_TimeBlockEditor> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _noteController = TextEditingController();

  late DateTime _startTime;
  late DateTime _endTime;
  String _selectedColor = '#2196F3';
  String _repeatType = 'none';

  final List<String> _colors = ['#2196F3', '#4CAF50', '#FF9800', '#F44336', '#9C27B0', '#00BCD4'];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startTime = DateTime(
      widget.initialDate.year,
      widget.initialDate.month,
      widget.initialDate.day,
      now.hour,
      0,
    );
    _endTime = _startTime.add(const Duration(hours: 1));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('HH:mm');

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '添加时间块',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: '标题',
                  hintText: '例如：工作会议',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v?.isEmpty == true ? '请输入标题' : null,
              ),
              const SizedBox(height: 16),
              // Time pickers
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickTime(true),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: '开始时间',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(timeFormat.format(_startTime)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickTime(false),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: '结束时间',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(timeFormat.format(_endTime)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Repeat
              DropdownButtonFormField<String>(
                value: _repeatType,
                decoration: const InputDecoration(
                  labelText: '重复',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'none', child: Text('不重复')),
                  DropdownMenuItem(value: 'daily', child: Text('每天')),
                  DropdownMenuItem(value: 'weekly', child: Text('每周')),
                  DropdownMenuItem(value: 'monthly', child: Text('每月')),
                ],
                onChanged: (v) => setState(() => _repeatType = v!),
              ),
              const SizedBox(height: 16),
              // Color
              const Text('颜色'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _colors.map((color) {
                  final isSelected = color == _selectedColor;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = color),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Color(int.parse(color.replaceFirst('#', '0xFF'))),
                        borderRadius: BorderRadius.circular(18),
                        border: isSelected ? Border.all(color: Colors.black, width: 3) : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              // Note
              TextField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: '备注 (可选)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  child: const Text('保存'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickTime(bool isStart) async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(isStart ? _startTime : _endTime),
    );
    if (time != null) {
      setState(() {
        if (isStart) {
          _startTime = DateTime(
            _startTime.year,
            _startTime.month,
            _startTime.day,
            time.hour,
            time.minute,
          );
          if (_startTime.isAfter(_endTime)) {
            _endTime = _startTime.add(const Duration(hours: 1));
          }
        } else {
          _endTime = DateTime(
            _endTime.year,
            _endTime.month,
            _endTime.day,
            time.hour,
            time.minute,
          );
        }
      });
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    if (_endTime.isBefore(_startTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('结束时间不能早于开始时间')),
      );
      return;
    }

    // TODO: Save time block
    Navigator.pop(context);
  }
}