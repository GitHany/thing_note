import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thing_note/features/scheduled_digest/data/scheduled_digest_service.dart';
import '../domain/scheduled_digest_models.dart';

/// 定时摘要屏幕
class ScheduledDigestScreen extends ConsumerStatefulWidget {
  const ScheduledDigestScreen({super.key});

  @override
  ConsumerState<ScheduledDigestScreen> createState() => _ScheduledDigestScreenState();
}

class _ScheduledDigestScreenState extends ConsumerState<ScheduledDigestScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DigestConfig? _config;
  DigestData? _todayDigest;
  DigestData? _weekDigest;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final service = ref.read(scheduledDigestServiceProvider);
      final config = await service.getConfig();
      final todayDigest = await service.generateDigest(DigestFrequency.daily);
      final weekDigest = await service.generateDigest(DigestFrequency.weekly);

      setState(() {
        _config = config;
        _todayDigest = todayDigest;
        _weekDigest = weekDigest;
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
        title: const Text('定时摘要'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '今日'),
            Tab(text: '本周'),
            Tab(text: '设置'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildDigestTab(_todayDigest, '今天'),
                _buildDigestTab(_weekDigest, '本周'),
                _buildSettingsTab(),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _generateDigest(),
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildDigestTab(DigestData? digest, String periodName) {
    if (digest == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.summarize,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              '暂无 $periodName 摘要',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '开始记录后，这里会显示您的 $periodName 摘要',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 概览卡片
          _buildOverviewCard(digest, periodName),
          const SizedBox(height: 16),

          // AI 洞察
          if (digest.aiInsight != null) ...[
            _buildInsightCard(digest.aiInsight!),
            const SizedBox(height: 16),
          ],

          // 统计数据
          _buildStatsCard(digest),
          const SizedBox(height: 16),

          // 高亮记录
          if (digest.highlights.isNotEmpty) ...[
            _buildHighlightsCard(digest.highlights),
            const SizedBox(height: 16),
          ],

          // 标签排行
          if (digest.topTags.isNotEmpty) ...[
            _buildTopTagsCard(digest.topTags),
            const SizedBox(height: 16),
          ],

          // 事情排行
          if (digest.topThings.isNotEmpty) ...[
            _buildTopThingsCard(digest.topThings),
          ],
        ],
      ),
    );
  }

  Widget _buildOverviewCard(DigestData digest, String periodName) {
    return Card(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primaryContainer,
              Theme.of(context).colorScheme.secondaryContainer,
            ],
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.summarize,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '$periodName 摘要',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildOverviewItem(
                  Icons.edit_note,
                  '${digest.totalRecords}',
                  '条记录',
                ),
                _buildOverviewItem(
                  Icons.schedule,
                  _formatMinutes(digest.totalMinutes),
                  '总时长',
                ),
                _buildOverviewItem(
                  Icons.calendar_today,
                  '${digest.activeDays}',
                  '活跃天',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, size: 24, color: Theme.of(context).colorScheme.primary),
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
    );
  }

  Widget _buildInsightCard(String insight) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.lightbulb,
                  color: Colors.amber,
                ),
                const SizedBox(width: 8),
                Text(
                  '智能洞察',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              insight,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard(DigestData digest) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '统计详情',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _buildStatRow('记录数', '${digest.totalRecords} 条'),
            _buildStatRow('总时长', _formatMinutes(digest.totalMinutes)),
            _buildStatRow('活跃天数', '${digest.activeDays} 天'),
            if (digest.averageMood != null)
              _buildStatRow('平均情绪', digest.averageMood!.toStringAsFixed(1)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightsCard(List<Map<String, dynamic>> highlights) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber),
                const SizedBox(width: 8),
                Text(
                  '精彩记录',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...highlights.map((h) {
              return ListTile(
                leading: const Icon(Icons.photo),
                title: Text(h['note']?.toString() ?? '记录'),
                subtitle: Text('${(h['photo_count'] as int? ?? 0)} 张照片'),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTopTagsCard(List<String> tags) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.label, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  '热门标签',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: tags.map((tag) {
                return Chip(
                  label: Text(tag),
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopThingsCard(List<String> things) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.category, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  '常用事情',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: things.map((thing) {
                return Chip(
                  avatar: const Icon(Icons.bookmark, size: 16),
                  label: Text(thing),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTab() {
    if (_config == null) return const SizedBox.shrink();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SwitchListTile(
          title: const Text('启用定时摘要'),
          subtitle: const Text('自动生成并发送摘要'),
          value: _config!.enabled,
          onChanged: (value) async {
            final service = ref.read(scheduledDigestServiceProvider);
            await service.saveConfig(_config!.copyWith(enabled: value));
            _loadData();
          },
        ),
        const Divider(),
        ListTile(
          title: const Text('摘要频率'),
          subtitle: Text(_config!.frequency == DigestFrequency.daily ? '每日' : 
                         _config!.frequency == DigestFrequency.weekly ? '每周' : '每月'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {},
        ),
        ListTile(
          title: const Text('发送时间'),
          subtitle: Text(_getTimeLabel(_config!.defaultTime)),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {},
        ),
        const Divider(),
        ListTile(
          title: const Text('内容类型'),
          subtitle: Text(_config!.contentTypes.map((t) => t.name).join(', ')),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {},
        ),
        SwitchListTile(
          title: const Text('自动发送'),
          subtitle: const Text('摘要生成后自动发送通知'),
          value: _config!.autoSend,
          onChanged: (value) async {
            final service = ref.read(scheduledDigestServiceProvider);
            await service.saveConfig(_config!.copyWith(autoSend: value));
            _loadData();
          },
        ),
      ],
    );
  }

  String _getTimeLabel(DigestTime time) {
    switch (time) {
      case DigestTime.morning:
        return '早上 8:00';
      case DigestTime.afternoon:
        return '下午 14:00';
      case DigestTime.evening:
        return '晚上 20:00';
    }
  }

  String _formatMinutes(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return '${hours}h${mins > 0 ? "${mins}m" : ""}';
  }

  Future<void> _generateDigest() async {
    try {
      final service = ref.read(scheduledDigestServiceProvider);
      final digest = await service.generateDigest(DigestFrequency.daily);
      await service.saveDigest(digest);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('摘要已生成')),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('生成失败: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}