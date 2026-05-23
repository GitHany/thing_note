import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/date_formatter.dart';
import '../data/screen_time_repository.dart';
import '../domain/screen_time_entry.dart';

final screenTimeProvider = StateNotifierProvider<ScreenTimeNotifier, AsyncValue<List<ScreenTimeEntry>>>((ref) {
  return ScreenTimeNotifier(ref.watch(screenTimeRepositoryProvider));
});

class ScreenTimeNotifier extends StateNotifier<AsyncValue<List<ScreenTimeEntry>>> {
  final ScreenTimeRepository _repository;

  ScreenTimeNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadScreenTime();
  }

  Future<void> loadScreenTime() async {
    state = const AsyncValue.loading();
    try {
      final entries = await _repository.getAllScreenTime();
      state = AsyncValue.data(entries);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addScreenTime(ScreenTimeEntry entry) async {
    await _repository.insertScreenTime(entry);
    await loadScreenTime();
  }

  Future<void> deleteScreenTime(int id) async {
    await _repository.deleteScreenTime(id);
    await loadScreenTime();
  }

  Future<void> updateScreenTime(ScreenTimeEntry entry) async {
    await _repository.updateScreenTime(entry);
    await loadScreenTime();
  }
}

class ScreenTimeScreen extends ConsumerStatefulWidget {
  const ScreenTimeScreen({super.key});

  @override
  ConsumerState<ScreenTimeScreen> createState() => _ScreenTimeScreenState();
}

class _ScreenTimeScreenState extends ConsumerState<ScreenTimeScreen> {
  String _selectedDate = DateFormatter.formatDate(DateTime.now());

  @override
  Widget build(BuildContext context) {
    final entriesAsync = ref.watch(screenTimeProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('屏幕时间追踪'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          _buildDateSelector(),
          Expanded(
            child: entriesAsync.when(
              data: (entries) => _buildScreenTimeList(entries),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('错误: $e')),
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

  Widget _buildDateSelector() {
    final date = DateTime.parse(_selectedDate);
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).primaryColor.withOpacity(0.1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              setState(() {
                _selectedDate = DateFormatter.formatDate(date.subtract(const Duration(days: 1)));
              });
            },
          ),
          TextButton(
            onPressed: () => _selectDate(context),
            child: Text(
              DateFormatter.formatDateFull(date),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              setState(() {
                _selectedDate = DateFormatter.formatDate(date.add(const Duration(days: 1)));
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildScreenTimeList(List<ScreenTimeEntry> entries) {
    final dailyEntries = entries.where((e) => e.date == _selectedDate).toList();
    final totalMinutes = dailyEntries.fold(0, (sum, e) => sum + e.durationMinutes);
    
    return Column(
      children: [
        _buildSummaryCard(totalMinutes, dailyEntries),
        Expanded(
          child: dailyEntries.isEmpty
              ? const Center(child: Text('暂无记录'))
              : ListView.builder(
                  itemCount: dailyEntries.length,
                  itemBuilder: (context, index) {
                    return _buildScreenTimeItem(dailyEntries[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(int totalMinutes, List<ScreenTimeEntry> entries) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              '${(totalMinutes / 60).toStringAsFixed(1)} 小时',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '今日屏幕使用时间',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            _buildCategoryBreakdown(entries),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBreakdown(List<ScreenTimeEntry> entries) {
    if (entries.isEmpty) return const SizedBox();
    
    final categoryStats = <String, int>{};
    for (final entry in entries) {
      categoryStats[entry.category] = (categoryStats[entry.category] ?? 0) + entry.durationMinutes;
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: categoryStats.entries.map((e) {
        return Chip(
          label: Text('${e.key}: ${(e.value / 60).toStringAsFixed(1)}h'),
          backgroundColor: _getCategoryColor(e.key),
        );
      }).toList(),
    );
  }

  Color _getCategoryColor(String category) {
    final colors = {
      '社交': Colors.blue,
      '视频': Colors.red,
      '游戏': Colors.purple,
      '工作': Colors.green,
      '阅读': Colors.orange,
      '购物': Colors.pink,
      '音乐': Colors.teal,
      '其他': Colors.grey,
    };
    return colors[category] ?? Colors.grey;
  }

  Widget _buildScreenTimeItem(ScreenTimeEntry entry) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getCategoryColor(entry.category),
          child: Icon(
            _getCategoryIcon(entry.category),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(entry.appName ?? entry.category),
        subtitle: Text(entry.note ?? ''),
        trailing: Text(
          '${entry.durationMinutes}分钟',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        onLongPress: () => _showDeleteDialog(context, entry),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    final icons = {
      '社交': Icons.chat,
      '视频': Icons.videocam,
      '游戏': Icons.games,
      '工作': Icons.work,
      '阅读': Icons.book,
      '购物': Icons.shopping_cart,
      '音乐': Icons.music_note,
      '其他': Icons.more_horiz,
    };
    return icons[category] ?? Icons.more_horiz;
  }

  Future<void> _selectDate(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.parse(_selectedDate),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() {
        _selectedDate = DateFormatter.formatDate(date);
      });
    }
  }

  void _showAddDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddScreenTimeDialog(),
    );
  }

  void _showDeleteDialog(BuildContext context, ScreenTimeEntry entry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除记录'),
        content: const Text('确定要删除这条记录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(screenTimeProvider.notifier).deleteScreenTime(entry.id!);
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}

class AddScreenTimeDialog extends ConsumerStatefulWidget {
  const AddScreenTimeDialog({super.key});

  @override
  ConsumerState<AddScreenTimeDialog> createState() => _AddScreenTimeDialogState();
}

class _AddScreenTimeDialogState extends ConsumerState<AddScreenTimeDialog> {
  String _selectedCategory = '其他';
  String? _appName;
  int _durationMinutes = 60;
  String? _note;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('添加屏幕时间'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(labelText: '分类'),
              items: ScreenTimeEntry.categories.map((c) => DropdownMenuItem(
                value: c,
                child: Text(c),
              )).toList(),
              onChanged: (value) => setState(() => _selectedCategory = value!),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(labelText: '应用名称（可选）'),
              onChanged: (value) => _appName = value.isEmpty ? null : value,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('时长: '),
                Expanded(
                  child: Slider(
                    value: _durationMinutes.toDouble(),
                    min: 5,
                    max: 480,
                    divisions: 95,
                    label: '$_durationMinutes 分钟',
                    onChanged: (value) => setState(() => _durationMinutes = value.toInt()),
                  ),
                ),
                Text('$_durationMinutes 分钟'),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(labelText: '备注（可选）'),
              maxLines: 2,
              onChanged: (value) => _note = value.isEmpty ? null : value,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () {
            final entry = ScreenTimeEntry(
              date: DateFormatter.formatDate(DateTime.now()),
              durationMinutes: _durationMinutes,
              category: _selectedCategory,
              appName: _appName,
              note: _note,
              createdAt: DateTime.now().toIso8601String(),
            );
            ref.read(screenTimeProvider.notifier).addScreenTime(entry);
            Navigator.pop(context);
          },
          child: const Text('添加'),
        ),
      ],
    );
  }
}