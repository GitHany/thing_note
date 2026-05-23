import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/smart_dashboard/data/smart_dashboard_repository.dart';
import 'package:thing_note/features/smart_dashboard/domain/smart_dashboard.dart';

final smartDashboardRepoProvider = Provider((ref) => SmartDashboardRepository(ref));

class SmartDashboardScreen extends ConsumerStatefulWidget {
  const SmartDashboardScreen({super.key});

  @override
  ConsumerState<SmartDashboardScreen> createState() => _SmartDashboardScreenState();
}

class _SmartDashboardScreenState extends ConsumerState<SmartDashboardScreen> {
  SmartDashboardConfig? _config;
  bool _isLoading = true;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    setState(() => _isLoading = true);
    final repo = ref.read(smartDashboardRepoProvider);
    await repo.initDefaultConfig();
    _config = await repo.getActiveConfig();
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('智能仪表盘'),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.check : Icons.edit),
            onPressed: () {
              setState(() => _isEditing = !_isEditing);
              if (!_isEditing) _loadConfig();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _config == null
              ? _buildEmptyState()
              : _buildDashboard(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.dashboard, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('暂无仪表盘配置'),
          ElevatedButton.icon(
            onPressed: _loadConfig,
            icon: const Icon(Icons.refresh),
            label: const Text('加载配置'),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildWidgetCard('今日概览', Icons.today, _buildTodayOverview()),
          _buildWidgetCard('记录统计', Icons.list_alt, _buildRecordStats()),
          _buildWidgetCard('习惯进度', Icons.check_circle, _buildHabitProgress()),
          _buildWidgetCard('目标进度', Icons.flag, _buildGoalProgress()),
          _buildWidgetCard('快速操作', Icons.flash_on, _buildQuickActions()),
        ],
      ),
    );
  }

  Widget _buildWidgetCard(String title, IconData icon, Widget content) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildTodayOverview() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Column(
          children: [
            Text('3', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            Text('记录'),
          ],
        ),
        Column(
          children: [
            Text('2h', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            Text('时长'),
          ],
        ),
        Column(
          children: [
            Text('5', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            Text('习惯'),
          ],
        ),
      ],
    );
  }

  Widget _buildRecordStats() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.chevron_right, size: 16),
            Text('本周记录: 15 条'),
          ],
        ),
        Row(
          children: [
            Icon(Icons.chevron_right, size: 16),
            Text('本月记录: 45 条'),
          ],
        ),
        Row(
          children: [
            Icon(Icons.chevron_right, size: 16),
            Text('总记录: 326 条'),
          ],
        ),
      ],
    );
  }

  Widget _buildHabitProgress() {
    return const Column(
      children: [
        LinearProgressIndicator(value: 0.7),
        SizedBox(height: 8),
        Text('完成 7/10 个今日习惯'),
      ],
    );
  }

  Widget _buildGoalProgress() {
    return const Column(
      children: [
        Row(
          children: [
            Icon(Icons.flag, size: 16),
            SizedBox(width: 4),
            Text('学习目标'),
            Spacer(),
            Text('75%'),
          ],
        ),
        LinearProgressIndicator(value: 0.75),
        SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.flag, size: 16),
            SizedBox(width: 4),
            Text('运动目标'),
            Spacer(),
            Text('50%'),
          ],
        ),
        LinearProgressIndicator(value: 0.5),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ActionChip(
          avatar: const Icon(Icons.add, size: 18),
          label: const Text('新记录'),
          onPressed: () {},
        ),
        ActionChip(
          avatar: const Icon(Icons.search, size: 18),
          label: const Text('搜索'),
          onPressed: () {},
        ),
        ActionChip(
          avatar: const Icon(Icons.calendar_today, size: 18),
          label: const Text('日历'),
          onPressed: () {},
        ),
        ActionChip(
          avatar: const Icon(Icons.timer, size: 18),
          label: const Text('专注'),
          onPressed: () {},
        ),
      ],
    );
  }
}